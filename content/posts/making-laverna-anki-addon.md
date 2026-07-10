---
title: "Making Laverna Anki Addon"
date: 2025-12-27T00:00:00+00:00
author: Talha Altinel
description: "Simplifying Anki Support with Laverna Anki Addon"
tags:
- go
- cli
- python
slug: making-laverna-anki-addon
canonicalURL: https://occamist.dev/posts/making-laverna-anki-addon
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: 6e8868d22596312e6f427afe064ae69b.webp
  alt: temple-image
---

Recently, I've been working on simplifying the Laverna CLI integration with Anki. What
seemed challenging during the planning phase turned out to be elegant in execution. Here's
a summary of the challenges and takeaways.

## The Original Workflow

Three months ago, I built an integration between Laverna CLI and Anki with this workflow:

1. User downloads a custom Cloze note type (`note-type.apkg`) from the repository and then imports to Anki (one-time setup)
2. User prepares CSV data in the expected format
3. User runs Laverna CLI, which outputs enriched CSV
4. User manually imports the CSV via Anki's deck import tab

Everything looked normal on the surface, but steps 1 and 4 were cumbersome and repetitive.
Since Anki doesn't provide an official SDK or REST API, I needed to find another approach.
Step 1 and 4 were also more error prone since it contained my internal app logic.

## Discovery

While researching, I discovered [Anki Connect](https://github.com/FooSoft/anki-connect)
which is an addon written as a single `__init__.py` file. Anki also has [documentation on
writing addons](https://addon-docs.ankiweb.net/intro.html). It was quite readable way to
interface with Anki.

Adding Python to a 100% pure Go repository felt strange, but I decided to build a proof of
concept since there was no other way to do it. I have tried sqlite3 reverse engineering of
Anki's DB but it was strongly disencouraged way.

The constraint was clear: I had to use [Anki's bundled Python
dependencies](https://github.com/ankitects/anki/blob/main/qt/pyproject.toml#L7-L19), which
vary by Anki version. Looking at Anki Connect's codebase, I noticed it used only standard
library and no external dependencies which was very outdated but safe approach, it
basically had to re-invent HTTPServer and HTTPClient via Unix sockets.

Fortunately, `flask`, `waitress`, `request`, and `jsonschema` were already available in
Anki's dependencies. I chose Flask (for HTTP abstractions) and Waitress (for the WSGI
server) since I needed an endpoint to receive enriched CSV data and trigger Anki's import
functionality.

One another constraint was we could only run the addon code after Anki application started
running. This meant that development workflow would need some sort of copy/paste or
symlinking workflow which was not pretty but doable. Basically Anki addons were zipped
`__init__.py` files which relied on Anki library and its dependencies and rarely vendored
addon dependencies with no solid dependency hashes.

## The Problem

Everything seemed fine until I hit an SQLite error:

```python
# __init__.py
from flask import Flask, jsonify
from waitress import serve
import threading
from aqt import mw

app = Flask(__name__)

@app.route('/')
def hello():
    note_count = mw.col.note_count()  # RuntimeError: Cannot access collection from a background thread
    return jsonify({'message': 'hello', 'notes': note_count})

def start_server():
    serve(app, host='127.0.0.1', port=5000)

thread = threading.Thread(target=start_server, daemon=True)
thread.start()
```

The issue: Anki's SQLite driver connection isn't thread-safe. The collection object
(`mw.col`) can only be accessed from Qt's main thread. The [documentation mentions
this](https://addon-docs.ankiweb.net/background-ops.html). Additionally, `__init__.py` can
not block so we run HTTP server in deamon mode :)

## The Solution

The solution was to use `mw.taskman.run_on_main()` to run queries on the main thread. But how do I collect the result and return it to my HTTP handler?

Check out Python's `Future` a concept:

```python
from concurrent.futures import Future

@app.route('/')
def hello():
    future: Future = Future()
    
    def get_count():
        try:
            count = mw.col.note_count()
            future.set_result(count)
        except Exception as e:
            future.set_exception(e)
    
    mw.taskman.run_on_main(get_count)

    try:
        note_count = future.result()
    except Exception as e:
        return jsonify({'error': str(e)}), 500

    return jsonify({'message': 'hello', 'notes': note_count}), 200
```

This blocks until `future.result()` returns and handles exceptions.

## Simplifying Further

I'm not a fan of try/catch boilerplate. After reading the [`note_count`
implementation](https://github.com/ankitects/anki/blob/main/pylib/anki/collection.py#L599-L600),
I decided to use tuples for error handling:

```python
from concurrent.futures import Future

@app.route('/')
def hello() -> tuple[Response, HTTPStatus]:
    future: Future = Future()
    
    def get_count() -> None:
        col = mw.col
        if col is None:
            return future.set_result((None, "Failed to load collection"))

        count = col.note_count()
        future.set_result((count, None))
    
    mw.taskman.run_on_main(get_count)

    (res, err) = future.result()
    if err is not None:
        return jsonify({"message": err}), HTTPStatus.INTERNAL_SERVER_ERROR
    
    return jsonify({'message': 'hello', 'notes': res}), HTTPStatus.OK
```

This pattern might not be "Pythonic," but it simplified everything beautifully.

![Future is now](/kgalasoqkasd.webp)

## Building the Full Logic

After the PoC worked, I implemented the complete solution ([see PR](https://github.com/occamist/laverna/pull/20/files#diff-785d7aa4d535d30185b30a6e7e86268639f3e01dd38185b84b6023f3dd21a151)):

1. Validate the incoming request
2. Perform Anki validations: create note type if missing, create deck if missing
3. Read CSV and import via Anki functions (mostly protobuf types)
4. Update Laverna CLI to POST directly to the addon's endpoint instead of writing files
5. Add flags and configuration options

## The New Workflow

Starting with Laverna v0.3.0, the workflow is much smoother:

1. User downloads Laverna Anki Addon from the official addon website (one-time setup)
2. User prepares CSV data
3. User runs Laverna CLI

```shell
❯ laverna anki --help
NAME:
   laverna anki - Downloads audios to anki media folder and generates anki CSV file

USAGE:
   laverna anki [options]

OPTIONS:
   --profile string, -p string  anki profile name
   --deck string, -d string     anki deck name
   --endpoint URL, -e URL       anki addon endpoint URL (default: "http://localhost:5555/v1/import-csv")
   --speed SPEED, -s SPEED      specify the SPEED of audios (default: "normal")
   --voice VOICE, -v VOICE      specify the VOICE of audios
   --shuffle                    shuffles the text choices per row (default: true)
   --strip-csv-header           strips the csv header from the generated anki CSV file (default: true)
   --stdout                     prints the generated anki CSV file to stdout (default: false)
   --help, -h                   show help

GLOBAL OPTIONS:
   --file FILE, -f FILE   filepath to prompt FILE
   --workers int, -w int  maximum number of concurrent downloads (default: 16)

Example:
laverna anki --profile Talha --deck my-viet-deck --voice vi --file ./anki-vi-example.csv
```

## Final

Happy new year to everyone!
