---
title: "A Christmas Gift for Language Learners"
date: 2024-12-24T00:00:00+00:00
author: Talha Altinel
description: "Meet Laverna CLI"
tags:
- go
- cli
slug: laverna-a-christmas-gift-for-language-learners
canonicalURL: https://occamist.dev/posts/a-christmas-gift-for-language-learners
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: akfg8124lkdfa.webp
  alt: laverna-image
---

In this post, I announce my newest tool for language learners. As long as I am learning a new language, I plan to maintain it.

## What is Laverna? What does it solve?

Laverna is a sleek command-line tool that transforms text into spoken audio. All it needs
is a config file to read. Whether you're practicing Thai greetings, perfecting your
Japanese pronunciation, or working on English phrases, Laverna can boost your productivity
when you want to store individual language audios.

## Getting Started

If you're a Go user, simply run `go install github.com/occamist/laverna@latest`
Not a Go developer? No problem! You can download ready-to-use binaries directly from [releases](https://github.com/occamist/laverna/releases/tag/v0.0.5).

After you have installed, simply create a YAML file such as example.yaml

```yaml
- speed: normal
  voice: th
  text: "สวัสดีครับ"
- speed: slower
  voice: en
  text: "Hello there"
- speed: slowest
  voice: ja
  text: "こんにちは~"
```

then pass along the command line as below.

```shell
laverna -file example.yaml
```

if you fancy the flags, here they are;

```text
Usage of laverna:
  -file string
        filename path that is used for reading YAML file
  -workers int
        maximum number of concurrent downloads (default 20)
```

Want to give Laverna a try this holiday season? Head over to [Laverna GitHub
Repository](https://github.com/occamist/laverna) and you can start creating your
personalized language learning audio. Happy Holidays and happy learning! 🎄🎧✨

Found a bug? Spotted an issue? Have a brilliant idea to share? Don't hesitate to give me a nudge!
