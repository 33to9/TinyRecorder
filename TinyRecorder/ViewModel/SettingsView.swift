//
//  SettingsView.swift
//  TinyRecorder
//
//  Created by apple on 2024/4/19.
//

import SwiftUI
import AVFoundation
import Sparkle
import ServiceManagement
import KeyboardShortcuts
import MatrixColorSelector

struct SettingsView: View {
    /// macOS 13+ sidebar selection. Non-optional on purpose: List(selection: Binding<String>)
    /// with plain String tags matches row tags exactly on every macOS version. The previous
    /// String? binding + `as String?` tags stopped matching on macOS 27 — rows rendered
    /// greyed out (treated as non-selectable), had no highlight and ignored clicks.
    @State private var selectedItem: String = "General"
    /// macOS 12 NavigationLink(tag:selection:) needs an Optional binding.
    @State private var legacySelectedItem: String? = "General"

    var body: some View {
        // NavigationView is deprecated since macOS 13 and renders blank windows
        // on recent macOS releases; use NavigationSplitView there instead.
        if #available(macOS 13, *) {
            NavigationSplitView {
                List(selection: $selectedItem) {
                    Label("General", image: "gear").tag("General")
                    Label("Recorder", image: "record").tag("Recorder")
                    Label("Output", image: "film").tag("Output")
                    Label("Hotkey", image: "hotkey").tag("Hotkey")
                    Label("Blocklist", image: "blacklist").tag("Blaoklist")
                }
                .listStyle(.sidebar)
                .padding(.top, 9)
                .navigationSplitViewColumnWidth(180)
            } detail: {
                switch selectedItem {
                case "Recorder": RecorderView()
                case "Output": OutputView()
                case "Hotkey": HotkeyView()
                case "Blaoklist": BlocklistView()
                default: GeneralView()
                }
            }
            .frame(width: 640, height: 540)
            .background(SettingsWindowConfigurator())
        } else {
            NavigationView {
                List(selection: $legacySelectedItem) {
                    NavigationLink(destination: GeneralView(), tag: "General", selection: $legacySelectedItem) {
                        Label("General", image: "gear")
                    }
                    NavigationLink(destination: RecorderView(), tag: "Recorder", selection: $legacySelectedItem) {
                        Label("Recorder", image: "record")
                    }
                    NavigationLink(destination: OutputView(), tag: "Output", selection: $legacySelectedItem) {
                        Label("Output", image: "film")
                    }
                    NavigationLink(destination: HotkeyView(), tag: "Hotkey", selection: $legacySelectedItem) {
                        Label("Hotkey", image: "hotkey")
                    }
                    NavigationLink(destination: BlocklistView(), tag: "Blaoklist", selection: $legacySelectedItem) {
                        Label("Blocklist", image: "blacklist")
                    }
                }
                .listStyle(.sidebar)
                .padding(.top, 9)
                .frame(minWidth: 180)
            }
            .frame(width: 640, height: 540)
            .background(SettingsWindowConfigurator())
        }
    }
}

/// 设置窗尺寸固定（640x540）且不可拉伸；启动时把历史上保存的异常窗口 frame
/// （被拉大或探出屏幕外）拉回屏幕中央，避免顶部内容跑到屏幕外看不见。
struct SettingsWindowConfigurator: NSViewRepresentable {
    static let fixedSize = NSSize(width: 640, height: 540)

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { Self.configure(v.window) }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { Self.configure(nsView.window) }
    }

    static func configure(_ window: NSWindow?) {
        guard let w = window else { return }
        w.styleMask.remove(.resizable)
        let vf = (w.screen ?? NSScreen.main)?.visibleFrame
        // 异常 frame：尺寸与固定内容不符、大于屏幕或探出屏幕外 → 回到屏幕中央
        // 注意比较的是内容区尺寸：w.frame 含标题栏，与 fixedSize 永远不等，
        // 以前每次刷新都会重设尺寸和位置，与 SwiftUI 自身的窗口尺寸管理互相打架。
        let contentSize = w.contentRect(forFrameRect: w.frame).size
        if abs(contentSize.width - fixedSize.width) > 1 || abs(contentSize.height - fixedSize.height) > 1 {
            w.setContentSize(fixedSize)
            if let vf = vf {
                w.setFrameOrigin(NSPoint(x: vf.midX - fixedSize.width / 2,
                                         y: vf.midY - fixedSize.height / 2))
            }
        } else if let vf = vf {
            let f = w.frame
            if f.maxX > vf.maxX || f.maxY > vf.maxY || f.minX < vf.minX || f.minY < vf.minY {
                w.setFrameOrigin(NSPoint(x: vf.midX - fixedSize.width / 2,
                                         y: vf.midY - fixedSize.height / 2))
            }
        }
    }
}

struct GeneralView: View {
    @AppStorage("countdown") private var countdown: Int = 0
    @AppStorage("poSafeDelay") private var poSafeDelay: Int = 1
    @AppStorage("showOnDock") private var showOnDock: Bool = true
    @AppStorage("showMenubar") private var showMenubar: Bool = true
    @AppStorage(Analytics.enabledKey) private var shareUsageData: Bool = true
    
    @State private var launchAtLogin = false
    @State private var showRepairConfirm = false
    @State private var showRepairFailed = false
    @State private var language: String = AppLanguage.current
    @State private var showLanguageRestart = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        // Tighter section spacing than the other pages so the whole page fits the
        // fixed-height window without scrolling.
        SForm(spacing: 20) {
            SGroupBox(label: "Startup") {
                SPicker("Language", selection: $language) {
                    Text("Follow System").tag(AppLanguage.system)
                    Divider()
                    ForEach(AppLanguage.available, id: \.self) { code in
                        // Each language is shown in its own script so people who can't read
                        // the current UI language can still find theirs (deliberate exception
                        // to the one-language-per-surface rule).
                        Text(verbatim: AppLanguage.nativeName(code)).tag(code)
                    }
                }
                .onChange(of: language) { newValue in
                    guard newValue != AppLanguage.current else { return }
                    AppLanguage.current = newValue
                    showLanguageRestart = true
                }
                SDivider()
                if #available(macOS 13, *) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    SDivider()
                }
                SToggle("Show TinyRecorder on Dock", isOn: $showOnDock)
                    //.disabled(!showMenubar)
                SDivider()
                SToggle("Show TinyRecorder on Menu Bar", isOn: $showMenubar)
                    //.disabled(!showOnDock)
                SDivider()
                SItem(label: "Welcome Guide") {
                    Button("Show Again") { AppDelegate.shared.replayOnboarding() }
                }
            }
            SGroupBox(label: "Update") {
                UpdaterSettingsView(updater: updaterController.updater)
                SDivider()
                SItem(label: "TinyRecorder v\(appVersion)") {
                    CheckForUpdatesView(updater: updaterController.updater)
                }
            }
            SGroupBox(label: "Privacy") {
                SToggle("Share Anonymous Usage Data", isOn: $shareUsageData, tips: "Helps improve TinyRecorder. Sends the app and macOS version, language, and the type, format and length of recordings. Never your recordings, file names or window titles.")
                    .onChange(of: shareUsageData) { Analytics.setEnabled($0) }
            }
            SGroupBox(label: "Permissions") {
                SButton("Screen Recording Permission", buttonTitle: "Repair…",
                        tips: "If the screen recording toggle in System Settings won't stay enabled (may happen after upgrading or replacing the app), reset the permission record and grant it again.") {
                    showRepairConfirm = true
                }
            }
        }
        .onAppear{ if #available(macOS 13, *) { launchAtLogin = (SMAppService.mainApp.status == .enabled) }}
        .onChange(of: showMenubar) { _ in updateStatusBar() }
        .onChange(of: showOnDock) { newValue in
            if !newValue {
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                NSApp.setActivationPolicy(.regular)
            }
        }
        .alert("Repair Screen Recording Permission?", isPresented: $showRepairConfirm) {
            Button("Repair & Relaunch", role: .destructive) { resetScreenPermission() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Warning: this removes the screen recording permission TinyRecorder currently has and relaunches the app. Only use it when the System Settings toggle won't stay enabled — you will need to grant the permission again afterwards.")
        }
        .alert("Restart to Change Language", isPresented: $showLanguageRestart) {
            if AppLanguage.isRecording {
                Button("OK", role: .cancel) {}
            } else {
                Button("Restart Now") { relaunchApp() }
                Button("Later", role: .cancel) {}
            }
        } message: {
            if AppLanguage.isRecording {
                Text("A recording is in progress. The new language will take effect the next time TinyRecorder starts.")
            } else {
                Text("The new language will take effect after TinyRecorder restarts.")
            }
        }
        .alert("Repair Failed", isPresented: $showRepairFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please run this command in Terminal instead:\ntccutil reset ScreenCapture \(Bundle.main.bundleIdentifier ?? "com.33to9.TinyRecorder")")
        }
    }

    private func resetScreenPermission() {
        if resetScreenCapturePermission() { relaunchApp() } else { showRepairFailed = true }
    }
}

/// Per-app language override. Stored as `AppleLanguages` in the app's own defaults domain —
/// the same key macOS 13+ writes from System Settings → General → Language & Region →
/// Applications, so the two stay in sync. Read by the system at launch, so a change needs
/// a restart; switching live would leave SwiftUI literals, open menus, Sparkle and system
/// alerts in the old language.
enum AppLanguage {
    static let system = "system"
    private static let key = "AppleLanguages"

    /// Languages the app ships, from its .lproj folders; English first, then by native name.
    static var available: [String] {
        Bundle.main.localizations
            .filter { $0 != "Base" }
            .sorted { a, b in
                if a == "en" { return true }
                if b == "en" { return false }
                return nativeName(a) < nativeName(b)
            }
    }

    /// The name of a language written in that language, e.g. "Italiano", "简体中文".
    static func nativeName(_ code: String) -> String {
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forIdentifier: code) ?? code
        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }

    /// The override set for this app only, or `system`. Reads the app's own domain:
    /// `ud.array(forKey:)` would also return the global system language list.
    static var current: String {
        get {
            guard let id = Bundle.main.bundleIdentifier,
                  let langs = ud.persistentDomain(forName: id)?[key] as? [String],
                  let first = langs.first else { return system }
            let shipped = Bundle.main.localizations
            if shipped.contains(first) { return first }
            // Values written by System Settings may carry a region, e.g. "zh-Hans-CN".
            return shipped.first { first.hasPrefix($0 + "-") } ?? system
        }
        set {
            if newValue == system { ud.removeObject(forKey: key) }
            else { ud.set([newValue], forKey: key) }
        }
    }

    static var isRecording: Bool { SCContext.streamType != nil || SCContext.stream != nil }
}

struct RecorderView: View {
    @AppStorage("countdown")        private var countdown: Int = 0
    @AppStorage("poSafeDelay")      private var poSafeDelay: Int = 1
    @AppStorage("highlightMouse")   private var highlightMouse: Bool = false
    @AppStorage("includeMenuBar")   private var includeMenuBar: Bool = true
    @AppStorage("hideDesktopFiles") private var hideDesktopFiles: Bool = false
    @AppStorage("trimAfterRecord")  private var trimAfterRecord: Bool = false
    @AppStorage("miniStatusBar")    private var miniStatusBar: Bool = false
    @AppStorage("hideSelf")         private var hideSelf: Bool = true
    @AppStorage("preventSleep")     private var preventSleep: Bool = true
    @AppStorage("showPreview")      private var showPreview: Bool = true
    @AppStorage("hideCCenter")      private var hideCCenter: Bool = false
    @AppStorage("showFloatingController") private var showFloatingController: Bool = true
    @AppStorage("copyToClipboard")  private var copyToClipboard: Bool = false
    @AppStorage("autoCamera")       private var autoCamera: String = ""
    @AppStorage("cameraShape")      private var cameraShape: String = "rounded"
    
    @State private var userColor: Color = Color.black
    @State private var cameras = SCContext.getCameras()

    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Recorder") {
                SSteper("Delay Before Recording", value: $countdown, min: 0, max: 99)
                SDivider()
                if #available(macOS 14, *) {
                    SSteper("Presenter Overlay Delay", value: $poSafeDelay, min: 0, max: 99, tips: "If enabling Presenter Overlay causes recording failure, please increase this value.")
                    SDivider()
                }
                SItem(label: "Custom Background Color") {
                    if #unavailable(macOS 13) {
                        ColorPicker("", selection: $userColor)
                    } else {
                        MatrixColorSelector("", selection: $userColor)
                            .onChange(of: userColor) { userColor in ud.setColor(userColor, forKey: "userColor") }
                    }
                }
            }
            SGroupBox {
                SToggle("Mini size Menu Bar controller", isOn: $miniStatusBar)
                SDivider()
                SToggle("Prevent Mac from sleeping while recording", isOn: $preventSleep)
                SDivider()
                if #available(macOS 13, *) {
                    SToggle("Show floating preview after recording", isOn: $showPreview)
                    SDivider()
                }
                SToggle("Open video trimmer after recording", isOn: $trimAfterRecord)
                SDivider()
                SToggle("Copy the recording to the clipboard", isOn: $copyToClipboard)
                SDivider()
                SToggle("Show on-screen controller when the menu bar icon is hidden", isOn: $showFloatingController, tips: "When the menu bar icon can't be seen (e.g. behind the notch or hidden by a menu bar manager), a small controller with the timer appears at the top of the screen. Turn this off to never show it; use the hotkeys to stop or pause.")
            }
            SGroupBox(label: "Camera") {
                SPicker("Open Camera When Recording Starts", selection: $autoCamera) {
                    Text("Off").tag("")
                    ForEach(cameras, id: \.uniqueID) { camera in
                        Text(verbatim: camera.localizedName).tag(camera.localizedName)
                    }
                    // Keep a camera chosen earlier selectable while it is unplugged
                    if !autoCamera.isEmpty && !cameras.contains(where: { $0.localizedName == autoCamera }) {
                        Text(verbatim: autoCamera).tag(autoCamera)
                    }
                }
                .onChange(of: autoCamera) { name in
                    if !name.isEmpty { SCContext.withCameraAccess {} }
                }
                SDivider()
                SPicker("Camera Overlay Shape", selection: $cameraShape) {
                    Text("Rounded Rectangle").tag("rounded")
                    Text("Circle").tag("circle")
                }
            }
            SGroupBox {
                SToggle("Exclude TinyRecorder itself", isOn: $hideSelf)
                SDivider()
                if #available (macOS 13, *) {
                    SToggle("Include Menu Bar in Recording", isOn: $includeMenuBar)
                    SDivider()
                }
                SToggle("Hide Control Center Icons", isOn: $hideCCenter, tips: "Hide the clock, Wi-Fi, bluetooth, volume and other system icons in the menu bar.")
                SDivider()
                SToggle("Highlight the Mouse Cursor", isOn: $highlightMouse, tips: "Not available for \"Single Window Capture\"")
                SDivider()
                SToggle("Exclude Files on Desktop", isOn: $hideDesktopFiles, tips: "If enabled, all files on the Desktop will be hidden from the video when recording.")
            }
        }.onAppear{ userColor = ud.color(forKey: "userColor") ?? Color.black }
    }
}

struct OutputView: View {
    @AppStorage("encoder")          private var encoder: Encoder = .h264
    @AppStorage("videoFormat")      private var videoFormat: VideoFormat = .mp4
    @AppStorage("audioFormat")      private var audioFormat: AudioFormat = .aac
    @AppStorage("audioQuality")     private var audioQuality: AudioQuality = .high
    @AppStorage("pixelFormat")      private var pixelFormat: PixFormat = .delault
    @AppStorage("background")       private var background: BackgroundType = .wallpaper
    @AppStorage("remuxAudio")       private var remuxAudio: Bool = true
    @AppStorage("enableAEC")        private var enableAEC: Bool = false
    @AppStorage("AECLevel")         private var AECLevel: String = "mid"
    @AppStorage("withAlpha")        private var withAlpha: Bool = false
    @AppStorage("saveDirectory")    private var saveDirectory: String?

    var body: some View {
        SForm(spacing: 30) {
            SGroupBox(label: "Audio") {
                SPicker("Quality", selection: $audioQuality) {
                    if audioFormat == .alac || audioFormat == .flac {
                        Text("Lossless").tag(audioQuality)
                    }
                    Text("Normal - 128Kbps").tag(AudioQuality.normal)
                    Text("Good - 192Kbps").tag(AudioQuality.good)
                    Text("High - 256Kbps").tag(AudioQuality.high)
                    Text("Extreme - 320Kbps").tag(AudioQuality.extreme)
                }.disabled(audioFormat == .alac || audioFormat == .flac)
                SDivider()
                SPicker("Format", selection: $audioFormat) {
                    Text("MP3").tag(AudioFormat.mp3)
                    Text("AAC").tag(AudioFormat.aac)
                    Text("ALAC (Lossless)").tag(AudioFormat.alac)
                    Text("FLAC (Lossless)").tag(AudioFormat.flac)
                    Text("Opus").tag(AudioFormat.opus)
                }
                SDivider()
                if #available(macOS 13, *) {
                    SToggle("Record Microphone to Main Track", isOn: $remuxAudio)
                    SDivider()
                }
                SToggle("Enable Acoustic Echo Cancellation", isOn: $enableAEC)
                if #available(macOS 14, *) {
                    SDivider()
                    SPicker("Audio Ducking Level", selection: $AECLevel) {
                        Text("Min").tag("min")
                        Text("Mid").tag("mid")
                        Text("Max").tag("max")
                    }.disabled(!enableAEC)
                }
            }
            SGroupBox(label: "Video") {
                SPicker("Format", selection: $videoFormat) {
                    Text("MOV").tag(VideoFormat.mov)
                    Text("MP4").tag(VideoFormat.mp4)
                }.disabled(withAlpha)
                SDivider()
                SPicker("Encoder", selection: $encoder) {
                    Text("H.264").tag(Encoder.h264)
                    Text("H.265").tag(Encoder.h265)
                }.disabled(withAlpha)
                SDivider()
                SToggle("Recording with Alpha Channel", isOn: $withAlpha)
            }
            SGroupBox(label: "Save") {
                SItem(label: "Output Folder") {
                    Text(String(format: "Currently set to \"%@\"".local, saveDirectory!.lastPathComponent))
                        .font(.footnote)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Button("Select...", action: { updateOutputDirectory() })
                }
            }
        }.onChange(of: withAlpha) {alpha in
            if alpha {
                encoder = Encoder.h265; videoFormat = VideoFormat.mov
            } else {
                if background == .clear { background = .wallpaper }
            }
        }
    }
    
    func updateOutputDirectory() { // todo: re-sandbox
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowedContentTypes = []
        openPanel.allowsOtherFileTypes = false
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path { saveDirectory = path }
        }
    }
}

struct HotkeyView: View {
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Hotkey") {
                SItem(label: "Open Main Panel") { KeyboardShortcuts.Recorder("", name: .showPanel) }
            }
            SGroupBox {
                SItem(label: "Stop Recording") { KeyboardShortcuts.Recorder("", name: .stop) }
                SDivider()
                SItem(label: "Pause / Resume") { KeyboardShortcuts.Recorder("", name: .pauseResume) }
                SDivider()
                SItem(label: "Discard Recording") { KeyboardShortcuts.Recorder("", name: .discard) }
            }
            SGroupBox {
                SItem(label: "Record System Audio") { KeyboardShortcuts.Recorder("", name: .startWithAudio) }
                SDivider()
                SItem(label: "Record Current Screen") { KeyboardShortcuts.Recorder("", name: .startWithScreen) }
                SDivider()
                SItem(label: "Record Topmost Window") { KeyboardShortcuts.Recorder("", name: .startWithWindow) }
                SDivider()
                SItem(label: "Select Area to Record") { KeyboardShortcuts.Recorder("", name: .startWithArea) }
                SDivider()
                Text("Press a recording hotkey again to stop the recording.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            SGroupBox {
                SItem(label: "Save Current Frame") { KeyboardShortcuts.Recorder("", name: .saveFrame) }
                SDivider()
                SItem(label: "Toggle Screen Magnifier") {KeyboardShortcuts.Recorder("", name: .screenMagnifier) }
            }
        }
    }
}

struct BlocklistView: View {
    var body: some View {
        SForm(spacing: 0, noSpacer: true, scrollable: false) {
            SGroupBox(label: "Blocklist") {
                    BundleSelector()
                    Text("These apps will be excluded when recording \"Screen\" or \"Screen Area\"\nBut if the app is launched after the recording starts, it cannot be excluded.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary)
            }
        }
    }
}

extension UserDefaults {
    func setColor(_ color: Color?, forKey key: String) {
        guard let color = color else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(color), requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Error archiving color:", error)
        }
    }
    
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return Color(nsColor)
    }
    
    func cgColor(forKey key: String) -> CGColor? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return nsColor.cgColor
    }
}

extension KeyboardShortcuts.Name {
    static let startWithAudio = Self("startWithAudio")
    static let startWithScreen = Self("startWithScreen")
    static let startWithWindow = Self("startWithWindow")
    static let startWithArea = Self("startWithArea")
    static let screenMagnifier = Self("screenMagnifier")
    static let saveFrame = Self("saveFrame")
    static let pauseResume = Self("pauseResume")
    static let stop = Self("stop")
    static let discard = Self("discard")
    static let showPanel = Self("showPanel")
}

extension AppDelegate {
    @available(macOS 13.0, *)
    @objc func setLoginItem(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        do {
            if sender.state == .on { try SMAppService.mainApp.register() }
            if sender.state == .off { try SMAppService.mainApp.unregister() }
        }catch{
            print("Failed to \(sender.state == .on ? "enable" : "disable") launch at login: \(error.localizedDescription)")
        }
    }
}