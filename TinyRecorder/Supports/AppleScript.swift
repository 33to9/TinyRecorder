//
//  AppleScript.swift
//  TinyRecorder
//
//  Created by apple on 2024/9/23.
//

import Foundation
import AppKit
import SwiftUI
import ScreenCaptureKit
import UniformTypeIdentifiers

// The classes below are referenced by name from Scriptable.sdef (<cocoa class="..."/>).
// @objc(...) gives them stable, module-independent Objective-C names, so scripting keeps
// working regardless of the Swift module name.

extension NSScriptCommand {
    /// Arguments of the command (empty when none were evaluated).
    var scriptArgs: [String: Any] { evaluatedArguments ?? [:] }

    /// Reports an error back to the calling script instead of showing a modal alert
    /// inside the Apple Event handler.
    func scriptFail(_ message: String) -> Any? {
        scriptErrorNumber = -10000 // errAEEventFailed
        scriptErrorString = message
        return nil
    }

    /// Cancels a countdown that hasn't started recording yet. CountdownView skips its action
    /// once the panel is hidden. Returns true if there was one.
    func cancelPendingCountdown() -> Bool {
        guard countdownPanel.isVisible else { return false }
        // Same as the countdown's Cancel button: also drop the area frame of an area recording.
        for w in NSApp.windows.filter({
            $0.title == "Countdown Panel".local || $0.title == "Area Overlayer".local
        }) { w.close() }
        return true
    }

    /// Common precondition for the recording commands. Returns an error message if the
    /// command can't run now, nil otherwise.
    func scriptRecordingPrecondition() -> String? {
        // streamType 覆盖 iPhone/iPad 录制（没有 SCStream）和正在启动中的录制
        if SCContext.streamType != nil { return "Already recording!".local }
        // A recording is counting down and about to start; a second one would race it.
        if countdownPanel.isVisible { return "Already recording!".local }
        if !CGPreflightScreenCaptureAccess() {
            DispatchQueue.main.async { AppDelegate.shared.showScreenPermissionGuide() }
            return "Screen Recording Permission".local
        }
        // The tinyrecorder command passes the hidden client "cli" parameter; only that value
        // is recognised, so a script can't put arbitrary text into the statistics.
        Analytics.recordingSource = scriptArgs["client"] as? String == "cli" ? "cli" : "script"
        return nil
    }

    /// Ends a command suspended with suspendExecution(): reports `error` to the script, or
    /// returns `result`. Main thread.
    func resume(error: String? = nil, result: Any? = nil) {
        if let error {
            scriptErrorNumber = -10000 // errAEEventFailed
            scriptErrorString = error
        }
        resumeExecution(withResult: result)
    }

    /// Runs a recording command: checks the preconditions, refreshes the screens and windows,
    /// then runs `start` on the main queue. `start` returns an error message, or nil once the
    /// countdown, the recording or a selector window is on its way. Errors go back to the
    /// script instead of an alert, so a script (or an AI agent driving it) never waits on a
    /// dialog nobody sees.
    func runRecordingCommand(_ start: @escaping () -> String?) -> Any? {
        if let error = scriptRecordingPrecondition() { return scriptFail(error) }
        suspendExecution()
        SCContext.refreshAvailableContent { ok in
            DispatchQueue.main.async {
                guard ok else {
                    Analytics.recordingSource = nil
                    self.resume(error: "Couldn't read the screens and windows. Check the Screen Recording permission.")
                    return
                }
                let error = start()
                // Nothing will start, so don't let this command's source tag the next recording.
                if error != nil { Analytics.recordingSource = nil }
                self.resume(error: error)
            }
        }
        return nil
    }

    /// The "saving to" argument of a recording command, checked: the path without its
    /// extension (TinyRecorder adds it), nil if there is none, or an error message.
    func scriptRecordingOutput(audio: Bool = false, mic: Bool = false) -> (base: String?, error: String?) {
        guard let raw = scriptArgs["output"] as? String, !raw.isEmpty else { return (nil, nil) }
        let ext = ScriptTargets.recordingExtension(audio: audio, mic: mic)
        let (path, error) = ScriptTargets.outputPath(raw, allowed: [ext])
        return (path.map { ($0 as NSString).deletingPathExtension }, error)
    }
}

/// Helpers for the commands that find, list or capture screens and windows by script.
enum ScriptTargets {
    /// Display number N (1-based, the order "record screen numbered N" uses); 1 if nil.
    static func display(_ number: Int?) -> SCDisplay? {
        guard let displays = SCContext.availableContent?.displays else { return nil }
        let n = number ?? 1
        return displays.indices.contains(n - 1) ? displays[n - 1] : nil
    }

    /// Number of the display a window is (mostly) on, 1-based.
    static func displayNumber(of frame: CGRect) -> Int? {
        guard let displays = SCContext.availableContent?.displays else { return nil }
        let best = displays.enumerated().max { a, b in
            area(a.element.frame.intersection(frame)) < area(b.element.frame.intersection(frame))
        }
        guard let best, area(best.element.frame.intersection(frame)) > 0 else { return nil }
        return best.offset + 1
    }

    private static func area(_ r: CGRect) -> CGFloat { r.isNull ? 0 : r.width * r.height }

    /// Windows a script can pick: the same ones the window picker shows, with a title.
    static func windows(app: String? = nil) -> [SCWindow] {
        SCContext.getWindows().filter {
            guard let title = $0.title, !title.isEmpty else { return false }
            return app == nil || $0.owningApplication?.applicationName == app
        }
    }

    /// Finds one window by ID, or by exact title (and app). Returns it or an error message.
    static func window(id: Int?, title: String?, app: String?) -> (SCWindow?, String?) {
        guard let content = SCContext.availableContent else { return (nil, "Couldn't read the screens and windows.") }
        if let id {
            guard let w = content.windows.first(where: { $0.windowID == CGWindowID(clamping: id) }) else {
                return (nil, "No window with ID \(id). Run \"tinyrecorder list windows\" for the current IDs.")
            }
            return (w, nil)
        }
        guard let title else { return (nil, nil) }
        let found = content.windows.filter {
            $0.title == title && (app == nil || $0.owningApplication?.applicationName == app)
        }
        if found.isEmpty { return (nil, "No such window!".local) }
        if found.count > 1 {
            return (nil, "Several windows have this title. Pick one by its ID (see \"tinyrecorder list windows\").")
        }
        return (found[0], nil)
    }

    /// Parses "x,y,width,height" (points, from the display's top-left corner) and checks it
    /// fits on the display. Returns the rectangle or an error message.
    static func rect(_ text: String, on display: SCDisplay) -> (CGRect?, String?) {
        let parts = text.split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 4, let x = parts[0], let y = parts[1], let w = parts[2], let h = parts[3] else {
            return (nil, "The area must be x,y,width,height in whole points, e.g. 100,100,1280,720.")
        }
        guard w >= 16, h >= 16 else { return (nil, "The area must be at least 16 × 16 points.") }
        let size = display.frame.size
        guard x >= 0, y >= 0, CGFloat(x + w) <= size.width, CGFloat(y + h) <= size.height else {
            return (nil, "The area doesn't fit on the display, which is \(Int(size.width)) × \(Int(size.height)) points.")
        }
        return (CGRect(x: x, y: y, width: w, height: h), nil)
    }

    /// Extension of the file the next recording is saved as.
    static func recordingExtension(audio: Bool, mic: Bool) -> String {
        guard audio else { return ud.string(forKey: "videoFormat") ?? VideoFormat.mp4.rawValue }
        if mic { return "qma" }
        switch ud.string(forKey: "audioFormat") {
        case AudioFormat.flac.rawValue: return "flac"
        case AudioFormat.opus.rawValue: return "ogg"
        case AudioFormat.mp3.rawValue: return "mp3"
        default: return "m4a"
        }
    }

    private static let mediaExtensions: Set<String> = ["mp4", "mov", "m4a", "mp3", "ogg", "flac", "qma", "png", "jpg", "jpeg", "heic"]

    /// Checks an output path from a script: absolute, in an existing folder, nothing there yet.
    /// `allowed` are the extensions the file may have; the first is added when there is none.
    /// Returns the full path or an error message.
    static func outputPath(_ raw: String, allowed: [String]) -> (String?, String?) {
        let expanded = (raw as NSString).expandingTildeInPath
        guard expanded.hasPrefix("/") else { return (nil, "The output path must be absolute: \(raw)") }
        var path = URL(fileURLWithPath: expanded).standardizedFileURL.path
        let ext = (path as NSString).pathExtension.lowercased()
        if !mediaExtensions.contains(ext) {
            path += "." + allowed[0]
        } else if !allowed.contains(ext) {
            let list = allowed.map { "." + $0 }.joined(separator: " or ")
            return (nil, "The output file must end in \(list) (the current format), not .\(ext).")
        }
        let folder = (path as NSString).deletingLastPathComponent
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder, isDirectory: &isDir), isDir.boolValue else {
            return (nil, "The output folder doesn't exist: \(folder)")
        }
        if FileManager.default.fileExists(atPath: path) { return (nil, "A file already exists at \(path)") }
        return (path, nil)
    }
}

@objc(selectScreen)
class selectScreen: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let index = scriptArgs["index"] as? Int
        return runRecordingCommand {
            closeAllWindow()
            guard let index else {
                AppDelegate.shared.createNewWindow(view: ScreenSelector(), title: "Screen Selector".local)
                return nil
            }
            guard let screens = SCContext.availableContent?.displays, screens.indices.contains(index - 1) else {
                return "Invalid screen number!".local
            }
            let screen = screens[index - 1]
            let output = self.scriptRecordingOutput()
            if let error = output.error { return error }
            AppDelegate.shared.createCountdownPanel(screen: screen) {
                SCContext.nextOutputBase = output.base
                AppDelegate.shared.prepRecord(type: "display", screens: screen, windows: nil, applications: nil)
            }
            return nil
        }
    }
}

@objc(selectArea)
class selectArea: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let rectText = scriptArgs["rect"] as? String
        let displayNumber = scriptArgs["display"] as? Int
        return runRecordingCommand {
            closeAllWindow()
            guard let rectText else {
                if displayNumber != nil || self.scriptArgs["output"] != nil {
                    return "Give the area as a rectangle too, or drag it with the mouse without other options."
                }
                DispatchQueue.main.async { AppDelegate.shared.startAreaSelection() }
                return nil
            }
            guard let screen = ScriptTargets.display(displayNumber), let nsScreen = screen.nsScreen else {
                return "Invalid screen number!".local
            }
            let (rect, error) = ScriptTargets.rect(rectText, on: screen)
            guard let rect else { return error }
            let output = self.scriptRecordingOutput()
            if let error = output.error { return error }
            // screenArea is measured from the display's bottom-left corner.
            SCContext.screenArea = NSRect(x: rect.minX, y: screen.frame.height - rect.maxY, width: rect.width, height: rect.height)
            // The same dashed frame around the area as when it's picked with the mouse.
            let frame = NSRect(x: nsScreen.frame.minX + rect.minX - 4, y: nsScreen.frame.maxY - rect.maxY - 4,
                               width: rect.width + 8, height: rect.height + 8)
            let overlay = NSWindow(contentRect: frame, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
            overlay.hasShadow = false
            overlay.level = .screenSaver
            overlay.ignoresMouseEvents = true
            overlay.isReleasedWhenClosed = false
            overlay.title = "Area Overlayer".local
            overlay.backgroundColor = .clear
            overlay.contentView = NSHostingView(rootView: DashWindow())
            overlay.orderFront(nil)
            AppDelegate.shared.createCountdownPanel(screen: screen) {
                SCContext.autoStop = 0
                SCContext.nextOutputBase = output.base
                AppDelegate.shared.prepRecord(type: "area", screens: screen, windows: nil, applications: nil)
            }
            return nil
        }
    }
}

@objc(selectApps)
class selectApps: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let name = scriptArgs["name"] as? String
        return runRecordingCommand {
            closeAllWindow()
            guard let name else {
                AppDelegate.shared.createNewWindow(view: AppSelector(), title: "App Selector".local)
                return nil
            }
            guard let content = SCContext.availableContent else { return "Couldn't read the screens and windows." }
            guard let app = content.applications.first(where: { $0.applicationName == name }) else {
                return "No such application!".local
            }
            let windows = content.windows.filter {
                guard let title = $0.title else { return false }
                return !title.contains("Item-0") && title != "Window" && $0.frame.width > 40 && $0.frame.height > 40
            }
            var s = [SCDisplay]()
            for screen in content.displays {
                for w in windows where NSIntersectsRect(screen.frame, w.frame) && !s.contains(screen) { s.append(screen) }
            }
            if s.isEmpty { return "This application has no windows!".local }
            if s.count != 1 {
                AppDelegate.shared.createNewWindow(view: AppSelector(), title: "App Selector".local)
                return "This app exists in multiple screens, please select it manually!".local
            }
            let output = self.scriptRecordingOutput()
            if let error = output.error { return error }
            AppDelegate.shared.createCountdownPanel(screen: s[0]) {
                SCContext.nextOutputBase = output.base
                AppDelegate.shared.prepRecord(type: "application", screens: s[0], windows: nil, applications: [app])
            }
            return nil
        }
    }
}

@objc(selectWindows)
class selectWindows: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let title = scriptArgs["title"] as? String
        let appName = scriptArgs["app"] as? String
        let windowID = scriptArgs["id"] as? Int
        return runRecordingCommand {
            closeAllWindow()
            guard title != nil || windowID != nil else {
                AppDelegate.shared.createNewWindow(view: WinSelector(), title: "Window Selector".local)
                return nil
            }
            guard let content = SCContext.availableContent else { return "Couldn't read the screens and windows." }
            let (found, error) = ScriptTargets.window(id: windowID, title: title, app: appName)
            guard let window = found else { return error }
            let output = self.scriptRecordingOutput()
            if let error = output.error { return error }
            let s = content.displays.filter { NSIntersectsRect($0.frame, window.frame) }
            if s.isEmpty { return "Unable to find the screen this window belongs to!".local }
            // Show the countdown on the pointer's screen if the window is on it, else on
            // the window's screen.
            let countdownScreen = SCContext.getSCDisplayWithMouse().flatMap { s.contains($0) ? $0 : nil } ?? s[0]
            AppDelegate.shared.createCountdownPanel(screen: countdownScreen) {
                SCContext.nextOutputBase = output.base
                AppDelegate.shared.prepRecord(type: "window", screens: s[0], windows: [window], applications: nil)
            }
            return nil
        }
    }
}

@objc(recordAudio)
class recordAudio: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let mic = scriptArgs["mic"] as? Bool
        return runRecordingCommand {
            let m = UserDefaults.standard.bool(forKey: "recordMic")
            let output = self.scriptRecordingOutput(audio: true, mic: mic ?? m)
            if let error = output.error { return error }
            if let mic { UserDefaults.standard.set(mic, forKey: "recordMic") }
            closeAllWindow()
            SCContext.nextOutputBase = output.base
            AppDelegate.shared.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil)
            UserDefaults.standard.set(m, forKey: "recordMic")
            return nil
        }
    }
}

// Stop / pause / resume / discard, so a script can run a whole recording (#128)

@objc(stopRecordingCommand)
class stopRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if SCContext.streamType == nil {
            // Stopping during the countdown cancels the recording before it starts.
            return cancelPendingCountdown() ? nil : scriptFail("Not recording.")
        }
        guard scriptArgs["wait"] as? Bool == true else {
            DispatchQueue.main.async { stopActiveRecording() }
            return nil
        }
        // "with waiting until saved": answer with the saved file once it's written (and mixed
        // or converted), or with the error if saving failed.
        guard let id = Analytics.recordingID else {
            return scriptFail("The recording is still starting. Try again in a moment.")
        }
        suspendExecution()
        SCContext.whenSaved(recordingID: id) { file, error in
            self.resume(error: error, result: file?.path)
        }
        DispatchQueue.main.async { stopActiveRecording() }
        return nil
    }
}

/// "recording status": what TinyRecorder is doing, for scripts and agents that need to check
/// before or while they drive a recording.
@objc(recordingStatusCommand)
class recordingStatusCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let type = SCContext.streamType else {
            return ["state": countdownPanel.isVisible ? "countdown" : "idle"] as NSDictionary
        }
        let state: String
        let elapsed: TimeInterval
        if SCContext.isPaused {
            state = "paused"
            elapsed = SCContext.timePassed
        } else if let start = SCContext.startTime {
            state = "recording"
            elapsed = Date.now.timeIntervalSince(start)
        } else {
            state = "starting"
            elapsed = 0
        }
        return ["state": state, "kind": String(describing: type), "elapsed": (elapsed * 10).rounded() / 10] as NSDictionary
    }
}

@objc(pauseRecordingCommand)
class pauseRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if SCContext.stream == nil { return scriptFail("Not recording.") }
        DispatchQueue.main.async { if SCContext.stream != nil && !SCContext.isPaused { SCContext.pauseRecording() } }
        return nil
    }
}

@objc(resumeRecordingCommand)
class resumeRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if SCContext.stream == nil { return scriptFail("Not recording.") }
        DispatchQueue.main.async { if SCContext.stream != nil && SCContext.isPaused { SCContext.pauseRecording() } }
        return nil
    }
}

@objc(discardRecordingCommand)
class discardRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if SCContext.stream == nil {
            return cancelPendingCountdown() ? nil : scriptFail("Not recording.")
        }
        DispatchQueue.main.async { SCContext.discardRecording() }
        return nil
    }
}

@objc(setPreferences)
class setPreferences: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if SCContext.streamType != nil { return scriptFail("Already recording!".local) }
        let args = scriptArgs
        if let fps = args["fps"] as? Int, ![240, 144, 120, 90, 60, 30, 24, 15, 10].contains(fps) {
            return scriptFail("Invalid frame rate! Allowed values: 240, 144, 120, 90, 60, 30, 24, 15, 10")
        }
        let format = (args["format"] as? String)?.lowercased()
        if let format, VideoFormat(rawValue: format) == nil {
            return scriptFail("Invalid file format! Allowed values: mp4, mov")
        }
        let codec = (args["codec"] as? String)?.lowercased().replacingOccurrences(of: ".", with: "")
        if let codec, Encoder(rawValue: codec) == nil {
            return scriptFail("Invalid video codec! Allowed values: h264, h265")
        }
        if let format { UserDefaults.standard.set(format, forKey: "videoFormat") }
        if let codec { UserDefaults.standard.set(codec, forKey: "encoder") }
        if let hires = args["hires"] as? Bool { UserDefaults.standard.set(hires ? 2 : 1, forKey: "highRes") }
        if let fps = self.scriptArgs["fps"] as? Int { UserDefaults.standard.set(fps, forKey: "frameRate") }
        if let cursor = self.scriptArgs["cursor"] as? Bool { UserDefaults.standard.set(cursor, forKey: "showMouse") }
        if let sound = self.scriptArgs["sound"] as? Bool { UserDefaults.standard.set(sound, forKey: "recordWinSound") }
        if let microphone = self.scriptArgs["microphone"] as? Bool { UserDefaults.standard.set(microphone, forKey: "recordMic") }
        if let quality = self.scriptArgs["quality"] as? Int {
            if [1,2,3].contains(quality) {
                switch quality {
                    case 1: UserDefaults.standard.set(0.3, forKey: "videoQuality")
                    case 2: UserDefaults.standard.set(0.7, forKey: "videoQuality")
                    default: UserDefaults.standard.set(1.0, forKey: "videoQuality")
                }
            }
        }
        if let micname = self.scriptArgs["micname"] as? String {
            if SCContext.getMicrophone().map({$0.localizedName}).contains(micname) || micname == "default" {
                UserDefaults.standard.set(micname, forKey: "micDevice")
            }
        }
        if let folder = args["folder"] as? String {
            let path = (folder as NSString).expandingTildeInPath
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
                return scriptFail("The save folder doesn't exist: \(path)")
            }
            UserDefaults.standard.set(path, forKey: "saveDirectory")
        }
        if let hdr = self.scriptArgs["hdr"] as? Bool {
            if #available(macOS 15.0, *) {
                UserDefaults.standard.set(hdr, forKey: "recordHDR")
            }
        }
        return nil
    }
}

/// "list targets": the displays, windows or apps a script can record, so an agent can look
/// before it picks one. Returns tab-separated lines with a header, or JSON.
@objc(listTargetsCommand)
class listTargetsCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let kind = (scriptArgs["kind"] as? String ?? "displays").lowercased()
        let appName = scriptArgs["app"] as? String
        let json = scriptArgs["json"] as? Bool ?? false
        guard ["displays", "windows", "apps"].contains(kind) else {
            return scriptFail("Unknown kind \"\(kind)\". Use displays, windows or apps.")
        }
        guard CGPreflightScreenCaptureAccess() else {
            DispatchQueue.main.async { AppDelegate.shared.showScreenPermissionGuide() }
            return scriptFail("Screen Recording Permission".local)
        }
        suspendExecution()
        SCContext.refreshAvailableContent { ok in
            DispatchQueue.main.async {
                guard ok, let content = SCContext.availableContent else {
                    self.resume(error: "Couldn't read the screens and windows. Check the Screen Recording permission.")
                    return
                }
                let rows: [[(String, Any)]]
                switch kind {
                case "displays":
                    rows = content.displays.enumerated().map { (i, d) -> [(String, Any)] in [
                        ("number", i + 1),
                        ("name", d.nsScreen?.localizedName ?? "Display \(i + 1)"),
                        ("width", Int(d.frame.width)), ("height", Int(d.frame.height)),
                        ("x", Int(d.frame.minX)), ("y", Int(d.frame.minY)),
                        ("main", d.displayID == CGMainDisplayID()),
                    ] }
                case "windows":
                    rows = ScriptTargets.windows(app: appName).map { w -> [(String, Any)] in [
                        ("id", Int(w.windowID)),
                        ("app", w.owningApplication?.applicationName ?? ""),
                        ("title", w.title ?? ""),
                        ("display", ScriptTargets.displayNumber(of: w.frame) ?? 0),
                        ("width", Int(w.frame.width)), ("height", Int(w.frame.height)),
                        ("x", Int(w.frame.minX)), ("y", Int(w.frame.minY)),
                    ] }
                default:
                    let windows = ScriptTargets.windows(app: appName)
                    rows = SCContext.getApps().filter { appName == nil || $0.applicationName == appName }.map { a -> [(String, Any)] in
                        let own = windows.filter { $0.owningApplication == a }
                        return [("name", a.applicationName), ("bundle_id", a.bundleIdentifier), ("windows", own.count)]
                    }
                }
                self.resume(result: json ? Self.json(rows) : Self.table(rows))
            }
        }
        return nil
    }

    private static func json(_ rows: [[(String, Any)]]) -> String {
        let objects = rows.map { Dictionary($0, uniquingKeysWith: { a, _ in a }) }
        guard let data = try? JSONSerialization.data(withJSONObject: objects, options: [.sortedKeys]) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func table(_ rows: [[(String, Any)]]) -> String {
        guard let first = rows.first else { return "" }
        func cell(_ v: Any) -> String {
            if let b = v as? Bool { return b ? "yes" : "no" }
            // Tabs and line breaks would break the columns, and "column" merges empty cells.
            let text = "\(v)".replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: " ")
            return text.isEmpty ? "-" : text
        }
        let header = first.map { $0.0.uppercased() }.joined(separator: "\t")
        return ([header] + rows.map { $0.map { cell($0.1) }.joined(separator: "\t") }).joined(separator: "\n")
    }
}

/// "take screenshot": saves a PNG (or JPEG) of a display, a window or an area and returns its
/// path. Uses TinyRecorder's Screen Recording permission, so the calling terminal needs none.
@objc(takeScreenshotCommand)
class takeScreenshotCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let args = scriptArgs
        let displayNumber = args["display"] as? Int
        let title = args["title"] as? String
        let appName = args["app"] as? String
        let windowID = args["id"] as? Int
        let rectText = args["rect"] as? String
        if (title != nil || windowID != nil) && (rectText != nil || displayNumber != nil) {
            return scriptFail("Take a screenshot of a window, or of a display or an area, not both.")
        }
        if appName != nil && title == nil { return scriptFail("Give the window's title too.") }
        guard CGPreflightScreenCaptureAccess() else {
            DispatchQueue.main.async { AppDelegate.shared.showScreenPermissionGuide() }
            return scriptFail("Screen Recording Permission".local)
        }
        // Check the path before anything is captured.
        var output: String?
        if let raw = args["output"] as? String, !raw.isEmpty {
            let (path, error) = ScriptTargets.outputPath(raw, allowed: ["png", "jpg", "jpeg"])
            guard let path else { return scriptFail(error ?? "Invalid output path.") }
            output = path
        }
        suspendExecution()
        SCContext.refreshAvailableContent { ok in
            DispatchQueue.main.async {
                guard ok, let content = SCContext.availableContent else {
                    self.resume(error: "Couldn't read the screens and windows. Check the Screen Recording permission.")
                    return
                }
                let filter: SCContentFilter
                let config = SCStreamConfiguration()
                if title != nil || windowID != nil {
                    let (found, error) = ScriptTargets.window(id: windowID, title: title, app: appName)
                    guard let window = found else { self.resume(error: error); return }
                    filter = SCContentFilter(desktopIndependentWindow: window)
                } else {
                    guard let display = ScriptTargets.display(displayNumber) else {
                        self.resume(error: "Invalid screen number!".local); return
                    }
                    // Leave TinyRecorder's own windows (the recording controls) out.
                    let own = content.windows.filter { $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier }
                    filter = SCContentFilter(display: display, excludingWindows: own)
                    if #available(macOS 14.2, *) { filter.includeMenuBar = true }
                    if let rectText {
                        let (rect, error) = ScriptTargets.rect(rectText, on: display)
                        guard let rect else { self.resume(error: error); return }
                        config.sourceRect = rect
                    }
                }
                let size = config.sourceRect.isEmpty ? filter.contentRect.size : config.sourceRect.size
                config.width = Int(size.width * CGFloat(filter.pointPixelScale))
                config.height = Int(size.height * CGFloat(filter.pointPixelScale))
                config.showsCursor = false
                config.captureResolution = .best
                let path = output ?? "\(SCContext.getFilePath(capture: true)).png"
                SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
                    DispatchQueue.main.async {
                        guard let image else {
                            self.resume(error: error?.localizedDescription ?? "Couldn't take the screenshot.")
                            return
                        }
                        if let error = Self.write(image, to: path) { self.resume(error: error); return }
                        self.resume(result: path)
                    }
                }
            }
        }
        return nil
    }

    /// Writes the image as PNG, or JPEG for .jpg/.jpeg. Returns an error message.
    private static func write(_ image: CGImage, to path: String) -> String? {
        let ext = (path as NSString).pathExtension.lowercased()
        let type = (ext == "jpg" || ext == "jpeg") ? UTType.jpeg : UTType.png
        guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, type.identifier as CFString, 1, nil) else {
            return "Couldn't create the file \(path)"
        }
        CGImageDestinationAddImage(dest, image, nil)
        return CGImageDestinationFinalize(dest) ? nil : "Couldn't write the file \(path)"
    }
}

/// Links the bundled `tinyrecorder` command into /usr/local/bin (on the default PATH), so it
/// works in Terminal without Homebrew. Asks for an administrator password only when that
/// folder isn't writable. Never replaces a file there that isn't a link.
enum CommandLineTool {
    static let linkPath = "/usr/local/bin/tinyrecorder"

    static func install() {
        NSApp.activate(ignoringOtherApps: true)
        guard let tool = Bundle.main.path(forResource: "tinyrecorder", ofType: nil) else {
            return fail("The command-line tool is missing from this copy of TinyRecorder. Download TinyRecorder again from tinyrecorder.app.".local)
        }
        // A quarantined app runs from a temporary, read-only copy; a link to it would break.
        if Bundle.main.bundlePath.contains("/AppTranslocation/") {
            return fail("Move TinyRecorder to the Applications folder, open it from there, then try again.".local)
        }
        let fm = FileManager.default
        let current = try? fm.destinationOfSymbolicLink(atPath: linkPath)
        if current == tool { return done() }
        if current == nil && fm.fileExists(atPath: linkPath) {
            return fail(String(format: "There is already a file at %@. Remove it, then try again.".local, linkPath))
        }
        do {
            if current != nil { try fm.removeItem(atPath: linkPath) }
            try fm.createDirectory(atPath: "/usr/local/bin", withIntermediateDirectories: true)
            try fm.createSymbolicLink(atPath: linkPath, withDestinationPath: tool)
            return done()
        } catch {
            // /usr/local/bin belongs to root on a fresh Mac: do it with the user's password.
            let shell = "/bin/mkdir -p /usr/local/bin && /bin/ln -sfn \(shellQuoted(tool)) \(shellQuoted(linkPath))"
            let source = "do shell script \"\(appleScriptEscaped(shell))\" with administrator privileges"
            var info: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&info)
            if let info {
                if info[NSAppleScript.errorNumber] as? Int == -128 { return } // cancelled
                return fail(info[NSAppleScript.errorMessage] as? String ?? "Unknown Error".local)
            }
            done()
        }
    }

    private static func done() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Command-Line Tool Installed".local
        alert.informativeText = "Open a new Terminal window to use the tinyrecorder command (windows that were already open won't find it). Run “tinyrecorder help” to see what it can do.".local
        alert.addButton(withTitle: "OK".local)
        alert.runModal()
    }

    private static func fail(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn't Install the Command-Line Tool".local
        alert.informativeText = message
        alert.addButton(withTitle: "OK".local)
        alert.runModal()
    }

    private static func shellQuoted(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptEscaped(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
