---
title: "Pauron: New Automation Bot for AUR"
date: 2025-07-02T00:00:00+00:00
author: Talha Altinel
description: "Easier AUR package maintenance"
tags:
- python
- linux
- opensource
slug: pauron-new-automation-bot-for-aur
canonicalURL: https://occamist.dev/posts/pauron-new-automation-bot-for-aur
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: fb67c9ad61316fe3651.webp
  alt: sauron-image
---

I have been quiet for a few months, the reason being I had an opportunity to develop new interesting things and I have been experimenting with some other technologies while trying to find the best use cases.

Meanwhile, I received a comment about a package that I have been maintaining for Arch Linux and I had no available time to respond or update my AUR package. If you remember from my previous post [Packaging Go for Arch Linux Tutorial](https://occamist.dev/posts/packaging-go-for-arch-linux-tutorial), I like maintaining AUR packages but it gets time consuming when you need to track new releases and update version, SHA and commit hashes manually by hand. I had to come up with my own niche solution.

![The AUR Thread](/aur-comments.png)

## What is Pauron? What does it solve?

I dedicated a day and created [Pauron](https://github.com/occamist/pauron), when you have lame problems, you solve them with lame languages. Pauron is essentially a single file program that checks the upstream GitHub URL for your AUR package, if there is no newer version, it will not do anything. If there is a newer version, it will patch required values in PKGBUILD and .SRCINFO then push it to AUR with a new commit.

This solves a lot of manual hand tasks such as entering a new version, entering a new SHA hash and entering a new commit hash which is mentioned on my [previous post](https://occamist.dev/posts/packaging-go-for-arch-linux-tutorial) about AUR packages.

## Getting Started

Pauron is meant to be run on github actions, but you can do a cron job on anywhere else if you prefer. I have been using YAML file below to periodically run it. If you have more than one package, you can specify it with `-p` equivelant to `--pkg-name` like below. You should also setup `AUR_SSH_KEY` env variable which is your private SSH key for AUR. 

To try it out, you can fork my repository and adjust your github actions along with `AUR_SSH_KEY` secret if you have AUR account or interested in AUR package maintenance.

```yaml
name: Update AUR packages

on:
  # Manual trigger
  workflow_dispatch:

  # Cron trigger on the 22nd of every month at 00:00 UTC
  schedule:
    - cron: '0 0 22 * *'

jobs:
  update-k3sup-aur:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.13"

      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install -y python3-pip
          pip3 install requests

      - name: Update AUR package
        env:
          AUR_SSH_KEY: ${{ secrets.AUR_SSH_KEY }}
        run: |
          python main.py -p k3sup
```

Or you can simply use [Pauron PyPI package](https://pypi.org/project/pauron/) with `pipx` which is the "RECOMMENDED" way.

```sh
AUR_SSH_KEY="$(cat ~/.ssh/pauron)" pipx run pauron -p k3sup
```

The normal output if your package is up to date will look like below:

```
> Run python main.py -p k3sup
INFO: SSH key fingerprint: 256 SHA256:TwGFdHlbNpteILDQx4/cOXD/PiDNnq2C9B/0h7XsteA pauron@pauron.com (ED25519)
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
INFO: Added AUR host key to known_hosts
INFO: SSH test completed with exit code: 1
INFO: SSH stderr: Welcome to AUR, occamist! Interactive shell is disabled.
Try `ssh aur@aur.archlinux.org help` for a list of commands.

INFO: Processing AUR package: ssh://aur@aur.archlinux.org/k3sup.git
INFO: Cloning ssh://aur@aur.archlinux.org/k3sup.git
INFO: Parsing PKGBUILD...
INFO: Extracted metadata:
INFO:   pkgver: 0.13.9
INFO:   sha256sums: ('4764f787f55fae4dab9527c5d829fc70a522e1c2b7f7a23cde6df1096fefbc31')
INFO:   _commit: ('a1700f64dcffd249890b13cf6d97f4c120a53e08')
INFO:   source: ("${pkgname}-${pkgver}.tar.gz::https://github.com/alexellis/k3sup/archive/${pkgver}.tar.gz")
INFO:   owner_name: alexellis
INFO:   repo_name: k3sup
INFO: Checking for latest Github release version...
INFO: Newest Github version(0.13.9) and current PKGBUILD version(0.13.9) are same, quitting.
```

If the package is not up to date, the output will look like below:

```
> Run python main.py -p k3sup
INFO: SSH key fingerprint: 256 SHA256:TwGFdHlbNpteILDQx4/cOXD/PiDNnq2C9B/0h7XsteA pauron@pauron.com (ED25519)
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
# aur.archlinux.org:22 SSH-2.0-OpenSSH_10.0
INFO: Added AUR host key to known_hosts
INFO: SSH test completed with exit code: 1
INFO: SSH stderr: Welcome to AUR, occamist! Interactive shell is disabled.
Try `ssh aur@aur.archlinux.org help` for a list of commands.

INFO: Processing AUR package: ssh://aur@aur.archlinux.org/k3sup.git
INFO: Cloning ssh://aur@aur.archlinux.org/k3sup.git
INFO: Parsing PKGBUILD...
INFO: Extracted metadata:
INFO:   pkgver: 0.13.7
INFO:   sha256sums: ('b0c15f99aef35f7bb2dda45b08c2acaa7f6289fa8544f64e3fdaa07892a466a1')
INFO:   _commit: ('b7bb7cb246eb639629f204c2aca2b446bfb4b244')
INFO:   source: ("${pkgname}-${pkgver}.tar.gz::https://github.com/alexellis/k3sup/archive/${pkgver}.tar.gz")
INFO:   owner_name: alexellis
INFO:   repo_name: k3sup
INFO: Checking for latest Github release version...
INFO: SHA256 hash for release tag(0.13.9): 4764f787f55fae4dab9527c5d829fc70a522e1c2b7f7a23cde6df1096fefbc31
INFO: Commit hash for release tag(0.13.9): a1700f64dcffd249890b13cf6d97f4c120a53e08
INFO: PKGBUILD file was updated successfully
INFO: .SRCINFO file was updated successfully
[master 4e17155] v0.13.9
 2 files changed, 6 insertions(+), 6 deletions(-)
To ssh://aur.archlinux.org/k3sup.git
   78947de..4e17155  master -> master
INFO: Successfully committed and pushed 0.13.9
```

Quick note: the upstream source URL needs to be GitHub since I use GitHub API to determine latest release versions but feel free to PR or make an issue about any other version control systems such as GitLab
if you think it is useful to have!