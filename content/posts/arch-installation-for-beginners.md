---
title: "Arch Installation for Beginners"
date: 2023-09-14T00:00:00+00:00
author: Talha Altinel
description: "Fast up and running setup with Archinstall"
tags:
- linux
- opensource
slug: arch-installation-for-beginners
canonicalURL: https://occamist.dev/posts/arch-installation-for-beginners
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: https://occamist.dev/qbqoshmoeu.webp
  alt: arch-linux-penguin
---

## Getting Started

&nbsp;&nbsp;&nbsp;&nbsp; Hello everyone, in this blog I will help you bootstrap your arch linux setup in 5-10 minutes, and teach you where you can look into when you need help. Arch Linux has been one of the most difficult distros to setup until the new convenient `archinstall` script.
I will be using `archinstall` script in this guide. It is known with its non-exhaustive user friendly TUI installation phase.

First of all, ensure you install the ISO from [Download Page](https://archlinux.org/download/), Arch is used within the whole world so don't be scared of picking the closest mirror to yourself. All the mirrors have SSL/TLS enabled, the contents are the same you don't need to worry about it. Also `archlinux-x86_64.iso` and `archlinux-YYYY.MM.DD-x86_64.iso` correspond to the same ISO, there is no difference.

Second of all, you need a software to burn the ISO, I used to use fedora media writer or opensuse image writer. But [Balena Etcher](https://etcher.balena.io/#download-etcher) is the cross-platform option for your own OS, after you insert the USB flash stick, just select the ISO and click burn or write.

## The Requirements

- USB flash stick (recommended space >= 2G)
- ISO burner/ISO writer software (Balena Etcher)
- The internet (either with reliable ethernet or wifi)
- The keyboard

## Setting up with Archinstall

After your burned the ISO then you plug in the USB flash stick and start the computer, you should see the classic Arch boot menu.

![Arch Boot Menu](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/sydvo7136ile4egomlx7.png)

![Arch Terminal](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/j9x0qjlzdmbkf8dcizs3.png)

Firstly, you will need an internet connection, if you have ethernet you can just plug the ethernet cable and continue. If you have wifi, you need to type a few commands then enter the password(passphrase).

```sh
root@archiso $ iwctl
[iwd] $ help
[iwd] $ device list
[iwd] $ station wlan0 scan
[iwd] $ station wlan0 get-networks
[iwd] $ station wlan0 connect YOUR_NETWORK_NAME
Passphrase: *********
[iwd] $ station wlan0 show
[iwd] $ exit
```

Then we write and enter `archinstall` to join TUI installation phase. There are couple of options presented to us;

```sh
root@archiso $ archinstall
```


#### Language

I pick English.

![Language](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/itraviplp3kmxa7k611v.png)


#### Mirror

I pick the closest mirror to me as a country.

![Mirror](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/a9n3avrobdcfwdburon7.png)

#### Locales

I pick my locales for my keyboard.

![Locale](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/27qxfhvs26nbfjhdntoj.png)

#### Disk configuration

I pick BTRFS with compression/subvolumes enabled and auto disk partitioning. Please skip the disk encryption as it complicates many things.

![disk partitioning](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/de26i2vqpdf1s4a5drvz.png)
![disk filesystem](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/kkai2f50c0dzv0o0m7gp.png)


#### Bootloader

I like the standard GRUB.

![Bootloader](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/t8x9r8tadw5jt5z3fjvz.png)

#### Swap

Always yes.

![Swap](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/f3bqzs73zk0absiyrpy1.png)

#### Hostname/Root Password/User Account

![Hostname](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/krwkbgm6l8wniic7pozm.png)

#### Profile

I pick Desktop/Gnome/all open-source drivers. You may need to pay attention to the drivers if you have NVIDIA driver.

![profile](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qqoe8sinmupzty19yzxy.png)
![profile-desktop](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/w2ziw8a5djy1z96m7iub.png)
![profile-drivers](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/u8jdguw79ze56k81n59n.png)

#### Audio

Pipewire for latest hardware, pulse for very old hardware.

![audio](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vynkwbvsg74uiliocuwn.png)

#### Kernel

- linux is the normal latest one. (I prefer this)
- linux-hardened is full of security therefore has lots of restraints.
- linux-lts is LTS (old) kernel.
- linux-zen is for performance machines with higher power usage such as gaming.

![Kernel](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5ke5erbwx6sxuwcqixqx.png)

#### Network Configuration

Pick network manager if you are using GNOME or KDE.

![network config](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7p5phliml0zwo8ww4jhg.png)

#### Timezone / Automatic Time Sync

I pick my timezone and enable automatic time sync as the clock changes in winter and summer times.

![Timezone](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ohkgqzc5slmeby4mykf6.png)

#### Install

Finally click on install and enjoy, you can remove the flash stick after it asks you to do so when installation finishes.

![Install End](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cporr7xq5h7hls2bqv91.png)


## Tuning Pacman

Pacman is the fastest package manager in the unixverse, but a little bit of tuning is required to make it skyrocket out of the roof. Big warning, once it is tuned, you will never enjoy mediocre package managers.

In `/etc/pacman.conf`, change `#color` row to `color`, add a below row under it `ILoveCandy`, also change `#ParallelDownloads = 5` to `ParallelDownloads = 10`, you can make the number higher as well if your internet is good.

We also need to set up `paccache` (pacman cache cleaner for weekly)

```sh
$ sudo pacman -S pacman-contrib
$ sudo systemctl enable paccache.timer
```

Lastly, let's edit `/etc/makepkg.conf`, change `MAKEFLAGS="-j4"` to `MAKEFLAGS="-j$(nproc)"`

## Pacman Cheatsheet

`dnf upgrade` equivelant, upgrades your whole system including the kernel

```sh
$ pacman -Syu
```

`dnf search` equivelant, only searches through official repos, not AUR

```sh
$ pacman -Ss xPackage
```

`dnf install` equivelant, installs the package to the system

```sh
$ pacman -S xPackage
```

`dnf remove` equivelant, removes the package from the system

```sh
$ pacman -Rs xPackage
```

`dnf list --all` equivelant, lists all the packages

```sh
$ pacman -Q
```

## Using AUR for Unofficial Packages

I will be showing how you can install Brave through AUR, AUR is everyone's ship to upload packages, you can make packages for anyone and upload it to AUR, so we need to be **EXTREMELY** careful while using AUR.

We will be downloading Brave from [brave-bin](https://aur.archlinux.org/packages/brave-bin), common Arch package convention is to rename packaged software accordingly; 

- abc (means build from stable version of the source)
- abc-git (means build from main branch of the source)
- abc-bin (means pre-built stable version binary)

We inspect URLs in PKGBUILD file for brave-bin to ensure we are not downloading the next crypto miner bot for our GPU.

```sh
$ mkdir AUR && cd ~/AUR
$ git clone https://aur.archlinux.org/brave-bin.git
$ cd ./brave-bin
$ less PKGBUILD
$ makepkg -si
```

**Important note**: DO NOT ever install an AUR helper, it is your job as an user to check every single AUR package before installing something, if something is not in official arch repo, use AUR wisely or even contribute to it!

## Enable Microcode

Microcode is a very low-level instruction set which is stored permanently in a computer, it helps your processor's power and computing efficiency.

For intel `intel-ucode`, for AMD `amd-ucode`

```sh
$ sudo pacman -S intel-ucode
```

## Enable Bluetooth

Sometimes bluetooth may not work on Linux in general but since you are on Arch, you just need a single package to make it work for every bluetooth driver out there. Remember this is not Linux's fault, it is the fault of hardware manufacturers  due to not open sourcing bluetooth drivers.

```sh
sudo pacman -S bluez bluez-utils
systemctl start bluetooth
sudo systemctl status bluetooth
sudo systemctl enable bluetooth

● bluetooth.service - Bluetooth service
     Loaded: loaded (/usr/lib/systemd/system/bluetooth.service; enabled; preset: disabled)
     Active: active (running) since Tue 2023-07-01 11:31:45 BST; 1 day 7h ago
       Docs: man:bluetoothd(8)
   Main PID: 633 (bluetoothd)
     Status: "Running"
      Tasks: 1 (limit: 76824)
     Memory: 3.0M
        CPU: 46.646s
     CGroup: /system.slice/bluetooth.service
             └─633 /usr/lib/bluetooth/bluetoothd
```


## Disable GRUB Screen

The thing is when you open your computer and see GRUB screen everytime, it could be annoying unless you have multiple OSes in a single machine. So I recommend to change your `/etc/default/grub`. Under GRUB settings, I change `GRUB_TIMEOUT_STYLE=countdown` to `GRUB_TIMEOUT_STYLE=hidden` to get rid of waiting on GRUB screen for 5 seconds. You can still visit GRUB screen with special Fx key on your machine.

## My Personal Taste of Software (Optional)

```sh
$ sudo pacman -S wget curl git neofetch sl cowsay fortune-mod lolcat nmap mandoc vlc thunderbird obsidian discord gimp converseen calibre libreoffice-still go kubectl docker terraform rsync nodejs pnpm vscode
```

Installing vscode on arch, requires a small metadata patching for vscode marketplace as this vscode is not closely connected to Microsoft telemetry or Microsoft binary directly. We will use AUR for this purpose, please inspect the contents of PKGBUILD and other scripts for your own safety all the time. If we don't patch our vscode marketplace, some plugins will be missing. **please ALWAYS inspect the contents please.**

```sh
$ cd ~/AUR
$ git clone https://aur.archlinux.org/code-marketplace.git 
$ cd ./code-marketplace
$ less PKGBUILD
$ makepkg -si
```

## Install Zsh (Optional)

Zsh is the fully fledged shell for end-users. You can install by doing `sudo pacman -S zsh` then run `chsh -s $(which zsh)`

After you have installed zsh, we will be theming with `ohmyzsh` and `powerlevel10k` and also couple of shell plugins such as `zsh completion`, `zsh autosuggestion`, `zsh highlighting`

The installation of ohmyzsh is quite straight forward but please do INSPECT the shell script for the peace of the mind;

```sh
$ wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
$ less install.sh
$ sh install.sh
```

Logout and login again and open your shell to complete prompted options.

The installation of powerlevel10k is a bit more different. You need to install manually these 4 fonts; MesloLGS NF "Regular, Bold, Italic, Bold Italic" then double click each .ttf file and click install. Here is the link to [the fonts](https://github.com/romkatv/powerlevel10k#manual-font-installation)

Let's now install powerlevel10k through our ohmyzsh settings.

```sh
$ git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Now we can set ZSH_THEME="powerlevel10k/powerlevel10k" in `~/.zshrc` file. And simply run `exec zsh && p10k configure`.

At least but not the last, if you check out [zsh users repository](https://github.com/zsh-users) we have 3 must zsh productivity plugins; completions, highlighting and autosuggestions. Let's install them one by one.

We install zsh-completions through ohmyzsh again. This will give you a custom CLI completion if a program provides its zsh completion.

```sh
$ git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
```

Add it to FPATH in your .zshrc by adding the following line before source "$ZSH/oh-my-zsh.sh"

```
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
```

Then we install zsh-syntax-highlighting and zsh-autosuggestions. This will give you correct text highlighting and autosuggestions from the previous terminal history.

```sh 
$ git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
$ git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Now modify `plugins=` in your `~/.zshrc` file.

```
plugins=( 
    # other plugins...
    zsh-syntax-highlighting
    zsh-autosuggestions
)
```

## Additional Help

If you get stuck or encounter a very difficult problem, you can check out the [forums](https://bbs.archlinux.org/), arch forums/wiki/AUR is what makes arch the best distro in the unixverse.


> “Power to the people”
>
> — <cite>Unknown</cite>