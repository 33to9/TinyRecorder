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

    static func recordingStarted(_ type: StreamType?) {
        var params = ["type": name(type), "format": format(type)]
        if type != .systemaudio, type != .idevice {
            params["encoder"] = ud.string(forKey: "encoder") ?? "unknown"
            params["frameRate"] = String(ud.integer(forKey: "frameRate"))
        }
        params["microphone"] = ud.bool(forKey: "recordMic") ? "on" : "off"
        signal("Recording.started", parameters: params)
    }

    static func recordingFinished(_ type: StreamType?, startedAt: Date?) {
        let seconds = startedAt.map { max(0, Date.now.timeIntervalSince($0)) }
        signal("Recording.finished", parameters: ["type": name(type), "format": format(type)], floatValue: seconds)
    }

    static func recordingDiscarded(_ type: StreamType?) {
        signal("Recording.discarded", parameters: ["type": name(type)])
    }

    /// `stage`: "start", "writing" or "saving". Only the error domain and code are sent,
    /// never the message (it can contain file paths).
    static func recordingFailed(stage: String, type: StreamType?, error: Error?) {
        var params = ["stage": stage, "type": name(type)]
        if let error = error as NSError? {
            params["errorDomain"] = error.domain
            params["errorCode"] = String(error.code)
        }
        signal("Recording.failed", parameters: params)
    }
}
