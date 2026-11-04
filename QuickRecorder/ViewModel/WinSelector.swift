//
//  WinSelector.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/17.
//

import SwiftUI
import Foundation
import AVFoundation
import ScreenCaptureKit

struct WinSelector: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = WindowSelectorViewModel()
    @State private var selected = [SCWindow]()
    @State private var display: SCDisplay!
    @State private var selectedTab = 0
    @State private var isPopoverShowing = false
    @State private var isPopoverShowing2 = false
    @State private var disableFilter = false
    @State private var donotCapture = false
    @State private var autoStop = 0
    var appDelegate = AppDelegate.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                if #available(macOS 15, *) {
                    Text("Please select the window(s) to record").offset(y: 12)
                } else {
                    HStack {
                        Spacer()
                        Text("Please select the window(s) to record")
                        Spacer()
                        HoverButton(action: {
                            // 与工具栏按钮一致：录制所选窗口本身（mode 2 是录一块固定屏幕区域）
                            WindowHighlighter.shared.registerMouseMonitor()
                        }, label: {
                            ZStack {
                                Color.white.opacity(0.0001)
                                Image("window.select")
                                    .resizable().scaledToFit()
                            }.frame(width: 20, height: 20)
                        })
                        .help("Select Window Directly")
                        .padding(.leading, -20)
                    }.padding(.horizontal, 10)
                }
                TabView(selection: $selectedTab) {
                    let allApps = viewModel.windowThumbnails.sorted(by: { $0.key.displayID < $1.key.displayID })
                    ForEach(allApps, id: \.key) { element in
                        let (screen, thumbnails) = element
                        let index = allApps.firstIndex(where: { $0.key == screen }) ?? 0
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                ForEach(0..<thumbnails.count/4 + 1, id: \.self) { rowIndex in
                                    HStack(spacing: 16.5) {
                                        ForEach(0..<4, id: \.self) { columnIndex in
                                            let index = 4 * rowIndex + columnIndex
                                            if index <= thumbnails.count - 1 {
                                                let item = thumbnails[index]
                                                Button(action: {
                                                    if !selected.contains(item.window) {
                                                        selected.append(item.window)
                                                    } else {
                                                        selected.removeAll{ $0 == item.window }
                                                    }
                                                }, label: {
                                                    VStack(spacing: 1){
                                                        ZStack{
                                                            if colorScheme == .light {
                                                                Image(nsImage: item.image)
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fit)
                                                                    .colorMultiply(.black)
                                                                    .blur(radius: 0.5)
                                                                    .opacity(1)
                                                                    .frame(width: 160, height: 90, alignment: .center)
                                                            } else {
                                                                Image(nsImage: item.image)
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fit)
                                                                    .colorMultiply(.black)
                                                                    .colorInvert()
                                                                    .blur(radius: 0.5)
                                                                    .opacity(1)
                                                                    .frame(width: 160, height: 90, alignment: .center)
                                                            }
                                                            Image(nsImage: item.image)
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .frame(width: 160, height: 90, alignment: .center)
                                                            Image(systemName: "circle.fill")
                                                                .font(.system(size: 31))
                                                                .foregroundStyle(.white)
                                                                .opacity(selected.contains(item.window) ? 1.0 : 0.0)
                                                                .offset(x: 55, y: 25)
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .font(.system(size: 27))
                                                                .foregroundStyle(.green)
                                                                .opacity(selected.contains(item.window) ? 1.0 : 0.0)
                                                                .offset(x: 55, y: 25)
                                                            Image(nsImage: SCContext.getAppIcon(item.window.owningApplication!)!)
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .frame(width: 40, height: 40, alignment: .center)
                                                                .offset(y: 35)
                                                        }
                                                        .padding(5)
                                                        .padding(.vertical, 5)
                                                        .background(
                                                            Rectangle()
                                                                .foregroundStyle(.blue)
                                                                .cornerRadius(5)
                                                                .opacity(selected.contains(item.window) ? 0.2 : 0.0001)
                                                        )
                                                        Text(item.window.title!)
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(.secondary)
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                            .frame(width: 160)
                                                    }
                                                }).buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 12).padding(.top, 5)
                                }
                            }
                        }
                        .tag(index)
                        .tabItem { Text(screen.nsScreen?.localizedName ?? ("Display ".local + "\(index)")) }
                        .onAppear{ display = screen }
                    }
                }
                .frame(height: 445)
                .padding(.horizontal, 10)
                .onChange(of: selectedTab) { _ in selected.removeAll() }
                .onReceive(viewModel.$isReady) { isReady in
                    if isReady {
                        let allApps = viewModel.windowThumbnails.sorted(by: { $0.key.displayID < $1.key.displayID })
                        if let s = NSApp.windows.first(where: { $0.title == "Window Selector".local })?.screen,
                           let index = allApps.firstIndex(where: { $0.key.displayID == s.displayID }) {
                            selectedTab = index
                        }
                    }
                }
                HStack(spacing: 4) {
                    Button(action: {
                        self.viewModel.setupStreams(filter: !disableFilter, capture: !donotCapture)
                        self.selected.removeAll()
                    }, label: {
                        VStack{
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.blue)
                            Text("Refresh")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                        
                    }).buttonStyle(.plain)
                    Button(action: {
                        isPopoverShowing2 = true
                    }, label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.blue)
                    })
                    .buttonStyle(.plain)
                    .padding(.top, 42.5)
                    .popover(isPresented: $isPopoverShowing2, arrowEdge: .bottom, content: {
                        VStack(alignment: .leading) {
                            Toggle(isOn: $disableFilter) { Text("Show Windows with No Title") }
                                .toggleStyle(.checkbox)
                                .onChange(of: disableFilter) { _ in
                                    self.viewModel.setupStreams(filter: !disableFilter, capture: !donotCapture)
                                    self.selected.removeAll()
                                }
                            Toggle(isOn: $donotCapture) { Text("Don't Create Thumbnails") }
                                .toggleStyle(.checkbox)
                                .onChange(of: donotCapture) { _ in
                                    self.viewModel.setupStreams(filter: !disableFilter, capture: !donotCapture)
                                    self.selected.removeAll()
                                }
                        }
                        .fixedSize()
                        .padding()
                    })
                    Spacer()
                    OptionsView()
                    Spacer()
                    Button(action: {
                        isPopoverShowing = true
                    }, label: {
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.blue)
                    })
                    .buttonStyle(.plain)
                    .padding(.top, 42.5)
                    .popover(isPresented: $isPopoverShowing, arrowEdge: .bottom, content: {
                        HStack {
                            Text(" Stop after".local)
                            TextField("", value: $autoStop, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Stepper("", value: $autoStop)
                                .padding(.leading, -10)
                            Text("minutes ".local)
                        }
                        .fixedSize()
                        .padding()
                    })
                    Button(action: {
                        startRecording()
                    }, label: {
                        VStack{
                            Image(systemName: "record.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.red)
                            Text("Start")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                    })
                    .buttonStyle(.plain)
                    .disabled(selected.count < 1)
                }.padding(.horizontal, 40)
                Spacer()
            }.padding(.top, -5)
        }
        .frame(width: 780, height:555)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HoverButton(action: {
                    WindowHighlighter.shared.registerMouseMonitor()
                }, label: {
                    Image("window.select")
                        .resizable().scaledToFit()
                        .frame(width: 20)
                }).help("Select Window Directly")
            }
        }
    }
    
    func startRecording() {
        closeAllWindow()
        appDelegate.createCountdownPanel(screen: display) {
            SCContext.autoStop = autoStop
            appDelegate.prepRecord(type: (selected.count<2 ? "window" : "windows") , screens: display, windows: selected, applications: nil)
        }
    }
}

class WindowSelectorViewModel: NSObject, ObservableObject, SCStreamDelegate, SCStreamOutput {
    @Published var windowThumbnails = [SCDisplay:[WindowThumbnail]]()
    @Published var isReady = false
    // All of the state below is only touched on the main queue (stream output is
    // delivered on .main and setup runs on the main actor).
    private var allWindows = [SCWindow]()
    private var streams = [SCStream]()
    /// Streams still waiting for their first frame, mapped to the window they capture.
    private var streamWindows = [ObjectIdentifier: SCWindow]()
    private var setupGeneration = 0
    
    override init() {
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupStreams()
        }
    }
    
    private func addThumbnail(_ thumbnail: WindowThumbnail) {
        let window = thumbnail.window
        guard let displays = SCContext.availableContent?.displays.filter({ NSIntersectsRect(window.frame, $0.frame) }) else { return }
        for d in displays {
            if self.windowThumbnails[d] != nil {
                if !self.windowThumbnails[d]!.contains(where: { $0.window == window }) { self.windowThumbnails[d]!.append(thumbnail) }
            } else {
                self.windowThumbnails[d] = [thumbnail]
            }
        }
    }
    
    /// Marks a stream as done; once every stream delivered (or failed) the view is ready.
    private func finishStream(_ key: ObjectIdentifier) {
        streamWindows[key] = nil
        if streamWindows.isEmpty { isReady = true }
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        if CMSampleBufferGetImageBuffer(sampleBuffer) == nil { return }
        let key = ObjectIdentifier(stream)
        guard let currentWindow = streamWindows[key] else { return }
        let nsImage = sampleBuffer.nsImage ?? NSImage.unknowScreen
        DispatchQueue.main.async {
            // Ignore frames from a stream that was dropped by a refresh meanwhile.
            guard self.streamWindows[key] != nil else { return }
            self.addThumbnail(WindowThumbnail(image: nsImage, window: currentWindow))
            self.finishStream(key)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { stream.stopCapture() }
    }
    
    /// Stops and forgets all thumbnail streams (main queue only).
    private func stopAllStreams() {
        for stream in streams { stream.stopCapture() }
        streams.removeAll()
        streamWindows.removeAll()
    }

    func setupStreams(filter: Bool = true, capture: Bool = true) {
        SCContext.updateAvailableContent {
            Task { @MainActor in
                self.stopAllStreams()
                self.setupGeneration += 1
                let generation = self.setupGeneration
                self.isReady = false
                self.windowThumbnails.removeAll()
                self.allWindows = SCContext.getWindows().filter({
                    !($0.title == "" && $0.owningApplication?.bundleIdentifier == "com.apple.finder")
                    && $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier
                    && $0.owningApplication?.applicationName != ""
                })
                if filter { self.allWindows = self.allWindows.filter({ $0.title != "" }) }
                let windows = self.allWindows
                if capture && !windows.isEmpty {
                    var pending = [(SCStream, SCWindow)]()
                    for window in windows {
                        let contentFilter = SCContentFilter(desktopIndependentWindow: window)
                        let streamConfiguration = SCStreamConfiguration()
                        let width = window.frame.width
                        let height = window.frame.height
                        var factor = 0.5
                        if width < 200 && height < 200 { factor = 1.0 }
                        streamConfiguration.width = Int(width * factor)
                        streamConfiguration.height = Int(height * factor)
                        streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(1))
                        streamConfiguration.pixelFormat = kCVPixelFormatType_32BGRA
                        if #available(macOS 13, *) { streamConfiguration.capturesAudio = false }
                        streamConfiguration.showsCursor = false
                        streamConfiguration.scalesToFit = true
                        streamConfiguration.queueDepth = 3
                        let stream = SCStream(filter: contentFilter, configuration: streamConfiguration, delegate: self)
                        do {
                            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                        } catch {
                            print("Get windowshot error：\(error)")
                            self.addThumbnail(WindowThumbnail(image: NSImage.unknowScreen, window: window))
                            continue
                        }
                        // Register every stream before starting any, so "ready" can't fire early.
                        self.streams.append(stream)
                        self.streamWindows[ObjectIdentifier(stream)] = window
                        pending.append((stream, window))
                    }
                    if pending.isEmpty { self.isReady = true }
                    for (stream, window) in pending {
                        // A newer refresh started meanwhile: abandon this one.
                        if generation != self.setupGeneration { return }
                        do {
                            try await stream.startCapture()
                        } catch {
                            // One failing window must not abort the others.
                            print("Get windowshot error：\(error)")
                            if generation != self.setupGeneration { return }
                            if self.streamWindows[ObjectIdentifier(stream)] != nil {
                                self.addThumbnail(WindowThumbnail(image: NSImage.unknowScreen, window: window))
                                self.finishStream(ObjectIdentifier(stream))
                            }
                        }
                    }
                    // Safety net: don't keep the view waiting forever for a silent stream.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if generation == self.setupGeneration && !self.isReady { self.isReady = true }
                    }
                } else {
                    for w in windows {
                        self.addThumbnail(WindowThumbnail(image: NSImage.unknowScreen, window: w))
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if generation == self.setupGeneration { self.isReady = true }
                    }
                }
            }
        }
    }
}

class WindowThumbnail {
    let image: NSImage
    let window: SCWindow

    init(image: NSImage, window: SCWindow) {
        self.image = image
        self.window = window
    }
}
