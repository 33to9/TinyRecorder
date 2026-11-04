//
//  StatusBarItem.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import SwiftUI
import AppKit

/// macOS 27 regression workaround.
///
/// The whole menu bar item is a SwiftUI view hosted inside `statusBarItem.button`. Since
/// macOS 27 every mouse event delivered inside the status item's window reports
/// `locationInWindow` as the *centre* of that window, wherever the pointer really is.
/// SwiftUI hit-tests that single fixed point, so only the control sitting in the middle of
/// the item can ever be activated: the stop / pause / camera buttons of the recording bar
/// receive the press only if they happen to be centred, and in practice clicks do nothing.
/// Hover is unaffected, which is why the item still highlights and looks functional.
///
/// The click itself is not lost: the events do arrive at the status item's window, hover
/// and tracking areas still work, and `NSEvent.mouseLocation` is exact. Only the position
/// reported by the event is wrong, so the cheapest repair is to rebuild those events with
/// the real pointer position before AppKit dispatches them. On earlier systems the two
/// already agree and the event is returned untouched.
func installStatusBarEventLocationFix() {
    // Only macOS 27+ is affected; leave older systems completely untouched.
    guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 else { return }
    NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { event in
        guard event.type == .leftMouseDown || event.type == .leftMouseUp,
              let window = event.window,
              window === statusBarItem?.button?.window else { return event }

        // Real pointer position in Cocoa global coordinates (bottom-left origin).
        // Must be NSEvent.mouseLocation: on macOS 27 the event's own position, including
        // `event.cgEvent?.location`, carries the same bogus window-centre point as
        // `locationInWindow`. Using it (v1.7.15/v1.7.16) made this fix a no-op and the
        // stop / pause buttons unclickable again.
        let screenPoint = NSEvent.mouseLocation
        // Only rewrite clicks that really happen inside the status item window. Allow 1pt
        // of slack: a pointer pushed against the top screen edge sits exactly on maxY,
        // which NSRect.contains excludes.
        guard window.frame.insetBy(dx: -1, dy: -1).contains(screenPoint) else { return event }

        var real = window.convertPoint(fromScreen: screenPoint)
        real.x = min(max(real.x, 0), window.frame.width - 1)
        real.y = min(max(real.y, 0), window.frame.height - 1)
        let reported = event.locationInWindow
        guard abs(real.x - reported.x) > 0.5 || abs(real.y - reported.y) > 0.5 else { return event }

        return NSEvent.mouseEvent(with: event.type,
                                  location: real,
                                  modifierFlags: event.modifierFlags,
                                  timestamp: event.timestamp,
                                  windowNumber: event.windowNumber,
                                  context: nil,
                                  eventNumber: event.eventNumber,
                                  clickCount: event.clickCount,
                                  pressure: event.pressure) ?? event
    }
}

/// Time at which the status item was first seen occluded (nil while visible).
/// Used to debounce the fallback "Recording Controller" panel so it does not
/// flicker when the occlusion state toggles briefly.
private var statusBarOccludedSince: Date?

class PopoverState: ObservableObject {
    static let shared = PopoverState()
    @Published var isShowing: Bool = false
    @Published var isPaused: Bool = false
}

struct StatusBarItem: View {
    @State private var deviceWindowIsShowing = true
    @State private var isMainMenuShowing = false
    @State private var isHovering = false
    @State private var recordingLength = "00:00"
    //@State private var isPassed = SCContext.isPaused
    @StateObject private var popoverState = PopoverState.shared
    //@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("miniStatusBar") private var miniStatusBar: Bool = false
    //@AppStorage("highlightMouse") private var highlightMouse: Bool = false
    private var appDelegate = AppDelegate.shared
    
    var body: some View {
        HStack(spacing: 0) {
            if SCContext.streamType != nil {
                ZStack {
                    Rectangle()
                        .fill(Color.mypurple)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .cornerRadius(4)
                    HStack(spacing: 4) {
                        if miniStatusBar {
                            if isHovering {
                                Button(action: {
                                    if SCContext.streamType == .idevice {
                                        AVOutputClass.shared.stopRecording()
                                    } else {
                                        SCContext.stopRecording()
                                    }
                                }, label: {
                                    ZStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.red)
                                            .frame(width: 10, alignment: .center)
                                        Image(systemName: "stop.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }
                                }).buttonStyle(.plain)
                                if SCContext.streamType != .idevice {
                                    Button(action: {
                                        SCContext.pauseRecording()
                                    }, label: {
                                        Image(systemName: popoverState.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }).buttonStyle(.plain)
                                } else {
                                    Button(action:{
                                        DispatchQueue.main.async {
                                            if deviceWindow.isVisible { deviceWindow.close() } else { deviceWindow.orderFront(nil) }
                                            deviceWindowIsShowing = deviceWindow.isVisible
                                        }
                                    }, label: {
                                        Image(systemName: "eye.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                            .opacity(deviceWindowIsShowing ? 1 : 0.7)
                                    }).buttonStyle(.plain)
                                }
                                if SCContext.streamType != .systemaudio && SCContext.streamType != .idevice && SCContext.streamType != .window {
                                    Button(action:{
                                        popoverState.isShowing = true
                                    }, label: {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }).buttonStyle(.plain)
                                }
                            } else {
                                Text(recordingLength)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 15).monospaced())
                                    .offset(x: 0.5)
                            }
                        } else {
                            Group {
                                Button(action: {
                                    if SCContext.streamType == .idevice {
                                        AVOutputClass.shared.stopRecording()
                                    } else {
                                        SCContext.stopRecording()
                                    }
                                }, label: {
                                    ZStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.red)
                                            .frame(width: 10, alignment: .center)
                                        Image(systemName: "stop.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }
                                }).buttonStyle(.plain)
                                if SCContext.streamType != .idevice {//&& SCContext.streamType != .systemaudio {
                                    Button(action: {
                                        SCContext.pauseRecording()
                                    }, label: {
                                        Image(systemName: popoverState.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }).buttonStyle(.plain)
                                }
                                Text(recordingLength)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 15).monospaced())
                                    .offset(x: 0.5)
                            }
                        }
                    }
                }
                .padding([.leading,.trailing], 4)
                .popover(isPresented: $popoverState.isShowing, arrowEdge: .bottom) {
                    CameraPopoverView(closePopover: { popoverState.isShowing = false })
                }
                .onReceive(updateTimer) { t in
                    recordingLength = SCContext.getRecordingLength()
                    // 按实际录制时长（不含暂停）判断自动停止；暂停期间不会触发
                    if SCContext.autoStop != 0 && !SCContext.isPaused && SCContext.timePassed / 60 >= CGFloat(SCContext.autoStop) { SCContext.stopRecording() }
                    if let visible = statusBarItem.button?.window?.occlusionState.contains(.visible) {
                        if visible {
                            statusBarOccludedSince = nil
                            NSApp.windows.first(where: { $0.title == "Recording Controller".local })?.close(); return
                        }
                        // The user can turn the on-screen controller off completely (#250)
                        if !ud.bool(forKey: "showFloatingController") { return }
                        // Debounce: only show the fallback panel after the status item has
                        // stayed occluded for about a second.
                        let now = Date()
                        if statusBarOccludedSince == nil { statusBarOccludedSince = now }
                        if now.timeIntervalSince(statusBarOccludedSince ?? now) < 0.9 { return }
                        if SCContext.streamType != nil  && !visible && !(NSApp.windows.first(where: { $0.title == "Recording Controller".local })?.isVisible ?? false) {
                            guard let screen = SCContext.getScreenWithMouse() else { return }
                            let width = getStatusBarWidth()
                            let wX = (screen.frame.width - width) / 2 + screen.frame.minX
                            let contentView = NSHostingView(rootView: StatusBarItem())
                            contentView.frame = NSRect(x: wX, y: screen.visibleFrame.maxY, width: width, height: 24)
                            controlPanel.setFrame(contentView.frame, display: true)
                            controlPanel.contentView = contentView
                            controlPanel.makeKeyAndOrderFront(nil)
                        }
                    }
                }
                if !miniStatusBar {
                    if SCContext.streamType != .systemaudio {
                        if SCContext.streamType != .idevice {
                            Button(action:{
                                popoverState.isShowing = true
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .fill(SCContext.isCameraRunning() ? Color.mygreen : .gray)
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                        .cornerRadius(4)
                                    Image("camera")
                                        .foregroundStyle(.white)
                                }.frame(width: 36).padding([.leading,.trailing], 4)
                            }).buttonStyle(.plain)
                        } else {
                            Button(action:{
                                DispatchQueue.main.async {
                                    if deviceWindow.isVisible { deviceWindow.close() } else { deviceWindow.orderFront(nil) }
                                }
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .fill(deviceWindow.isVisible ? Color.myblue : .gray.opacity(0.7))
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                        .cornerRadius(4)
                                    Image(systemName: "apps.ipad")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }.frame(width: 36).padding([.leading,.trailing], 4)
                            })
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else if ud.bool(forKey: "showMenubar") {
                Button(action: {
                    popoverState.isShowing = true
                }, label: {
                    ZStack {
                        Color.white.opacity(0.0001)
                        Image(systemName: "dot.circle.and.hand.point.up.left.fill")
                            .font(.system(size: 14, weight: .medium))
                            .offset(y: 1)
                    }
                })
                .buttonStyle(.plain)
                .popover(isPresented: $popoverState.isShowing, arrowEdge: .bottom) {
                    if #available(macOS 13, *) {
                        ContentViewNew().onAppear{ closeAllWindow() }
                    } else {
                        ContentView(fromStatusBar: true)
                            .onAppear{
                                closeAllWindow()
                                if isMacOS12 { NSApp.activate(ignoringOtherApps: true) }
                            }
                    }
                }
            }
        }
        .onTapGesture {}
        .onHover { hovering in
            isHovering = hovering
            hideMousePointer = hovering
            hideScreenMagnifier = hovering
        }
    }
}

func updateStatusBar() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        if SCContext.streamType == nil && !ud.bool(forKey: "showMenubar") {
            statusBarItem.isVisible = false
            return
        }
        guard let button = statusBarItem.button else { return }
        //let width = SCContext.streamType == nil ? 36 : ((SCContext.streamType == .idevice || SCContext.streamType == .systemaudio) ? 138 : 158)
        let iconView = NSHostingView(rootView: StatusBarItem().padding(.top, isMacOS14 ? -2 : -1))
        iconView.frame = NSRect(x: 0, y: 1, width: getStatusBarWidth(), height: isMacOS14 ? 22 : 21)
        button.subviews = [iconView]
        button.frame = iconView.frame
        button.setAccessibilityLabel("TinyRecorder")
        statusBarItem.isVisible = true
    }
}
