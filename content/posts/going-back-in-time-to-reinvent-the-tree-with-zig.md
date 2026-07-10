---
title: "Going Back in Time to Reinvent the Tree with Zig"
date: 2026-01-04T00:00:00+00:00
author: Talha Altinel
description: "Do toy languages ever grow up to be the future?"
tags:
- zig
- tree
slug: going-back-in-time-to-reinvent-the-tree-with-zig
canonicalURL: https://occamist.dev/posts/going-back-in-time-to-reinvent-the-tree-with-zig/
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: bo-tree.webp
  alt: bodhi-tree
---

Over the Christmas holiday, I migrated the classic UNIX `tree` utility to Zig, creating a
modernized fork called [`bo`](https://github.com/occamist/bo). The original tree project
has been around since the 90s, displaying directory structures in a hierarchical format.
While the C codebase is elegant, it carries decades of legacy baggage. Obsolete platform
support, ancient Makefile, and preprocessing macros for long-dead operating systems.

The migration resulted in a lot of deleting which is a lot of fun and I replaced the
Makefile with Zig's build system, removed support for OS/2 and proprietary HP systems,
deleted the archaic `.lsm` metadata format, and embedded the man page directly into the
binary. This post walks through the technical decisions and trade-offs of modernizing a
30-year-old C project.

## Why Zig?

I wanted to work with systems code without writing C (there is nothing wrong with C, I
just prefer only reading it) and without dealing with C++'s "dogwater" tooling/stdlib or
fighting Rust's concept fatigue. Zig's killer feature is seamless C interop without FFI
bindings, the compiler itself is a cross-platform C compiler with extensive target
support. This makes it ideal for wrapping existing C code while gradually porting pieces
to Zig's more modern syntax. However, one could argue that seamless C interop is also its
biggest weakness, as it requires a deep understanding of C before you can rewrite it in
Zig. Plus, market forces aren't on Zig's side at this pre-v1.0 stage. Nonetheless, I find
it quite pleasing to work with. In fact, I managed to burn out my two-year-old laptop's
Intel CPU while compiling Zig from source in March 2025!

## Archaeology: Going Back in Time

Before diving into the build system, I needed to understand what I was inheriting. The original tree repository contained some interesting things:

**tree.lsm**: A Linux Software Map file from the 1990s. Between 1994-2000, developers
manually uploaded these metadata files to curated databases hosted on static web pages.
The LSM project shut down in the early 2000s. This file served no purpose in 2026.

**tree.1**: A man page written in groff syntax, cryptic to read and edit. I eventually
embedded this directly into the binary so users can run `bo man` without needing the
system `man` command installed.

**Makefile**: Surprisingly readable until I noticed the platform targets: HP/UX, HP
NonStop, and OS/2. The first two are proprietary HP systems that never ran open source
software anyway. OS/2 was IBM's post-DOS operating system, long extinct, but it had
infected the codebase with `__EMX__` preprocessor blocks throughout the C files.

Zig doesn't support these platforms (LLVM doesn't either). Breaking compatibility with
OS/2 meant I could delete hundreds of lines of conditional compilation. The trade-off was
obvious, lose support for <0.1% of theoretical users, gain a clean codebase and modern
cross-compilation for platforms people actually use.

## From Makefile to build.zig

With the archaeological survey complete, it was time to replace the Makefile with Zig's
build system. The goal was straightforward. Compile the existing C source files, link them
with a Zig entrypoint, and support cross-compilation without platform-specific Makefile
commands.

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = createExecutable(b, target, optimize);
    b.installArtifact(exe);

    makeRunStep(b, exe);
}

...
```

The build function is minimal: configure target and optimization, create the executable, and add a run step for convenience.

### Adding C Source Files

The meat of the build is in `createExecutable`, where I compile the original C source
files and link them with a Zig entrypoint at `src/main.zig`. Since I'm wrapping C code, I
need to explicitly link libc, Zig programs typically don't need this, but if you have C
dependencies, it will require it.

```zig
fn createExecutable(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const common_sources = [_][]const u8{
        "tree.c",
        "list.c",
        "hash.c",
        "color.c",
        "file.c",
        "filter.c",
        "info.c",
        "unix.c",
        "xml.c",
        "json.c",
        "html.c",
    };

    var sources_buf: [12][]const u8 = undefined;
    var num_sources: usize = 0;

    for (common_sources) |src| {
        sources_buf[num_sources] = src;
        num_sources += 1;
    }

    // Conditionally include strverscmp.c
    // Only include strverscmp.c if not Linux or if Android
    const needs_strverscmp = target.result.os.tag != .linux or target.result.abi == .android;
    if (needs_strverscmp) {
        sources_buf[num_sources] = "strverscmp.c";
        num_sources += 1;
    }

    const exe = b.addExecutable(.{
        .name = "bo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const sources = sources_buf[0..num_sources];
    const cflags = &[_][]const u8{
        "-std=c11",
        "-Wpedantic",
        "-Wall",
        "-Wextra",
        "-Wstrict-prototypes",
        "-Wshadow",
        "-Wconversion",
    };
    exe.addCSourceFiles(.{
        .files = sources,
        .flags = cflags,
    });
    addPreprocessorDefines(exe, target);
    exe.linkLibC();
    return exe;
}

...
```

Notice the conditional compilation at build.zig `strverscmp.c` is only included for
Android targets. This is because Android's bionic libc doesn't provide `strverscmp`,
unlike glibc on standard Linux systems. This workaround is temporary and inherited from
original codebase, I plan to port `strverscmp` to pure Zig to eliminate platform
conditionals entirely.

### C Preprocessor Macros

Zig's build system lets me define C preprocessor macros programmatically rather than
scattering them across Makefiles. The `addPreprocessorDefines` function handles
platform-specific C macros. The run step makes development ergonomic, `zig build run -- -L
2` runs the binary with arguments directly rather than the cumbersome `zig build &&
./zig-out/bin/bo -L 2`.

```zig
fn addPreprocessorDefines(exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    // Universal defines for large file support
    exe.root_module.addCMacro("LARGEFILE_SOURCE", "");
    exe.root_module.addCMacro("_FILE_OFFSET_BITS", "64");

    const os_tag = target.result.os.tag;
    switch (os_tag) {
        .linux => {
            exe.root_module.addCMacro("_GNU_SOURCE", "");
        },
        .solaris, .illumos => {
            exe.root_module.addCMacro("_XOPEN_SOURCE", "500");
            exe.root_module.addCMacro("_POSIX_C_SOURCE", "200112");
        },
        else => {},
    }

    if (target.result.abi == .android) {
        exe.root_module.addCMacro("_LARGEFILE64_SOURCE", "");
    }
}

fn makeRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Allow passing arguments
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the tree command");
    run_step.dependOn(&run_cmd.step);
}
```

---

**Cross-compilation without pain**: Want a macOS ARM binary? `zig build
-Dtarget=aarch64-macos`. Linux on ARM? `zig build -Dtarget=aarch64-linux-gnu`. No need to
install cross-toolchains or configure separate build environments. It is much easier to
produce binaries from 1 Linux machine for all major platforms.

**Embedded man page**: I added Python scripts to convert the original man page into a Zig
string constant. Now `bo man` displays help without requiring the system `man` command.
This is particularly useful in minimal environments like containers.

**One build system for them all**: The original Makefile had platform-specific rules for
HP/UX, Solaris, and others. Now `build.zig` handles everything declaratively based on the
target triple.

## Final

The full migration isn't complete, there are still C things I'd like to eliminate:

**Port strverscmp to Zig**: Currently, I conditionally compile `strverscmp.c` for Android
because bionic libc lacks it (see the [Android bionic
source](https://android.googlesource.com/platform/bionic/+/ics-mr0/libc/string/)). Porting
this function to pure Zig would remove platform-specific compilation entirely.

**Native Windows support**: The C codebase still relies on POSIX APIs that don't work on
Windows. If I port these sections to Zig's cross-platform standard library, Windows
becomes a first-class target without conditional compilation hacks.

**JSON parsing**: Use Zig's json parser instead of handrolled json.c

Modernizing legacy C projects is satisfying when you pick your battles carefully. Dropping
OS/2 support was trivial, nobody cares about IBM's 1990s operating system. The payoff was
deleting hundreds of lines of preprocessor cruft.

Zig's C interop makes incremental migration practical. I didn't need to rewrite everything
upfront, wrap the C in a build.zig, add a Zig entrypoint, then port pieces over time as
needed.

The [tree](https://oldmanprogrammer.net/source.php?dir=projects/tree) →
[bo](https://github.com/occamist/bo) migration took a weekend, resulted in less code, and
now cross-compiles to dozens of targets from a single command. Not bad for a holiday
project.
