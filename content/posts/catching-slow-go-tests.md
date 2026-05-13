---
title: "Catching Slow Go Tests"
date: 2024-11-08T00:00:00+00:00
author: Talha Altinel
description: "Practical way of catching slow tests"
tags:
- go
- testing
slug: catching-slow-go-tests
canonicalURL: https://occamist.dev/posts/catching-slow-go-tests
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: qwelksdfkalf.webp
  alt: turtle-slow-performance
---

## The Problem

Hello, in this short and sweet post, I will show a handy bash script to catch slow go tests based on their durations and their go cache status, but first we need to define the problem.

Our current problem is when I run `go test -v ./...` we get simply huge output that is overwhelming with subtest outputs as well as t.Parallel pauses/continues. Plus, my inner
OCD strikes when some things are always cached and some things are always not cached, I could never guess why and I never have time to look at plain log that has 1 million lines.

So I came up with a solution that mimicks better output and displays what is cached or not. You could run this in your CI/CD pipelines etc... to keep track of test duration increases/decreases or test cache statuses.

## The Solution

One important note is that my solution only works for "passed" tests, if your tests are skipping or failing, my solution will ignore them.

For an example, I have used test file below replicated across some Guinea pig packages for representation purposes.

```go
import (
	"testing"
	"time"
)

func TestQuickSleep(t *testing.T) {
	time.Sleep(100 * time.Millisecond)
}

func TestMediumSleep(t *testing.T) {
	time.Sleep(500 * time.Millisecond)
}

func TestLongSleep(t *testing.T) {
	t.Run("Wait1.5Seconds", func(t *testing.T) {
		time.Sleep(1500 * time.Millisecond)
	})
	
	t.Run("Wait2.5Seconds", func(t *testing.T) {
		time.Sleep(2500 * time.Millisecond)
	})
}

func TestParallelSleep(t *testing.T) {
	t.Parallel()
	time.Sleep(750 * time.Millisecond)
}
```

This was roughly outputting this verbose output which is what `-v` means
sure, we could ignore using `-v` but then I have no idea which specific test case is causing issues and increasing its duration or ignoring its cache.
```
❯ go test -v ./...
?       github.com/lingua-sensei/lingua-sensei  [no test files]
=== RUN   TestQuickSleep
--- PASS: TestQuickSleep (0.10s)
=== RUN   TestMediumSleep
--- PASS: TestMediumSleep (0.50s)
=== RUN   TestLongSleep
=== RUN   TestLongSleep/Wait1.5Seconds
=== RUN   TestLongSleep/Wait2.5Seconds
--- PASS: TestLongSleep (4.00s)
    --- PASS: TestLongSleep/Wait1.5Seconds (1.50s)
    --- PASS: TestLongSleep/Wait2.5Seconds (2.50s)
=== RUN   TestParallelSleep
=== PAUSE TestParallelSleep
=== RUN   TestParallel2Sleep
=== PAUSE TestParallel2Sleep
=== CONT  TestParallelSleep
=== CONT  TestParallel2Sleep
--- PASS: TestParallel2Sleep (0.75s)
--- PASS: TestParallelSleep (0.75s)
PASS
ok      github.com/lingua-sensei/lingua-sensei/pkg1     (cached)
=== RUN   TestParallel2Sleep
=== PAUSE TestParallel2Sleep
=== CONT  TestParallel2Sleep
--- PASS: TestParallel2Sleep (0.50s)
PASS
ok      github.com/lingua-sensei/lingua-sensei/pkg2     (cached)
=== RUN   TestParallel2Sleep
=== PAUSE TestParallel2Sleep
=== RUN   TestParallel3Sleep
=== PAUSE TestParallel3Sleep
=== CONT  TestParallel2Sleep
=== CONT  TestParallel3Sleep
--- PASS: TestParallel3Sleep (0.50s)
--- PASS: TestParallel2Sleep (0.50s)
PASS
ok      github.com/lingua-sensei/lingua-sensei/pkg2/pkg3        0.504s
```


I have come up with this handy bash script below

```sh
#!/bin/bash

TEST_ARGS="${@:-./...}"

go test -v -json $TEST_ARGS \
  | jq -r '
    if .Action == "pass" and .Test != null then
      [.Package, .Test, (.Elapsed | tostring), ""] | join(",")
    elif .Action == "output" and (.Output | contains("ok")) then
      [.Package, "", "", .Output] | join(",")
    else
      empty
    end' \
  | awk -F, '
    BEGIN {
      line = "════════════════════════════════════════════════════════════════════════════════"
      printf "\n%-60s %-8s %s\n", "Test Name", "Duration", "Status"
      printf "%s\n\n", line
    }
    
    # Store results by package
    $2 != "" { 
      pkg_tests[$1][$2] = $3 
    }
    
    # Store package cache status
    $4 ~ /ok.*/ { 
      cached = ($4 ~ /cached/) ? "(cached)" : ""
      pkgs[$1] = cached
    }
    
    END {
      for (pkg in pkg_tests) {
        printf "%s:\n", pkg
        
        # Get all tests for each package and sort
        n = asorti(pkg_tests[pkg], sorted)
        for (i = 1; i <= n; i++) {
          test = sorted[i]
          printf "  %-58s %6.2fs %s\n", test, pkg_tests[pkg][test], pkgs[pkg]
        }
        printf "\n"
      }
      printf "%s\n", line
    }'
```

What happens is we use `jq` to filter the json format of our go tests then we use `awk` to make it pretty and it ends up as a result below

```
Test Name                                                    Duration Status
════════════════════════════════════════════════════════════════════════════════

github.com/lingua-sensei/lingua-sensei/pkg2/pkg3:
  TestParallel2Sleep                                           0.50s 
  TestParallel3Sleep                                           0.50s 

github.com/lingua-sensei/lingua-sensei/pkg1:
  TestLongSleep                                                4.00s (cached)
  TestLongSleep/Wait1.5Seconds                                 1.50s (cached)
  TestLongSleep/Wait2.5Seconds                                 2.50s (cached)
  TestMediumSleep                                              0.50s (cached)
  TestParallel2Sleep                                           0.75s (cached)
  TestParallelSleep                                            0.75s (cached)
  TestQuickSleep                                               0.10s (cached)

github.com/lingua-sensei/lingua-sensei/pkg2:
  TestParallel2Sleep                                           0.50s (cached)

════════════════════════════════════════════════════════════════════════════════
```

## The Ending

Thanks for reading, I swear I don't like bazel and shady shell scripts lying around my repos.

## References

- [Go: Find Slow Tests by Leigh](https://leighmcculloch.com/posts/go-find-slow-tests/)

