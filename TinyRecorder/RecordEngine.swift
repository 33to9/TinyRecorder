//
//  RecordEngine.swift
//  TinyRecorder
//
//  Created by apple on 2024/4/17.
//

import Foundation
import UserNotifications
import ScreenCaptureKit
import AVFoundation
import AVFAudio
import VideoToolbox
import AECAudioStream

/// 录制启动/运行时的错误（用于中止录制并提示用户）
struct RecordingError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { return message }
}

extension AppDelegate {
    /// 中止一次尚未成功开始（或启动失败）的录制：清理资源、重置状态并提示用户。可在任意线程调用。
    func abortRecording(reason: String) {
        print("Recording aborted: \(reason)")
        Analytics.recordingFailed(stage: "start", type: SCContext.streamType, error: nil)
        SCContext.streamQueue.sync { SCContext.isStopping = true }
        SCContext.stopMicCapture()
        if let stream = SCContext.stream { stream.stopCapture() }
        SCContext.stream = nil
        if let writer = SCContext.vW, writer.status == .writing { writer.cancelWriting() }
        SCContext.vW = nil
        SCContext.vwInput = nil
        SCContext.awInput = nil
        SCContext.micInput = nil
        SCContext.audioFile = nil
        SCContext.audioFile2 = nil
        SleepPreventer.shared.allowSleep()
        DispatchQueue.main.async {
            SCContext.streamType = nil
            SCContext.startTime = nil
            SCContext.window = nil
            SCContext.screen = nil
            self.stopGlobalMouseMonitor()
            updateStatusBar()
            _ = createAlert(level: .critical, title: "Failed to Record", message: reason, button1: "OK").runModal()
        }
    }
    
    @objc func prepRecord(type: String, screens: SCDisplay?, windows: [SCWindow]?, applications: [SCRunningApplication]?, fastStart: Bool = false) {
        switch type {
        case "window":  SCContext.streamType = .window
        case "windows":  SCContext.streamType = .windows
        case "display": SCContext.streamType = .screen
        case "application": SCContext.streamType = .application
        case "area": SCContext.streamType = .screenarea
        case "audio":   SCContext.streamType = .systemaudio
            default: return // if we don't even know what to record I don't think we should even try
        }
        // 重置上一次录制遗留的状态，并对本次录制相关设置做快照（停止时使用快照而不是当前设置）
        SCContext.resetForNewRecording()
        SCContext.recMic = recordMic
        SCContext.recWinSound = recordWinSound
        SCContext.recRemuxAudio = remuxAudio
        SCContext.recAudioFormat = audioFormat.rawValue
        // HDR needs a 10-bit HEVC hardware encoder; without one the writer produces an empty
        // file (#144, #94). The toggle is disabled in that case, this covers old settings.
        if recordHDR && !hevcHardwareEncoderAvailable { recordHDR = false }
        var isDirectory: ObjCBool = false
        let outputPath = saveDirectory!
        if fd.fileExists(atPath: outputPath, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                SCContext.streamType = nil
                _ = createAlert(title: "Failed to Record".local, message: "The output path is a file instead of a folder!".local, button1: "OK").runModal()
                return
            }
        } else {
            do {
                try fd.createDirectory(atPath: outputPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                SCContext.streamType = nil
                _ = createAlert(title: "Failed to Record".local, message: "Unable to create output folder!".local, button1: "OK").runModal()
                return
            }
        }
        
        // file preparation
        guard let content = SCContext.availableContent else {
            abortRecording(reason: "Unable to get the list of shareable content. Please check the screen recording permission.")
            return
        }
        if let screens = screens {
            SCContext.screen = content.displays.first(where: { $0 == screens })
        } else { SCContext.streamType = nil; return }
        
        if let windows = windows {
            SCContext.window = content.windows.filter({ windows.contains($0) })
        } else { if SCContext.streamType == .window { SCContext.streamType = nil; return } }
        
        if let applications = applications {
            SCContext.application = content.applications.filter({ applications.contains($0) })
        } else { if SCContext.streamType == .application { SCContext.streamType = nil; return } }
        
        guard let screen = SCContext.screen ?? SCContext.getSCDisplayWithMouse() else {
            abortRecording(reason: "Unable to find the display to record.")
            return
        }
        let qrSelf = SCContext.getSelf()
        let qrWindows = SCContext.getSelfWindows()
        let dockApp = content.applications.first(where: { $0.bundleIdentifier.description == "com.apple.dock" })
        let wallpaper = content.windows.filter({
            guard let title = $0.title else { return false }
            return $0.owningApplication?.bundleIdentifier == "com.apple.dock" && title != "LPSpringboard" && title != "Dock"
        })
        let desktop = content.windows.filter({
            guard let title = $0.title else { return false }
            return $0.owningApplication?.bundleIdentifier == "" && title == "Desktop"
        })
        let dockWindow = content.windows.filter({
            guard let title = $0.title else { return true }
            return $0.owningApplication?.bundleIdentifier == "com.apple.dock" && title == "Dock"
        })
        let desktopFiles = content.windows.filter({
            $0.owningApplication?.bundleIdentifier == "com.apple.finder"
            && $0.title == "" && $0.frame == screen.frame })
        let controlCenterWindow = content.applications.filter({ $0.bundleIdentifier == "com.apple.controlcenter" })
        let mouseWindow = content.windows.filter({ $0.title == "Mouse Pointer".local && $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier })
        let camLayer = content.windows.filter({ $0.title == "Camera Overlayer".local && $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier })
        var appBlackList = [String]()
        if let savedData = ud.data(forKey: "hiddenApps"),
           let decodedApps = try? JSONDecoder().decode([AppInfo].self, from: savedData) {
            appBlackList = (decodedApps as [AppInfo]).map({ $0.bundleID })
        }
        let excliudedApps = content.applications.filter({ appBlackList.contains($0.bundleIdentifier) })
        
        if SCContext.streamType == .window || SCContext.streamType == .windows {
            if var includ = SCContext.window {
                if includ.isEmpty {
                    abortRecording(reason: "The selected window is no longer available.")
                    return
                }
                if includ.count > 1 {
                    if highlightMouse { includ += mouseWindow }
                    if background.rawValue == BackgroundType.wallpaper.rawValue { if dockApp != nil { includ += wallpaper }}
                    SCContext.filter = SCContentFilter(display: screen, including: includ + camLayer)
                    if #available(macOS 14.2, *) { SCContext.filter?.includeMenuBar = includeMenuBar }
                } else {
                    SCContext.streamType = .window
                    SCContext.filter = SCContentFilter(desktopIndependentWindow: includ[0])
                }
            }
        } else {
            if SCContext.streamType == .screen || SCContext.streamType == .screenarea {
                if SCContext.streamType == .screenarea {
                    if let area = SCContext.screenArea {
                        let a: [String: CGFloat] = ["x": area.origin.x, "y": area.origin.y, "width": area.width, "height": area.height]
                        // 与已保存的其它屏幕区域合并；优先以 displayID 为键（AreaSelector 读取时先查 displayID 再查名称）
                        var saved = (ud.object(forKey: "savedArea") as? [String: [String: CGFloat]]) ?? [:]
                        saved[String(screen.displayID)] = a
                        if let name = screen.nsScreen?.localizedName { saved.removeValue(forKey: name) }
                        ud.set(saved, forKey: "savedArea")
                    }
                }
                var excluded = [SCRunningApplication]()
                var except = [SCWindow]()
                excluded += excliudedApps
                if hideCCenter { excluded += controlCenterWindow }
                if hideSelf { if let qrWindows = qrWindows { except += qrWindows }}
                if background.rawValue != BackgroundType.wallpaper.rawValue { if dockApp != nil {
                    except += wallpaper
                    except += desktop
                }}
                if hideDesktopFiles { except += desktopFiles }
                SCContext.filter = SCContentFilter(display: screen, excludingApplications: excluded, exceptingWindows: except)
                if #available(macOS 14.2, *) { SCContext.filter?.includeMenuBar = ((SCContext.streamType == .screen || SCContext.streamType == .screenarea) && includeMenuBar) }
                // 录制开始后才启动的名单内 App 也要排除（采集开始后在 record() 里启动监听）
                if let filter = SCContext.filter { HiddenAppsWatcher.prepare(filter: filter, display: screen, excluded: excluded, except: except) }
            }
            if SCContext.streamType == .application {
                var includ = SCContext.application ?? []
                var except = [SCWindow]()
                // Audio is often played by another process than the selected app: browser web
                // apps (com.google.Chrome.app.<id>) play through the browser's helpers, and
                // many apps (e.g. meeting apps) through their own helper processes. Include
                // those processes too, but hide their windows so only the selected app shows.
                for app in includ {
                    let id = app.bundleIdentifier
                    var related = content.applications.filter { $0.bundleIdentifier.hasPrefix(id + ".") }
                    if let r = id.range(of: ".app.") {
                        let parent = String(id[..<r.lowerBound])
                        related += content.applications.filter { $0.bundleIdentifier == parent || $0.bundleIdentifier.hasPrefix(parent + ".helper") }
                    }
                    for extra in related where !includ.contains(extra) {
                        includ.append(extra)
                        except += content.windows.filter { $0.owningApplication == extra }
                    }
                }
                if let qrSelf = qrSelf { includ.append(qrSelf) }
                let withFinder = includ.map{ $0.bundleIdentifier }.contains("com.apple.finder")
                if withFinder && hideDesktopFiles { except += desktopFiles }
                if hideSelf { if let qrWindows = qrWindows { except += qrWindows }}
                //if ud.bool(forKey: "highlightMouse") { if let qrSelf = qrSelf { includ.append(qrSelf) }}
                if background.rawValue == BackgroundType.wallpaper.rawValue { if let dock = dockApp { includ.append(dock); except += dockWindow}}
                SCContext.filter = SCContentFilter(display: screen, including: includ, exceptingWindows: except)
                if #available(macOS 14.2, *) { SCContext.filter?.includeMenuBar = includeMenuBar }
            }
        }
        if SCContext.streamType == .systemaudio {
            SCContext.filter = SCContentFilter(display: screen, excludingApplications: [], exceptingWindows: [])
            do {
                try prepareAudioRecording()
            } catch {
                abortRecording(reason: error.localizedDescription)
                return
            }
        }
        guard let filter = SCContext.filter else {
            abortRecording(reason: "Unable to create the capture filter.")
            return
        }
        Task { await record(filter: filter, fastStart: fastStart) }
    }

    func record(filter: SCContentFilter, fastStart: Bool = true) async {
        let audioOnly = SCContext.streamType == .systemaudio
        
        let conf: SCStreamConfiguration
#if compiler(>=6.0)
        if recordHDR {
            if #available(macOS 15, *) {
                // TODO change here. https://developer.apple.com/videos/play/wwdc2024/10088/?time=191
                // For canonical display, it means you are capturing HDR content that is optimized for sharing with other HDR devices.
                // hdrLocalDisplay or hdrCanonicalDisplay


                conf = SCStreamConfiguration(preset: .captureHDRStreamLocalDisplay)
            } else { conf = SCStreamConfiguration() }
        } else { conf = SCStreamConfiguration() }
#else
        conf = SCStreamConfiguration()
#endif
        conf.width = 2
        conf.height = 2
        
        if !audioOnly {
            if #available(macOS 14.0, *) {
                conf.width = Int(filter.contentRect.width) * (highRes == 2 ? Int(filter.pointPixelScale) : 1)
                conf.height = Int(filter.contentRect.height) * (highRes == 2 ? Int(filter.pointPixelScale) : 1)
            } else {
                guard let display = SCContext.screen ?? SCContext.getSCDisplayWithMouse(),
                      let pointPixelScaleOld = display.nsScreen?.backingScaleFactor else {
                    abortRecording(reason: "Unable to find the display to record.")
                    return
                }
                if SCContext.streamType == .application || SCContext.streamType == .windows || SCContext.streamType == .screen {
                    let frame = display.frame
                    conf.width = Int(frame.width)
                    conf.height = Int(frame.height)
                }
                if SCContext.streamType == .window {
                    guard let frame = SCContext.window?.first?.frame else {
                        abortRecording(reason: "The selected window is no longer available.")
                        return
                    }
                    conf.width = Int(frame.width)
                    conf.height = Int(frame.height)
                }
                if SCContext.streamType == .screenarea {
                    guard let frame = SCContext.screenArea else {
                        abortRecording(reason: "Unable to get the selected area.")
                        return
                    }
                    conf.width = Int(frame.width)
                    conf.height = Int(frame.height)
                }
                conf.width = conf.width * (highRes == 2 ? Int(pointPixelScaleOld) : 1)
                conf.height = conf.height * (highRes == 2 ? Int(pointPixelScaleOld) : 1)
            }
            
            if fastStart{
                conf.showsCursor = false
            } else{
                conf.showsCursor = showMouse
            }
                    

            if background.rawValue != BackgroundType.wallpaper.rawValue { conf.backgroundColor = SCContext.getBackgroundColor() }
            if !recordHDR {
                conf.pixelFormat = kCVPixelFormatType_32BGRA
                conf.colorSpaceName = CGColorSpace.sRGB
                //if withAlpha { conf.pixelFormat = kCVPixelFormatType_32BGRA }
            } else {
                // For recording HDR in a BT2020 PQ container
                conf.colorSpaceName = CGColorSpace.itur_2100_PQ
//                https://developer.apple.com/videos/play/wwdc2022/10155/ guide on how to record 4k60
//                streamConfiguration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    
// Note: 420 encoding causes color bleed at edges, e.g. youtube settings icon with red logo
                // conf.pixelFormat = kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
//              dont exceed 8 frames  https://developer.apple.com/documentation/screencapturekit/scstreamconfiguration/queuedepth
//                lower queuedepth has more stutter, dont go below 4 https://github.com/nonstrict-hq/ScreenCaptureKit-Recording-example/blob/main/Sources/sckrecording/main.swift
                conf.queueDepth = 8
            }
        }
        
        if #available(macOS 13, *) {
            conf.capturesAudio = recordWinSound || fastStart || audioOnly
            conf.sampleRate = 48000
            conf.channelCount = 2
        }
        

        //  conf.minimumFrameInterval = CMTime(value: 1, timescale: audioOnly ? CMTimeScale.max : CMTimeScale(frameRate))
        // 纯音频：1 fps 即可（屏幕帧会被丢弃）；>=60 fps：CMTime.zero 表示不限速；其余按设定帧率限速
        if audioOnly {
            conf.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        } else if frameRate >= 60 || frameRate <= 0 {
            conf.minimumFrameInterval = CMTime.zero
        } else {
            conf.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        }

//        CMTimeScale is the denominator in the fraction
//        conf.minimumFrameInterval = CMTime(seconds: audioOnly ? Double(CMTimeScale.max) : Double(1)/Double(frameRate), preferredTimescale: 10000)

        // note: ScreenCaptureKit only delivers frames when something changes
        // https://www.reddit.com/r/swift/comments/158n4c9/comment/ju847rm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

        //blog post from the reddit comment https://nonstrict.eu/blog/2023/recording-to-disk-with-screencapturekit/

        //https://github.com/nonstrict-hq/ScreenCaptureKit-Recording-example

        // https://developer.apple.com/documentation/screencapturekit/scstreamconfiguration/minimumframeinterval
        //minimumFrameInterval: Use this value to throttle the rate at which you receive updates. The default value is 0, which indicates that the system uses the maximum supported frame rate.

        print("Frame interval passed to ScreenCaptureKit. (timescale is FPS. 0 means no throttling): \(conf.minimumFrameInterval)")
        

        if SCContext.streamType == .screenarea {
            if let nsRect = SCContext.screenArea {
                guard let areaDisplay = SCContext.screen ?? SCContext.getSCDisplayWithMouse() else {
                    abortRecording(reason: "Unable to find the display to record.")
                    return
                }
                let newY = areaDisplay.frame.height - nsRect.size.height - nsRect.origin.y
                conf.sourceRect = CGRect(x: nsRect.origin.x, y: newY, width: nsRect.size.width, height: nsRect.size.height)
                if #available(macOS 14.0, *) {
                    conf.width = Int(conf.sourceRect.width) * (highRes == 2 ? Int(filter.pointPixelScale) : 1)
                    conf.height = Int(conf.sourceRect.height) * (highRes == 2 ? Int(filter.pointPixelScale) : 1)
                } else {
                    guard let pointPixelScaleOld = areaDisplay.nsScreen?.backingScaleFactor else {
                        abortRecording(reason: "Unable to find the display to record.")
                        return
                    }
                    conf.width = Int(conf.sourceRect.width) * (highRes == 2 ? Int(pointPixelScaleOld) : 1)
                    conf.height = Int(conf.sourceRect.height) * (highRes == 2 ? Int(pointPixelScaleOld) : 1)
                }
            }
        }
        
        let encoderIsH265 = (encoder.rawValue == Encoder.h265.rawValue) || recordHDR
        if !audioOnly && !encoderIsH265 {
            var session: VTCompressionSession?
            let status = VTCompressionSessionCreate(
                allocator: nil,
                width: Int32(conf.width),
                height: Int32(conf.height),
                codecType: kCMVideoCodecType_H264,
                encoderSpecification: [kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder as String: true] as CFDictionary,
                imageBufferAttributes: nil,
                compressedDataAllocator: nil,
                outputCallback: nil,
                refcon: nil,
                compressionSessionOut: &session
            )
            
            if status != noErr {
                let button = showAlertSyncOnMainThread(
                    level: .critical,
                    title: "Encoder Warning",
                    message: "VideoToolbox H.264 hardware encoder doesn't support the current resolution.\nContinue with a software encoder will significantly increase the CPU usage.\n\nWould you like to use H.265 instead?".local,
                    button1: "Use H.265",
                    button2: "Continue with H.264"
                )
                if button == .alertFirstButtonReturn { ud.setValue(Encoder.h265.rawValue, forKey: "encoder") }
            }
        }
        
        // Open the chosen camera overlay automatically when recording starts (#119). Not for a
        // single window (the overlay can't be captured there) or several windows (the filter
        // was built without it).
        if !audioOnly, SCContext.streamType != .window, SCContext.streamType != .windows, SCContext.recordCam.isEmpty,
           let name = ud.string(forKey: "autoCamera"), !name.isEmpty,
           AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
           let camera = SCContext.getCameras().first(where: { $0.localizedName == name }) {
            SCContext.recordCam = name
            recordingCamera(with: camera)
        }
        let stream = SCStream(filter: filter, configuration: conf, delegate: self)
        SCContext.stream = stream
        SCContext.streamQueue.sync { SCContext.activeStream = ObjectIdentifier(stream) }
        // 先申请防睡眠：失败中止 / 停止时都会无条件调用 allowSleep()，不会泄漏
        if preventSleep { SleepPreventer.shared.preventSleep(reason: "Screen recording in progress") }
        do {
            // 所有回调使用同一个串行队列，避免与停止流程竞争
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: SCContext.streamQueue)
            if #available(macOS 13, *) { try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: SCContext.streamQueue) }
            if !audioOnly {
                try initVideo(conf: conf)
            } else {
                //SCContext.startTime = Date.now
                if SCContext.recMic { try startMicRecording() }
            }
            try await stream.startCapture()
        } catch {
            print("capture failed: \(error)")
            abortRecording(reason: error.localizedDescription)
            return
        }
        // 启动期间用户可能已经停止了录制
        if SCContext.streamQueue.sync(execute: { SCContext.isStopping }) {
            // stopRecording() 在 startCapture 完成前就执行了，那时停不掉这个 stream：在这里补停，
            // 否则它会一直采集（录制指示一直亮），回调还可能写进下一次录制
            try? await stream.stopCapture()
            SleepPreventer.shared.allowSleep()
            return
        }
        if !audioOnly { registerGlobalMouseMonitor() }
        HiddenAppsWatcher.start(stream: stream, filter: filter)
        Analytics.recordingStarted(SCContext.streamType)
        DispatchQueue.main.async { updateStatusBar() }
    }

    func prepareAudioRecording() throws {
        var fileEnding = audioFormat.rawValue
        var fileType = AVFileType.m4a
        let encorder = fileEnding == AudioFormat.mp3.rawValue ? "aac" : fileEnding
        switch fileEnding { // todo: I'd like to store format info differently
            case AudioFormat.mp3.rawValue: fallthrough
            case AudioFormat.aac.rawValue: fallthrough
            case AudioFormat.alac.rawValue: fileEnding = "m4a"
            case AudioFormat.flac.rawValue: fileEnding = "flac"; fileType = .caf
            case AudioFormat.opus.rawValue: fileEnding = "ogg"; fileType = .caf
            default: assertionFailure("loaded unknown audio format: ".local + fileEnding)
        }
        let path = SCContext.getFilePath()
        if SCContext.recMic && SCContext.streamType == .systemaudio {
            let packagePath = "\(path).qma"
            SCContext.filePath = packagePath
            SCContext.filePath1 = "\(path).qma/sys.\(fileEnding)"
            SCContext.filePath2 = "\(path).qma/mic.\(fileEnding)"
            let infoJsonURL = "\(path).qma/info.json".url
            let jsonString = "{\"format\": \"\(fileEnding)\", \"encoder\": \"\(encorder)\", \"exportMP3\": \(audioFormat.rawValue == AudioFormat.mp3.rawValue), \"sysVol\": 1.0, \"micVol\": 1.0}"
            do {
                try fd.createDirectory(at: packagePath.url, withIntermediateDirectories: true, attributes: nil)
                try jsonString.write(to: infoJsonURL, atomically: true, encoding: .utf8)
                
                SCContext.audioFile = try AVAudioFile(forWriting: SCContext.filePath1.url, settings: SCContext.updateAudioSettings(), commonFormat: .pcmFormatFloat32, interleaved: false)

                let sampleRate = SCContext.getSampleRate() ?? 48000
                let settings = SCContext.updateAudioSettings(rate: sampleRate)
                let writer = try AVAssetWriter(outputURL: SCContext.filePath2.url, fileType: fileType)
                let micInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: settings)
                micInput.expectsMediaDataInRealTime = true
                guard writer.canAdd(micInput) else { throw RecordingError("Unable to add the microphone track to the recording.") }
                writer.add(micInput)
                guard writer.startWriting() else {
                    throw writer.error ?? RecordingError("Unable to start writing the microphone track.")
                }
                SCContext.micInput = micInput
                SCContext.vW = writer
            } catch {
                // 清理半成品文件包，避免留下无法打开的 .qma
                SCContext.audioFile = nil
                try? fd.removeItem(atPath: packagePath)
                throw error
            }
            //SCContext.audioFile2 = try! AVAudioFile(forWriting: SCContext.filePath2.url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        } else {
            SCContext.filePath = "\(path).\(fileEnding)"
            SCContext.filePath1 = SCContext.filePath
            SCContext.audioFile = try AVAudioFile(forWriting: SCContext.filePath.url, settings: SCContext.updateAudioSettings(), commonFormat: .pcmFormatFloat32, interleaved: false)
        }
    }
}

/// 让「App 排除列表」（UserDefaults 键 hiddenApps）对录制中途才启动（或重新启动）的 App 也生效。
/// prepRecord() 建过滤器时只能排除当时已在运行的 App。「全屏」「屏幕区域」录制期间，这里观察运行中的
/// App 列表（App 一开始启动就会出现在列表里，比「启动完成」通知早得多，Edge 要早两秒多），并低频轮询兜底；
/// 发现名单内 App 有未被排除的进程时，重新获取 SCShareableContent，按原过滤器（同一显示器、原来的
/// exceptingWindows 和 includeMenuBar）补上排除，再用 updateContentFilter 应用。
/// 名单内 App 已经有窗口、排除却还没生效的那一小段（实测约 0.15 秒）不写入画面，录像短暂停在上一帧，
/// 保证一帧都不漏。除 holdUntil（加锁）外，所有状态只在主线程读写。
final class HiddenAppsWatcher {
    private static var shared: HiddenAppsWatcher?

    // 定格：采集时间早于 holdUntil 的画面帧不写入；等待排除生效时为 +∞。录制回调线程也会读，所以加锁
    private static let holdLock = NSLock()
    private static var holdUntil = CMTime.zero
    private var holdTimeout: DispatchWorkItem?

    private let filter: SCContentFilter          // prepRecord() 建的过滤器，用来认出是哪一次录制
    private let display: SCDisplay
    private let except: [SCWindow]
    private var excluded: [SCRunningApplication] // 当前过滤器排除的 App
    private var stream: SCStream?
    private var appsObservation: NSKeyValueObservation?
    private var pollTimer: Timer?
    private var windowTimer: Timer?
    private var windowTicks = 0
    private var firstSeen = [pid_t: Date]()      // 在运行但还没被排除的名单内进程 → 第一次发现的时间
    private var windowSeen = Set<pid_t>()        // 其中已经有窗口出现在屏幕上的
    private var lastFetch = Date.distantPast
    private var isUpdating = false
    private var needsCheck = false

    private init(filter: SCContentFilter, display: SCDisplay, excluded: [SCRunningApplication], except: [SCWindow]) {
        self.filter = filter
        self.display = display
        self.excluded = excluded
        self.except = except
    }

    /// prepRecord() 建好「全屏」「屏幕区域」的过滤器后调用（主线程）
    static func prepare(filter: SCContentFilter, display: SCDisplay, excluded: [SCRunningApplication], except: [SCWindow]) {
        stop()
        shared = HiddenAppsWatcher(filter: filter, display: display, excluded: excluded, except: except)
    }

    /// stream 用 filter 开始采集后调用（任意线程）；filter 不是 prepare() 登记的那个就什么都不做
    static func start(stream: SCStream, filter: SCContentFilter) {
        DispatchQueue.main.async {
            guard let watcher = shared, watcher.filter === filter, watcher.stream == nil,
                  SCContext.stream === stream else { return }
            watcher.stream = stream
            // App 一开始启动（向 LaunchServices 登记）就会加进这个列表；KVO 在主 run loop 上回调
            watcher.appsObservation = NSWorkspace.shared.observe(\.runningApplications) { [weak watcher] _, _ in
                DispatchQueue.main.async { watcher?.check() }
            }
            // 兜底：漏掉的变化，以及迟迟没出现在 SCShareableContent 里的 App
            let timer = Timer(timeInterval: 2, repeats: true) { [weak watcher] _ in watcher?.check() }
            RunLoop.main.add(timer, forMode: .common)
            watcher.pollTimer = timer
            // 选择屏幕/区域之后、开始采集之前启动的 App 也不在过滤器里
            watcher.check()
        }
    }

    /// 录制回调（streamQueue）里对每一帧画面调用：是否要丢掉这一帧（定格）
    static func shouldDropFrame(_ sample: CMSampleBuffer) -> Bool {
        holdLock.lock(); defer { holdLock.unlock() }
        return CMTimeCompare(CMSampleBufferGetPresentationTimeStamp(sample), holdUntil) < 0
    }

    /// 开始定格：名单内 App 已经有窗口（或窗口已在屏幕上），排除还没生效
    private func hold() {
        Self.holdLock.lock()
        let wasHolding = Self.holdUntil == .positiveInfinity
        Self.holdUntil = .positiveInfinity
        Self.holdLock.unlock()
        guard !wasHolding else { return }
        // 保底：2 秒内排除还没生效也恢复写入，画面不会一直卡住
        let timeout = DispatchWorkItem { [weak self] in
            print("Hidden app not excluded after 2 s, writing frames again")
            self?.releaseHold(margin: 0)
        }
        holdTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: timeout)
    }

    /// 结束定格：只写采集时间晚于「现在 + margin」的画面（之前采集的可能还是旧过滤器的画面）
    private func releaseHold(margin: Double) {
        holdTimeout?.cancel()
        holdTimeout = nil
        Self.holdLock.lock()
        if Self.holdUntil == .positiveInfinity {
            Self.holdUntil = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTime(seconds: margin, preferredTimescale: 1000))
        }
        Self.holdLock.unlock()
    }

    private static func resetHold() {
        holdLock.lock()
        holdUntil = .zero
        holdLock.unlock()
    }

    /// 录制停止时调用（主线程）
    static func stop() {
        resetHold()
        guard let watcher = shared else { return }
        shared = nil
        watcher.holdTimeout?.cancel()
        watcher.appsObservation?.invalidate()
        watcher.pollTimer?.invalidate()
        watcher.windowTimer?.invalidate()
    }

    /// 要排除的 bundle ID：当前的排除名单，加上本次录制已经排除的（含「隐藏控制中心」）
    private var bundleIDs: Set<String> {
        var ids = Set(excluded.map { $0.bundleIdentifier })
        if let data = ud.data(forKey: "hiddenApps"),
           let apps = try? JSONDecoder().decode([AppInfo].self, from: data) {
            ids.formUnion(apps.map { $0.bundleID })
        }
        return ids
    }

    /// 找出在运行但还没被排除的名单内 App，有的话更新过滤器
    private func check(retry: Bool = false) {
        guard Self.shared === self, let stream = stream else { return }
        guard SCContext.stream === stream else { Self.stop(); return }
        let ids = bundleIDs
        let known = Set(excluded.map { $0.processID })
        let missing = Set(NSWorkspace.shared.runningApplications.filter { app in
            guard let id = app.bundleIdentifier else { return false }
            return ids.contains(id) && !known.contains(app.processIdentifier)
        }.map { $0.processIdentifier })
        let now = Date()
        firstSeen = firstSeen.filter { missing.contains($0.key) }
        windowSeen.formIntersection(missing)
        var isNew = false
        for pid in missing where firstSeen[pid] == nil {
            firstSeen[pid] = now
            isNew = true
        }
        watchWindows(!missing.isEmpty)
        // 窗口观察触发的定格，在没有待排除的进程后就可以结束了
        if missing.isEmpty { releaseHold(margin: 0.1) }
        // 新发现的马上查，刚发现 10 秒内反复查（见 finish()），之后仍找不到的（比如没有窗口的进程）每 10 秒查一次
        guard !missing.isEmpty, isNew || retry || now.timeIntervalSince(lastFetch) >= 10 else { return }
        guard !isUpdating else { needsCheck = true; return }
        // 没有权限时不碰 SCK（会弹授权框）
        guard CGPreflightScreenCaptureAccess() else { return }
        isUpdating = true
        lastFetch = now
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            DispatchQueue.main.async {
                let fresh = content?.applications.filter { ids.contains($0.bundleIdentifier) } ?? []
                let found = fresh.filter { !known.contains($0.processID) }
                guard Self.shared === self, SCContext.stream === stream, !found.isEmpty else {
                    if let error = error { print("Failed to get shareable content: \(error.localizedDescription)") }
                    self.finish()
                    return
                }
                // 实测能列出来时它通常已经建好窗口，窗口随时会出现在屏幕上：排除生效前先定格
                self.hold()
                // 已排除且还在运行的 App 保留（关掉所有窗口的 App 可能暂时不在 SCShareableContent 里）
                let freshPIDs = Set(fresh.map { $0.processID })
                let apps = fresh + self.excluded.filter {
                    !freshPIDs.contains($0.processID) && NSRunningApplication(processIdentifier: $0.processID) != nil
                }
                // 与 prepRecord() 建的过滤器相同，只是排除的 App 换成最新的
                let newFilter = SCContentFilter(display: self.display, excludingApplications: apps, exceptingWindows: self.except)
                if #available(macOS 14.2, *) { newFilter.includeMenuBar = self.filter.includeMenuBar }
                stream.updateContentFilter(newFilter) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Failed to update the content filter: \(error.localizedDescription)")
                        } else {
                            self.excluded = apps
                            // 刚排除的进程不再算「待排除」，免得窗口观察又为它们定格
                            let excludedPIDs = Set(apps.map { $0.processID })
                            self.firstSeen = self.firstSeen.filter { !excludedPIDs.contains($0.key) }
                            self.windowSeen.subtract(excludedPIDs)
                            print("Excluded hidden app launched during the recording: pid \(found.map { "\($0.processID)" }.joined(separator: ","))")
                            // 余量 0.1 秒：兜住更新前采集、更新后才送到的画面
                            self.releaseHold(margin: 0.1)
                        }
                        self.finish()
                    }
                }
            }
        }
    }

    /// 一次获取/更新结束：期间有新情况就马上再查；名单内 App 刚发现不久就 0.1 秒后重试
    private func finish() {
        isUpdating = false
        if needsCheck { needsCheck = false; check(retry: true); return }
        if firstSeen.values.contains(where: { Date().timeIntervalSince($0) < 10 }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.check(retry: true) }
        }
    }

    /// 有名单内 App 没被排除时看它的窗口有没有出现在屏幕上（刚发现 10 秒内每 20 ms 看一次，之后每 0.5 秒），
    /// 出现了就马上重新获取 SCShareableContent。读窗口列表很便宜（实测约 0.25 ms），也不需要录屏权限。
    private func watchWindows(_ on: Bool) {
        guard on else { windowTimer?.invalidate(); windowTimer = nil; return }
        guard windowTimer == nil else { return }
        let timer = Timer(timeInterval: 0.02, repeats: true) { [weak self] _ in self?.checkWindows() }
        RunLoop.main.add(timer, forMode: .common)
        windowTimer = timer
    }

    private func checkWindows() {
        let known = Set(excluded.map { $0.processID })
        let pending = firstSeen.filter { !windowSeen.contains($0.key) && !known.contains($0.key) }
        guard !pending.isEmpty else { return }
        windowTicks += 1
        let recent = pending.values.contains { Date().timeIntervalSince($0) < 10 }
        guard recent || windowTicks % 25 == 0 else { return }
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        let owners = Set(windows.compactMap { $0[kCGWindowOwnerPID as String] as? pid_t })
        let appeared = Set(pending.keys).intersection(owners)
        guard !appeared.isEmpty else { return }
        windowSeen.formUnion(appeared)
        hold()
        check(retry: true)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
    var isMainScreen: Bool {
        guard let id = self.displayID else { return false }
        return (CGDisplayIsMain(id) == 1)
    }
}

extension SCDisplay {
    var nsScreen: NSScreen? {
        return NSScreen.screens.first(where: { $0.displayID == self.displayID })
    }
}

extension AppDelegate {
    func initVideo(conf: SCStreamConfiguration) throws {
        SCContext.startTime = nil

        let fileEnding = videoFormat.rawValue
        var fileType: AVFileType?
        switch fileEnding {
            case VideoFormat.mov.rawValue: fileType = AVFileType.mov
            case VideoFormat.mp4.rawValue: fileType = AVFileType.mp4
            default: assertionFailure("loaded unknown video format".local)
        }

        guard let videoFileType = fileType else { throw RecordingError("Unknown video format: \(fileEnding)") }
        if SCContext.recRemuxAudio && SCContext.recMic && SCContext.recWinSound {
            SCContext.filePath = "\(SCContext.getFilePath()).\(fileEnding).\(fileEnding).\(fileEnding)"
        } else {
            SCContext.filePath = "\(SCContext.getFilePath()).\(fileEnding)"
        }
        let writer = try AVAssetWriter(outputURL: SCContext.filePath.url, fileType: videoFileType)
        // Write the movie in 10-second fragments: if the app crashes, is killed or the Mac
        // loses power, everything up to the last fragment stays playable instead of the
        // whole file being lost ("moov atom not found", #129 #120 #256 ...).
        writer.movieFragmentInterval = CMTime(seconds: 10, preferredTimescale: 600)
        writer.metadata = SCContext.recordingMetadata()
        SCContext.vW = writer
        let encoderIsH265 = (encoder.rawValue == Encoder.h265.rawValue) || recordHDR
        let fpsMultiplier: Double = Double(frameRate)/8
        let encoderMultiplier: Double = encoderIsH265 ? 0.5 : 0.9
        let resolution = Double(max(600, conf.width)) * Double(max(600, conf.height))
        var qualityMultiplier = 1 - (log10(sqrt(resolution) * fpsMultiplier) / 5)
        switch videoQuality {
            case 0.3: qualityMultiplier = max(0.1, qualityMultiplier)
            case 0.7: qualityMultiplier = max(0.4, min(0.6, qualityMultiplier * 3))
            default: qualityMultiplier = 1.0
        }
        let h264Level = AVVideoProfileLevelH264HighAutoLevel
        let h265Level = recordHDR ? kVTProfileLevel_HEVC_Main10_AutoLevel : kVTProfileLevel_HEVC_Main_AutoLevel

        let targetBitrate = resolution * fpsMultiplier * encoderMultiplier * qualityMultiplier * (recordHDR ? 2 : 1)
        print("framerate set in app: \(frameRate)")
        print("target bitrate: \(targetBitrate/1000000)")

        var videoSettings: [String: Any] = [
            AVVideoCodecKey: encoderIsH265 ? ((withAlpha && !recordHDR) ? AVVideoCodecType.hevcWithAlpha : AVVideoCodecType.hevc) : AVVideoCodecType.h264,
            // yes, not ideal if we want more than these encoders in the future, but it's ok for now
            AVVideoWidthKey: conf.width,
            AVVideoHeightKey: conf.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoProfileLevelKey: encoderIsH265 ? h265Level : h264Level,
                AVVideoAverageBitRateKey: max(200000, Int(targetBitrate)),
                AVVideoExpectedSourceFrameRateKey: frameRate,
                // No B-frames: ScreenCaptureKit only delivers frames when the screen changes, and
                // with frame reordering a long still period produced huge composition offsets
                // that make ffmpeg-based players (IINA, mpv, LosslessCut) drop all audio (#291).
                AVVideoAllowFrameReorderingKey: false,
            ] as [String : Any]
        ]
        
        if recordHDR {
            // Tag HDR files as BT.2020 / PQ; untagged files were reported as incompatible (#149)
            videoSettings[AVVideoColorPropertiesKey] = [
                AVVideoTransferFunctionKey: AVVideoTransferFunction_SMPTE_ST_2084_PQ,
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020] as [String : Any]
        } else {
            videoSettings[AVVideoColorPropertiesKey] = [
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2] as [String : Any]
        }
        
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        guard writer.canAdd(videoInput) else { throw RecordingError("Unable to add the video track with the current encoder settings.") }
        writer.add(videoInput)
        SCContext.vwInput = videoInput

        // Only add the system audio track when system audio is captured; otherwise the file
        // got an empty audio track (#51)
        if #available(macOS 13, *), conf.capturesAudio {
            let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: SCContext.updateAudioSettings())
            audioInput.expectsMediaDataInRealTime = true
            if writer.canAdd(audioInput) { writer.add(audioInput) }
            SCContext.awInput = audioInput
        }

        if SCContext.recMic {
            let sampleRate = SCContext.getSampleRate() ?? 48000
            let settings = SCContext.updateAudioSettings(rate: sampleRate)
            
            let micInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: settings)
            micInput.expectsMediaDataInRealTime = true
            if writer.canAdd(micInput) { writer.add(micInput) }
            SCContext.micInput = micInput
        }
        guard writer.startWriting() else {
            throw writer.error ?? RecordingError("Unable to start writing the video file.")
        }
        // 写入器就绪后再启动麦克风；写入要等 startSession 之后（sessionStarted）才会发生
        if SCContext.recMic { try startMicRecording() }
    }
    
    func startMicRecording() throws {
        if micDevice == "default" {
            if enableAEC {
                var level = AUVoiceIOOtherAudioDuckingLevel.mid
                switch AECLevel {
                    case "min": level = .min
                    case "max": level = .max
                    default: level = .mid
                }
                try SCContext.AECEngine.startAudioStream(enableAEC: enableAEC, duckingLevel: level, audioBufferHandler: { pcmBuffer in
                    // 在回调线程上立即转换（会拷贝数据），再交给串行队列写入
                    guard let sample = pcmBuffer.sampleBuffer(hostTime: nil) else { return }
                    SCContext.streamQueue.async { SCContext.appendMicSample(sample) }
                })
                SCContext.aecStarted = true
            } else {
                try SCContext.startMicTap()
            }
        } else {
            guard AudioRecorder.shared.setupAudioCapture() else {
                throw RecordingError("Unable to access the selected microphone.")
            }
            AudioRecorder.shared.start()
        }
    }
    
    func outputVideoEffectDidStart(for stream: SCStream) {
        DispatchQueue.main.async { camWindow.close() }
        print("[Presenter Overlay ON]")
        isPresenterON = true
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(poSafeDelay)) {
            self.isCameraReady = true
        }
    }
    
    func outputVideoEffectDidStop(for stream: SCStream) {
        print("[Presenter Overlay OFF]")
        presenterType = "OFF"
        isPresenterON = false
        isCameraReady = false
        DispatchQueue.main.async {
            if SCContext.stream != nil { camWindow.orderFront(self) }
        }
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        // 运行在 streamQueue 上：只处理当前录制的 stream，忽略已放弃的旧 stream
        if SCContext.activeStream != ObjectIdentifier(stream) { return }
        if SCContext.saveFrame, let imageBuffer = sampleBuffer.imageBuffer {
            SCContext.saveFrame = false
            
            var ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let url = "\(SCContext.getFilePath(capture: true)).png".url
            if !recordHDR {
                sampleBuffer.nsImage?.saveToFile(url)
            } else {
                let context = CIContext()
                
                // Create the HEIF destination with the correct UTI
                //            if let destination = url? {
                // Specify format and color space (assuming default settings here)
                //                let format = CIFormat.rgb10
                let colorSpace = CGColorSpace(name: CGColorSpace.itur_2100_PQ) ?? CGColorSpaceCreateDeviceRGB()
                
                // let colorSpace = ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                
                // Image exposure needs to be increased by one stop to match the original
                ciImage = ciImage.applyingFilter("CIExposureAdjust", parameters: ["inputEV": 1.0])
                
                
                
                
                
                //                context.writeHEIF10Representation(of: ciImage, to: destination as! URL, colorSpace: colorSpace)
                do{
                    // try context.writeHEIF10Representation(of:ciImage,
                    //                                       to:url,
                    //                                       colorSpace:colorSpace,
                    //                                       options: [
                    //     kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 1.0
                    if #available(macOS 14.0, *) {
                        try context.writePNGRepresentation(of:ciImage,
                                                           to:url,
                                                           format: .RGB10,
                                                           colorSpace:colorSpace
                        )
                    } else {
                        // Fallback on earlier versions
                        print("RGB10 PNG not supported on this macOS version")
                        try context.writePNGRepresentation(of:ciImage,
                                                           to:url,
                                                           format: .RGBA8,
                                                           colorSpace:colorSpace)
                    }
                    //        try context.writePNGRepresentation(of:outImage, to:outURL, format: .RGBA16,colorSpace:colorSpace,options:[:])
                } catch let error {
                    // Handle the error case
                    print("Error: \(error)")
                }
                //                CGImageDestinationFinalize(destination)
            }
        }
        // 本回调运行在 SCContext.streamQueue（串行）上
        if SCContext.isStopping { return }
        // 纯音频录制时的屏幕帧没有用处，也不能参与暂停偏移计算
        if outputType == .screen && SCContext.streamType == .systemaudio { return }
        if SCContext.isPaused { return }
        guard sampleBuffer.isValid else { return }
        // 写入器在录制中途失败：停止录制并提示（只触发一次）
        if let writer = SCContext.vW, writer.status == .failed {
            SCContext.handleWriterFailure(writer.error)
            return
        }
        var SampleBuffer = sampleBuffer
        if !SCContext.consumeResume(SampleBuffer) { return }
        // 暂停产生的时间偏移对所有写入同一写入器的轨道（视频、系统声音、麦克风）一致生效
        let hasOffset = CMTimeCompare(SCContext.timeOffset, CMTime.zero) > 0
        switch outputType {
        case .screen:
            if (SCContext.screen == nil && SCContext.window == nil && SCContext.application == nil) || SCContext.streamType == .systemaudio { break }
            guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(SampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                  let attachments = attachmentsArray.first else { return }
            guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
                  let status = SCFrameStatus(rawValue: statusRawValue),
                  status == .complete else { return }
            // 名单内 App 正在被排除：这段画面不写入，录像停在上一帧（见 HiddenAppsWatcher）
            if HiddenAppsWatcher.shouldDropFrame(SampleBuffer) { return }
            
            guard let writer = SCContext.vW, writer.status == .writing, let videoInput = SCContext.vwInput else { return }
            if !SCContext.sessionStarted {
                writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(SampleBuffer))
                SCContext.markSessionStarted()
            }
            if hasOffset {
                guard let adjusted = SCContext.adjustTime(sample: SampleBuffer, by: SCContext.timeOffset) else { return }
                SampleBuffer = adjusted
            }
            var pts = CMSampleBufferGetPresentationTimeStamp(SampleBuffer)
            let dur = CMSampleBufferGetDuration(SampleBuffer)
            if (dur.value > 0) { pts = CMTimeAdd(pts, dur) }
            if frameQueue.getArray().contains(where: { $0 >= pts }) { print("Skip this frame"); return } else { frameQueue.append(pts) }
            SCContext.updateLastPTS(pts)
            if videoInput.isReadyForMoreMediaData {
                if #available(macOS 14.2, *) {
                    if let rect = attachments[.presenterOverlayContentRect] as? [String: Any],
                       let x = rect["X"] as? CGFloat {
                        var type = "np"
                        let off = (x == .infinity)
                        let small = (x == 0.0)
                        let big = (!off && !small)
                        if off { type = "OFF" } else if small { type = "Small" } else if big { type = "Big" }
                        if type != presenterType {
                            print("Presenter Overlay set to \"\(type)\"!")
                            isCameraReady = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(poSafeDelay)) {
                                self.isCameraReady = true
                            }
                            presenterType = type
                        }
                    }
                }
                if isPresenterON && !isCameraReady { break }
                if SCContext.firstFrame == nil { SCContext.firstFrame = SampleBuffer }
                if !videoInput.append(SampleBuffer) { SCContext.handleWriterFailure(writer.error) }
            }
            break
        case .audio:
            var end = CMSampleBufferGetPresentationTimeStamp(SampleBuffer)
            let audioDur = CMSampleBufferGetDuration(SampleBuffer)
            if audioDur.flags.contains(CMTimeFlags.valid) && audioDur.value > 0 { end = CMTimeAdd(end, audioDur) }
            // lastPTS 记录的是扣除暂停偏移后的时间线
            if hasOffset { end = CMTimeSubtract(end, SCContext.timeOffset) }
            if SCContext.streamType == .systemaudio { // write directly to file if not video recording
                hideMousePointer = true
                if !SCContext.sessionStarted {
                    // qma 模式下 vW 是麦克风写入器，以首个系统音频时间戳开始会话
                    if let writer = SCContext.vW {
                        guard writer.status == .writing else { return }
                        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(SampleBuffer))
                    }
                    SCContext.markSessionStarted()
                }
                guard let samples = SampleBuffer.asPCMBuffer else { return }
                do {
                    try SCContext.audioFile?.write(from: samples)
                    SCContext.updateLastPTS(end)
                } catch {
                    print("audio file writing issue: \(error)")
                    SCContext.handleWriterFailure(error)
                }
            } else {
                if SCContext.lastPTS == nil || !SCContext.sessionStarted { return }
                guard let writer = SCContext.vW, writer.status == .writing, let audioInput = SCContext.awInput else { return }
                if hasOffset {
                    guard let adjusted = SCContext.adjustTime(sample: SampleBuffer, by: SCContext.timeOffset) else { return }
                    SampleBuffer = adjusted
                }
                if audioInput.isReadyForMoreMediaData {
                    if audioInput.append(SampleBuffer) {
                        SCContext.updateLastPTS(end)
                    } else {
                        SCContext.handleWriterFailure(writer.error)
                    }
                }
            }
#if compiler(>=6.0)
        case .microphone:
            break
#endif
        @unknown default:
            print("unknown stream output type")
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) { // stream error
        print("closing stream with error:\n".local, error,
              "\nthis might be due to the window closing or the user stopping from the sonoma ui".local)
        let id = ObjectIdentifier(stream)
        DispatchQueue.main.async {
            // 旧 stream 迟到的错误不能停掉新的录制
            guard SCContext.streamQueue.sync(execute: { SCContext.activeStream == id }) else { return }
            // Stopping from the system's screen sharing indicator is the user's own choice;
            // anything else (sleep, lock, display change, -3821 ...) used to end the recording
            // with only "Recording Completed", so say why it stopped (#222 #142 #290).
            if (error as NSError).code != SCStreamError.Code.userStopped.rawValue {
                SCContext.showNotification(title: "Recording Stopped by macOS".local,
                                           body: String(format: "Reason: %@\nWhat was recorded until then has been saved.".local, error.localizedDescription),
                                           id: "quickrecorder.error.\(UUID().uuidString)")
            }
            SCContext.stream = nil
            SCContext.stopRecording()
        }
    }
}

class AudioRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    static let shared = AudioRecorder()
    private var captureSession: AVCaptureSession!
    private var audioInput: AVCaptureDeviceInput!
    private var audioDataOutput: AVCaptureAudioDataOutput!

    @discardableResult
    func setupAudioCapture() -> Bool {
        captureSession = AVCaptureSession()

        // Get the default audio device (microphone)
        guard let audioDevice = SCContext.getCurrentMic() else {
            print("Unable to access microphone")
            return false
        }
        
        // Create audio input
        do {
            audioInput = try AVCaptureDeviceInput(device: audioDevice)
        } catch {
            print("Unable to create audio input: \(error)")
            return false
        }
        
        // Add audio input to capture session
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        } else {
            print("Unable to add audio input to capture session")
            return false
        }

        // Create audio data output
        audioDataOutput = AVCaptureAudioDataOutput()
        // Interfaces with more than 2 inputs: the microphone track is stereo, and appending
        // their native multi-channel buffers failed and stopped the recording (#133).
        // Ask for the first two channels as 32-bit float PCM instead.
        if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioDevice.activeFormat.formatDescription)?.pointee,
           asbd.mChannelsPerFrame > 2 {
            audioDataOutput.audioSettings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: asbd.mSampleRate,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsNonInterleaved: false,
            ]
        }
        // 与 SCStream 回调共用串行队列，避免与停止流程竞争
        audioDataOutput.setSampleBufferDelegate(self, queue: SCContext.streamQueue)
        
        // Add audio data output to capture session
        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutput(audioDataOutput)
        } else {
            print("Unable to add audio data output to capture session")
            return false
        }
        return true
    }
    
    func start() {
        if let session = captureSession {
            session.startRunning()
        }
    }
    
    func stop() {
        if let session = captureSession {
            if session.isRunning { session.stopRunning() }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 回调运行在 SCContext.streamQueue 上
        SCContext.appendMicSample(sampleBuffer)
    }
}

// https://developer.apple.com/documentation/screencapturekit/capturing_screen_content_in_macos
// For Sonoma updated to https://developer.apple.com/forums/thread/727709
extension CMSampleBuffer {
    var asPCMBuffer: AVAudioPCMBuffer? {
        try? self.withAudioBufferList { audioBufferList, _ -> AVAudioPCMBuffer? in
            guard let absd = self.formatDescription?.audioStreamBasicDescription else { return nil }
            guard let format = AVAudioFormat(standardFormatWithSampleRate: absd.mSampleRate, channels: absd.mChannelsPerFrame) else { return nil }
            return AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
        }
    }
    
    var nsImage: NSImage? {
        return autoreleasepool {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let ciContext = CIContext()
            if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                return NSImage(cgImage: cgImage, size: .zero)
            }
            return nil
        }
    }
}

// Based on https://gist.github.com/aibo-cora/c57d1a4125e145e586ecb61ebecff47c
extension AVAudioPCMBuffer {
    var asSampleBuffer: CMSampleBuffer? { sampleBuffer(hostTime: nil) }

    /// Wraps the buffer in a CMSampleBuffer stamped with the time its first sample was
    /// captured. `hostTime` is the capture time from the audio engine (AVAudioTime.hostTime);
    /// without it the start is estimated as "now minus the buffer length". Stamping with the
    /// time of the callback instead made the microphone drift against the system audio (#247).
    func sampleBuffer(hostTime: UInt64?) -> CMSampleBuffer? {
        let asbd = self.format.streamDescription
        var sampleBuffer: CMSampleBuffer? = nil
        var format: CMFormatDescription? = nil

        guard CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &format
        ) == noErr else { return nil }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Int32(asbd.pointee.mSampleRate)),
            presentationTimeStamp: {
                if let hostTime = hostTime, hostTime > 0 { return CMClockMakeHostTimeFromSystemUnits(hostTime) }
                let length = CMTime(value: CMTimeValue(self.frameLength), timescale: Int32(asbd.pointee.mSampleRate))
                return CMTimeSubtract(CMClockGetTime(CMClockGetHostTimeClock()), length)
            }(),
            decodeTimeStamp: .invalid
        )

        guard CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleCount: CMItemCount(self.frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        ) == noErr else { return nil }

        guard CMSampleBufferSetDataBufferFromAudioBufferList(
            sampleBuffer!,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: 0,
            bufferList: self.mutableAudioBufferList
        ) == noErr else { return nil }

        return sampleBuffer
    }
}
