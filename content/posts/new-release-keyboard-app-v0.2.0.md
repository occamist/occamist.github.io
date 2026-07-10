---
title: "New Release: Keyboard App v0.2.0"
date: 2025-09-06T00:00:00+00:00
author: Talha Altinel
description: "v0.2.0 comes with additions to the Keyboard App"
tags:
- tauri
- typescript
- cross-platform
slug: new-release-keyboard-app-v0.2.0
canonicalURL: https://occamist.dev/posts/new-release-keyboard-app-v0.2.0
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: keyboard-app-logo.png
  alt: thai-language
---

In this post, I will be announcing the new features and the existing struggles of my keyboard app.

## The Recap

Let's recap about "what does this app solve?" Onscreen keyboard app that uses English (UK/US) keyboard inputs to map to various languages.

{{< video src="/typing-thai.webm" >}}

## The New Features

New languages support such as German, Italian, Lao, Vietnamese. And a bug fix regarding
language specific fonts, this adjusts the natural font based on language choice. I was
quite fascinated how easy it was to add Vietnamese. Lao required me to evaluate font
choices but I liked how similar feel was to Thai Abugida. The Abugida composition was
beautifully handled by the font.

## The Struggles

The languages that made me struggle the most are Greek, Tibetan, and Korean. Making the total supported languages count 6.

Greek characters were straightforward; they didn't require additional fonts. However,
there is a specific diaeresis/dialytika mark that launches a different layout. I couldn't
find a solution to launch a third layout since my program supports a maximum of two
layouts per language.

Tibetan requires a specific font like Lao and Thai, which contributes to the growing
bundle size. The size is negligible; however, Tibetan has more than four layouts, which
requires an algorithm change to all layouts to perform "shift" key functionality on
different keys. This breaks the two-layouts-per-language rule in my app. But I have seen
these patterns in languages like Greek, so I may need to address this in the near future
to support more languages. Furthermore, Tibetan composition is completely handled by the
font so I am lucky with the embedded fonts.

Korean comes with its Hangul composition complexity. I initially thought Hangul
composition was handled by the fonts like in Thai, Lao, or other Indic Abugidas. It turns
out Hangul composition is handled by the IME (Input Method Editor of the specific OS), and
Tauri seems to be missing that layer. Re-writing Hangul composition is relatively hard and
requires derivations of existing methods in my project, and I am no expert in that area.
There were third-party libraries such as [khangul](https://github.com/dzikoysk/khangul);
however, it requires creating another input state in its context, which requires me to
juggle two different input states between language choices which is not cool for
maintainability of my project.

The interesting part I discovered was implementing NOOP buttons for Korean. It seems that
Korean Hangul is really running out of characters when the "shift" key is used. They have
no CAPS LOCK and fewer SHIFT variant keys, so some keys had to implement NOOP. This was
quite a different experience. Overall, I expected Korean fonts to resolve the need for
re-writing Hangul composition, but they didn't, so I am disappointed with the way Korean
(Hangul) characters work in composition. To add salt to the injury, undoing characters is
extremely complex with my own Hangul composition API or third-party Hangul composition
API.

## Final Words

Checkout the [releases](https://github.com/occamist/keyboard-app/releases) for v0.2.0

If you are Arch Linux user, Pauron bot got you covered with the [AUR package](https://aur.archlinux.org/packages/keyboard-app). Please upvote it! ;)

Found a bug? Spotted an issue? Have a brilliant idea to share? Don't hesitate to give me a nudge!
