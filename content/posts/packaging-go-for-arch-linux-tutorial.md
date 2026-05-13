---
title: "Packaging Go for Arch Linux Tutorial"
date: 2023-09-17T00:00:00+00:00
author: Talha Altinel
description: "Publishing a package for Arch Linux"
tags:
- linux
- opensource
- go
slug: packaging-go-for-arch-linux-tutorial
canonicalURL: https://occamist.dev/posts/packaging-go-for-arch-linux-tutorial
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: https://occamist.dev/ce2sjxav94seo7etkvfd.webp
  alt: spiral-staircase
---

## Getting Started

&nbsp;&nbsp;&nbsp;&nbsp; In this tutorial, I will be showing how to package Go application for [Arch Linux User Repository (AUR)](https://aur.archlinux.org/). We will be opening an AUR account and go through PKGBUILD template and follow Arch's Wiki guidelines for Go. By the end of the tutorial, you will be able to upload your own Arch package that uses Go to AUR.

## The Requirements

- Git
- Go
- Arch Linux x86_64
- AUR account

## Setting up AUR account and SSH key

We will fill up the username and the email in this form, as well as the most important one public ssh key. The rest are optional.

![AUR sign up page](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/q5j6qlj76py28cm9kfba.png)

Generate and fill in the SSH public key..

```sh
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

```sh
$ cat ~/.ssh/aur_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDiniLTrxNbDH/R66BYUHieRT9sTqkn2678picCjF8MoTxsZume105hsDFSfg79pzfedY3iJQXMsCzk11pcnUNsGHxT/wh9s8aFrlI+n9JVMpEe7VOZqTLYyNBXtpAJUaY2Ptp4/l2p81dhpeCGTMhYNu2eDxaCaI5QvDOkyEmAZYAmuLT19OwJv8YW/1+1tg+Piaxyg/b+Dic7EeQQT10AI9drfRQG5pazREYkLGjClJP6pw/OnNcScMWR/Sd4phiz84DKnBLWXIIdbK+CDKDyFPt1FMIXkY1YSY+RAyXgJ3m1z6byCRs5BrN4RZArPcIEmVRRffkhq7tVBK0mwygTl8Hku60MqvdENLrylPcH3Ua2iqYLhftuMNfsZffUb9d5MI0BCaoQuzMfEMG0ZZZuDoZ38HZDjZbFFG0Fg+rt6IRTdRogZ0bzWacM0ig8J+HDnJnNIhXut5RC/f4W1RIXITujNp0blQRISrh9lGXcH/qz002ovcAoAd2yRkRdhh3NlP9mAZ/Rns47FwKP94ooG2/Zb2JRNJLJgdgaEWT+u1v5G4tPAoySxwZ0HBZSxSEmZC34piiPxdaHd6NAy3drt3Nt7QWVdBU9pD17lj8PsBuzXVReBkM+/0MFMLYDThunwVVhpZSHtmDTzWoGijIJnzaZrJMPcZZab/vF1WJ/yQ== talhaaltinel@hotmail.com
```

After you copy pasted your public ssh key into SSH public key box, change your `~/.gitconfig`

```
[url "ssh://aur@aur.archlinux.org/"]
        insteadOf = https://aur.archlinux.org/
        insteadOf = http://aur.archlinux.org/
```

Finally run the final command and input the answer of the form to confirm.

## Understanding PKGBUILD

If you inspect `/usr/share/pacman/PKGBUILD.proto`, you will see the fields you can fill.

```
# This is an example PKGBUILD file. Use this as a start to creating your own,
# and remove these comments. For more information, see 'man PKGBUILD'.
# NOTE: Please fill out the license field for your package! If it is unknown,
# then please put 'unknown'.

# Maintainer: Your Name <youremail@domain.com>
pkgname=NAME
pkgver=VERSION
pkgrel=1
epoch=
pkgdesc=""
arch=()
url=""
license=('GPL')
groups=()
depends=()
makedepends=()
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("$pkgname-$pkgver.tar.gz"
        "$pkgname-$pkgver.patch")
noextract=()
md5sums=()
validpgpkeys=()

prepare() {
	cd "$pkgname-$pkgver"
	patch -p1 -i "$srcdir/$pkgname-$pkgver.patch"
}

build() {
	cd "$pkgname-$pkgver"
	./configure --prefix=/usr
	make
}

check() {
	cd "$pkgname-$pkgver"
	make -k check
}

package() {
	cd "$pkgname-$pkgver"
	make DESTDIR="$pkgdir/" install
}
```

In summary, you don't have to fill all these fields but will be good to remember what they are.

- pkgname and pkgversion are the name of the software package and the version of the software you are providing. 
- pkgrel and epoch are additional way of subversioning the pkgversion, most of the time, you won't use
- pkgdesc is the description for your software, arch is architecture and most of the time, it is just x86_64
- url and license are the url of the software repository and the actual license name, these are quite important.
- groups provide us a way to install multiple software packages, think it like a gnome(very big software group)
- depends is runtime dependencies
- makedepends is compile-time dependencies
- checkdepends is check/test dependencies
- optdepends is optional runtime dependencies
- provides is used as alternative replacement for another package
- conflicts is used as to not install the conflicted package
- replaces is used as what this built package can replace
- backup lists files that should be backed up when upgrading the package
- options can include things like compiler flags, compression settings, etc.
- install can be used to specify custom installation scripts or commands to run during the installation process
- changelog does specify the location of a changelog or relase notes file
- source lists the source files required to build the package. It includes the URLs or file paths to the source code or other necessary files
- noextract lets you specify files that shouldn't be extracted during the build process
- md5sums, b2sums, sha512sums, sha256sums are checksums, they can also be skipped if not needed
- validpgpkeys is also similar to above checksums.

there are also 4 most common standard PKGBUILD shell functions such as;

- `prepare()` is used to make changes or apply patches to the source code before the build process begins
- `build()` is where the actual compilation or building of the software package takes place.
- `check()` runs tests to ensure that the software behaves as expected. It is used to verify the correctness of the package before installation
- `package()` puts the built files into a packaged format suitable for installation. It copies files into a temporary directory structure that mirrors the final installation directory.

## Create a .gitignore

Since we will be building multiple times to confirm our package, I highly recommend a good `.gitignore` to not accidentally push your artifacts. Below is my .gitignore file.

```
*
!/.gitignore
!/.SRCINFO
!/PKGBUILD
```

## Basic PKGBUILD for Go

From the thought of my mind, I have made a very simple `PKGBUILD` file for `k3sup` which is an amazing tool for bootstrapping k3s clusters. Please check [k3sup](https://github.com/alexellis/k3sup) out and support if you like.

**Friendly reminder for pkgname**; xyzpackage means a build from stable version of the source, xyzpackage-git means a build from the latest commit of the source, xyzpackage-bin means fetching prebuilt binary without build phase.

```sh
# Maintainer: Talha Altinel <talhaaltinel@hotmail.com>

pkgname=k3sup
pkgver=0.13.0
pkgrel=1
pkgdesc='A tool to bootstrap K3s over SSH in < 60s'
arch=('x86_64')
url='https://github.com/alexellis/k3sup'
license=('MIT')
depends=('openssh')
makedepends=('git' 'go>=1.20')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/alexellis/k3sup/archive/${pkgver}.tar.gz")
sha256sums=('24939844ac6de581eb05ef6425c89c32b2d0e22800f1344c19b2164eec846c92')
_commit=('1d2e443ea56a355cc6bd0a14a8f8a2661a72f2e8')

build() {
  cd "$pkgname-$pkgver"

  CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build \
    -ldflags "-s -w -X github.com/alexellis/k3sup/cmd.Version=$pkgver -X github.com/alexellis/k3sup/cmd.GitCommit=$_commit" \
    -o k3sup \
    .

  for shell in bash fish zsh; do
    ./k3sup completion "$shell" > "$shell-completion"
  done
}

package() {
  cd "$pkgname-$pkgver"

  install -vDm755 -t "$pkgdir/usr/bin" k3sup

  mkdir -p "${pkgdir}/usr/share/bash-completion/completions/"
  mkdir -p "${pkgdir}/usr/share/zsh/site-functions/"
  mkdir -p "${pkgdir}/usr/share/fish/vendor_completions.d/"
  install -vDm644 bash-completion "$pkgdir/usr/share/bash-completion/completions/k3sup"
  install -vDm644 fish-completion "$pkgdir/usr/share/fish/vendor_completions.d/k3sup.fish"
  install -vDm644 zsh-completion "$pkgdir/usr/share/zsh/site-functions/_k3sup"

  install -vDm644 -t "$pkgdir/usr/share/licenses/$pkgname" LICENSE
}
```

In my build phase, I compile the source to create a k3sup binary and I also run the binary to generate shell script completions. Give kudos to this functionality which comes from [spf13/cobra](https://github.com/spf13/cobra) Go library for CLIs.

In my package phase, I move the binary, the shell script completions and the license to correct places.

That all sounds cool and sweet but we are missing couple of things, so Arch Wiki has an extensive guide about this [here](https://wiki.archlinux.org/title/Go_package_guidelines) but long story short I need a program called `namcap` and when I do `sudo pacman -S namcap` then run namcap on PKGBUILD and produced .zst archive.

```sh
$ namcap ./PKGBUILD

$ makepkg -s && namcap k3sup-0.13.0-1-x86_64.pkg.tar.zst
k3sup W: ELF file ('usr/bin/k3sup') lacks FULL RELRO, check LDFLAGS.
k3sup W: ELF file ('usr/bin/k3sup') lacks PIE.
k3sup W: Dependency included, but may not be needed ('openssh')
```

the biggest surprise was all of arch guides actually only allowed specifically built type of Go binaries with CGO :( the above PKGBUILD was completely valid but if you want your package in the official arch repositories outside of AUR, you need to ensure FULL RELRO and PIE are satisfied. I won't be explaining these terms too much, it is essentially binary hardening for the extreme security.


## Security Hardened PKGBUILD for Go

```sh
# Maintainer: Talha Altinel <talhaaltinel@hotmail.com>

pkgname=k3sup
pkgver=0.13.0
pkgrel=1
pkgdesc='A tool to bootstrap K3s over SSH in < 60s'
arch=('x86_64')
url='https://github.com/alexellis/k3sup'
license=('MIT')
depends=('glibc' 'openssh')
makedepends=('git' 'go>=1.20')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/alexellis/k3sup/archive/${pkgver}.tar.gz")
sha256sums=('24939844ac6de581eb05ef6425c89c32b2d0e22800f1344c19b2164eec846c92')
_commit=('1d2e443ea56a355cc6bd0a14a8f8a2661a72f2e8')

build() {
  cd "$pkgname-$pkgver"
  export CGO_CPPFLAGS="${CPPFLAGS}"
  export CGO_CFLAGS="${CFLAGS}"
  export CGO_CXXFLAGS="${CXXFLAGS}"
  export CGO_LDFLAGS="${LDFLAGS}"
  export GOFLAGS="-buildmode=pie -trimpath -mod=readonly -modcacherw"

  go build \
    -ldflags "-s -w -X github.com/alexellis/k3sup/cmd.Version=$pkgver -X github.com/alexellis/k3sup/cmd.GitCommit=$_commit" \
    -o k3sup \
    .

  for shell in bash fish zsh; do
    ./k3sup completion "$shell" > "$shell-completion"
  done
}

package() {
  cd "$pkgname-$pkgver"

  install -Dm755 -t "$pkgdir/usr/bin" k3sup

  mkdir -p "${pkgdir}/usr/share/bash-completion/completions/"
  mkdir -p "${pkgdir}/usr/share/zsh/site-functions/"
  mkdir -p "${pkgdir}/usr/share/fish/vendor_completions.d/"
  install -Dm644 bash-completion "$pkgdir/usr/share/bash-completion/completions/k3sup"
  install -Dm644 fish-completion "$pkgdir/usr/share/fish/vendor_completions.d/k3sup.fish"
  install -Dm644 zsh-completion "$pkgdir/usr/share/zsh/site-functions/_k3sup"

  install -Dm644 -t "$pkgdir/usr/share/licenses/$pkgname" LICENSE
}
```

Now we run `namcap` again to verify after we run `makepkg`

```sh
$ namcap ./PKGBUILD

$ makepkg -s && namcap k3sup-0.13.0-1-x86_64.pkg.tar.zst                                                ✔  03:18:13  
k3sup W: Dependency included, but may not be needed ('openssh')
```

now it all looks amazingly secure at a binary level if your glibc version doesn't have a security vulnerability ;)

let's push it to the AUR now. Remember to renew `.SRCINFO` before every push. Also pay attention to already taken package names in AUR.

```sh
$ updpkgsums && makepkg --printsrcinfo > .SRCINFO
$ git init
$ git remote add origin https://aur.archlinux.org/k3sup.git
$ git add . && git commit -m "initial release"
$ git push -u origin master
```

## The End Result

- https://aur.archlinux.org/packages/k3sup

```sh
$ git clone https://aur.archlinux.org/packages/k3sup
$ cd ./k3sup && less ./PKGBUILD
$ makepkg -si
```

## The References

- [Arch Wiki](https://wiki.archlinux.org/title/creating_packages)
- [k9s](https://gitlab.archlinux.org/archlinux/packaging/packages/k9s/-/blob/main/PKGBUILD?ref_type=heads) 
- [goreleaser](https://gitlab.archlinux.org/archlinux/packaging/packages/goreleaser/-/blob/main/PKGBUILD?ref_type=heads)
- [k3sup](https://github.com/alexellis/k3sup)

> “Victory usually goes to the army who has better trained officers and men”
>
> — <cite>Sun Tzu</cite>