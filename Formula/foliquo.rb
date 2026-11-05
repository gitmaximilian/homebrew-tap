class Foliquo < Formula
  desc "Local browser workspace for noncommercial document translation"
  homepage "https://maximilianauer.at/projects/foliquo/"
  license "PolyForm-Noncommercial-1.0.0"

  depends_on macos: :sequoia

  on_macos do
    on_arm do
      url "https://github.com/gitmaximilian/Foliquo/releases/download/v0.13.0/Foliquo-Community-0.13.0-macOS-arm64.tar.gz"
      sha256 "1efb729d895ce5b86f117fa6611fd89a8694fa3e987a6fc1669ce4bd9e5e6a0c"
    end
    on_intel do
      url "https://github.com/gitmaximilian/Foliquo/releases/download/v0.13.0/Foliquo-Community-0.13.0-macOS-x64.tar.gz"
      sha256 "58bd8f7db34c34cd8945d627c7f4dfad81dac7687df038516d3b8ad73eff714a"
    end
  end

  def install
    libexec.install Dir["*"]
    (bin/"foliquo").write <<~SH
      #!/bin/sh
      exec "#{libexec}/runtime/node" "#{libexec}/bin/foliquo.mjs" "$@"
    SH
    (bin/"foliquo").chmod 0755
  end

  def caveats
    <<~EOS
      LibreOffice Writer is required for PDF/Word processing and export:
        brew install --cask libreoffice
      Verify exports: foliquo doctor
      Start: foliquo; stop: foliquo stop; update: brew upgrade foliquo
      Data: ~/Library/Application Support/Foliquo (preserved on uninstall).
      Migrate an old workspace: foliquo migrate --from /path/to/old/.local
      Foliquo Community uses PolyForm Noncommercial 1.0.0; commercial use is restricted.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/foliquo --version").strip
    cd libexec do
      system libexec/"runtime/node", "--input-type=module", "-e",
             "import s from 'sharp';await s({create:{width:1,height:1,channels:3,background:'red'}}).png().toBuffer()"
    end
    ENV["TRANSLATEOCR_SOFFICE"] = ENV["HOMEBREW_FOLIQUO_TEST_SOFFICE"] if ENV["HOMEBREW_FOLIQUO_TEST_SOFFICE"]
    ENV["FOLIQUO_DATA_DIR"] = (testpath/"private-data").to_s
    ENV["FOLIQUO_NO_BROWSER"] = "1"
    ENV["FOLIQUO_PORT"] = free_port.to_s
    pid = fork { exec bin/"foliquo" }
    begin
      sleep 3
      assert_match "foliquo", shell_output("curl --fail --silent http://127.0.0.1:#{ENV.fetch("FOLIQUO_PORT")}/api/health")
      system bin/"foliquo"
      system bin/"foliquo", "stop"
      Process.wait pid
      assert_path_exists testpath/"private-data/workspace.key"
    ensure
      begin
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
        # The child has already exited.
      end
    end
  end
end
