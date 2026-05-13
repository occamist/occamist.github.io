---
title: "Building Cross-Platform Magic: From GTK to Tauri"
date: 2025-08-02T00:00:00+00:00
author: Talha Altinel
description: "Meet my new cross-platform keyboard app built with Tauri"
tags:
- tauri
- typescript
- cross-platform
slug: building-cross-platform-magic-from-gtk-to-tauri
canonicalURL: https://occamist.dev/posts/building-cross-platform-magic-from-gtk-to-tauri
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: dlehn34ldlakiwtbx.webp
  alt: thai-language
---

In this post, I announce my newest project: a cross-platform on-screen keyboard that supersedes my previous virtual-keyboard work. Built with Tauri, it's faster, smaller, and works beautifully across Windows, macOS, and Linux.

## What does it solve?

This is a cross-platform on-screen keyboard for different languages. English (UK/US) keyboard inputs map to various languages. It's a complete rewrite of my previous virtual-keyboard project, built from the ground up with modern alternative.

{{< video src="/typing-thai.webm" >}}

## Why Tauri over GTK?

Having worked with Python GTK bindings before, the difference is night and day. Here's why Tauri wins:

**Bundle Size**: Python GTK apps are ultra large, Tauri apps are just a few megabytes instead of 100MB+ monsters.

**Cross-Platform Consistency**: Python GTK behaves differently across platforms and harder to rebuild across platforms. Tauri gives you the same smooth experience everywhere and makes it super easy to distribute across Linux/Windows/Macos.

**Developer Experience**: Modern frontend tools with minimal config = pure joy. Hot reloading, excellent tooling, easy logo customization, built-in asset bundlers and very easy to style the look.

**Closer to Native Feel**: Uses your system's webkit/webview instead of bundling an entire browser. Your app feels like it belongs on the platform plus it supports system tray icons and menu actions.

## Getting Started

You can build locally:
```bash
git clone https://github.com/occamist/keyboard-app
pnpm install
pnpm tauri build
```

Or I **strongly** recommend to download Tauri-made binaries directly from [releases](https://github.com/occamist/keyboard-app/releases).

Arch Linux users get special treatment, there's an [AUR package](https://aur.archlinux.org/packages/keyboard-app) waiting for you. Please upvote it! ;)


## Final Words

สุขสันต์วันภาษาไทย

July 29th marked the Thai Language Day, Happy Thai Language Day! 



Projects like this play a small role in supporting linguistic diversity by removing barriers to digital communication. Every language deserves easy access in our modern computing environments.

Found a bug? Spotted an issue? Have a brilliant idea to share? Don't hesitate to give me a nudge!
