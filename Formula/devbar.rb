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
  end

  def caveats
    <<~EOS
      DevBar runs as a menu bar app. Start it with:
        devbar
      It will appear as a </> icon in your menu bar.
    EOS
  end

  test do
    assert_predicate bin/"devbar", :executable?
  end
end
