class Devbar < Formula
  desc "macOS menu bar app that monitors local dev servers and AI coding agents"
  homepage "https://github.com/yanirmanor/devbar"
  url "https://github.com/yanirmanor/devbar/archive/refs/tags/v1.5.1.tar.gz"
  sha256 "f72ebdac692ed0bc4038242a0b136cfe728e34abbf7a5737883f308ab9d0fd98"
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
    # Kill running DevBar before replacing
    system "pkill", "-x", "DevBar"
    sleep 1

    # Use osascript with admin privileges to bypass macOS App Management restrictions.
    # This prompts the user for their password via a native macOS dialog.
    app_source = prefix/"DevBar.app"
    system "osascript", "-e",
      "do shell script \"rm -rf /Applications/DevBar.app && " \
      "cp -R #{app_source} /Applications/DevBar.app\" " \
      "with administrator privileges"
  end

  def caveats
    <<~EOS
      DevBar has been installed to /Applications.
      You may be prompted for your password during installation.
      Open it from Spotlight, Raycast, or run:
        open /Applications/DevBar.app
      It will appear as a </> icon in your menu bar.
    EOS
  end

  test do
    assert_predicate bin/"devbar", :executable?
  end
end
