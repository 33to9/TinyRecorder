//
//  PreviewView.swift
//  TinyRecorder
//
//  Created by apple on 2024/12/10.
//

import SwiftUI
import Combine

struct PreviewView: View {
    /// 共享的 previewWindow 每显示一次新预览就递增；旧预览的定时关闭据此失效，避免误关新预览
    static var activeGeneration = 0
    
    let frame: NSImage
    let filePath: String
    var generation: Int = 0
    private let sharingDelegate = SharingServicePickerDelegate()
    @State private var isHovered: Bool = false
    @State private var isHovered2: Bool = false
    @State private var isSharing: Bool = false
    @State private var nsWindow: NSWindow?
    @State private var opacity: Double = 0.0
    @AppStorage("trimAfterRecord")  private var trimAfterRecord: Bool = false
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            ZStack {
                Color.clear
                    .background(.ultraThickMaterial)
                    .environment(\.controlActiveState, .active)
                    .cornerRadius(6)
                ZStack {
                    Image(nsImage: frame)
                        .resizable().scaledToFit()
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 1.5)
                    if isHovered2 {
                        Button(action: {
                            if fd.fileExists(atPath: filePath) {
                                NSWorkspace.shared.open(filePath.url)
                                closeWindow()
                            }
                        }, label: {
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 49))
                                    .foregroundStyle(.black)
                                    .opacity(0.5)
                                Image(systemName: "play.circle")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                        }).buttonStyle(.plain)
                    }
                }
                .onHover(perform: { isHovered2 = $0 })
                .padding(8)
            }
            if isHovered {
                HoverButton(color: .buttonRed, secondaryColor: .buttonRedDark,
                            action: { closeWindow() }, label: {
                    ZStack {
                        Image(systemName: "circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                        Image(systemName: "circle.fill")
                            .font(.title2)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                    }
                }).padding(4)
            }
        }
        .opacity(opacity)
        .onHover(perform: { isHovered = $0 })
        .background(WindowAccessor(onWindowOpen: { w in nsWindow = w }))
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if isCurrent && !isHovered && !isSharing { closeWindow() }
            }
        }
        .onChange(of: isHovered) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if isCurrent && !isHovered && !isSharing { closeWindow() }
                }
            }
        }
        .contextMenu {
            Button("Show in Finder") {
                if fd.fileExists(atPath: filePath) {
                    NSWorkspace.shared.activateFileViewerSelecting([filePath.url])
                }
                closeWindow()
            }
            Button("Move to Trash") {
                // 先确认，再移到废纸篓（可在访达中恢复），不再直接永久删除
                let alert = createAlert(level: .warning, title: "Move this recording to the Trash?",
                                        message: filePath.lastPathComponent,
                                        button1: "Move to Trash", button2: "Cancel")
                guard alert.runModal() == .alertFirstButtonReturn else { return }
                do {
                    try fd.trashItem(at: filePath.url, resultingItemURL: nil)
                } catch {
                    print("Failed to move file to Trash: \(error.localizedDescription)")
                }
                closeWindow()
            }
            Divider()
            Button("Copy") {
                if fd.fileExists(atPath: filePath) {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([filePath.url as NSURL])
                }
                closeWindow()
            }
            Button("Share…") { showSharingServicePicker(for: filePath.url) }
            Divider()
            if !trimAfterRecord {
                Button("Trim") {
                    if fd.fileExists(atPath: filePath) {
                        AppDelegate.shared.createNewWindow(view: VideoTrimmerView(videoURL: filePath.url), title: filePath.lastPathComponent, only: false)
                    }
                    closeWindow()
                }
            }
            if #available(macOS 13, *) {
                if ["mp4", "mov"].contains(filePath.pathExtension) {
                    Button("Make GIF") {
                        if isAppInstalled(id: "com.sindresorhus.Gifski") {
                            makeGif()
                            closeWindow()
                        } else {
                            let alert = createAlert(title: "Gifski not found",
                                                    message: "Please install \"Gifski\" first to make GIF!",
                                                    button1: "Open App Store", button2: "Cancel").runModal()
                            if alert == .alertFirstButtonReturn { openURL("https://apps.apple.com/app/id1351639930") }
                        }
                    }
                    Divider()
                }
            }
            Button("Close") { closeWindow() }
        }
    }
    
    func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 本预览是否仍是共享窗口当前显示的那一个
    private var isCurrent: Bool { generation == PreviewView.activeGeneration }
    
    private func closeWindow() {
        // 已被更新的预览替换：不要关闭共享窗口
        guard isCurrent else { return }
        withAnimation(.easeIn(duration: 0.2)) { opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if isCurrent { nsWindow?.close() }
        }
    }
    
    private func isAppInstalled(id: String) -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
    }
    
    private func makeGif() {
        let task = Process()
        task.arguments = ["-b", "com.sindresorhus.Gifski", filePath]
        task.launchPath = "/usr/bin/open"
        task.launch()
    }
    
    private func showSharingServicePicker(for url: URL) {
        if let window = nsWindow {
            isSharing = true
            sharingDelegate.onDidChooseService = { service in
                isSharing = false
                if service != nil {
                    DispatchQueue.main.async { closeWindow() }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        if isCurrent && !isHovered && !isSharing { closeWindow() }
                    }
                }
            }
            let sharingPicker = NSSharingServicePicker(items: [url])
            sharingPicker.delegate = sharingDelegate
            sharingPicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
}

// 自定义 NSSharingServicePickerDelegate
class SharingServicePickerDelegate: NSObject, NSSharingServicePickerDelegate {
    var onDidChooseService: ((NSSharingService?) -> Void)?
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        onDidChooseService?(service)
    }
}
