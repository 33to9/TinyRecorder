//
//  qmaPlayer.swift
//  QuickRecorder
//
//  Created by apple on 2024/6/28.
//

import Foundation
import AVFoundation
import SwiftUI

struct qmaPlayerView: View {
    @Binding var document: qmaPackageHandle
    @State var fileURL: URL
    @State private var overPlay: Bool = false
    @State private var overStop: Bool = false
    @State private var overSave: Bool = false
    @State private var overExport: Bool = false
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    
    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectView().ignoresSafeArea()
            VStack(spacing: 3) {
                Button {} label: {
                    PlayerSlider(percentage: $audioPlayerManager.progress, audioLength: $audioPlayerManager.audioLength){ editing in
                        if !editing {
                            let newTime = audioPlayerManager.progress * audioPlayerManager.getPlayerDuration()
                            audioPlayerManager.seek(to: newTime)
                            audioPlayerManager.shouldPlay = false
                        } else {
                            if audioPlayerManager.isPlaying {
                                audioPlayerManager.pause()
                                audioPlayerManager.shouldPlay = true
                            }
                        }
                    }.frame(height: 30)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayerManager.exporting)
                
                HStack(spacing: 4) {
                    Rectangle().opacity(0.00001).frame(width: 30)
                    Spacer()
                    Button {
                        audioPlayerManager.stop()
                    } label: {
                        ZStack {
                            Rectangle()
                                .cornerRadius(6)
                                .foregroundColor(.secondary.opacity(overStop ? 0.1 : 0.00001))
                            Image(systemName: "stop.fill")
                                .font(.system(size: 20))
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Stop Play")
                    .frame(width: 30, height: 30)
                    .disabled(audioPlayerManager.exporting)
                    .onHover { hovering in overStop = hovering }
                    
                    Button {
                        if audioPlayerManager.isPlaying {
                            audioPlayerManager.pause()
                        } else {
                            audioPlayerManager.play()
                        }
                    } label: {
                        ZStack {
                            Rectangle()
                                .cornerRadius(6)
                                .foregroundColor(.secondary.opacity(overPlay ? 0.1 : 0.00001))
                            Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Play / Pause")
                    .frame(width: 35, height: 35)
                    .padding(.leading, 2)
                    .disabled(audioPlayerManager.exporting)
                    .onHover { hovering in overPlay = hovering }
                    
                    Button {
                        saveQMA()
                    } label: {
                        ZStack {
                            Rectangle()
                                .cornerRadius(6)
                                .foregroundColor(.secondary.opacity(overSave ? 0.1 : 0.00001))
                            Image("save")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16.5)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Save Changes")
                    .frame(width: 30, height: 30)
                    .disabled(audioPlayerManager.exporting)
                    .onHover { hovering in overSave = hovering }
                    
                    Spacer()
                    
                    Button {
                        saveQMA()
                        audioPlayerManager.export()
                    } label: {
                        ZStack {
                            Rectangle()
                                .cornerRadius(6)
                                .foregroundColor(.secondary.opacity(overExport ? 0.1 : 0.00001))
                            if audioPlayerManager.exporting {
                                ActivityIndicator()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                    .offset(y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Export")
                    .frame(width: 30, height: 30)
                    .disabled(audioPlayerManager.exporting)
                    .onHover { hovering in overExport = hovering }
                }
                
                Button {} label: {
                    HStack(spacing: 14) {
                        HStack(spacing: 2) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("\(Int(audioPlayerManager.sysVol * 100))%").foregroundColor(.secondary).frame(width: 40)
                            VolumeSlider(percentage: $audioPlayerManager.sysVol, maxValue: 4){ editing in }
                                .frame(height: 16)
                                .disabled(audioPlayerManager.exporting)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "mic.fill")
                            Text("\(Int(audioPlayerManager.micVol * 100))%").foregroundColor(.secondary).frame(width: 40)
                            VolumeSlider(percentage: $audioPlayerManager.micVol, maxValue: 4){ editing in }
                                .frame(height: 16)
                                .disabled(audioPlayerManager.exporting)
                        }
                    }
                }.buttonStyle(.plain)
            }.padding().padding(.top, -14)
        }
        .onAppear {
            audioPlayerManager.loadAudioFiles(format: document.info.format, package: fileURL, encoder: document.info.encoder, saveMP3: document.info.exportMP3)
                audioPlayerManager.sysVol = document.info.sysVol
                audioPlayerManager.micVol = document.info.micVol
        }
        .background(WindowAccessor(onWindowOpen: { w in
            guard let w = w else { return }
            w.setContentSize(CGSize(width: 400, height: 100))
            w.isMovableByWindowBackground = true
            w.titlebarAppearsTransparent = true
        }, onWindowActive: { w in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { w?.titlebarAppearsTransparent = true }
        }, onWindowDeactivate: { w in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { w?.titlebarAppearsTransparent = true }
        }, onWindowClose: { audioPlayerManager.reset() }))
    }
    
    func saveQMA() {
        var save = 0
        if document.info.sysVol != audioPlayerManager.sysVol {
            document.info.sysVol = audioPlayerManager.sysVol
            save += 1
        }
        if document.info.micVol != audioPlayerManager.micVol {
            document.info.micVol = audioPlayerManager.micVol
            save += 1
        }
        if save != 0 {
            NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}

struct VolumeSlider: View {
    @Binding var percentage: Float
    @State var maxValue: Float = 1.0
    @State private var isDragging = false
    @State private var isHover = false

    var onEditingChanged: (Bool) -> Void // Callback for editing changes

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Group {
                    Rectangle()
                        .foregroundColor(.secondary.opacity(0.2))
                    Rectangle()
                        .foregroundColor(.accentColor)
                        .frame(width: geometry.size.width * CGFloat(min(1.0, self.percentage / maxValue)))
                }.frame(height: 5).cornerRadius(12)
                Circle()
                    .shadow(radius: 1)
                    .foregroundColor(.white)
                    .opacity(isHover || isDragging ? 1.0 : 0.00001)
                    .frame(width: 16, height: 16)
                    .offset(x: geometry.size.width * CGFloat(min(1.0, self.percentage / maxValue)) - 8)
            }.onHover { hovering in isHover = hovering }
                .compositingGroup()
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        self.percentage = min(max(0, Float(value.location.x / geometry.size.width) * maxValue), maxValue)
                        self.isDragging = true // Indicate dragging
                        self.onEditingChanged(true) // Notify that editing started
                    }
                    .onEnded { value in
                        // Update the bound percentage value when dragging ends
                        self.percentage = min(max(0, Float(value.location.x / geometry.size.width) * maxValue), maxValue)
                        self.isDragging = false // Indicate dragging ended
                        self.onEditingChanged(false) // Notify that editing ended
                    }
                )
        }
    }
}

struct PlayerSlider: View {
    @Binding var percentage: Double
    @Binding var audioLength: TimeInterval
    @State private var isDragging = false
    @State private var isHover = false
    @State private var temporaryPercentage: Double = 0.0 // Temporary value during dragging

    var onEditingChanged: (Bool) -> Void // Callback for editing changes

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 2) {
                HStack {
                    Text("\(String(format: "%.2d:%.2d:%.2d", isDragging ? Int(temporaryPercentage * audioLength) / 3600 : Int(percentage * audioLength) / 3600, isDragging ? Int(temporaryPercentage * audioLength) / 60 : Int(percentage * audioLength) / 60, isDragging ? Int(temporaryPercentage * audioLength) % 60 : Int(percentage * audioLength) % 60))"
                    ).foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.2d:%.2d:%.2d", Int(audioLength) / 3600, Int(audioLength) / 60, Int(audioLength) % 60))")
                        .foregroundColor(.secondary)
                }
                ZStack(alignment: .leading) {
                    Group {
                        Rectangle()
                            .foregroundColor(.secondary.opacity(0.5))
                        Rectangle()
                            .foregroundColor(.secondary)
                            .frame(width: geometry.size.width * CGFloat(min(1.0, self.isDragging ? self.temporaryPercentage : self.percentage)))
                    }.frame(height: 4).cornerRadius(12)
                    if isHover || isDragging {
                        Rectangle()
                            .foregroundColor(.black)
                            .blendMode(.destinationOut)
                            .frame(width: 6, height: 10)
                            .offset(x: geometry.size.width * CGFloat(min(1.0, self.isDragging ? self.temporaryPercentage : self.percentage)) - 3)
                    }
                    Rectangle()
                        .cornerRadius(12)
                        .foregroundColor(.primary)
                        .opacity(isHover || isDragging ? 1.0 : 0.00001)
                        .frame(width: 4, height: 12)
                        .offset(x: geometry.size.width * CGFloat(min(1.0, self.isDragging ? self.temporaryPercentage : self.percentage)) - 2)
                }.onHover { hovering in isHover = hovering }
                    .compositingGroup()
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Update temporary percentage during dragging
                            self.temporaryPercentage = min(max(0, Double(value.location.x / geometry.size.width)), 1)
                            self.isDragging = true // Indicate dragging
                            self.onEditingChanged(true) // Notify that editing started
                        }
                        .onEnded { value in
                            // Update the bound percentage value when dragging ends
                            self.percentage = self.temporaryPercentage
                            self.isDragging = false // Indicate dragging ended
                            self.onEditingChanged(false) // Notify that editing ended
                        }
                    )
            }
        }
    }
}

struct qmaPackageHandle: FileDocument {
    static var readableContentTypes: [UTType] { [UTType.qma] }
    
    var info: Info
    var sysAudio: Data
    var micAudio: Data
    
    struct Info: Codable {
        var format: String
        var encoder: String
        var exportMP3: Bool
        var sysVol: Float
        var micVol: Float
    }
    
    init(info: Info = Info(format: "m4a", encoder: "aac", exportMP3: false, sysVol: 1.0, micVol: 1.0), sysAudio: Data = Data(), micAudio: Data = Data()) {
        self.info = info
        self.sysAudio = sysAudio
        self.micAudio = micAudio
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileWrappers = configuration.file.fileWrappers else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        guard let infoFileWrapper = fileWrappers["info.json"],
              let infoData = infoFileWrapper.regularFileContents,
              let info = try? JSONDecoder().decode(Info.self, from: infoData) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.info = info
        
        guard let sysAudioFileWrapper = fileWrappers["sys.\(info.format)"],
              let sysAudio = sysAudioFileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.sysAudio = sysAudio
        
        guard let micAudioFileWrapper = fileWrappers["mic.\(info.format)"],
              let micAudio = micAudioFileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.micAudio = micAudio
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let infoData = try JSONEncoder().encode(info)
        let infoFileWrapper = FileWrapper(regularFileWithContents: infoData)
        infoFileWrapper.preferredFilename = "info.json"
        
        let sysAudioFileWrapper = FileWrapper(regularFileWithContents: sysAudio)
        sysAudioFileWrapper.preferredFilename = "sys.\(info.format)"
        
        let micAudioFileWrapper = FileWrapper(regularFileWithContents: micAudio)
        micAudioFileWrapper.preferredFilename = "mic.\(info.format)"
        
        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "info.json": infoFileWrapper,
            "sys.\(info.format)": sysAudioFileWrapper,
            "mic.\(info.format)": micAudioFileWrapper
        ])
        
        return fileWrapper
    }
}

extension qmaPackageHandle {
    static func load(from url: URL) throws -> qmaPackageHandle {
        let fileWrapper = try FileWrapper(url: url, options: .immediate)
        guard let infoFileWrapper = fileWrapper.fileWrappers?["info.json"],
              let infoData = infoFileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let info = try JSONDecoder().decode(Info.self, from: infoData)

        guard let sysAudioFileWrapper = fileWrapper.fileWrappers?["sys.\(info.format)"],
              let sysAudio = sysAudioFileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        guard let micAudioFileWrapper = fileWrapper.fileWrappers?["mic.\(info.format)"],
              let micAudio = micAudioFileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return qmaPackageHandle(info: info, sysAudio: sysAudio, micAudio: micAudio)
    }
}

class AudioPlayerManager: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isPlaying: Bool = false
    @Published var shouldPlay: Bool = false
    @Published var exporting: Bool = false
    @Published var audioLength: TimeInterval = 0
    @Published var sysVol: Float = 1.0 {
        didSet {
            updateSysVol()
        }
    }
    @Published var micVol: Float = 1.0 {
        didSet {
            updateMicVol()
        }
    }
    
    private var engine = AVAudioEngine()
    private var playerNode1 = AVAudioPlayerNode()
    private var playerNode2 = AVAudioPlayerNode()
    private var mixerNode = AVAudioMixerNode()
    private var timer: Timer?
    /// 当前已调度片段在文件中的起始时间（秒）
    private var lastStartTime: Double = 0
    /// 播放节点上是否已有调度好的音频（暂停后继续播放时不应重复调度）
    private var isScheduled = false
    private var audioFile1: AVAudioFile?
    private var audioFile2: AVAudioFile?
    private var isSeeking = false
    private var exportMP3 = false
    private var fileFormat = "m4a"
    private var fileEncoder = "aac"
    private var packageURL: URL?
    private var seekTime: Double = 0
    private var panel = NSSavePanel()
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // 导出后会再次调用本方法，节点已挂载时不能重复 attach
        if playerNode1.engine == nil { engine.attach(playerNode1) }
        if playerNode2.engine == nil { engine.attach(playerNode2) }
        if mixerNode.engine == nil { engine.attach(mixerNode) }
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: false)!
        engine.connect(playerNode1, to: mixerNode, format: outputFormat)
        engine.connect(playerNode2, to: mixerNode, format: outputFormat)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: outputFormat)
        
        do {
            try engine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    func loadAudioFiles(format: String, package: URL, encoder: String, saveMP3: Bool) {
        do {
            fileFormat = format
            fileEncoder = encoder
            exportMP3 = saveMP3
            packageURL = package
            audioFile1 = try AVAudioFile(forReading: package.appendingPathComponent("sys.\(format)"))
            audioFile2 = try AVAudioFile(forReading: package.appendingPathComponent("mic.\(format)"))
            
            audioLength = Double(audioFile1?.length ?? 0) / (audioFile1?.processingFormat.sampleRate ?? 48000.0)
            
            updateSysVol()
            updateMicVol()
        } catch {
            print("Error loading audio data: \(error)")
        }
    }
    
    func play() {
        guard let audioFile1 = audioFile1, let audioFile2 = audioFile2 else { return }
        if !isScheduled {
            // 只有在停止/播放结束后才重新调度整段文件；暂停后继续播放直接 play()
            playerNode1.scheduleFile(audioFile1, at: nil, completionHandler: nil)
            playerNode2.scheduleFile(audioFile2, at: nil, completionHandler: nil)
            lastStartTime = 0
            isScheduled = true
        }
        if !engine.isRunning { try? engine.start() }
        playerNode1.play()
        playerNode2.play()
        stopProgressTimer()
        startProgressTimer()
        isPlaying = true
    }
    
    func pause() {
        playerNode1.pause()
        playerNode2.pause()
        stopProgressTimer()
        isPlaying = false
    }
    
    func stop() {
        playerNode1.stop()
        playerNode2.stop()
        stopProgressTimer()
        lastStartTime = 0
        isScheduled = false
        progress = 0.0
        isPlaying = false
    }
    
    func seek(to time: Double) {
        guard let audioFile1 = audioFile1, let audioFile2 = audioFile2 else { return }
        playerNode1.stop()
        playerNode2.stop()
        stopProgressTimer()
        
        seekTime = max(0, time)
        isSeeking = true
        isScheduled = false
        
        // 两个文件的采样率/长度可能不同，分别计算
        let startFrame1 = AVAudioFramePosition(seekTime * audioFile1.processingFormat.sampleRate)
        let startFrame2 = AVAudioFramePosition(seekTime * audioFile2.processingFormat.sampleRate)
        let remaining1 = audioFile1.length - startFrame1
        let remaining2 = audioFile2.length - startFrame2
        let maxCount = AVAudioFramePosition(AVAudioFrameCount.max)
        
        if remaining1 > 0 {
            lastStartTime = seekTime
            playerNode1.scheduleSegment(audioFile1, startingFrame: startFrame1, frameCount: AVAudioFrameCount(min(remaining1, maxCount)), at: nil, completionHandler: nil)
            if remaining2 > 0 {
                playerNode2.scheduleSegment(audioFile2, startingFrame: startFrame2, frameCount: AVAudioFrameCount(min(remaining2, maxCount)), at: nil, completionHandler: nil)
            }
            isScheduled = true
            progress = audioLength > 0 ? seekTime / audioLength : 0
            if isPlaying || shouldPlay {
                playerNode1.play()
                playerNode2.play()
                startProgressTimer()
                isPlaying = true
            }
        } else {
            stop()
        }
        
        
    }
    
    private func startProgressTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let lastRenderTime = self.playerNode1.lastRenderTime, let playerTime = self.playerNode1.playerTime(forNodeTime: lastRenderTime) {
                let currentTime = self.lastStartTime + Double(playerTime.sampleTime) / playerTime.sampleRate
                self.progress = self.audioLength > 0 ? currentTime / self.audioLength : 0
                if currentTime > self.audioLength {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.stop()
                    }
                }
            }
        }
    }
    
    private func stopProgressTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func getPlayerDuration() -> TimeInterval {
        return audioLength
    }
    
    func reset() {
        stop()
        playerNode1.reset()
        playerNode2.reset()
        audioFile1 = nil
        audioFile2 = nil
    }
    
    func export() {
        guard let packageURL = packageURL else { return }
        stop()
        let format = exportMP3 ? "mp3" : self.fileFormat
        showSavePanel(defaultFileName: "\(packageURL.deletingPathExtension().appendingPathExtension(format).lastPathComponent)", exportMP3: exportMP3) { url, saveAsMP3 in
            if let url = url { self.saveFile(url, saveAsMP3: saveAsMP3) }
        }
    }
    
    func saveFile(_ url: URL, saveAsMP3: Bool = false) {
        var url = url
        if url.pathExtension == "mp3" { url = url.deletingPathExtension() }
        if url.pathExtension != self.fileFormat { url = url.appendingPathExtension(self.fileFormat) }
        let lastComp = url.lastPathComponent
        if self.exportMP3 { url = url.deletingLastPathComponent().appendingPathComponent("." + url.lastPathComponent) }
        
        Thread.detachNewThread {
            DispatchQueue.main.async { self.exporting = true }
            // 无论成功、失败还是提前返回，都要恢复 exporting 状态
            defer { DispatchQueue.main.async { self.exporting = false } }
            do {
                guard let audioFile1 = self.audioFile1, let audioFile2 = self.audioFile2 else {
                    throw NSError(domain: "QmaExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio files are not loaded."])
                }
                self.playerNode1.scheduleFile(audioFile1, at: nil, completionHandler: nil)
                self.playerNode2.scheduleFile(audioFile2, at: nil, completionHandler: nil)
                
                let audioSettings = SCContext.updateAudioSettings(format: self.fileEncoder)
                let outputFormat = self.playerNode1.outputFormat(forBus: 0)
                let outputFile = try AVAudioFile(forWriting: url, settings: audioSettings, commonFormat: .pcmFormatFloat32, interleaved: false)
                self.engine.stop()
                try self.engine.enableManualRenderingMode(.offline, format: outputFormat, maximumFrameCount: 4096)
                try self.engine.start()
                
                self.playerNode1.play()
                self.playerNode2.play()
                
                let duration = audioFile1.length
                guard let buffer = AVAudioPCMBuffer(pcmFormat: self.engine.manualRenderingFormat, frameCapacity: self.engine.manualRenderingMaximumFrameCount) else {
                    throw NSError(domain: "QmaExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create the render buffer."])
                }
                
                while self.engine.manualRenderingSampleTime < duration {
                    let framesToRender = min(UInt32(buffer.frameCapacity), UInt32(duration - self.engine.manualRenderingSampleTime))
                    let status = try self.engine.renderOffline(framesToRender, to: buffer)
                    if status == .success {
                        try outputFile.write(from: buffer)
                    } else {
                        // 离线渲染无法继续：直接报错退出循环，避免死循环
                        throw NSError(domain: "QmaExportError", code: status.rawValue, userInfo: [NSLocalizedDescriptionKey: "Offline rendering failed (status \(status.rawValue))."])
                    }
                }
                
                self.restoreEngineAfterExport()
                
                let title = "Recording Completed".local
                var body = String(format: "File saved to: %@".local, url.path.removingPercentEncoding ?? url.path)
                let id = "quickrecorder.completed.\(UUID().uuidString)"
                
                if saveAsMP3 {
                    let oldURL = url
                    let newURl = url.deletingLastPathComponent().appendingPathComponent(lastComp).deletingPathExtension().appendingPathExtension("mp3")
                    body = String(format: "File saved to: %@".local, newURl.path.removingPercentEncoding ?? newURl.path)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        Task {
                            do {
                                try await SCContext.m4a2mp3(inputUrl: oldURL, outputUrl: newURl)
                                try? fd.removeItem(at: oldURL)
                            } catch {
                                SCContext.showNotification(title: "Failed to save file".local, body: "\(error.localizedDescription)", id: "quickrecorder.error.\(UUID().uuidString)")
                                return
                            }
                        }
                    }
                }
                
                SCContext.showNotification(title: title, body: body, id: id)
            } catch {
                self.restoreEngineAfterExport()
                SCContext.showNotification(title: "Failed to save file".local, body: "\(error.localizedDescription)", id: "quickrecorder.error.\(UUID().uuidString)")
            }
        }
    }
    
    /// 导出结束（成功或失败）后恢复为实时播放模式
    private func restoreEngineAfterExport() {
        playerNode1.stop()
        playerNode2.stop()
        if engine.isInManualRenderingMode { engine.disableManualRenderingMode() }
        engine.stop()
        setupAudioEngine()
        DispatchQueue.main.async { self.isScheduled = false }
    }
    
    private func updateSysVol() {
        playerNode1.volume = sysVol
    }
    
    private func updateMicVol() {
        playerNode2.volume = micVol
    }
    
    private func showSavePanel(defaultFileName: String, exportMP3: Bool, completion: @escaping (URL?, Bool) -> Void) {
        panel.isReleasedWhenClosed = true
        panel.nameFieldStringValue = defaultFileName
        panel.canCreateDirectories = true
        panel.title = "Export Recording".local
        
        let checkBox = NSButton(checkboxWithTitle: "Export as MP3".local, target: self, action: #selector(checkBoxToggled(_:)))
        checkBox.state = exportMP3 ? .on : .off
        
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: checkBox.frame.width, height: checkBox.frame.height))
        accessoryView.addSubview(checkBox)
        
        panel.accessoryView = accessoryView
        
        panel.begin { response in
            if response == .OK {
                let exportAsMP3 = (checkBox.state == .on)
                completion(self.panel.url, exportAsMP3)
            } else {
                completion(nil, false)
            }
        }
    }
    
    @objc private func checkBoxToggled(_ sender: NSButton) {
        panel.close()
        panel = NSSavePanel()
        exportMP3.toggle()
        export()
    }
}

extension UTType {
    static let qma = UTType(exportedAs: "com.33to9.TinyRecorder.qma")
}
