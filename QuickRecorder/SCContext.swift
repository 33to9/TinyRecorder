//
//  SCContext.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import AVFAudio
import AVFoundation
import Foundation
import ScreenCaptureKit
import UserNotifications
import SwiftLAME
import SwiftUI
import AECAudioStream

class SCContext {
    static var trimingList = [URL]()
    static var firstFrame: CMSampleBuffer?
    static var autoStop = 0
    static var recordCam = ""
    static var recordDevice = ""
    static var captureSession: AVCaptureSession!
    static var previewSession: AVCaptureSession!
    static var frameCache: CMSampleBuffer?
    static var filter: SCContentFilter?
    static var isMagnifierEnabled = false
    static var saveFrame = false
    static var isPaused = false
    static var isResume = false
    static var isSkipFrame = false
    static var lastPTS: CMTime?
    static var timeOffset = CMTime.zero
    /// 串行队列：SCStream 回调与麦克风写入都在这里执行，避免与停止流程/彼此之间产生竞争
    static let streamQueue = DispatchQueue(label: "com.33to9.TinyRecorder.stream")
    // 以下录制状态只在 streamQueue 上读写（主线程通过 streamQueue.sync 修改）
    static var isStopping = false
    static var sessionStarted = false
    static var writerFailureReported = false
    // 录制开始时的设置快照：停止时使用，避免录制中途修改设置导致清理不一致
    static var recMic = false
    static var recWinSound = false
    static var recRemuxAudio = false
    static var recAudioFormat = ""
    // 实际启动了哪些麦克风采集组件，停止时据此清理
    static var micTapInstalled = false
    static var aecStarted = false
    static var screenArea: NSRect?
    static let audioEngine = AVAudioEngine()
    static let AECEngine = AECAudioStream(sampleRate: 48000)
    static var backgroundColor: CGColor = CGColor.black
    static var filePath: String!
    static var filePath1: String!
    static var filePath2: String!
    static var audioFile: AVAudioFile?
    static var audioFile2: AVAudioFile?
    static var vW: AVAssetWriter!
    static var vwInput, awInput, micInput: AVAssetWriterInput!
    static var startTime: Date?
    static var timePassed: TimeInterval = 0
    static var stream: SCStream!
    static var screen: SCDisplay?
    static var window: [SCWindow]?
    static var application: [SCRunningApplication]?
    static var streamType: StreamType?
    static var availableContent: SCShareableContent?
    static let excludedApps = ["", "com.apple.dock", "com.apple.screencaptureui", "com.apple.controlcenter", "com.apple.notificationcenterui", "com.apple.systemuiserver", "com.apple.WindowManager", "dev.mnpn.Azayaka", "com.gaosun.eul", "com.pointum.hazeover", "net.matthewpalmer.Vanilla", "com.dwarvesv.minimalbar", "com.bjango.istatmenus.status"]
    
    static func updateAvailableContentSync() -> SCShareableContent? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: SCShareableContent? = nil

        updateAvailableContent { content in
            result = content
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }
    
    private static func updateAvailableContent(completion: @escaping (SCShareableContent?) -> Void) {
        // 无权限时绝不触发 SCK 枚举（macOS 15+ 会弹出系统授权框，轮询会造成弹窗轰炸）
        guard CGPreflightScreenCaptureAccess() else {
            completion(nil)
            return
        }
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { [self] content, error in
            if let error = error {
                switch error {
                case SCStreamError.userDeclined:
                    // 权限被拒绝/未授予：交给启动流程里的引导窗处理。
                    // 不要在这里自动重试——曾经 1 秒重试一次，与系统授权框形成无限弹窗循环。
                    break
                default:
                    print("Error: failed to fetch available content: ".local, error.localizedDescription)
                }
                completion(nil) // 在错误情况下返回 nil
                return
            }

            availableContent = content
            if let displays = content?.displays, !displays.isEmpty {
                completion(content) // 返回成功获取的 content
            } else {
                print("There needs to be at least one display connected!".local)
                completion(nil) // 如果没有显示器连接，则返回 nil
            }
        }
    }
    
    static func updateAvailableContent(completion: @escaping () -> Void) {
        // 无权限时直接引导用户去授权，而不是调用 SCK（会再次触发系统授权框）
        guard CGPreflightScreenCaptureAccess() else {
            requestPermissions()
            return
        }
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error = error {
                switch error {
                case SCStreamError.userDeclined: requestPermissions()
                default: print("Error: failed to fetch available content: ".local, error.localizedDescription)
                }
                return
            }
            availableContent = content
            assert(availableContent?.displays.isEmpty != nil, "There needs to be at least one display connected!".local)
            completion()
        }
    }
    
    static func getSelf() -> SCRunningApplication? {
        guard let content = SCContext.availableContent else { return nil }
        return content.applications.first(where: { Bundle.main.bundleIdentifier == $0.bundleIdentifier })
    }
    
    static func getSelfWindows() -> [SCWindow]? {
        guard let content = SCContext.availableContent else { return nil }
        return content.windows.filter( {
            guard let title = $0.title else { return false }
            return $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
            && title != "Mouse Pointer".local
            && title != "Screen Magnifier".local
            && title != "Camera Overlayer".local
            && title != "iDevice Overlayer".local
        })
    }
    
    static func getApps(isOnScreen: Bool = true, hideSelf: Bool = true) -> [SCRunningApplication] {
        var apps = [SCRunningApplication]()
        for app in getWindows(isOnScreen: isOnScreen, hideSelf: hideSelf).compactMap({ $0.owningApplication }) {
            if !apps.contains(app) { apps.append(app) }
        }
        if hideSelf && ud.bool(forKey: "hideSelf") { apps = apps.filter({$0.bundleIdentifier != Bundle.main.bundleIdentifier}) }
        return apps
    }
    
    static func getWindows(isOnScreen: Bool = true, hideSelf: Bool = true) -> [SCWindow] {
        var windows = [SCWindow]()
        guard let content = availableContent else { return windows }
        windows = content.windows.filter {
            guard let app =  $0.owningApplication,
                  let title = $0.title else {//, !title.isEmpty else {
                return false
            }
            return !excludedApps.contains(app.bundleIdentifier)
            && !title.contains("Item-0")
            && title != "Window"
            && $0.frame.width > 40
            && $0.frame.height > 40
        }
        if isOnScreen { windows = windows.filter({$0.isOnScreen == true}) }
        if hideSelf && ud.bool(forKey: "hideSelf") { windows = windows.filter({$0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier}) }
        return windows
    }
    
    static func getAppIcon(_ app: SCRunningApplication) -> NSImage? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 69, height: 69)
            return icon
        }
        let icon = NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: "blank icon")
        icon!.size = NSSize(width: 69, height: 69)
        return icon
    }
    
    static func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
        return screenWithMouse
    }
    
    static func getSCDisplayWithMouse() -> SCDisplay? {
        if let displays = availableContent?.displays {
            for display in displays {
                if let currentDisplayID = getScreenWithMouse()?.displayID {
                    if display.displayID == currentDisplayID {
                        return display
                    }
                }
            }
        }
        return nil
    }
    
    static func getFilePath(capture: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-MM-dd HH.mm.ss"
        return ud.string(forKey: "saveDirectory")! + (capture ? "/Capturing at ".local : "/Recording at ".local) + dateFormatter.string(from: Date())
    }
    
    static func updateAudioSettings(format: String = ud.string(forKey: "audioFormat") ?? "", rate: Int = 48000) -> [String : Any] {
        var audioSettings: [String : Any] = [AVSampleRateKey : rate, AVNumberOfChannelsKey : 2] // reset audioSettings
        var bitRate = ud.integer(forKey: "audioQuality") * 1000
        if rate < 44100 { bitRate = min(64000, bitRate / 2) }
        switch format {
        case AudioFormat.mp3.rawValue: fallthrough
        case AudioFormat.aac.rawValue:
            audioSettings[AVFormatIDKey] = kAudioFormatMPEG4AAC
            audioSettings[AVEncoderBitRateKey] = bitRate
        case AudioFormat.alac.rawValue:
            audioSettings[AVFormatIDKey] = kAudioFormatAppleLossless
            audioSettings[AVEncoderBitDepthHintKey] = 16
        case AudioFormat.flac.rawValue:
            audioSettings[AVFormatIDKey] = kAudioFormatFLAC
        case AudioFormat.opus.rawValue:
            audioSettings[AVFormatIDKey] = ud.string(forKey: "videoFormat") != VideoFormat.mp4.rawValue ? kAudioFormatOpus : kAudioFormatMPEG4AAC
            audioSettings[AVEncoderBitRateKey] =  bitRate
        default:
            assertionFailure("unknown audio format while setting audio settings: ".local + (ud.string(forKey: "audioFormat") ?? "[no defaults]".local))
        }
        return audioSettings
    }
    
    static func getBackgroundColor() -> CGColor {
        guard let color = ud.string(forKey: "background") else { return CGColor.black  }
        if color == BackgroundType.wallpaper.rawValue { return CGColor.black }
        switch color {
            case "clear": backgroundColor = CGColor.clear
            case "black": backgroundColor = CGColor.black
            case "white": backgroundColor = CGColor.white
            case "gray": backgroundColor = NSColor.systemGray.cgColor
            case "yellow": backgroundColor = NSColor.systemYellow.cgColor
            case "orange": backgroundColor = NSColor.systemOrange.cgColor
            case "green": backgroundColor = NSColor.systemGreen.cgColor
            case "blue": backgroundColor = NSColor.systemBlue.cgColor
            case "red": backgroundColor = NSColor.systemRed.cgColor
            default: backgroundColor = ud.cgColor(forKey: "userColor") ?? CGColor.black
        }
        return backgroundColor
    }
    
    static func performMicCheck() async {
        guard ud.bool(forKey: "recordMic") == true else { return }
        if await AVCaptureDevice.requestAccess(for: .audio) { return }

        ud.setValue(false, forKey: "recordMic")
        DispatchQueue.main.async {
            let alert = createAlert(title: "Permission Required",
                                                       message: "TinyRecorder needs permission to record your microphone.",
                                                       button1: "Open Settings",
                                                       button2: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            }
        }
    }
    
    private static func requestPermissions() {
        // 弹出统一的权限引导窗（内部幂等，不会叠多个窗口）。
        // 旧实现：自定义 Alert + NSApp.terminate——强制退出后重启又会自动请求权限，
        // 与 SCShareableContent 的系统授权框一起形成「弹窗-退出-重开-再弹窗」死循环。
        DispatchQueue.main.async {
            AppDelegate.shared.showScreenPermissionGuide()
        }
    }
    
    static func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized, .restricted, .notDetermined:
            break
        case .denied:
            DispatchQueue.main.async {
                let alert = createAlert(title: "Permission Required",
                                                           message: "TinyRecorder needs this permission to record your camera or mobile device.",
                                                           button1: "Open Settings",
                                                           button2: "Cancel")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
                }
            }
        @unknown default:
            break
        }
    }
    
    static func getWallpaper(_ display: SCDisplay) -> NSImage? {
        guard let screen = display.nsScreen else { return nil }
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        do {
            var wallpaper: NSImage?
            try wallpaper = NSImage(data: Data(contentsOf: url))
            if let w = wallpaper { return w }
        } catch {
            print("load wallpaper error: \(error)")
        }
        return nil
    }
    
    static func getRecordingSize() -> String {
        do {
            let fileAttr = try fd.attributesOfItem(atPath: filePath)
            let byteFormat = ByteCountFormatter()
            byteFormat.allowedUnits = [.useMB]
            byteFormat.countStyle = .file
            return byteFormat.string(fromByteCount: fileAttr[FileAttributeKey.size] as! Int64)
        } catch {
            print(String(format: "failed to fetch file for size indicator: %@".local, error.localizedDescription))
        }
        return "Unknown".local
    }
    
    static func getRecordingLength() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        if isPaused { return formatter.string(from: timePassed) ?? "Unknown".local }
        timePassed = Date.now.timeIntervalSince(startTime ?? Date.now)
        return formatter.string(from: timePassed) ?? "Unknown".local
    }
    
    static func isCameraRunning() -> Bool {
        var preview = false
        var capture = false
        if let session = previewSession { preview = session.isRunning }
        if let session = captureSession { capture = session.isRunning }
        return (preview || capture)
    }
    
    static func pauseRecording() {
        let paused: Bool = streamQueue.sync { () -> Bool in
            isPaused.toggle()
            if !isPaused { isResume = true }
            return isPaused
        }
        PopoverState.shared.isPaused = paused
        if !paused {
            startTime = Date.now.addingTimeInterval(-1) - SCContext.timePassed
        }
    }
    
    /// 新录制开始前重置录制状态（主线程调用）
    static func resetForNewRecording() {
        streamQueue.sync {
            isStopping = false
            sessionStarted = false
            writerFailureReported = false
            isPaused = false
            isResume = false
            lastPTS = nil
            timeOffset = CMTime.zero
            firstFrame = nil
        }
        vW = nil
        vwInput = nil
        awInput = nil
        micInput = nil
        audioFile = nil
        audioFile2 = nil
        startTime = nil
        PopoverState.shared.isPaused = false
    }
    
    /// 会话已开始（在 streamQueue 上调用），开始时间在主线程记录
    static func markSessionStarted() {
        sessionStarted = true
        DispatchQueue.main.async {
            if streamType != nil && startTime == nil { startTime = Date.now }
        }
    }
    
    /// 录制中写入失败：只处理一次，通知用户并停止录制（须在 streamQueue 上调用）
    static func handleWriterFailure(_ error: Error?) {
        if writerFailureReported || isStopping { return }
        writerFailureReported = true
        let err = error?.localizedDescription ?? "Unknown Error".local
        print("Writer failed during recording: \(err)")
        showNotification(title: "Recording Failed".local, body: err, id: "quickrecorder.error.\(UUID().uuidString)")
        DispatchQueue.main.async { stopRecording() }
    }
    
    /// 追加一段麦克风音频（须在 streamQueue 上调用）
    static func appendMicSample(_ sample: CMSampleBuffer) {
        if isStopping || isPaused || isResume || !sessionStarted { return }
        guard let writer = vW, let input = micInput else { return }
        if writer.status == .failed { handleWriterFailure(writer.error); return }
        guard writer.status == .writing else { return }
        var buffer = sample
        if CMTimeCompare(timeOffset, CMTime.zero) > 0 {
            guard let adjusted = adjustTime(sample: sample, by: timeOffset) else { return }
            buffer = adjusted
        }
        if input.isReadyForMoreMediaData {
            if !input.append(buffer) { handleWriterFailure(writer.error) }
        }
    }
    
    /// 记录已写入媒体的结束时间（须在 streamQueue 上调用）
    static func updateLastPTS(_ end: CMTime) {
        if let last = lastPTS, last.flags.contains(CMTimeFlags.valid), CMTimeCompare(last, end) >= 0 { return }
        lastPTS = end
    }
    
    /// 停止麦克风采集（只清理实际启动过的组件，可重复调用）
    static func stopMicCapture() {
        AudioRecorder.shared.stop()
        if micTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            micTapInstalled = false
        }
        if audioEngine.isRunning { audioEngine.stop() }
        if aecStarted {
            try? AECEngine.stopAudioUnit()
            aecStarted = false
        }
    }
    
    /// 安全地结束写入器，completion 在后台线程回调，参数表示文件是否成功写完
    static func finishWriter(_ writer: AVAssetWriter, completion: @escaping (Bool) -> Void) {
        guard writer.status == .writing else {
            completion(writer.status == .completed)
            return
        }
        guard sessionStarted else {
            // 一帧都没收到：没有可保存的内容
            writer.cancelWriting()
            completion(false)
            return
        }
        for input in writer.inputs { input.markAsFinished() }
        writer.finishWriting {
            completion(writer.status == .completed)
        }
    }
    
    static func reportSaveFailure(_ error: Error?) {
        let err = error?.localizedDescription ?? "No content was captured.".local
        print("Failed to save recording: \(err)")
        showNotification(title: "Failed to save file".local, body: err, id: "quickrecorder.error.\(UUID().uuidString)")
    }
    
    /// 混音失败（或只有一条音轨无需混音）时，把中间文件 xxx.mp4.mp4.mp4 改回正常文件名，避免录制丢失
    static func recoverUnmixedRecording(videoURL: URL) -> URL {
        let partialAudioURL = videoURL.deletingPathExtension()
        let targetURL = partialAudioURL.deletingPathExtension()
        guard fd.fileExists(atPath: videoURL.path) else { return targetURL }
        if fd.fileExists(atPath: partialAudioURL.path) { try? fd.removeItem(at: partialAudioURL) }
        if fd.fileExists(atPath: targetURL.path) { try? fd.removeItem(at: targetURL) }
        do {
            try fd.moveItem(at: videoURL, to: targetURL)
            return targetURL
        } catch {
            print("Failed to rename unmixed recording: \(error.localizedDescription)")
            return videoURL
        }
    }
    
    static func stopRecording() {
        guard streamType != nil else { return }
        // 防重入；并在串行队列上置位，保证此后的回调都不会再写入
        let firstCall: Bool = streamQueue.sync { () -> Bool in
            if isStopping { return false }
            isStopping = true
            return true
        }
        guard firstCall else { return }
        
        SleepPreventer.shared.allowSleep()
        autoStop = 0
        recordCam = ""
        recordDevice = ""
        isMagnifierEnabled = false
        mousePointer.orderOut(nil)
        screenMagnifier.orderOut(nil)
        AppDelegate.shared.stopGlobalMouseMonitor()

        if let w = NSApp.windows.first(where:  { $0.title == "Area Overlayer".local }) { w.close() }
        
        if stream != nil { stream.stopCapture() }
        stream = nil
        stopMicCapture()
        
        let currentType = streamType
        let path: String = filePath ?? ""
        let remuxVideo = recMic && recWinSound && recRemuxAudio
        let remuxQma = recMic && recRemuxAudio
        var videoSaved = false
        
        if currentType != .systemaudio {
            if let writer = vW {
                let previewImage: NSImage? = remuxVideo ? firstFrame?.nsImage : nil
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                finishWriter(writer) { ok in
                    videoSaved = ok
                    if !ok {
                        print("Video writing failed with status: \(writer.status.rawValue), error: \(String(describing: writer.error))")
                        reportSaveFailure(writer.error)
                    } else if remuxVideo {
                        mixAudioTracks(videoURL: path.url) { result in
                            let finalURL: URL
                            switch result {
                            case .success(let url):
                                finalURL = url
                                print("Exported video to \(String(describing: url.path))")
                                if !ud.bool(forKey: "showPreview") {
                                    showNotification(title: "Recording Completed".local, body: String(format: "File saved to: %@".local, url.path), id: "quickrecorder.completed.\(UUID().uuidString)")
                                }
                            case .failure(let error):
                                print("Failed to export video: \(error.localizedDescription)")
                                finalURL = recoverUnmixedRecording(videoURL: path.url)
                                let body = String(format: "File saved to: %@".local, finalURL.path) + "\n" + error.localizedDescription
                                showNotification(title: "Failed to mix audio tracks".local, body: body, id: "quickrecorder.error.\(UUID().uuidString)")
                            }
                            DispatchQueue.main.async {
                                if ud.bool(forKey: "trimAfterRecord") {
                                    AppDelegate.shared.createNewWindow(view: VideoTrimmerView(videoURL: finalURL), title: finalURL.lastPathComponent, only: false)
                                } else {
                                    showPreview(path: finalURL.path, image: previewImage)
                                }
                            }
                        }
                    }
                    dispatchGroup.leave()
                }
                // finishWriting 的回调不会回到主线程同步执行，这里等待不会死锁
                dispatchGroup.wait()
            } else {
                reportSaveFailure(nil)
            }
        }
        
        DispatchQueue.main.async {
            controlPanel.close()
            if isCameraRunning() {
                if camWindow.isVisible { camWindow.close() }
                if deviceWindow.isVisible { deviceWindow.close() }
                if let preview = previewSession { preview.stopRunning() }
                if let capture = captureSession { capture.stopRunning() }
            }
        }
        
        audioFile = nil // close audio file
        audioFile2 = nil // close audio file2
        if currentType == .systemaudio {
            let path1: String = filePath1 ?? path
            if recMic {
                if let writer = vW {
                    finishWriter(writer) { ok in
                        let error = writer.error
                        DispatchQueue.main.async {
                            finalizeQmaRecording(path: path, micSaved: ok, error: error, remux: remuxQma)
                        }
                    }
                } else {
                    finalizeQmaRecording(path: path, micSaved: false, error: nil, remux: remuxQma)
                }
            } else if recAudioFormat == AudioFormat.mp3.rawValue {
                Task {
                    let outPutUrl = (String(path.dropLast(4)) + ".mp3").url
                    do {
                        try await m4a2mp3(inputUrl: path1.url, outputUrl: outPutUrl)
                        try? fd.removeItem(atPath: path1)
                        if !ud.bool(forKey: "showPreview") {
                            let title = "Recording Completed".local
                            let body = String(format: "File saved to: %@".local, outPutUrl.path.removingPercentEncoding ?? outPutUrl.path)
                            let id = "quickrecorder.completed.\(UUID().uuidString)"
                            showNotification(title: title, body: body, id: id)
                        } else {
                            DispatchQueue.main.async { showPreview(path: outPutUrl.path, image: NSImage(named: "audioIcon")) }
                        }
                    } catch {
                        showNotification(title: "Failed to save file".local, body: "\(error.localizedDescription)", id: "quickrecorder.error.\(UUID().uuidString)")
                    }
                }
            } else {
                if !ud.bool(forKey: "showPreview") {
                    let title = "Recording Completed".local
                    let body = String(format: "File saved to: %@".local, path)
                    let id = "quickrecorder.completed.\(UUID().uuidString)"
                    showNotification(title: title, body: body, id: id)
                } else {
                    showPreview(path: path, image: NSImage(named: "audioIcon"))
                }
            }
        }
        
        streamQueue.sync {
            isPaused = false
            isResume = false
            lastPTS = nil
        }
        PopoverState.shared.isPaused = false
        hideMousePointer = false
        window = nil
        screen = nil
        startTime = nil
        AppDelegate.shared.presenterType = "OFF"
        updateStatusBar()
        
        if currentType != .systemaudio && !remuxVideo && videoSaved {
            if !ud.bool(forKey: "showPreview") {
                let title = "Recording Completed".local
                let body = String(format: "File saved to: %@".local, path)
                let id = "quickrecorder.completed.\(UUID().uuidString)"
                showNotification(title: title, body: body, id: id)
            } else {
                showPreview(path: path)
            }
            trimVideo()
        }
        
        streamType = nil
        firstFrame = nil
    }
    
    /// qma（系统声音 + 麦克风分轨）录制收尾：必须在麦克风写入器完成之后调用（主线程）
    private static func finalizeQmaRecording(path: String, micSaved: Bool, error: Error?, remux: Bool) {
        guard micSaved else {
            let err = error?.localizedDescription ?? "No content was captured.".local
            let body = String(format: "File saved to: %@".local, path) + "\n" + err
            showNotification(title: "Failed to save file".local, body: body, id: "quickrecorder.error.\(UUID().uuidString)")
            return
        }
        if remux {
            let fileURL = path.url
            do {
                let document = try qmaPackageHandle.load(from: fileURL)
                let audioPlayerManager = AudioPlayerManager()
                audioPlayerManager.loadAudioFiles(format: document.info.format, package: fileURL, encoder: document.info.encoder, saveMP3: document.info.exportMP3)
                audioPlayerManager.sysVol = document.info.sysVol
                audioPlayerManager.micVol = document.info.micVol
                let exportMP3 = document.info.exportMP3
                let format = exportMP3 ? "mp3" : document.info.format
                let saveURL = fileURL.deletingPathExtension().appendingPathExtension(format)
                audioPlayerManager.saveFile(saveURL, saveAsMP3: exportMP3)
            } catch {
                let body = String(format: "File saved to: %@".local, path) + "\n" + error.localizedDescription
                showNotification(title: "Failed to mix audio tracks".local, body: body, id: "quickrecorder.error.\(UUID().uuidString)")
            }
        } else {
            if !ud.bool(forKey: "showPreview") {
                let title = "Recording Completed".local
                let body = String(format: "File saved to: %@".local, path)
                let id = "quickrecorder.completed.\(UUID().uuidString)"
                showNotification(title: title, body: body, id: id)
            } else {
                showPreview(path: path, image: NSImage(named: "qmaIcon"))
            }
        }
    }
    
    static func showPreview(path: String, image: NSImage? = nil) {
        if !ud.bool(forKey: "showPreview") { return }
        var previewImage: NSImage?
        let previewURL = fd.temporaryDirectory.appendingPathComponent("qr-preview.jpg")
        if image == nil { firstFrame?.nsImage?.saveToFile(previewURL, type: .jpeg) }
        
        if let i = image { previewImage = i } else { previewImage = NSImage(contentsOf: previewURL) }
        if let previewImage = previewImage, let screen = getScreenWithMouse() {
            PreviewView.activeGeneration += 1
            let contentView = NSHostingView(rootView: PreviewView(frame: previewImage, filePath: path, generation: PreviewView.activeGeneration))
            previewWindow.contentView = contentView
            previewWindow.setFrameOrigin(NSPoint(x: screen.frame.maxX - 280, y: screen.frame.minY + 20))
            previewWindow.orderFront(self)
        }
    }
    
    static func m4a2mp3(inputUrl: URL, outputUrl: URL) async throws {
        let progress = Progress()
        let lameEncoder = try SwiftLameEncoder(
            sourceUrl: inputUrl,
            configuration: .init(
                sampleRate: .custom(48000),
                bitrateMode: .constant(Int32(ud.integer(forKey: "audioQuality"))),
                quality: .nearBest
            ),
            destinationUrl: outputUrl,
            progress: progress // optional
        )
        try await lameEncoder.encode(priority: .userInitiated)
    }
    
    static func trimVideo() {
        if ud.bool(forKey: "trimAfterRecord") {
            let fileURL = filePath.url
            AppDelegate.shared.createNewWindow(view: VideoTrimmerView(videoURL: fileURL), title: fileURL.lastPathComponent, only: false)
        }
    }
    
    static func getCameras() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
        return discoverySession.devices
    }
    
    static func getMicrophone() -> [AVCaptureDevice] {
        var discoverySession: AVCaptureDevice.DiscoverySession
        if #available(macOS 15.0, *) {
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .microphone], mediaType: .audio, position: .unspecified)
        } else {
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .externalUnknown], mediaType: .audio, position: .unspecified)
        }
        return discoverySession.devices.filter({ !$0.localizedName.contains("CADefaultDeviceAggregate") })
    }
    
    static func getiDevice() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown], mediaType: .muxed, position: .unspecified)
        return discoverySession.devices
    }
    
    static func getCurrentMic() -> AVCaptureDevice? {
        let deviceName = ud.string(forKey: "micDevice")
        return getMicrophone().first(where: { $0.localizedName == deviceName })
    }
    
    /*static func getChannelCount() -> Int? {
        if let device = getCurrentMic() {
            if let channels = device.formats.first?.formatDescription.audioChannelLayout?.numberOfChannels {
                return channels
            }
            
            let activeFormat = device.activeFormat
            let description = activeFormat.formatDescription
            if let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee {
                let channelCount = audioStreamBasicDescription.mChannelsPerFrame
                return max(2, Int(channelCount))
            }
        }
        return getDefaultChannelCount()
    }
    
    static func getDefaultChannelCount() -> Int? {
        var deviceID = AudioObjectID(0)
        var propertySize = UInt32(MemoryLayout.size(ofValue: deviceID))
        
        // 获取默认音频输入设备
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        
        guard status == noErr else {
            print("Failed to get default audio input device")
            return nil
        }
        
        // 获取通道数
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // 查询流配置信息
        var streamConfig: UnsafeMutableAudioBufferListPointer?
        propertySize = 0
        
        // 先获取属性大小
        let sizeStatus = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &propertySize)
        guard sizeStatus == noErr else {
            print("Failed to get size for stream configuration")
            return nil
        }
        
        // 分配内存以存储音频流配置
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propertySize))
        defer { bufferList.deallocate() }
        
        let configStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propertySize, bufferList)
        guard configStatus == noErr else {
            print("Failed to get stream configuration")
            return nil
        }
        
        streamConfig = UnsafeMutableAudioBufferListPointer(bufferList)
        
        // 计算通道总数
        var totalChannels = 0
        for buffer in streamConfig! {
            totalChannels += Int(buffer.mNumberChannels)
        }
        return max(2, totalChannels)
    }*/
    
    static func getSampleRate() -> Int? {
        if let device = getCurrentMic() {
            let activeFormat = device.activeFormat
            let description = activeFormat.formatDescription
            
            if let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee {
                let sampleRate = audioStreamBasicDescription.mSampleRate
                return Int(sampleRate)
            }
        }
        return getDefaultSampleRate()
    }
    
    static func getDefaultSampleRate() -> Int? {
        var deviceID = AudioObjectID(0)
        var propertySize = UInt32(MemoryLayout.size(ofValue: deviceID))
        
        // 获取默认音频输入设备
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        
        guard status == noErr else {
            print("Failed to get default audio input device")
            return nil
        }
        
        // 获取采样率
        var sampleRate: Double = 0
        propertySize = UInt32(MemoryLayout.size(ofValue: sampleRate))
        
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let sampleRateStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propertySize,
            &sampleRate
        )
        
        guard sampleRateStatus == noErr else {
            print("Failed to get sample rate for the default input device")
            return nil
        }
        
        return Int(sampleRate)
    }
    
    static func adjustTime(sample: CMSampleBuffer, by offset: CMTime) -> CMSampleBuffer? {
        guard CMSampleBufferGetFormatDescription(sample) != nil else { return nil }
        
        // 先查询实际的 timing 条目数（音频 buffer 通常只有 1 条，而不是每个采样一条）
        var entryCount: CMItemCount = 0
        guard CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &entryCount) == noErr,
              entryCount > 0 else { return nil }
        var timingInfo = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(), count: entryCount)
        guard CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: entryCount, arrayToFill: &timingInfo, entriesNeededOut: &entryCount) == noErr else { return nil }
        
        for i in 0..<timingInfo.count {
            timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, offset)
            timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, offset)
        }
        
        var outSampleBuffer: CMSampleBuffer?
        guard CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: timingInfo.count, sampleTimingArray: &timingInfo, sampleBufferOut: &outSampleBuffer) == noErr else { return nil }
        
        return outSampleBuffer
    }
    
    static func showNotification(title: String, body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Notification failed to send：\(error.localizedDescription)") }
        }
    }
    
    static func mixAudioTracks(videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: videoURL)
        let audioOutputURL = videoURL.deletingPathExtension()
        let outputURL = audioOutputURL.deletingPathExtension()
        let audioOnlyComposition = AVMutableComposition()
        
        let fileEnding = ud.string(forKey: "videoFormat") ?? ""
        var fileType: AVFileType?
        switch fileEnding {
        case VideoFormat.mov.rawValue: fileType = AVFileType.mov
        case VideoFormat.mp4.rawValue: fileType = AVFileType.mp4
        default: assertionFailure("loaded unknown video format".local)
        }
        
        let audioTracks = asset.tracks(withMediaType: .audio)
        guard audioTracks.count > 1 else {
            // 只有一条（或没有）音轨，无需混音：直接把中间文件改回正常文件名
            completion(.success(recoverUnmixedRecording(videoURL: videoURL)))
            return
        }
        showNotification(title: "Still Processing".local, body: "Mixing audio track...".local, id: "quickrecorder.processing.\(UUID().uuidString)")
        
        for audioTrack in audioTracks {
            if let compositionAudioTrack = audioOnlyComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                do {
                    try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
                } catch {
                    completion(.failure(NSError(domain: "AudioTrackInsertionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert audio track: \(error.localizedDescription)"])))
                    return
                }
            }
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioTracks.map {
            let parameters = AVMutableAudioMixInputParameters(track: $0)
            parameters.trackID = $0.trackID
            return parameters
        }
        
        guard let audioExportSession = AVAssetExportSession(asset: audioOnlyComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "AudioExportSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio export session."])))
            return
        }
        audioExportSession.outputURL = audioOutputURL
        audioExportSession.outputFileType = fileType ?? .mp4
        audioExportSession.audioMix = audioMix
        
        audioExportSession.exportAsynchronously {
            /*var exportStatus: AVAssetExportSession.Status = .unknown
            
            // Loop until export session is completed, failed, or cancelled
            while exportStatus != .completed && exportStatus != .failed && exportStatus != .cancelled {
                exportStatus = audioExportSession.status
                Thread.sleep(forTimeInterval: 0.1)
            }*/
            
            switch audioExportSession.status {
            case .completed:
                let audioAsset = AVAsset(url: audioOutputURL)
                let composition = AVMutableComposition()
                
                guard let videoTrack = asset.tracks(withMediaType: .video).first,
                      let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                    completion(.failure(NSError(domain: "VideoTrackError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get video track."])))
                    return
                }
                
                do {
                    try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
                } catch {
                    completion(.failure(NSError(domain: "VideoTrackInsertionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert video track: \(error.localizedDescription)"])))
                    return
                }
                
                let audioTracks = audioAsset.tracks(withMediaType: .audio)
                guard audioTracks.count >= 1 else {
                    completion(.failure(NSError(domain: "AudioTrackError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not enough audio tracks found."])))
                    return
                }
                
                for audioTrack in audioTracks {
                    if let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                        do {
                            try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
                        } catch {
                            completion(.failure(NSError(domain: "AudioTrackInsertionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert audio track: \(error.localizedDescription)"])))
                            return
                        }
                    }
                }
                
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
                    completion(.failure(NSError(domain: "ExportSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."])))
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = fileType ?? .mp4
                exportSession.audioMix = audioMix
                
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        let  fileManager = fd
                        try? fileManager.removeItem(at: videoURL)
                        try? fileManager.removeItem(atPath: audioOutputURL.path)
                        completion(.success(outputURL))
                    case .failed:
                        completion(.failure(exportSession.error ?? NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export failed for an unknown reason."])))
                    case .cancelled:
                        completion(.failure(NSError(domain: "ExportCancelled", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export was cancelled."])))
                    default:
                        completion(.failure(exportSession.error ?? NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export finished with unexpected status."])))
                    }
                }
            case .failed:
                completion(.failure(audioExportSession.error ?? NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export failed for an unknown reason."])))
            case .cancelled:
                completion(.failure(NSError(domain: "ExportCancelled", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export was cancelled."])))
            default:
                completion(.failure(audioExportSession.error ?? NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export finished with unexpected status."])))
            }
        }
    }
}