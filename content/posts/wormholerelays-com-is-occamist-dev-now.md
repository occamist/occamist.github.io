---
title: "Wormhole out, Occam in"
date: 2026-05-20T00:00:00+00:00
author: Talha Altinel
description: "Wormholerelays.com is Occamist.dev now"
tags:
- summary
slug: wormholerelays-com-is-occamist-dev-now
canonicalURL: https://occamist.dev/posts/wormholerelays-com-is-occamist-dev-now
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: occam.webp
  alt: william-of-ockham
---

Spring cleaning season is upon us! I just wanted to announce some new changes and focus on
new hobby projects while summarizing what I have been up to in the last 5-6 months.

## Bo (my tree tree fork)

I must say, this went through four distinct phases: easy at first, then hard, then easy
again once the C interop settled, then hard again when it became fully Zig with Zig's C
types.

Initially, I saw [tree](https://github.com/Old-Man-Programmer/tree) utility being 5000
lines and no big dependencies. And I decided to take on legendary "re-write in Rust"
challenge, just joking, I wanted to understand how an ancient project would be ported to
"Zig" gradually without making crazy breaking changes and 1M lines of diffs like [the
famous bun PR](https://github.com/oven-sh/bun/pull/30412) and "Zig" was the perfect
candidate here because of its strong C interoperability (not C++ unfortunately).

It started off as simple project, I ported the project from Makefiles to Zig build system
as mentioned in my previous post. I also started writing Zig code as "strangler fig"
approach, it is an approach that you should start from the leaves of the tree and slowly
swallow the whole tree. What does that exactly mean? If you think of execution traces of a
program, it is essentially a tree, you don't target the trunk or the branches or the
sub-branches first, you target the leaf functions. Then from C, you call the Zig
implementations.

I have been saying this for a while but Zig's strongest strength is also the weakest
selling point. The ability to port PhD level C macros to Zig macros is not easy at all.
Constants sure, platform specific substitutions sure, but there are very complex C macros
that lurk in C codebases which still can not be expressed easily in Zig without making
changes or simplifying C macros in C files. Luckily, my upstream was very inactive so if I
made a small patch to the C headers, I wouldn't get conflicts for a looooong time, so I
had to simplify some C macros before turning into Zig.

Things have become easier when I reached 100% Zig and removed last C header file. But I
have hit another point. Basically, when you complete "strangler fig" pattern, you realize
your files are Zig but nothing imports each other since they are linked as static objects
like C does and most of the source code is C slices or C null-terminated arrays or full of
C pointer types. Zig truly made porting easier, however at the end of "strangler fig"
pattern, you don't reach the most idiomatic Zig code, you reach this archaic point of Zig
that looks like C but still valid Zig and has partial memory safety compared to idiomatic
Zig if you are passing Zig's allocator to every single place along with Zig's io (Zig
0.16.0 made io necessary everywhere).

So I am happy to hit the last hard point of porting, which is making everything more Zig
idiomatic. But honestly, I wouldn't recommend porting C projects to Zig. It is quite
mentally-taxing twice, goes back to "if aint broke, don't fix it". Therefore, I would be
maintaining my fork less than a usual hobby project. I still love Zig as an educational
language or a compiler toolchain but I wouldn't port anything to it as a language even if
it happens gradually.

Sure, LLMs can help you tremendously for translating and interop testing against the
original tree CLI, however you are very likely to give up with behaviour regressions and C
ABI differences and worst of all non-idiomatic code that doesn't look like whatever you
are porting to as a language. And even sometimes, there is no equivalent of things that is
in your new language, that existed in "libc" of your platform, [the famous locale-aware
string comparison](https://github.com/occamist/bo/blob/main/src/cstd.zig#L107), this makes
system programming languages really tough and less cross-platform.

## Nawa (my container management system)

Well, I have been checking these new contenders (coolify written in
php-laravel-blade-templates, dokploy written in typescript-node-react) in this space which
want to simplify Infrastructure as a Service to simple management UIs. I looked at head to
head comparisons but features felt excessive and I didn't like some approaches when it
came to self-hosting. I don't like over-blown features so I took a look at my more basic
approaches such as only docker container management UIs such as "portainer, dockge,
arcane".

Portainer is the most mature one and the one I used to use when I did self-hosting for
some customers 3 years ago. However, portainer really falls short on docker compose files
and being able to drag-and-drop those files and re-setup same infrastructure multiple
times. So, "dockge" the minimal UI takes this approach very well, you have docker compose
file, you drop these to your dockge container's volumes and it handles it very well.
Ideally, I really liked this approach. However feature wise, what I really loved was
"arcane", it had perfect feature parity, and I liked security scanning of images
automatically and auto-updates. I also found the UI super simple, along with simple user
management and OIDC login which is lacking in other alternatives.

So I have shifted my hobby project time to "Nawa", I am mixing both "dockge" and "arcane"
features with crystal clear UI. It is not really easy for me to handle frontend since my
frontend knowledge is more rusty. But keeping it vanilla typescript with Astro really
served me well, lazy approach and no crazy frameworks. Here is some sneak peek:

![Nawa-dashboard](/nawa-dashboard.webp)
![Nawa-containers](/nawa-containers.webp)
![Nawa-logs](/nawa-logs.webp)
![Nawa-images](/nawa-images.webp)

## Wormholerelays.com to Occamist.dev

I have switched my domain to something simpler and more pragmatic, "occam" was the first
programming language that implemented "CSP" (communicating sequential processes) paper. So
"occamist.dev" is born. I have also changed github username from "mrwormhole" to
"occamist" since I actually live in the same county (Surrey) "William of Ockham" lived

William of Ockham was also the medieval philosopher who coined the term "Occam's razor"
which means the simplest solution with the least amount of assumptions yield better
long-term benefits and correctness as a solution. To understand more of "Occam's razor in
Software Engineering", I highly recommend [this blog
post](https://naveenkumarmuguda.medium.com/occams-razor-in-software-development-56ee3e8b8ce8)
by Naveen Muguda.

I also associated "wormhole" as being more nerdy, deep-thinker nature and endless
assumptions/worst-cases in my nickname choice hence why I used for years since my DOTA
life at early 13s-14s, and now "occam" is more concise and pragmatic version of thinking
with less complex assumptions and direct to simple obvious approaches with quantifiable
real life data.

## Final Words

Me and my brother have become full UK citizens and my paperwork debt is lowered now, it
sounds cool to have dual citizenship but after naturalisation, I decided to give up on my
initial citizenship, the paperwork effort and having two passport renewal fees didn't seem
pragmatic. Here is a picture with me and my brother in the ceremony.

![citizenship](/uk-citizenship.webp)

Yes, of course I had a chat about all the medals of the gentleman.
