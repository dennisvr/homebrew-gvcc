# DO NOT EDIT BY HAND.
#
# The version, urls and sha256s below are rewritten on every release by the
# `release` workflow in the private source repo (dennisvr/galvanized), which
# builds the binaries, attaches the tarballs to a Release on this repo, and
# pushes the bump here. Two things that workflow's substitutions depend on:
#   - the version line stays `  version "..."` at two spaces of indent
#   - each sha256 stays 64 lowercase hex chars on the line right after its url
#
# The 0.0.0 placeholders below are what an unreleased tap looks like; the first
# release replaces them.
class Gvcc < Formula
  desc "Compiler for the Galvanized programming language"
  homepage "https://github.com/dennisvr/homebrew-gvcc"
  version "0.4.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.4.1/gvcc-0.4.1-arm64-apple-darwin.tar.gz"
      sha256 "01b4e4400ea684e163d52ea6bdd74ed28b67fba192999d35c2d136f50718be9b"
    end
    on_intel do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.4.1/gvcc-0.4.1-x86_64-apple-darwin.tar.gz"
      sha256 "99c3edaa5f7242362b361294b97e17cf9f712429b8764b7452c78faaa335278e"
    end
  end

  on_linux do
    # gvcc compiles to LLVM IR and shells out to `clang` to link the result, so
    # a clang has to exist at RUN time. macOS has one via the Xcode Command Line
    # Tools (which Homebrew itself requires); on Linux nothing guarantees that,
    # so pull LLVM in and append it to PATH behind the user's own clang.
    depends_on "llvm"

    on_arm do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.4.1/gvcc-0.4.1-aarch64-linux.tar.gz"
      sha256 "55d0eb2f22b0e3365afa0b864be93eba7a3d6b6bc58b8d2cf6a69d2ad328ee7b"
    end
    on_intel do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.4.1/gvcc-0.4.1-x86_64-linux.tar.gz"
      sha256 "a4de04d937e2e9b55cb1ed3246f56f8849d1fc1b2c51f985ef80d8df058887fc"
    end
  end

  def install
    # gvcc resolves its stdlib as --stdlib > GALV_STDLIB > ./stdlib/ >
    # <binary-dir>/stdlib/, so the executable and the stdlib have to stay
    # together -- installing gvcc straight into bin would put the stdlib out of
    # its reach. Keep both in libexec and make bin/gvcc a thin exec wrapper,
    # the same shape as the source tree's install.sh launcher. The wrapper
    # exec's by full path, so argv[0] points at libexec and the lookup lands.
    libexec.install "gvcc", "stdlib"
    prefix.install "LICENSE", "NOTICE"

    if OS.linux?
      (bin/"gvcc").write_env_script libexec/"gvcc", PATH: "$PATH:#{Formula["llvm"].opt_bin}"
    else
      bin.write_exec_script libexec/"gvcc"
    end
  end

  test do
    (testpath/"hello.galv").write <<~GALV
      greet: string (w: string) {
          return "hi, {w}"
      }
      println(greet("brew"))
    GALV

    # Front end only (no clang): testpath has no ./stdlib, so passing here means
    # the wrapper really did find the stdlib installed beside the binary.
    system bin/"gvcc", "--check", "hello.galv"

    # Full path: emit IR, link it with clang, run the program.
    system bin/"gvcc", "hello.galv", "-o", "hello"
    assert_equal "hi, brew", shell_output("#{testpath}/hello").chomp
  end
end
