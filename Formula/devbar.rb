class Devbar < Formula
  desc "macOS menu bar app that monitors local dev servers and AI coding agents"
  homepage "https://github.com/yanirmanor/devbar"
  url "https://github.com/yanirmanor/devbar/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "db2c838809fb769d6c59555495c7bbeef5fa7e9dbcff00298bacfe05cb8a088a"
  license "MIT"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox",
           "--build-path", buildpath/".build"
    binary = buildpath/".build/release/DevBar"

    # Build .app bundle before bin.install moves the binary
    app_dir = prefix/"DevBar.app/Contents"
    (app_dir/"MacOS").mkpath
    (app_dir/"Resources").mkpath
    cp buildpath/"assets/Info.plist", app_dir/"Info.plist"
    cp binary, app_dir/"MacOS/DevBar"
    cp buildpath/"assets/AppIcon.icns", app_dir/"Resources/AppIcon.icns" if (buildpath/"assets/AppIcon.icns").exist?

    bin.install binary => "devbar"
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
