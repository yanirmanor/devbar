class Devbar < Formula
  desc "macOS menu bar app that monitors local dev servers"
  homepage "https://github.com/yanirmanor/devbar"
  url "https://github.com/yanirmanor/devbar/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "b4e96b7e14e81fc2b70ade6386da851629b0d27607a11bdda367ef51fc5bf33b"
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
