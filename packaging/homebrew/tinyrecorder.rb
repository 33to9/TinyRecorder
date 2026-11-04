# Homebrew cask for TinyRecorder, published in the 33to9/homebrew-tap repository:
#   brew install --cask 33to9/tap/tinyrecorder
# CI (.github/workflows/build.yml, job "homebrew") rewrites version + sha256 on every tag release.
cask "tinyrecorder" do
  version "1.7.19"
  sha256 "08eb2dde84fa2e9ddd57487edbccfc4bd92828e73a22b498100ef1de71c2baf2"

  url "https://github.com/33to9/TinyRecorder/releases/download/v#{version}/TinyRecorder_v#{version}.dmg"
  name "TinyRecorder"
  desc "Lightweight screen recorder (QuickRecorder fork with macOS 27 support)"
  homepage "https://github.com/33to9/TinyRecorder"

  livecheck do
    url :url
    strategy :github_latest
  end

  # The app updates itself with Sparkle (Check for Updates…).
  auto_updates true
  depends_on macos: ">= :monterey"

  app "TinyRecorder.app"

  # The app is self-signed, not notarized by Apple: without this, Gatekeeper
  # blocks the first launch of the quarantined copy Homebrew downloaded.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/TinyRecorder.app"]
  end

  uninstall quit: "com.33to9.TinyRecorder"

  zap trash: [
    "~/Library/Caches/com.33to9.TinyRecorder",
    "~/Library/HTTPStorages/com.33to9.TinyRecorder",
    "~/Library/Preferences/com.33to9.TinyRecorder.plist",
    "~/Library/Saved Application State/com.33to9.TinyRecorder.savedState",
  ]
end
