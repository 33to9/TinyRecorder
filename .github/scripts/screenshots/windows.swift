// Lists on-screen windows as "id<TAB>x<TAB>y<TAB>w<TAB>h<TAB>layer<TAB>pid<TAB>owner<TAB>title", largest first.
//   windows [pid]   — only windows of that process when a pid is given
import CoreGraphics
import Foundation

let pidFilter = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) : nil
let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
FileHandle.standardError.write("windows on screen: \(info.count)\n".data(using: .utf8)!)
var rows: [(Int, String)] = []
for w in info {
    let pid = w[kCGWindowOwnerPID as String] as? Int ?? -1
    if let p = pidFilter, p != pid { continue }
    let id = w[kCGWindowNumber as String] as? Int ?? 0
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    func n(_ k: String) -> Int { (b[k] as? NSNumber)?.intValue ?? 0 }
    let layer = w[kCGWindowLayer as String] as? Int ?? 0
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let title = w[kCGWindowName as String] as? String ?? ""
    rows.append((n("Width") * n("Height"), "\(id)\t\(n("X"))\t\(n("Y"))\t\(n("Width"))\t\(n("Height"))\t\(layer)\t\(pid)\t\(owner)\t\(title)"))
}
for r in rows.sorted(by: { $0.0 > $1.0 }) { print(r.1) }
