//
//  AppleScript.swift
//  TinyRecorder
//
//  Created by apple on 2024/9/23.
//

import Foundation
import AppKit
import ScreenCaptureKit

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
            AppDelegate.shared.createCountdownPanel(screen: screen) {
                AppDelegate.shared.prepRecord(type: "display", screens: screen, windows: nil, applications: nil)
            }
            return nil
        }
    }
}

@objc(selectArea)
class selectArea: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        runRecordingCommand {
            closeAllWindow()
            DispatchQueue.main.async { AppDelegate.shared.startAreaSelection() }
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
            AppDelegate.shared.createCountdownPanel(screen: s[0]) {
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
        return runRecordingCommand {
            closeAllWindow()
            guard let title else {
                AppDelegate.shared.createNewWindow(view: WinSelector(), title: "Window Selector".local)
                return nil
            }
            guard let content = SCContext.availableContent else { return "Couldn't read the screens and windows." }
            let windows = content.windows.filter {
                $0.title == title && (appName == nil || $0.owningApplication?.applicationName == appName)
            }
            if windows.isEmpty { return "No such window!".local }
            if windows.count > 1 {
                AppDelegate.shared.createNewWindow(view: WinSelector(), title: "Window Selector".local)
                return "Duplicate window exists, please select it manually!".local
            }
            let window = windows[0]
            let s = content.displays.filter { NSIntersectsRect($0.frame, window.frame) }
            if s.isEmpty { return "Unable to find the screen this window belongs to!".local }
            // Show the countdown on the pointer's screen if the window is on it, else on
            // the window's screen.
            let countdownScreen = SCContext.getSCDisplayWithMouse().flatMap { s.contains($0) ? $0 : nil } ?? s[0]
            AppDelegate.shared.createCountdownPanel(screen: countdownScreen) {
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
            if let mic { UserDefaults.standard.set(mic, forKey: "recordMic") }
            closeAllWindow()
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
