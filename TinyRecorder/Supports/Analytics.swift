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

    private static func baseParams(_ type: StreamType?, id: String?) -> [String: String] {
        var params = ["recordingType": name(type)]
        if let id { params["recordingID"] = id }
        return params
    }

    static func recordingStarted(_ type: StreamType?) {
        let id = UUID().uuidString
        recordingID = id
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
    }

    static func recordingDiscarded(_ type: StreamType?) {
        signal("Recording.discarded", parameters: baseParams(type, id: recordingID))
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
    }
}
