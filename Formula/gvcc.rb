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
  version "0.2.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.2.1/gvcc-0.2.1-arm64-apple-darwin.tar.gz"
      sha256 "442650e50613868704cbf48b55681d10a6cc93412ab4e3d4f52821efe14be2e1"
    end
    on_intel do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.2.1/gvcc-0.2.1-x86_64-apple-darwin.tar.gz"
      sha256 "39ad4538d3b3527f130c4e7b203d3c841fc62aeeb1d14f0ca80c8ea12265fde7"
    end
  end

  on_linux do
    # gvcc compiles to LLVM IR and shells out to `clang` to link the result, so
    # a clang has to exist at RUN time. macOS has one via the Xcode Command Line
    # Tools (which Homebrew itself requires); on Linux nothing guarantees that,
    # so pull LLVM in and append it to PATH behind the user's own clang.
    depends_on "llvm"

    on_arm do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.2.1/gvcc-0.2.1-aarch64-linux.tar.gz"
      sha256 "cf7297117385a85f2dd6adfe38bd7b0e325fe02120b6a8e83b61b62ca5edde19"
    end
    on_intel do
      url "https://github.com/dennisvr/homebrew-gvcc/releases/download/v0.2.1/gvcc-0.2.1-x86_64-linux.tar.gz"
      sha256 "d8f2e76c400a87ff10d5cce54487d9321e8b652040b8d12cd21df517c7fb7ce4"
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
