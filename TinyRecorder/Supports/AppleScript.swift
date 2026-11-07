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
        Analytics.recordingSource = "script"
        return nil
    }
}

@objc(selectScreen)
class selectScreen: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let error = scriptRecordingPrecondition() { return scriptFail(error) }
        SCContext.updateAvailableContent {
            DispatchQueue.main.async {
                closeAllWindow()
                if var index = self.scriptArgs["index"] as? Int {
                    guard let screens = SCContext.availableContent?.displays else { return }
                    index -= 1
                    closeAllWindow()
                    if index >= screens.count || index < 0 {
                        createAlert(title: "Error".local, message: "Invalid screen number!".local, button1: "OK".local).runModal()
                        return
                    } else {
                        let screen = screens[index]
                        AppDelegate.shared.createCountdownPanel(screen: screen) {
                            AppDelegate.shared.prepRecord(type: "display", screens: screen, windows: nil, applications: nil)
                        }
                    }
                } else {
                    closeAllWindow()
                    AppDelegate.shared.createNewWindow(view: ScreenSelector(), title: "Screen Selector".local)
                }
            }
        }
        return nil
    }
}

@objc(selectArea)
class selectArea: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let error = scriptRecordingPrecondition() { return scriptFail(error) }
        SCContext.updateAvailableContent {
            DispatchQueue.main.async {
                closeAllWindow()
                DispatchQueue.main.async {
                    AppDelegate.shared.startAreaSelection()
                }
            }
        }
        return nil
    }
}

@objc(selectApps)
class selectApps: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let error = scriptRecordingPrecondition() { return scriptFail(error) }
        SCContext.updateAvailableContent {
            DispatchQueue.main.async {
                closeAllWindow()
                if let name = self.scriptArgs["name"] as? String {
                    guard let app = SCContext.availableContent?.applications.first(where: { $0.applicationName == name }) else {
                        createAlert(title: "Error".local, message: "No such application!".local, button1: "OK".local).runModal()
                        return
                    }
                    closeAllWindow()
                    guard let screens = SCContext.availableContent?.displays else { return }
                    guard let windows = SCContext.availableContent?.windows.filter({
                        guard let title = $0.title else { return false }
                        return !title.contains("Item-0")
                        && title != "Window"
                        && $0.frame.width > 40
                        && $0.frame.height > 40
                    }) else { return }
                    var s = [SCDisplay]()
                    for screen in screens {
                        for w in windows {
                            if NSIntersectsRect(screen.frame, w.frame) { if !s.contains(screen) { s.append(screen) }}
                        }
                    }
                    if s.isEmpty {
                        createAlert(title: "Error".local, message: "This application has no windows!".local, button1: "OK".local).runModal()
                        return
                    }
                    if s.count != 1 {
                        AppDelegate.shared.createNewWindow(view: AppSelector(), title: "App Selector".local)
                        createAlert(title: "Error".local, message: "This app exists in multiple screens, please select it manually!".local, button1: "OK".local).runModal()
                    } else {
                        AppDelegate.shared.createCountdownPanel(screen: s.first!) {
                            AppDelegate.shared.prepRecord(type: "application", screens: s.first!, windows: nil, applications: [app])
                        }
                    }
                } else {
                    closeAllWindow()
                    AppDelegate.shared.createNewWindow(view: AppSelector(), title: "App Selector".local)
                }
            }
        }
        return nil
    }
}

@objc(selectWindows)
class selectWindows: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let error = scriptRecordingPrecondition() { return scriptFail(error) }
        SCContext.updateAvailableContent {
            DispatchQueue.main.async {
                closeAllWindow()
                if let title = self.scriptArgs["title"] as? String {
                    var windows = [SCWindow]()
                    guard let w = SCContext.availableContent?.windows.filter({ $0.title == title }) else { return }
                    windows = w
                    if let app = self.scriptArgs["app"] as? String {
                        guard let w = SCContext.availableContent?.windows.filter({ $0.title == title && $0.owningApplication?.applicationName == app }) else { return }
                        windows = w
                    }
                    closeAllWindow()
                    if windows.isEmpty {
                        createAlert(title: "Error".local, message: "No such window!".local, button1: "OK".local).runModal()
                        return
                    }
                    if windows.count > 1 {
                        AppDelegate.shared.createNewWindow(view: WinSelector(), title: "Window Selector".local)
                        createAlert(title: "Error".local, message: "Duplicate window exists, please select it manually!".local, button1: "OK".local).runModal()
                        return
                    }
                    let window = windows.first!
                    guard let screens = SCContext.availableContent?.displays else { return }
                    var s = [SCDisplay]()
                    for screen in screens {
                        if NSIntersectsRect(screen.frame, window.frame) { if !s.contains(screen) { s.append(screen) }}
                    }
                    if s.isEmpty {
                        createAlert(title: "Error".local, message: "Unable to find the screen this window belongs to!".local, button1: "OK".local).runModal()
                        return
                    }
                    // Show the countdown on the pointer's screen if the window is on it, else on
                    // the window's screen. (Previously nothing happened when the pointer's screen
                    // couldn't be determined.)
                    let countdownScreen = SCContext.getSCDisplayWithMouse().flatMap { s.contains($0) ? $0 : nil } ?? s.first!
                    AppDelegate.shared.createCountdownPanel(screen: countdownScreen) {
                        AppDelegate.shared.prepRecord(type: "window" , screens: s.first!, windows: [window], applications: nil)
                    }
                } else {
                    closeAllWindow()
                    AppDelegate.shared.createNewWindow(view: WinSelector(), title: "Window Selector".local)
                }
            }
        }
        return nil
    }
}

@objc(recordAudio)
class recordAudio: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let error = scriptRecordingPrecondition() { return scriptFail(error) }
        SCContext.updateAvailableContent {
            DispatchQueue.main.async {
                let m = UserDefaults.standard.bool(forKey: "recordMic")
                if let mic = self.scriptArgs["mic"] as? Bool {
                    UserDefaults.standard.set(mic, forKey: "recordMic")
                }
                closeAllWindow()
                AppDelegate.shared.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil)
                UserDefaults.standard.set(m, forKey: "recordMic")
            }
        }
        return nil
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
        DispatchQueue.main.async { stopActiveRecording() }
        return nil
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
