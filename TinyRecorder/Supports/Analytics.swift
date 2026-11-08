//
//  Analytics.swift
//  TinyRecorder
//
//  Anonymous usage statistics via TelemetryDeck (https://telemetrydeck.com).
//  TelemetryDeck hashes the user identifier on device and stores no IP addresses.
//
//  What is sent: the SDK's default signal metadata (app version, macOS version,
//  locale, device model) plus the few signals below. Never file names, paths,
//  window or app titles, error messages or recording content.
//  Recording signals carry a recordingID: a random UUID made for each recording,
//  only used to link its started/finished/saved/failed signals. It is not tied to
//  the user, the device or the file.
//
//  Users can turn it off in Settings › General › Privacy ("shareUsageData").
//

import Foundation
import TelemetryDeck

enum Analytics {
    private static let appID = "1414EDEE-E795-4687-9DD1-694F6A03802C"
    static let enabledKey = "shareUsageData"

    static var isEnabled: Bool {
        ud.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Call once at launch.
    static func start() {
        if isEnabled { initialize() }
    }

    /// Called when the Settings toggle changes.
    static func setEnabled(_ enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                if !TelemetryManager.isInitialized { initialize() }
            } else if TelemetryManager.isInitialized {
                TelemetryDeck.terminate()
            }
        }
    }

    private static func initialize() {
        TelemetryDeck.initialize(config: .init(appID: appID))
    }

    /// Sends a signal if the user hasn't opted out. Safe to call from any thread.
    static func signal(_ name: String, parameters: [String: String] = [:], floatValue: Double? = nil) {
        DispatchQueue.main.async {
            guard isEnabled, TelemetryManager.isInitialized else { return }
            TelemetryDeck.signal(name, parameters: parameters, floatValue: floatValue)
        }
    }

    // MARK: - Recording events

    private static func name(_ type: StreamType?) -> String {
        guard let type else { return "unknown" }
        return String(describing: type)
    }

    private static func format(_ type: StreamType?) -> String {
        let key = type == .systemaudio ? "audioFormat" : "videoFormat"
        return ud.string(forKey: key) ?? "unknown"
    }

    /// The recording in progress; set when it starts, cleared when it stops.
    static var recordingID: String?

    // MARK: Where recordings start

    /// Where the user started the next recording from: "toolbar", "menuBar", "hotkey",
    /// "script" (AppleScript) or "cli" (the tinyrecorder command). Set by each entry point,
    /// taken by `recordingStarted`, so a path that doesn't set it shows up as "unknown".
    static var recordingSource: String?

    /// The source of each recording, by recording ID, so its later signals (finished, saved,
    /// failed, discarded) carry it too and automated recordings can be filtered out without
    /// joining on the ID. Written from several threads, hence the lock.
    private static var sources: [String: String] = [:]
    private static let sourcesLock = NSLock()

    private static func source(of id: String) -> String? {
        sourcesLock.lock(); defer { sourcesLock.unlock() }
        return sources[id]
    }

    private static func setSource(_ source: String, of id: String) {
        sourcesLock.lock(); defer { sourcesLock.unlock() }
        // A recording that never reports its end (crash, quit while saving) would stay here
        if sources.count > 20 { sources.removeAll() }
        sources[id] = source
    }

    /// The recording has nothing more to report.
    private static func forgetSource(of id: String?) {
        guard let id else { return }
        sourcesLock.lock(); defer { sourcesLock.unlock() }
        sources[id] = nil
    }
    /// How the toolbar now on screen was opened, sent with recordings started from it.
    private static var toolbarOpenedFrom = "reopen"
    /// Set right before an in-app call opens the toolbar: "hotkey", "onboarding" or "launch".
    /// Otherwise the system opened it ("reopen": the Dock icon, or opening the app again).
    private static var nextToolbarOpener: String?

    static func toolbarWillOpen(from opener: String) { nextToolbarOpener = opener }

    /// Called at the start of applicationShouldHandleReopen, whether or not it shows the toolbar.
    static func toolbarOpenRequested() -> String {
        let opener = nextToolbarOpener ?? "reopen"
        nextToolbarOpener = nil
        return opener
    }

    static func toolbarOpened(from opener: String) {
        recordingSource = "toolbar"
        toolbarOpenedFrom = opener
    }

    /// "pending" until this install's first recording starts, then "done". Installs that
    /// already finished the setup before this was added start at "done": whether they ever
    /// recorded is unknown.
    private static let firstRecordingKey = "analyticsFirstRecording"

    /// Call at launch, before the onboarding can mark the setup as done.
    static func prepareFirstRecordingFlag(setupDone: Bool) {
        if ud.string(forKey: firstRecordingKey) == nil {
            ud.set(setupDone ? "done" : "pending", forKey: firstRecordingKey)
        }
    }

    private static func baseParams(_ type: StreamType?, id: String?) -> [String: String] {
        var params = ["recordingType": name(type)]
        if let id {
            params["recordingID"] = id
            if let source = source(of: id) { params["source"] = source }
        }
        return params
    }

    static func recordingStarted(_ type: StreamType?) {
        let id = UUID().uuidString
        recordingID = id
        let source = recordingSource ?? "unknown"
        recordingSource = nil
        setSource(source, of: id)
        var params = baseParams(type, id: id)
        params["format"] = format(type)
        if type != .systemaudio, type != .idevice {
            params["encoder"] = ud.string(forKey: "encoder") ?? "unknown"
            params["frameRate"] = String(ud.integer(forKey: "frameRate"))
        }
        // Screen/audio recordings use the per-recording snapshot (a script can override the
        // microphone for one recording); iPhone/iPad recordings read the setting directly.
        let mic = type == .idevice ? ud.bool(forKey: "recordMic") : SCContext.recMic
        params["microphone"] = mic ? "on" : "off"
        if source == "toolbar" { params["toolbarOpenedFrom"] = toolbarOpenedFrom }
        if ud.string(forKey: firstRecordingKey) == "pending" {
            params["firstRecording"] = "true"
            ud.set("done", forKey: firstRecordingKey)
        }
        signal("Recording.started", parameters: params)
    }

    /// The recording was stopped; sent before its file is written out, so it says nothing
    /// about whether saving worked (see `recordingSaved`).
    static func recordingFinished(_ type: StreamType?, startedAt: Date?) {
        let seconds = startedAt.map { max(0, Date.now.timeIntervalSince($0)) }
        var params = baseParams(type, id: recordingID)
        params["format"] = format(type)
        signal("Recording.finished", parameters: params, floatValue: seconds)
    }

    /// The recording's file is in the save folder. `id` is captured when the recording
    /// stopped, as saving finishes after `recordingID` is cleared.
    static func recordingSaved(_ type: StreamType?, id: String?) {
        var params = baseParams(type, id: id)
        params["format"] = format(type)
        signal("Recording.saved", parameters: params)
        forgetSource(of: id)
    }

    static func recordingDiscarded(_ type: StreamType?) {
        signal("Recording.discarded", parameters: baseParams(type, id: recordingID))
        forgetSource(of: recordingID)
    }

    /// `stage`: "start", "writing", "saving", "mixing" (the file is kept without the mixed
    /// audio) or "converting" (MP3). Only the error domain and code are sent, never the
    /// message (it can contain file paths). `id` defaults to the recording in progress.
    static func recordingFailed(stage: String, type: StreamType?, error: Error?, id: String? = Analytics.recordingID) {
        var params = baseParams(type, id: id)
        params["stage"] = stage
        if let error = error as NSError? {
            params["errorDomain"] = error.domain
            params["errorCode"] = String(error.code)
        }
        signal("Recording.failed", parameters: params)
        // "writing" is followed by the stop and save, "mixing" by Recording.saved
        if ["start", "saving", "converting"].contains(stage) { forgetSource(of: id) }
    }

    // MARK: - First-run funnel

    /// `replay`: the onboarding was reopened from Preferences, not shown at first launch.
    private static func onboardingParams(_ replay: Bool) -> [String: String] {
        ["replay": replay ? "true" : "false"]
    }

    /// An onboarding step was shown: "permission", "microphone", "format" or "start".
    static func onboardingStepShown(_ step: String, replay: Bool) {
        var params = onboardingParams(replay)
        params["step"] = step
        signal("Onboarding.stepShown", parameters: params)
    }

    /// "Start Recording" on the last step.
    static func onboardingCompleted(replay: Bool) {
        signal("Onboarding.completed", parameters: onboardingParams(replay))
    }

    /// The onboarding window was closed without finishing; `step` is where it was closed.
    static func onboardingClosed(atStep step: String, replay: Bool) {
        var params = onboardingParams(replay)
        params["step"] = step
        signal("Onboarding.closed", parameters: params)
    }

    /// `action`: "requested" (Grant Permission clicked), "granted" (seen while the guide is
    /// open) or "reset" (Reset Permission & Relaunch). `context`: "onboarding" or "guide"
    /// (the standalone guide shown later when the permission is missing).
    static func screenRecordingPermission(_ action: String, context: String) {
        signal("Permission.screenRecording", parameters: ["action": action, "context": context])
    }

    /// Result of a system microphone prompt. `context`: "onboarding" or "recording"
    /// (asked when a recording with the microphone starts).
    static func microphonePermission(granted: Bool, context: String) {
        signal("Permission.microphone", parameters: ["result": granted ? "granted" : "denied", "context": context])
    }
}
