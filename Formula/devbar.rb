class Devbar < Formula
  desc "macOS menu bar app that monitors local dev servers and AI coding agents"
  homepage "https://github.com/yanirmanor/devbar"
  url "https://github.com/yanirmanor/devbar/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "f52c454ab8888ea25841299e908de45a4d3ab6b9f38f21c1dcbb4b0ccf851ea2"
  license "MIT"

  depends_on xcode: ["14.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/DevBar" => "devbar"

    # Build .app bundle for Spotlight / Raycast discovery
    app_dir = prefix/"DevBar.app/Contents"
    (app_dir/"MacOS").mkpath
    (app_dir/"Resources").mkpath
    cp buildpath/"assets/Info.plist", app_dir/"Info.plist"
    cp ".build/release/DevBar", app_dir/"MacOS/DevBar"
    cp buildpath/"assets/AppIcon.icns", app_dir/"Resources/AppIcon.icns" if (buildpath/"assets/AppIcon.icns").exist?
  end

  def post_install
    ln_sf prefix/"DevBar.app", "/Applications/DevBar.app"
  end

  def caveats
    <<~EOS
      DevBar has been added to /Applications.
      Open it from Spotlight, Raycast, or run:
        open /Applications/DevBar.app
      It will appear as a </> icon in your menu bar.
    EOS
  end

  test do
    assert_predicate bin/"devbar", :executable?
  end
end
