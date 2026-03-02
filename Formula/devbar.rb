class Devbar < Formula
  desc "macOS menu bar app that monitors local dev servers and AI coding agents"
  homepage "https://github.com/yanirmanor/devbar"
  url "https://github.com/yanirmanor/devbar/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "b947ee2fd2422443efbb5b1b8f0d378cfc627b04cbac10a10595066405f9fcf9"
  license "MIT"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox",
           "--build-path", buildpath/".build"
    binary = buildpath/".build/release/DevBar"
    bin.install binary => "devbar"

    # Build .app bundle for Spotlight / Raycast discovery
    app_dir = prefix/"DevBar.app/Contents"
    (app_dir/"MacOS").mkpath
    (app_dir/"Resources").mkpath
    cp buildpath/"assets/Info.plist", app_dir/"Info.plist"
    cp binary, app_dir/"MacOS/DevBar" if binary.exist?
    cp buildpath/"assets/AppIcon.icns", app_dir/"Resources/AppIcon.icns" if (buildpath/"assets/AppIcon.icns").exist?
  end

  def post_install
    system "rm", "-rf", "/Applications/DevBar.app"
    system "cp", "-R", (prefix/"DevBar.app").to_s, "/Applications/DevBar.app"
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
