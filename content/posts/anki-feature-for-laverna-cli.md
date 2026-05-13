---
title: "Anki Feature For Laverna CLI"
date: 2025-10-08T00:00:00+00:00
author: Talha Altinel
description: "Boost your Anki decks with Laverna CLI"
tags:
- go
- cli
slug: anki-feature-for-laverna-cli
canonicalURL: https://occamist.dev/posts/anki-feature-for-laverna-cli
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: MYadhrkenNg.webp
  alt: jellyfish-image
---

In this post, I announce an overhaul for Laverna CLI and new version which supports the new subcommands such as `run` and `anki`.

## The Recap

In this blog [post](https://occamist.dev/posts/a-christmas-gift-for-language-learners) I have introduced Laverna CLI which was a language learning tool designed to swallow Google's speech API. It was immensely useful but it lacked some features such as Anki integration.

## The New Anki Integration

Starting with `v0.1.0`, users can use the new `anki` command to create anki decks with laverna CLI.

Now with the most amazing Go project [urfave/cli](https://github.com/urfave/cli), it was super easy to support subcommands and flags of subcommands. I was happy to dodge spf13/cobra's complexity. 

And the previous default `laverna` command is now same as `laverna run` to keep the sweet backward compatibility. Plus we get shell completions for bash/zsh/fish as well. Make sure to check it out [here](https://github.com/occamist/laverna#shell-completions)

```sh
❯ laverna --help
NAME:
   laverna - A new cli application

USAGE:
   laverna [global options] [command [command options]]

DESCRIPTION:
   Download Google Translate audios as mp3 files

COMMANDS:
   run      Downloads audios
   anki     Downloads audios to anki media folder and generates anki CSV file
   help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --file FILE, -f FILE   filepath to prompt FILE
   --workers int, -w int  maximum number of concurrent downloads (default: 16)
   --help, -h             show help
```

```sh
❯ laverna anki --help
NAME:
   laverna anki - Downloads audios to anki media folder and generates anki CSV file

USAGE:
   laverna anki [options]

OPTIONS:
   --profile string, -p string  anki profile name
   --speed normal               specify the speed of audios, must be one of these values: `normal`, `slow`, `slowest` (default: "normal")
   --voice string               specify the voice of audios
   --shuffle, -s                shuffles A,B,C,D choices per row (default: true)
   --strip-csv-header, --strip  strips csv header from the generated anki CSV file (default: true)
   --help, -h                   show help

GLOBAL OPTIONS:
   --file FILE, -f FILE   filepath to prompt FILE
   --workers int, -w int  maximum number of concurrent downloads (default: 16)

```

For the new `anki` command, you need to provide a CSV file, a voice name and your anki profile name. Profile name is pretty much for determining your Anki media folder so that downloaded audios get stored there. Voice name is Google's language ISO code for the specific voices. The CSV file is where all the things are defined.

Your CSV file should look like below.

```csv
Text,HelperText,TextA,TextB,TextC,TextD
ฉันชอบ{{c1::ฟัง}}เพลง,I like to listen to music,ฟัง,เล่น,ดู,อ่าน
```

- It must have the text that uses "{{c1:ANSWERWORD}}" for the cloze of note types.
- It must specify the helper text which is a sentence for the reader to translate.
- It must have 4 text choices to guess the answer word.

Then we can run `laverna anki --profile Talha --voice th --file thai.csv` and it will output our actual CSV deck to be imported into Anki, by the time this command runs we get all the audios.

The below CSV will be called "Athai.csv", "A" postfix indicates the audio filenames that were created in media folder of Anki. It is a reference to the unique audio files.

```csv
ฉันชอบ{{c1::ฟัง}}เพลง,I like to listen to music,ฟัง,เล่น,ดู,อ่าน,[sound:a.mp3],[sound:b.mp3],[sound:c.mp3],[sound:d.mp3],[sound:e.mp3]
```

Finally, if you have imported the [Cloze Multi Choice Audio note type](https://github.com/occamist/laverna/blob/main/note-type.apkg) into Anki, you can go ahead and import the CSV in `File > Import > Select CSV` then choose `Cloze Multi Choice Audio` note type and pick delimeter as comma.

## Final words

The best thing about this approach is you can sync whole media with Anki Sync so that you don't need to manage storage in your devices manually. And this is very exciting if you have Anki mobile app on your phone, you can really make the most of your time with learning languages.

The CSV inputs can be generally generated via Gemini, in the future I plan to wrap Gemini API inside the Laverna CLI but there is no certain roadmap as I am testing it for now. I am currently testing Gemini's Vietnamese word generation, example CSV can be found [here](https://github.com/occamist/laverna/blob/main/testdata/anki-vi-example.csv)
