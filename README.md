# homebrew-gvcc

`gvcc` is the compiler for [Galvanized](https://github.com/dennisvr/galvanized),
a language exploring different ways to handle memory management and nullability.

## Install

```sh
brew tap dennisvr/gvcc
brew trust dennisvr/gvcc
brew install gvcc
```

The `brew trust` step is required. Homebrew 6 refuses to load formulae from
third-party taps until they are trusted explicitly, so without it `brew install`
fails with `Refusing to load formula dennisvr/gvcc/gvcc from untrusted tap`.
Trusting the tap covers its current and future formulae; if you would rather
grant the narrowest possible permission, use
`brew trust --formula dennisvr/gvcc/gvcc` instead and repeat it after each
upgrade.

Once the tap is trusted, the one-line form works too:

```sh
brew install dennisvr/gvcc/gvcc
```

## Usage

```sh
gvcc hello.galv -o hello   # compile and link
./hello
gvcc --check hello.galv    # front end only
```

## Requirements

gvcc lowers Galvanized to LLVM IR and shells out to `clang` to turn that into a
binary, so a clang has to be on your `PATH` at run time. On macOS the Xcode
Command Line Tools provide one (`xcode-select --install`); Homebrew requires
them anyway. On Linux the formula pulls in `llvm` for this reason and puts it on
`PATH` behind whatever clang you already have.

Two more tools are needed only by specific features, and neither is installed
for you: `pkg-config` for `gvcc build --system-deps`, and Conan 2.x for projects
that declare native dependencies in `build.gaml`.

## Upgrade & uninstall

```sh
brew upgrade gvcc
brew uninstall gvcc
```

## Releases

Binaries are prebuilt and attached to this repo's [GitHub Releases](https://github.com/dennisvr/homebrew-gvcc/releases). Each release ships one executable per platform — macOS Apple Silicon/Intel and Linux x86_64/ARM64 — with the Galvanized stdlib packaged alongside it, since gvcc resolves its stdlib from the directory holding the binary. The formula keeps that pairing by installing both into `libexec` and putting a wrapper in `bin`. The macOS builds are self-contained. The Linux builds link glibc dynamically and are produced on Ubuntu 24.04, so they need glibc 2.39 or newer. The `gvcc` source is not part of this repository.

Each build is a verified self-host: the checked-in IR seed produces a first
compiler, that compiler rebuilds itself, and the two generations must emit
byte-identical IR before the result is packaged.

Releases are published here automatically: CI in the private source repo builds
the per-platform binaries, creates the Release on this repo with the tarballs
attached, and commits the matching bump to `Formula/gvcc.rb`. The formula is
therefore generated — don't edit it by hand. The same workflow releases
[zinq](https://github.com/dennisvr/homebrew-zinq) from the same tag, so gvcc and
zinq share a version number.
