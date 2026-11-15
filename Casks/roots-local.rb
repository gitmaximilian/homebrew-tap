cask "roots-local" do
  version "0.2.0"
  sha256 "1e047d320d3902d0c784b174fd9f2ece27198f384f74626bbb08f5263bccfbe5"

  url "https://github.com/gitmaximilian/roots-local/releases/download/v#{version}/Roots-Local_#{version}_arm64.dmg"
  name "Roots Local"
  desc "Interpret MyHeritage DNA raw data offline"
  homepage "https://github.com/gitmaximilian/roots-local"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Roots Local.app"

  # Builds are signed ad hoc, not notarized. Without this step Gatekeeper
  # refuses to open the app after a download.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Roots Local.app"]
  end

  zap trash: [
    "~/Library/Caches/org.rootslocal.desktop",
    "~/Library/Saved Application State/org.rootslocal.desktop.savedState",
    "~/Library/WebKit/org.rootslocal.desktop",
  ]
end
