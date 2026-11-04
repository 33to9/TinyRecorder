// Lists on-screen windows of an app as "id<TAB>x<TAB>y<TAB>w<TAB>h<TAB>layer<TAB>title", largest first.
//   swift windows.swift TinyRecorder
import CoreGraphics
import Foundation

let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "TinyRecorder"
let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
var rows: [(Int, String)] = []
for w in info where (w[kCGWindowOwnerName as String] as? String) == owner {
    let id = w[kCGWindowNumber as String] as? Int ?? 0
    let b = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    let (x, y, wd, h) = (Int(b["X"] ?? 0), Int(b["Y"] ?? 0), Int(b["Width"] ?? 0), Int(b["Height"] ?? 0))
    let layer = w[kCGWindowLayer as String] as? Int ?? 0
    let title = w[kCGWindowName as String] as? String ?? ""
    rows.append((wd * h, "\(id)\t\(x)\t\(y)\t\(wd)\t\(h)\t\(layer)\t\(title)"))
}
for r in rows.sorted(by: { $0.0 > $1.0 }) { print(r.1) }
