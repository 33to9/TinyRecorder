//
//  AVContext.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/27.
//
import AppKit
import Foundation
import AVFoundation
import UserNotifications

extension AppDelegate {
    func recordingCamera(with device: AVCaptureDevice) {
        // 切换摄像头前停掉旧会话（同 AVOutputClass.startRecording），避免指示灯常亮
        if let old = SCContext.captureSession, old.isRunning { old.stopRunning() }
        if let old = SCContext.previewSession, old.isRunning { old.stopRunning() }
        SCContext.captureSession = AVCaptureSession()
        
        guard let input = try? AVCaptureDeviceInput(device: device),
              SCContext.captureSession.canAddInput(input) else {
            print("Failed to set up camera")
            SCContext.requestCameraPermission()
            return
        }
        SCContext.captureSession.addInput(input)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: .global())
        
        if SCContext.captureSession.canAddOutput(videoOutput) {
            SCContext.captureSession.addOutput(videoOutput)
        }
        
        SCContext.captureSession.startRunning()
        DispatchQueue.main.async { self.startCameraOverlayer() }
    }
    
    func closeCamera() {
        if SCContext.isCameraRunning() {
            //SCContext.previewType = nil
            if camWindow.isVisible { camWindow.close() }
            SCContext.captureSession?.stopRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        /* 保留后续以作他用
        if !SCContext.isPaused && ud.string(forKey: "recordCam") != "" {
            if sampleBuffer.isValid { SCContext.isCameraReady = true }
            if sampleBuffer.imageBuffer != nil { SCContext.frameCache = sampleBuffer }
        }*/
    }
}

class AVOutputClass: NSObject, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let shared = AVOutputClass()
    var output: AVCaptureMovieFileOutput!
    var dataOutput: AVCaptureVideoDataOutput!
    //var captureSession: AVCaptureSession!
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print(sampleBuffer.nsImage?.size)
    }
    
    public func startRecording(with device: AVCaptureDevice, mute: Bool = false, preset: AVCaptureSession.Preset = .high, didOutput: Bool = true) {
        // 先停掉上一个会话（例如录制中把摄像头画中画从 FaceTime 摄像头换成 iPhone），
        // 否则旧会话失去引用后仍在运行，摄像头指示灯会一直亮到退出 App
        if let old = SCContext.captureSession, old.isRunning { old.stopRunning() }
        if let old = SCContext.previewSession, old.isRunning { old.stopRunning() }
        output = AVCaptureMovieFileOutput()
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: .global())
        SCContext.captureSession = AVCaptureSession()
        SCContext.previewSession = AVCaptureSession()
        SCContext.captureSession.sessionPreset = preset
        SCContext.previewSession.sessionPreset = preset
        
        guard let input = try? AVCaptureDeviceInput(device: device),
              let preview = try? AVCaptureDeviceInput(device: device),
              SCContext.captureSession.canAddInput(input),
              SCContext.previewSession.canAddInput(preview),
              SCContext.captureSession.canAddOutput(output),
              SCContext.previewSession.canAddOutput(dataOutput) else {
            print("Failed to set up camera or device")
            SCContext.requestCameraPermission()
            return
        }
        
        SCContext.captureSession.addInput(input)
        SCContext.captureSession.addOutput(output)
        SCContext.previewSession.addInput(preview)
        SCContext.previewSession.addOutput(dataOutput)
        
        if mute {
            if let audioConnection = output.connection(with: .audio) {
                SCContext.captureSession.removeConnection(audioConnection)
                /*DispatchQueue.main.async {
                    let alert = createAlert(title: "No Audio Connection",
                                                               message: "Unable to get audio stream on this device, only screen content will be recorded!",
                                                               button1: "OK")
                    alert.runModal()
                }*/
            }
        }
        
        if didOutput {
            // AVCaptureMovieFileOutput raises an Objective-C exception (crash) for a codec it
            // can't use; without a hardware HEVC encoder fall back to H.264. (The output's
            // availableVideoCodecTypes is iOS-only, so check the encoder via VideoToolbox.)
            let wantsH265 = ud.string(forKey: "encoder") == Encoder.h265.rawValue
            let codec: AVVideoCodecType = wantsH265 && hevcHardwareEncoderAvailable ? .hevc : .h264
            let videoSettings: [String: Any] = [ AVVideoCodecKey: codec ]
            guard let connection = output.connection(with: .video) else { return }
            output.setOutputSettings(videoSettings, for: connection)
            let fileEnding = ud.string(forKey: "videoFormat") ?? ""
            SCContext.filePath = "\(SCContext.getFilePath()).\(fileEnding)"
            SCContext.captureSession.startRunning()
            output.startRecording(to: SCContext.filePath.url, recordingDelegate: self)
            SCContext.streamType = StreamType.idevice
            SCContext.startTime = Date.now
        }
        
        SCContext.previewSession.startRunning()
        DispatchQueue.main.async {
            closeAllWindow(except: "Area Overlayer".local)
            updateStatusBar()
            AppDelegate.shared.startDeviceOverlayer(size: NSSize(width: 300, height: 500))
        }
    }

    public func stopRecording() {
        if let session = SCContext.captureSession, session.isRunning {
            output?.stopRecording()
            session.stopRunning()
        }
        // 设备被拔掉时会话已自行停止：仍要复位录制状态，否则界面一直停在“录制中”
        SCContext.previewSession?.stopRunning()
        guard SCContext.streamType == .idevice else { return }
        SCContext.streamType = nil
        SCContext.startTime = nil
        DispatchQueue.main.async {
            controlPanel.close()
            deviceWindow.close()
            updateStatusBar()
        }
    }
    
    func closePreview() {
        if SCContext.isCameraRunning() {
            //SCContext.previewType = nil
            if deviceWindow.isVisible { deviceWindow.close() }
            if let preview = SCContext.previewSession { preview.stopRunning() }
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // 带 error 回调时文件也可能已完整写入（AVErrorRecordingSuccessfullyFinishedKey 为 true）
        var succeeded = true
        if let error = error as NSError? {
            succeeded = (error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
            print("Device recording finished with error: \(error.localizedDescription)")
        }
        if succeeded {
            SCContext.showNotification(title: "Recording Completed".local,
                                       body: String(format: "File saved to: %@".local, outputFileURL.path),
                                       id: "quickrecorder.completed.\(UUID().uuidString)")
        } else {
            SCContext.showNotification(title: "Failed to save file".local,
                                       body: error?.localizedDescription ?? "Unknown Error".local,
                                       id: "quickrecorder.error.\(UUID().uuidString)")
        }
    }
}
