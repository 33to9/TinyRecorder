//
//  QuickRecorderApp.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import AppKit
import SwiftUI
import AVFAudio
import AVFoundation
import ScreenCaptureKit
import UserNotifications
import KeyboardShortcuts
import ServiceManagement
import CoreMediaIO
import Sparkle
import VideoToolbox

let isMacOS12 = ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 12
let isMacOS14 = ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 14
let isMacOS15 = ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 15
var scPerm = false
let fd = FileManager.default
// Show the menu bar icon by default (new-user friendly).
// Users can still turn it off in Settings at any time.
let ud: UserDefaults = {
    let defaults = UserDefaults.standard
    defaults.register(defaults: ["showMenubar": true])
    return defaults
}()
var statusBarItem: NSStatusItem!
var mouseMonitor: Any?
var keyMonitor: Any?
/// Global monitor that follows the pointer across displays while the area selector is shown.
/// Kept separate from `mouseMonitor` (mouse highlight / magnifier during recording).
var areaSelectorScreenMonitor: Any?
/// True while the area selector is being moved to another display. Window-close handlers
/// of the old "Start Recording" panel check it so they don't tear down the new selector.
var isSwitchingAreaSelectorScreen = false
var hideMousePointer = false
var hideScreenMagnifier = false
let updateTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
let mousePointer = NSWindow(contentRect: NSRect(x: -70, y: -70, width: 70, height: 70), styleMask: [.borderless], backing: .buffered, defer: false)
let screenMagnifier = NSWindow(contentRect: NSRect(x: -402, y: -402, width: 402, height: 348), styleMask: [.borderless], backing: .buffered, defer: false)
let camWindow = NSPanel(contentRect: NSRect(x: 200, y: 200, width: 200, height: 200), styleMask: [.fullSizeContentView, .resizable, .nonactivatingPanel], backing: .buffered, defer: false)
let deviceWindow = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 200, height: 200), styleMask: [.fullSizeContentView, .resizable], backing: .buffered, defer: false)
let controlPanel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 10, height: 10), styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
let countdownPanel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 120, height: 120), styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
let previewWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 266, height: 156), styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
var updaterController: SPUStandardUpdaterController!

@main
struct QuickRecorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    //private let updaterController: SPUStandardUpdaterController
        
    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        Analytics.start()
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: qmaPackageHandle()) { file in
            //if SCContext.stream == nil {
                if let fileURL = file.fileURL {
                    qmaPlayerView(document: file.$document, fileURL: fileURL)
                        .frame(minWidth: 400, minHeight: 100, maxHeight: 100)
                        .focusable(false)
                }
            //}
        }
        .myWindowIsContentResizable()
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .saveItem) {}
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .textEditing) {}
        }
        
        Settings {
            SettingsView()
                .background(
                    WindowAccessor(
                        onWindowOpen: { w in
                            if let w = w {
                                //w.level = .floating
                                w.titlebarSeparatorStyle = .none
                                if #unavailable(macOS 13) {
                                    // Legacy NavigationView on macOS 12: pin the sidebar width
                                    // through the underlying NSSplitViewController.
                                    guard let nsSplitView = findNSSplitVIew(view: w.contentView),
                                          let controller = nsSplitView.delegate as? NSSplitViewController else { return }
                                    controller.splitViewItems.first?.canCollapse = false
                                    controller.splitViewItems.first?.minimumThickness = 140
                                    controller.splitViewItems.first?.maximumThickness = 140
                                }
                                w.orderFront(nil)
                            }
                        })
                )
        }
        .handlesExternalEvents(matching: [])
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}

extension Scene {
    func myWindowIsContentResizable() -> some Scene {
        if #available(macOS 13.0, *) {
            return self.windowResizability(.contentSize)
        }
        else {
            return self
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, SCStreamDelegate, SCStreamOutput, AVCaptureVideoDataOutputSampleBufferDelegate  {
    static let shared = AppDelegate()
    var filter: SCContentFilter?
    var isCameraReady = false
    var isPresenterON = false
    var isResizing = false
    var presenterType = "OFF"
    var frameQueue = FixedLengthArray<CMTime>(maxLength: 20)
    
    @AppStorage("showOnDock")       var showOnDock: Bool = true
    @AppStorage("showMenubar")      var showMenubar: Bool = true
    @AppStorage("enableAEC")        var enableAEC: Bool = false
    @AppStorage("recordMic")        var recordMic: Bool = false
    @AppStorage("micDevice")        var micDevice: String = "default"
    @AppStorage("remuxAudio")       var remuxAudio: Bool = true
    @AppStorage("recordWinSound")   var recordWinSound: Bool = true
    @AppStorage("recordHDR")        var recordHDR: Bool = false
    @AppStorage("encoder")          var encoder: Encoder = .h264
    @AppStorage("highRes")          var highRes: Int = 2
    @AppStorage("AECLevel")         var AECLevel: String = "mid"
    @AppStorage("withAlpha")        var withAlpha: Bool = false
    @AppStorage("saveDirectory")    var saveDirectory: String?
    @AppStorage("countdown")        var countdown: Int = 0
    @AppStorage("poSafeDelay")      var poSafeDelay: Int = 1
    @AppStorage("highlightMouse")   var highlightMouse: Bool = false
    @AppStorage("includeMenuBar")   var includeMenuBar: Bool = true
    @AppStorage("hideDesktopFiles") var hideDesktopFiles: Bool = false
    @AppStorage("trimAfterRecord")  var trimAfterRecord: Bool = false
    @AppStorage("miniStatusBar")    var miniStatusBar: Bool = false
    @AppStorage("hideSelf")         var hideSelf: Bool = true
    @AppStorage("preventSleep")     var preventSleep: Bool = true
    @AppStorage("showPreview")      var showPreview: Bool = true
    @AppStorage("background")       var background: BackgroundType = .wallpaper
    @AppStorage("showMouse")        var showMouse: Bool = true
    @AppStorage("frameRate")        var frameRate: Int = 60
    @AppStorage("videoQuality")     var videoQuality: Double = 1.0
    @AppStorage("videoFormat")      var videoFormat: VideoFormat = .mp4
    @AppStorage("audioFormat")      var audioFormat: AudioFormat = .aac
    @AppStorage("audioQuality")     var audioQuality: AudioQuality = .high
    @AppStorage("pixelFormat")      var pixelFormat: PixFormat = .delault
    @AppStorage("hideCCenter")      var hideCCenter: Bool = false
    
    func mousePointerReLocation(event: NSEvent) {
        if event.type == .scrollWheel { return }
        if !highlightMouse || hideMousePointer || SCContext.stream == nil || SCContext.streamType == .window {
            mousePointer.orderOut(nil)
            return
        }
        let mouseLocation = event.locationInWindow
        var windowFrame = mousePointer.frame
        windowFrame.origin = NSPoint(x: mouseLocation.x - windowFrame.width / 2, y: mouseLocation.y - windowFrame.height / 2)
        mousePointer.contentView = NSHostingView(rootView: MousePointerView(event: event))
        mousePointer.setFrameOrigin(windowFrame.origin)
        mousePointer.orderFront(nil)
    }
    
    func screenMagnifierReLocation(event: NSEvent) {
        if !SCContext.isMagnifierEnabled || hideScreenMagnifier { screenMagnifier.orderOut(nil); return }
        let mouseLocation = event.locationInWindow
        var windowFrame = screenMagnifier.frame
        windowFrame.origin = NSPoint(x: mouseLocation.x - windowFrame.width / 2, y: mouseLocation.y - windowFrame.height / 2)
        // Capture only the small area around the cursor (Cocoa global coordinates),
        // which also works across multiple displays.
        let rect = NSRect(x: mouseLocation.x - 67, y: mouseLocation.y - 58, width: 134, height: 116)
        guard let croppedImage = NSImage.createScreenShot(cocoaRect: rect) else { return }
        let magnifierView = ScreenMagnifier(screenShot: croppedImage, event: event)
        if let host = screenMagnifier.contentView as? NSHostingView<ScreenMagnifier> {
            host.rootView = magnifierView
        } else {
            screenMagnifier.contentView = NSHostingView(rootView: magnifierView)
        }
        screenMagnifier.setFrameOrigin(windowFrame.origin)
        screenMagnifier.orderFront(nil)
    }
    
    func registerGlobalMouseMonitor() {
        if let monitor = mouseMonitor { NSEvent.removeMonitor(monitor); mouseMonitor = nil }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel, .mouseMoved, .rightMouseUp, .rightMouseDown, .rightMouseDragged, .leftMouseUp,  .leftMouseDown, .leftMouseDragged, .otherMouseUp, .otherMouseDown, .otherMouseDragged]) { event in
            self.mousePointerReLocation(event: event)
            self.screenMagnifierReLocation(event: event)
        }
    }
        
    func stopGlobalMouseMonitor() {
        mousePointer.orderOut(nil)
        if let monitor = mouseMonitor { NSEvent.removeMonitor(monitor); mouseMonitor = nil }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if SCContext.streamType == .idevice { AVOutputClass.shared.stopRecording() }
        else if SCContext.stream != nil { SCContext.stopRecording() }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if SCContext.trimingList.contains(url) { continue }
            createNewWindow(view: VideoTrimmerView(videoURL: url), title: url.lastPathComponent, random: true, only: false)
            closeMainWindow()
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        scPerm = SCContext.updateAvailableContentSync() != nil
        
        checkDuplicateInstance()
        
        lazy var userDesktop = (NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as [String]).first!
        
        ud.register( // default defaults (used if not set)
            defaults: [
                "audioFormat": AudioFormat.aac.rawValue,
                "audioQuality": AudioQuality.high.rawValue,
                "background": BackgroundType.wallpaper.rawValue,
                "frameRate": 60,
                "highRes": 2,
                "hideSelf": true,
                "highlightMouse" : false,
                "hideDesktopFiles": false,
                "includeMenuBar": true,
                "videoQuality": 1.0,
                "countdown": 0,
                "videoFormat": VideoFormat.mp4.rawValue,
                "pixelFormat": PixFormat.delault.rawValue,
                "encoder": Encoder.h264.rawValue,
                "poSafeDelay": 1,
                "saveDirectory": userDesktop as NSString,
                "showMouse": true,
                "recordMic": false,
                "remuxAudio": isMacOS12 ? false : true,
                "recordWinSound": isMacOS12 ? false : true,
                "trimAfterRecord": false,
                "showOnDock": true,
                "showMenubar": true,
                "enableAEC": false,
                "recordHDR": false,
                "preventSleep": true,
                "showPreview": isMacOS12 ? false : true,
                "showFloatingController": true,
                "copyToClipboard": false,
                "autoCamera": "",
                "cameraShape": "rounded",
                "savedArea": [String: [String: CGFloat]]()
            ]
        )
        
        if highRes == 0 { highRes = 2 }
        if showOnDock { NSApp.setActivationPolicy(.regular) }
        if isMacOS12 { showPreview = false; remuxAudio = false }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("Notification authorization denied: \(error.localizedDescription)") }
        }
        
        var allow : UInt32 = 1
        let dataSize : UInt32 = 4
        let zero : UInt32 = 0
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, zero, nil, dataSize, &allow)

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.image = NSImage()
        installStatusBarEventLocationFix()

        mousePointer.title = "Mouse Pointer".local
        mousePointer.level = .screenSaver
        mousePointer.ignoresMouseEvents = true
        mousePointer.isReleasedWhenClosed = false
        mousePointer.backgroundColor = NSColor.clear
        
        screenMagnifier.title = "Screen Magnifier".local
        screenMagnifier.level = .floating
        screenMagnifier.ignoresMouseEvents = true
        screenMagnifier.isReleasedWhenClosed = false
        screenMagnifier.backgroundColor = NSColor.clear
        
        camWindow.title = "Camera Overlayer".local
        camWindow.isReleasedWhenClosed = false
        camWindow.isMovableByWindowBackground = true
        camWindow.backgroundColor = NSColor.clear
        // Above full-screen apps and slideshows (Keynote play mode), so the camera overlay
        // stays visible in the recording (#238)
        camWindow.level = .screenSaver
        camWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        countdownPanel.title = "Countdown Panel".local
        countdownPanel.level = .floating
        countdownPanel.isReleasedWhenClosed = false
        countdownPanel.isMovableByWindowBackground = false
        countdownPanel.backgroundColor = NSColor.clear
        
        deviceWindow.title = "iDevice Overlayer".local
        deviceWindow.level = .floating
        deviceWindow.isReleasedWhenClosed = false
        deviceWindow.isMovableByWindowBackground = true
        deviceWindow.backgroundColor = NSColor.clear
        
        controlPanel.title = "Recording Controller".local
        controlPanel.level = .floating
        controlPanel.titleVisibility = .hidden
        controlPanel.backgroundColor = NSColor.clear
        controlPanel.isReleasedWhenClosed = false
        controlPanel.titlebarAppearsTransparent = true
        controlPanel.isMovableByWindowBackground = true
        
        previewWindow.level = .statusBar
        previewWindow.titlebarAppearsTransparent = true
        previewWindow.titleVisibility = .hidden
        previewWindow.isReleasedWhenClosed = false
        previewWindow.backgroundColor = .clear
        
        KeyboardShortcuts.onKeyDown(for: .showPanel) {
            _ = self.applicationShouldHandleReopen(NSApp, hasVisibleWindows: true)
            if SCContext.stream == nil { NSApp.activate(ignoringOtherApps: true) }
        }
        KeyboardShortcuts.onKeyDown(for: .saveFrame) { if SCContext.stream != nil { SCContext.saveFrame = true }}
        KeyboardShortcuts.onKeyDown(for: .screenMagnifier) { if SCContext.stream != nil { SCContext.isMagnifierEnabled.toggle() }}
        KeyboardShortcuts.onKeyDown(for: .stop) { stopActiveRecording() }
        KeyboardShortcuts.onKeyDown(for: .discard) { if SCContext.stream != nil { SCContext.discardRecording() } }
        KeyboardShortcuts.onKeyDown(for: .pauseResume) { if SCContext.stream != nil { SCContext.pauseRecording() }}
        // Recording shortcuts always go through AppDelegate.shared (the instance the rest of
        // the app uses) and refresh the shareable content first, so they never run on stale
        // content or crash when screen recording permission is missing.
        KeyboardShortcuts.onKeyDown(for: .startWithAudio) {
            // Pressing a recording hotkey again stops the recording, so one key starts and stops (#95)
            if SCContext.streamType != nil { stopActiveRecording(); return }
            AppDelegate.shared.withFreshScreenContent {
                if SCContext.streamType != nil { return }
                closeAllWindow()
                AppDelegate.shared.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil, fastStart: true)
            }
        }
        KeyboardShortcuts.onKeyDown(for: .startWithScreen) {
            // Pressing a recording hotkey again stops the recording, so one key starts and stops (#95)
            if SCContext.streamType != nil { stopActiveRecording(); return }
            AppDelegate.shared.withFreshScreenContent {
                if SCContext.streamType != nil { return }
                closeAllWindow()
                AppDelegate.shared.prepRecord(type: "display", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil, fastStart: true)
            }
        }
        KeyboardShortcuts.onKeyDown(for: .startWithArea) {
            // Pressing a recording hotkey again stops the recording, so one key starts and stops (#95)
            if SCContext.streamType != nil { stopActiveRecording(); return }
            AppDelegate.shared.withFreshScreenContent {
                if SCContext.streamType != nil { return }
                closeAllWindow()
                AppDelegate.shared.startAreaSelection()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .startWithWindow) {
            // Pressing a recording hotkey again stops the recording, so one key starts and stops (#95)
            if SCContext.streamType != nil { stopActiveRecording(); return }
            let frontmostApp = NSWorkspace.shared.frontmostApplication
            AppDelegate.shared.withFreshScreenContent {
                if SCContext.streamType != nil { return }
                closeAllWindow()
                guard let pid = frontmostApp?.processIdentifier else { return }
                guard let scWindow = SCContext.getWindows().first(where: { $0.owningApplication?.processID == pid && $0.title != "" && $0.isOnScreen }) else { return }
                AppDelegate.shared.prepRecord(type: "window", screens: SCContext.getSCDisplayWithMouse(), windows: [scWindow], applications: nil, fastStart: true)
            }
        }
        updateStatusBar()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        closeAllWindow()
        // Remember where the main toolbar was dragged to (#159)
        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: nil, queue: .main) { note in
            guard let w = note.object as? NSWindow, w is EscPanel, w.title == "TinyRecorder".local, w.isVisible else { return }
            ud.set(NSStringFromPoint(w.frame.origin), forKey: mainPanelOriginKey)
        }
        // 测试用：带 `-resetOnboarding YES` 启动时按新用户重新走引导（不清权限）
        if ud.bool(forKey: "resetOnboarding") {
            ud.removeObject(forKey: firstRunSetupKey)
            ud.removeObject(forKey: onboardingStepKey)
        }
        if !ud.bool(forKey: firstRunSetupKey) {
            // 首次使用：一个分步引导窗完成 权限 → 麦克风 → 格式 → 怎么开始录。
            // 授权后需要重启，重启后引导窗会从下一步继续（见 OnboardingView.init）。
            // 引导期间不显示底部工具栏，最后一步「开始使用」再打开它。
            showOnboarding()
        } else if !scPerm {
            // 无录屏权限时不显示底部工具栏：工具栏在悬浮层，小屏幕上会盖住引导窗的
            // 「点击授权」按钮。引导完成授权并重启后，下次启动正常显示工具栏。
            showScreenPermissionGuide()
        } else if showOnDock || !showMenubar {
            // Dock 图标和菜单栏图标都关掉时，启动后也要显示录制工具栏，否则看起来像没打开
            _ = applicationShouldHandleReopen(NSApp, hasVisibleWindows: true)
        }
    }

    /// First-run onboarding: permission → microphone → format → how to start.
    func showOnboarding() {
        // 只复用还显示着的引导窗；关掉的窗口可能仍在 NSApp.windows 里，但状态停在旧步骤
        if let existing = NSApp.windows.first(where: { $0.title == onboardingTitle && $0.isVisible }) {
            existing.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        // 不设为 .floating：权限这一步要去系统设置里打开开关，浮动窗会挡住系统设置。
        let panel = EscPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
                             styleMask: [.titled, .closable, .fullSizeContentView],
                             backing: .buffered, defer: false)
        panel.contentView = NSHostingView(rootView: OnboardingView())
        panel.title = onboardingTitle
        // NSPanel 默认在 App 失去焦点时隐藏；权限这一步需要切到系统设置，引导窗必须留在屏幕上
        panel.hidesOnDeactivate = false
        // 关闭窗口 = 跳过剩余步骤；但还没拿到录屏权限时，下次启动继续引导
        var closeObserver: NSObjectProtocol?
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: panel, queue: .main) { _ in
            // 权限步骤里授权后会重启（窗口也可能随之关闭），那时还停在第 0 步，不能算完成
            if ud.integer(forKey: onboardingStepKey) >= OnboardingView.Step.microphone.rawValue {
                ud.set(true, forKey: firstRunSetupKey)
                // 引导结束后不留进度，以后从偏好设置重新打开时从头开始
                ud.removeObject(forKey: onboardingStepKey)
            }
            if let o = closeObserver { NotificationCenter.default.removeObserver(o) }
        }
        panel.titlebarAppearsTransparent = true
        panel.isRestorable = false
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Reopens the onboarding from its first step (Preferences → General).
    /// With screen recording already granted it starts at the microphone step.
    func replayOnboarding() {
        // 引导窗正开着就直接带到前面，不打断当前进度
        if !NSApp.windows.contains(where: { $0.title == onboardingTitle && $0.isVisible }) {
            ud.removeObject(forKey: onboardingStepKey)
        }
        showOnboarding()
    }

    /// Runs `action` on the main queue with freshly updated shareable content.
    /// Without screen recording permission the permission guide is shown instead.
    func withFreshScreenContent(_ action: @escaping () -> Void) {
        guard CGPreflightScreenCaptureAccess() else {
            showScreenPermissionGuide()
            return
        }
        SCContext.updateAvailableContent {
            DispatchQueue.main.async { action() }
        }
    }

    /// Quits if another (still running) instance exists. A just-relaunched process may
    /// briefly see the old instance that is still shutting down, so retry for a few seconds
    /// before complaining.
    func checkDuplicateInstance(retries: Int = 6) {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.33to9.TinyRecorder"
        let myPID = ProcessInfo.processInfo.processIdentifier
        let others = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != myPID && !$0.isTerminated
        }
        if others.isEmpty { return }
        if retries > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.checkDuplicateInstance(retries: retries - 1) }
            return
        }
        let button = createAlert(title: "TinyRecorder is Running".local, message: "Please do not run multiple instances!".local, button1: "Quit".local).runModal()
        if button == .alertFirstButtonReturn { NSApp.terminate(self) }
    }

    /// First-launch friendly guide for the screen recording permission.
    /// Uses CGPreflightScreenCaptureAccess (silent check) + CGRequestScreenCaptureAccess
    /// so the system prompt appears with proper context instead of confusing users.
    func showScreenPermissionGuide() {
        // 首次引导窗还开着时，权限这一步就在里面，不要再弹一个独立的授权窗
        if let onboarding = NSApp.windows.first(where: { $0.title == onboardingTitle && $0.isVisible }) {
            onboarding.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        // 幂等：引导窗已存在时仅激活，避免重复弹出多个
        // Don't filter by visibility: the guide may be temporarily hidden while the system
        // permission prompt is on screen, and must not be duplicated then.
        if let existing = NSApp.windows.first(where: { $0.title == "Screen Recording Permission".local }) {
            existing.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let guidePanel = EscPanel(contentRect: NSRect(x: 0, y: 0, width: 460, height: 500),
                                  styleMask: [.titled, .closable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
        guidePanel.contentView = NSHostingView(rootView: ScreenPermissionGuide())
        guidePanel.title = "Screen Recording Permission".local
        guidePanel.hidesOnDeactivate = false
        guidePanel.isRestorable = false
        guidePanel.isReleasedWhenClosed = false
        guidePanel.center()
        guidePanel.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if SCContext.stream == nil {
            let w1 = NSApp.windows.filter({ !$0.title.contains("Item-0") && !$0.title.isEmpty && $0.isVisible })
            let w2 = w1.filter({ !$0.title.contains(".qma") })
            if (!w1.isEmpty && w2.isEmpty) || w1.isEmpty {
                let offset = (!showOnDock && !showMenubar) ? 127 : 0
                let width = isMacOS12 ? 800 : 928
                let mainPanel = EscPanel(contentRect: NSRect(x: 0, y: 0, width: width + offset, height: 100), styleMask: [.fullSizeContentView, .nonactivatingPanel], backing: .buffered, defer: false)
                mainPanel.contentView = NSHostingView(rootView: ContentView())
                mainPanel.title = "TinyRecorder".local
                mainPanel.isOpaque = false
                mainPanel.level = .floating
                mainPanel.isRestorable = false
                mainPanel.backgroundColor = .clear
                mainPanel.isReleasedWhenClosed = false
                mainPanel.isMovableByWindowBackground = true
                mainPanel.collectionBehavior = [.canJoinAllSpaces]
                mainPanel.center()
                if let screen = mainPanel.screen {
                    let wX = (screen.frame.width - mainPanel.frame.width) / 2 + screen.frame.minX
                    let wY = (screen.frame.height - mainPanel.frame.height) / 2 + screen.frame.minY
                    mainPanel.setFrameOrigin(NSPoint(x: wX, y: wY))
                }
                // Reopen where the user last dragged it (#159), if that spot is still on a screen
                if let saved = ud.string(forKey: mainPanelOriginKey) {
                    let origin = NSPointFromString(saved)
                    let rect = NSRect(origin: origin, size: mainPanel.frame.size)
                    if NSScreen.screens.contains(where: { $0.visibleFrame.contains(NSPoint(x: rect.midX, y: rect.midY)) }) {
                        mainPanel.setFrameOrigin(origin)
                    }
                }
                mainPanel.makeKeyAndOrderFront(self)
                if #unavailable(macOS 13) { NSApp.activate(ignoringOtherApps: true) }
                PopoverState.shared.isShowing = false
            }
        }
        return false
    }
    
    func openSettingPanel() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            if let item = NSApp.mainMenu?.items.first?.submenu?.items.first(where: { $0.keyEquivalent == "," }) {
                item.performAction()
            } else {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        } else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    class EscPanel: NSPanel {
        override func cancelOperation(_ sender: Any?) {
            self.close()
        }
        override var canBecomeKey: Bool {
            return true
        }
    }
}

/// Onboarding view shown at first launch when screen recording permission is missing.
struct ScreenPermissionGuide: View {
    @State private var granted = CGPreflightScreenCaptureAccess()
    @State private var requested = false
    @State private var showResetConfirm = false
    @State private var showResetFailed = false
    /// Seconds left before the automatic relaunch after permission is granted; nil = no countdown.
    @State private var countdown: Int? = nil
    private let pollTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    /// Title of the window hosting this view (standalone guide or the onboarding window),
    /// used to hide/show it around the system prompt.
    private let panelTitle: String
    /// Compact layout when embedded in the onboarding window (it shows its own header).
    private let embedded: Bool

    init(panelTitle: String = "Screen Recording Permission".local, embedded: Bool = false) {
        self.panelTitle = panelTitle
        self.embedded = embedded
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: granted ? "checkmark.circle.fill" : "video.badge.waveform")
                    .font(.system(size: embedded ? 36 : 44))
                    .foregroundStyle(granted ? Color.green : Color.accentColor)
                Text((granted ? "All Set!" : "Screen Recording Permission").local)
                    .font(.title2.bold())
                Text((granted
                     ? "Permission granted. Restart TinyRecorder to apply it and start recording."
                     : "TinyRecorder needs screen recording permission before it can record. This is a one-time setup.").local)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 370)
                if granted {
                    Button("Restart TinyRecorder Now") { relaunch() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    if let left = countdown {
                        HStack(spacing: 6) {
                            Text(String(format: "Restarting automatically in %d s…".local, left))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Cancel".local) { countdown = nil }
                                .buttonStyle(.link)
                                .font(.caption)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Click \"Grant Permission\" below; macOS will show a system dialog.".local, systemImage: "1.circle.fill")
                        Label("In the dialog, click \"Open System Settings\" — TinyRecorder will then appear in the list; turn on its toggle and approve the relaunch.".local, systemImage: "2.circle.fill")
                        Label("Return here and restart TinyRecorder when the checkmark turns green.".local, systemImage: "3.circle.fill")
                    }
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 370, alignment: .leading)
                    PermissionToggleIllustration()
                        .frame(maxWidth: 370)
                    Text("If TinyRecorder is not in the list, quit System Settings (⌘Q) and reopen this page, or add it with the + button.".local)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 370, alignment: .leading)
                    Button(requested ? "Open System Settings" : "Grant Permission") {
                        if !requested {
                            requested = true
                            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15 {
                                // macOS 15+：系统授权框经常不出现（或只出现一次），隐藏引导窗会让
                                // 屏幕上什么都没有。保持引导窗可见，并直接打开系统设置的录屏页面。
                                CGRequestScreenCaptureAccess()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if !CGPreflightScreenCaptureAccess() { openScreenCaptureSettings() }
                                }
                            } else {
                                // 请求权限前先隐藏引导窗：系统 TCC 授权弹窗出现在屏幕顶部中央，
                                // 引导窗可能恰好挡住它的按钮（小屏幕 / 远程桌面下尤其明显）。
                                orderGuidePanel(visible: false)
                                CGRequestScreenCaptureAccess()
                                // 若 15 秒后仍未授权（用户点了“拒绝”或未处理），重新显示引导窗
                                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                                    if !CGPreflightScreenCaptureAccess() {
                                        orderGuidePanel(visible: true)
                                    }
                                }
                            }
                        } else {
                            openScreenCaptureSettings()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    if requested {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Waiting for permission…".local).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Divider().frame(maxWidth: 370)
                    // 升级/替换应用后，系统设置里残留的旧记录属于旧签名，对新程序无效：
                    // 开关打不开、或打开了这里仍显示未授权。重置记录后重新授权即可。
                    VStack(spacing: 4) {
                        Text("Toggle already on, won't stay on, or still not working? The permission record may belong to an older version of TinyRecorder.".local)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 370)
                        Button("Reset Permission & Relaunch".local) { showResetConfirm = true }
                            .buttonStyle(.link)
                            .font(.callout)
                    }
                }
            }
            .padding(24)
        }
        .alert("Reset Screen Recording Permission?".local, isPresented: $showResetConfirm) {
            Button("Reset & Relaunch".local, role: .destructive) {
                if resetScreenCapturePermission() { relaunchApp() } else { showResetFailed = true }
            }
            Button("Cancel".local, role: .cancel) {}
        } message: {
            Text("This clears TinyRecorder's old screen recording record and relaunches the app. After relaunch, click \"Grant Permission\" and turn on the toggle again.".local)
        }
        .alert("Repair Failed".local, isPresented: $showResetFailed) {
            Button("OK".local, role: .cancel) {}
        } message: {
            Text("Please run this command in Terminal instead:\ntccutil reset ScreenCapture \(Bundle.main.bundleIdentifier ?? "com.33to9.TinyRecorder")")
        }
        .onReceive(pollTimer) { _ in
            if let left = countdown {
                // 授权成功后的自动重启倒计时（用户可取消，改为手动点“立即重启”）
                if left <= 1 { countdown = nil; relaunch(); return }
                countdown = left - 1
            }
            let now = CGPreflightScreenCaptureAccess()
            if now && !granted {
                // 授权成功：若引导窗处于隐藏状态（请求权限时避让系统弹窗），重新显示，
                // 并开始 3 秒自动重启倒计时，省去用户再点一次。
                orderGuidePanel(visible: true)
                countdown = 3
            }
            granted = now
        }
    }

    /// 按标题找到引导窗并显示/隐藏
    private func orderGuidePanel(visible: Bool) {
        for w in NSApp.windows where w.title == panelTitle {
            if visible {
                if !w.isVisible {
                    w.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            } else if w.isVisible {
                w.orderOut(nil)
            }
        }
    }

    private func openScreenCaptureSettings() {
        // 不再强制退出「系统设置」（可能丢失用户在其中的其他操作）；直接打开录屏页面。
        // 若列表中没有 TinyRecorder，界面上已提示用户手动 ⌘Q 退出系统设置后重开。
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func relaunch() {
        relaunchApp()
    }
}

let firstRunSetupKey = "firstRunSetupDone"
/// Last onboarding step reached, so the onboarding resumes there after the permission relaunch.
let onboardingStepKey = "onboardingStep"
var onboardingTitle: String { "Welcome to TinyRecorder".local }

/// First-run onboarding in one window: screen recording permission → microphone (optional)
/// → default format → where to start recording. Granting the screen permission needs a
/// relaunch; on the next launch the window comes back at the step after it.
struct OnboardingView: View {
    enum Step: Int, CaseIterable {
        case permission, microphone, format, start
        var title: String {
            switch self {
            case .permission: return "Permission".local
            case .microphone: return "Voice".local
            case .format: return "Format".local
            case .start: return "Get Started".local
            }
        }
    }

    @State private var step: Step

    init() {
        let saved = Step(rawValue: ud.integer(forKey: onboardingStepKey)) ?? .permission
        // 有录屏权限就跳过权限这一步（授权后重启回来，或老用户首次看到引导）
        let granted = CGPreflightScreenCaptureAccess()
        let initial: Step = granted ? Step(rawValue: max(saved.rawValue, Step.microphone.rawValue))! : .permission
        _step = State(initialValue: initial)
        ud.set(initial.rawValue, forKey: onboardingStepKey)
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.top, 34)
                .padding(.bottom, 4)
            Group {
                switch step {
                case .permission:
                    ScreenPermissionGuide(panelTitle: onboardingTitle, embedded: true)
                case .microphone:
                    OnboardingMicrophoneStep(next: { go(.format) })
                case .format:
                    OnboardingFormatStep(back: { go(.microphone) }, next: { go(.start) })
                case .start:
                    OnboardingStartStep(back: { go(.format) }, finish: finish)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 480, height: 600)
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(s.rawValue <= step.rawValue ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(width: 18, height: 18)
                        if s.rawValue < step.rawValue {
                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        } else {
                            Text("\(s.rawValue + 1)").font(.system(size: 10, weight: .bold))
                                .foregroundColor(s.rawValue <= step.rawValue ? .white : .secondary)
                        }
                    }
                    Text(s.title)
                        .font(.caption)
                        .foregroundColor(s == step ? .primary : .secondary)
                }
                if s != Step.allCases.last {
                    Rectangle().fill(Color.secondary.opacity(0.25)).frame(width: 14, height: 1)
                }
            }
        }
    }

    private func go(_ s: Step) {
        step = s
        ud.set(s.rawValue, forKey: onboardingStepKey)
    }

    private func finish() {
        ud.set(true, forKey: firstRunSetupKey)
        NSApp.windows.first(where: { $0.title == onboardingTitle })?.close()
        // 打开录制工具栏，让用户马上能开始第一次录制。先关掉其他窗口（例如刚打开的偏好设置），
        // 否则“已有可见窗口”时工具栏不会弹出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            closeAllWindow()
            _ = AppDelegate.shared.applicationShouldHandleReopen(NSApp, hasVisibleWindows: true)
        }
    }
}

/// Step 2: optional microphone permission, so the first recording with voice isn't interrupted.
struct OnboardingMicrophoneStep: View {
    var next: () -> Void
    @AppStorage("recordMic") private var recordMic: Bool = false
    @State private var status = AVCaptureDevice.authorizationStatus(for: .audio)

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: status == .authorized ? "mic.circle.fill" : "mic.circle")
                .font(.system(size: 36))
                .foregroundStyle(status == .authorized ? Color.green : Color.accentColor)
            Text("Record Your Voice?".local).font(.title2.bold())
            Text("Narrating a tutorial or a bug report? Allow the microphone now so your first recording isn't interrupted by a system prompt. You can skip this and turn it on later.".local)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 380)
            switch status {
            case .authorized:
                Label("Microphone allowed".local, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Toggle("Record microphone by default".local, isOn: $recordMic)
                    .toggleStyle(.checkbox)
                Button("Next".local) { next() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            case .denied, .restricted:
                Text("Microphone access was denied. You can allow it in System Settings → Privacy & Security → Microphone.".local)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
                Button("Open System Settings".local) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                }
                Button("Next".local) { next() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            default:
                Button("Allow Microphone".local) {
                    AVCaptureDevice.requestAccess(for: .audio) { ok in
                        DispatchQueue.main.async {
                            status = AVCaptureDevice.authorizationStatus(for: .audio)
                            if ok { recordMic = true }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("Not Now".local) { next() }
                    .buttonStyle(.link)
            }
        }
        .padding(24)
    }
}

/// Step 3: default video encoder and container (was the v1.7.18 first-run panel).
struct OnboardingFormatStep: View {
    var back: () -> Void
    var next: () -> Void
    @AppStorage("encoder")     private var encoder: Encoder = .h264
    @AppStorage("videoFormat") private var videoFormat: VideoFormat = .mp4
    @AppStorage("withAlpha")   private var withAlpha: Bool = false
    private let hevcHardware = hevcHardwareEncoderAvailable
    private var recommended: Encoder { hevcHardware ? .h265 : .h264 }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
            Text("Recording Format".local).font(.title2.bold())
            Text("Choose the default format for your recordings. You can change it any time in Preferences → Output.".local)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 380)
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Encoder".local).font(.headline)
                    Picker("", selection: $encoder) {
                        Text((recommended == .h265 ? "H.265 (Recommended)" : "H.265").local).tag(Encoder.h265)
                        Text((recommended == .h264 ? "H.264 (Recommended)" : "H.264").local).tag(Encoder.h264)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text((encoder == .h265
                          ? "Better quality and smaller files. Plays on Macs and iPhones; some older players or websites may not support it."
                          : "Best compatibility with every player and website, but files are larger.").local)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if encoder == .h265 && !hevcHardware {
                        Label("This Mac has no hardware H.265 encoder. Recording in H.265 will use much more CPU.".local,
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Format".local).font(.headline)
                    Picker("", selection: $videoFormat) {
                        Text("MP4").tag(VideoFormat.mp4)
                        Text("MOV").tag(VideoFormat.mov)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .disabled(withAlpha)
            .frame(maxWidth: 380)
            HStack {
                Button("Back".local) { back() }
                Spacer()
                Button("Next".local) { next() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
            .frame(maxWidth: 380)
        }
        .padding(24)
        .onAppear {
            // 用户从没自己选过编码器时，预选本机推荐的那个；选过的保留
            let bundleID = Bundle.main.bundleIdentifier ?? "com.33to9.TinyRecorder"
            if !withAlpha && ud.persistentDomain(forName: bundleID)?["encoder"] == nil {
                encoder = recommended
            }
        }
    }
}

/// Whether this Mac can encode HEVC in hardware (Apple silicon and most Intel Macs from
/// 2017 on). Without it H.265 recording falls back to a slow, CPU-heavy software encoder.
let hevcHardwareEncoderAvailable: Bool = {
    var session: VTCompressionSession?
    let status = VTCompressionSessionCreate(
        allocator: nil, width: 1920, height: 1080,
        codecType: kCMVideoCodecType_HEVC,
        encoderSpecification: [kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder as String: true] as CFDictionary,
        imageBufferAttributes: nil, compressedDataAllocator: nil,
        outputCallback: nil, refcon: nil, compressionSessionOut: &session)
    if let session { VTCompressionSessionInvalidate(session) }
    return status == noErr
}()

/// Step 4: show where recording starts (menu bar icon / Dock), then open the toolbar.
struct OnboardingStartStep: View {
    var back: () -> Void
    var finish: () -> Void
    @AppStorage("showMenubar") private var showMenubar: Bool = true
    @AppStorage("showOnDock")  private var showOnDock: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
            Text("You're Ready".local).font(.title2.bold())
            VStack(alignment: .leading, spacing: 12) {
                if showMenubar {
                    hint(image: Image("TinyRecorderMenuBar").renderingMode(.template),
                         text: "Click the TinyRecorder icon in the menu bar (top right of the screen) to start a recording.".local)
                }
                if showOnDock {
                    hint(icon: "dock.rectangle",
                         text: "Or click TinyRecorder in the Dock to open the recording toolbar.".local)
                }
                hint(icon: "keyboard",
                     text: "Tip: set global shortcuts in Preferences → Hotkey to start recording a screen, window or area with one key press.".local)
                hint(icon: "stop.circle",
                     text: "While recording, click the stop button in the menu bar to finish. Recordings are saved to your Desktop by default.".local)
            }
            .frame(maxWidth: 380, alignment: .leading)
            HStack {
                Button("Back".local) { back() }
                Spacer()
                Button("Open Preferences".local) { AppDelegate.shared.openSettingPanel() }
                Button("Start Recording".local) { finish() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
            .frame(maxWidth: 380)
        }
        .padding(24)
    }

    private func hint(icon: String, text: String) -> some View {
        hint(image: Image(systemName: icon), text: text)
    }

    private func hint(image: Image, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            image
                .font(.system(size: 15))
                .foregroundColor(.accentColor)
                .frame(width: 22)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Sketch of the System Settings row the user has to switch on, so they know what to look for.
struct PermissionToggleIllustration: View {
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("TinyRecorder").font(.callout)
                Spacer()
                // 仿系统开关（已打开），只是示意，不可点击
                ZStack(alignment: .trailing) {
                    Capsule().fill(Color.accentColor).frame(width: 34, height: 20)
                    Circle().fill(Color.white).frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.2), radius: 1)
                        .padding(.trailing, 2)
                }
                Image(systemName: "arrow.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.6), lineWidth: 1))
            Text("System Settings → Privacy & Security → Screen & System Audio Recording".local)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityHidden(true)
    }
}

/// Resets this app's TCC ScreenCapture record via `tccutil` (no admin rights needed for the
/// app's own bundle ID). Fixes stale permission entries left by a build with a different code
/// signature (e.g. after updating an ad-hoc signed build): the old entry is shown in System
/// Settings but doesn't apply to the new binary. Returns false if tccutil failed.
@discardableResult
func resetScreenCapturePermission() -> Bool {
    let bundleID = Bundle.main.bundleIdentifier ?? "com.33to9.TinyRecorder"
    let reset = Process()
    reset.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
    reset.arguments = ["reset", "ScreenCapture", bundleID]
    do {
        try reset.run()
        reset.waitUntilExit()
        return reset.terminationStatus == 0
    } catch {
        return false
    }
}

/// Relaunches the app: the new instance is started by a detached shell after a short
/// delay, so it doesn't see this (still terminating) instance and quit as a duplicate.
func relaunchApp() {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "sleep 1; /usr/bin/open -n \"$0\"", Bundle.main.bundlePath]
    try? task.run()
    NSApp.terminate(nil)
}

/// UserDefaults key for the main toolbar's last position
let mainPanelOriginKey = "mainPanelOrigin"

/// Stops whatever is recording (screen/audio via ScreenCaptureKit, or an iPhone/iPad).
/// Does nothing while a recording is still starting up.
func stopActiveRecording() {
    // iPhone/iPad 录制走 AVCaptureSession，没有 SCStream，要单独停止
    if SCContext.streamType == .idevice { AVOutputClass.shared.stopRecording() }
    else if SCContext.stream != nil { SCContext.stopRecording() }
}

func closeMainWindow() {
    for w in NSApp.windows.filter({ $0.title == "TinyRecorder".local }) {
        w.close()
    }
}

func closeAllWindow(except: String = "") {
    for w in NSApp.windows.filter({
        // 首次引导不随其他窗口一起关闭：点菜单栏图标或按录制快捷键不应跳过剩下的引导步骤
        $0.title != "Item-0" && $0.title != "" && $0.title != onboardingTitle
        && !$0.title.lowercased().contains(".qma")
        && !$0.title.contains(except) }) { w.close() }
}

func findNSSplitVIew(view: NSView?) -> NSSplitView? {
    var queue = [NSView]()
    if let root = view { queue.append(root) }
    
    while !queue.isEmpty {
        let current = queue.removeFirst()
        if current is NSSplitView { return current as? NSSplitView }
        for subview in current.subviews { queue.append(subview) }
    }
    return nil
}

func getStatusBarWidth() -> CGFloat {
    @AppStorage("miniStatusBar") var miniStatusBar: Bool = false
    var width = 158.0
    switch SCContext.streamType {
    case nil: width = miniStatusBar ? 36.0 : 36.0
    case .idevice: width = miniStatusBar ? 68.0 : 138.0
    case .systemaudio: width = miniStatusBar ? 68.0 : 114.0
    default: width = miniStatusBar ? 78.0 : 158.0
    }
    return width
}

func process(path: String, arguments: [String]) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    task.standardError = Pipe()
    
    let outputPipe = Pipe()
    defer {
        outputPipe.fileHandleForReading.closeFile()
    }
    task.standardOutput = outputPipe
    
    do {
        try task.run()
    } catch let error {
        print("\(error.localizedDescription)")
        return nil
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    
    if output.isEmpty {
        return nil
    }
    
    return output.trimmingCharacters(in: .newlines)
}

func tips(_ message: String, title: String? = nil, id: String, buttonTitle: String = "OK", switchButton: Bool = false, width: Int? = nil, action: (() -> Void)? = nil) {
    let never = (ud.object(forKey: "neverRemindMe") as? [String]) ?? []
    if !never.contains(id) {
        if switchButton {
            let alert = createAlert(title: title ?? Bundle.main.appName + " Tips".local, message: message, button1: buttonTitle, button2: "Don't remind me again", width: width).runModal()
            if alert == .alertSecondButtonReturn { ud.setValue(never + [id], forKey: "neverRemindMe") }
            if alert == .alertFirstButtonReturn { action?() }
        } else {
            let alert = createAlert(title: title ?? Bundle.main.appName + " Tips".local, message: message, button1: "Don't remind me again", button2: buttonTitle, width: width).runModal()
            if alert == .alertFirstButtonReturn { ud.setValue(never + [id], forKey: "neverRemindMe") }
            if alert == .alertSecondButtonReturn { action?() }
        }
    }
}

func createAlert(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "", width: Int? = nil) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title.local
    alert.informativeText = message.local
    alert.addButton(withTitle: button1.local)
    if button2 != "" { alert.addButton(withTitle: button2.local) }
    alert.alertStyle = level
    if let width = width {
        alert.accessoryView = NSView(frame: NSMakeRect(0, 0, Double(width), 0))
    }
    return alert
}

func showAlertSyncOnMainThread(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "", width: Int? = nil) -> NSApplication.ModalResponse {
    // 已在主线程（例如 AppDelegate 是 @MainActor，record() 就跑在主线程）时直接弹窗：
    // 否则 main.async + 等待信号量会让主线程等自己，整个 App 卡死。
    if Thread.isMainThread {
        return createAlert(level: level, title: title, message: message, button1: button1, button2: button2, width: width).runModal()
    }
    var response: NSApplication.ModalResponse = .abort
    let semaphore = DispatchSemaphore(value: 0)
    
    DispatchQueue.main.async {
        let alert = createAlert(level: level, title: title, message: message, button1: button1, button2: button2, width: width)
        response = alert.runModal()
        semaphore.signal()
    }
    
    semaphore.wait()
    return response
}

extension Bundle {
    var appName: String {
        let appName = self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                     ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                     ?? "Unknown App Name"
        return appName
    }
}

extension String {
    var local: String { return NSLocalizedString(self, comment: "") }
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    var url: URL { return URL(fileURLWithPath: self) }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else {
            return
        }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

extension NSImage {
    /// Captures the screen (all windows except our own).
    /// - Parameter cocoaRect: area to capture in Cocoa global coordinates (bottom-left origin
    ///   of the primary display). `nil` captures everything (`CGRect.infinite`).
    static func createScreenShot(cocoaRect: NSRect? = nil) -> NSImage? {
        let excludedAppBundleIDs = ["com.33to9.TinyRecorder"]
        var exclusionPIDs = [Int]()
        for app in NSWorkspace.shared.runningApplications {
            if excludedAppBundleIDs.contains(app.bundleIdentifier ?? "") {
                exclusionPIDs.append(Int(app.processIdentifier))
            }
        }
        
        let windowDescriptions = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        var windowIDs = [CGWindowID]()
        for windowDict in windowDescriptions {
            if let windowProcessID = windowDict[kCGWindowOwnerPID as String] as? Int,
               !exclusionPIDs.contains(windowProcessID),
               let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID {
                windowIDs.append(windowID)
            }
        }
        let pointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)
        for (index, window) in windowIDs.enumerated() { pointer[index] = UnsafeRawPointer(bitPattern: UInt(window)) }
        let cWindowIDArray: CFArray = CFArrayCreate(kCFAllocatorDefault, pointer, windowIDs.count, nil)

        pointer.deallocate()

        var bounds = CGRect.infinite
        if let r = cocoaRect, let primaryHeight = NSScreen.screens.first?.frame.height {
            // Cocoa (bottom-left origin) -> CG global (top-left origin of the primary display)
            bounds = CGRect(x: r.origin.x, y: primaryHeight - r.origin.y - r.height, width: r.width, height: r.height)
        }
        guard let imageRef = CGImage(windowListFromArrayScreenBounds: bounds, windowArray: cWindowIDArray, imageOption: []) else {
            print("No image available")
            return nil
        }
        if let r = cocoaRect {
            return NSImage(cgImage: imageRef, size: r.size)
        }
        let factor = SCContext.getScreenWithMouse()?.backingScaleFactor ?? 1.0
        return NSImage(cgImage: imageRef, size: NSSize(width: CGFloat(imageRef.width)/factor, height: CGFloat(imageRef.height)/factor))
    }
    
    func saveToFile(_ url: URL, type: NSBitmapImageRep.FileType = .png) {
        if let tiffData = self.tiffRepresentation,
           let imageRep = NSBitmapImageRep(data: tiffData) {
            let pngData = imageRep.representation(using: type, properties: [:])
            do {
                try pngData?.write(to: url)
            } catch {
                print("Error saving image: \(error.localizedDescription)")
            }
        }
    }
    
    func trim(rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()

        let destRect = CGRect(origin: .zero, size: result.size)
        self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)

        result.unlockFocus()
        return result
    }
}

class NNSWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

struct FixedLengthArray<T> {
    private var array: [T] = []
    private let maxLength: Int

    init(maxLength: Int) {
        self.maxLength = maxLength
    }

    mutating func append(_ element: T) {
        if array.count >= maxLength {
            array.removeFirst()
        }
        array.append(element)
    }

    func getArray() -> [T] {
        return array
    }
}

extension utsname {
    static var sMachine: String {
        var utsname = utsname()
        uname(&utsname)
        return withUnsafePointer(to: &utsname.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }
    static var isAppleSilicon: Bool {
        sMachine == "arm64"
    }
}

enum AudioQuality: Int { case normal = 128, good = 192, high = 256, extreme = 320 }

enum AudioFormat: String { case aac, alac, flac, opus, mp3 }

enum VideoFormat: String { case mov, mp4 }

enum PixFormat: String { case delault, yuv420p8v, yuv420p8f, yuv420p10v, yuv420p10f, bgra32 }

enum ColSpace: String { case delault, srgb, p3, bt709, bt2020 }

enum Encoder: String { case h264, h265 }

enum StreamType: Int { case screen, window, windows, application, screenarea, systemaudio, idevice, camera }

enum BackgroundType: String { case wallpaper, clear, black, white, red, green, yellow, orange, gray, blue, custom }