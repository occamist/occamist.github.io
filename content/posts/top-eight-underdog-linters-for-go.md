---
title: "Top 8 Underdog Linters for Go"
date: 2025-02-06T00:00:00+00:00
author: Talha Altinel
description: "Spice your codebase with linters"
tags:
- go
- linter
slug: top-eight-underdog-linters-for-go
canonicalURL: https://occamist.dev/posts/top-eight-underdog-linters-for-go
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: lJJlaUWYrPE.webp
  alt: pug-image
---

In this post, we will go over the most unknown 8 linters that are not used by the most
people. These linters overall look unimportant, however they end up winning the hearts
with their humbleness. If this sounds interesting, let's start.

## 8 Godox

```yaml
# .golangci.yaml
linters-settings:
  godox:
    # Report any comments starting with keywords
    keywords:
      - TODO
      - BUG
      - FIXME
      - OPTIMIZE
      - HACK
```

```go
// TODO: what the hell is this
// hacky logic here
```

```shell
❯ golangci-lint run ./...
main.go:18:2: main.go:18: Line contains TODO/BUG/FIXME/OPTIMIZE/HACK: "TODO: what the hell is this" (godox)
// TODO: what the hell is this
```

[Godox](https://github.com/matoous/godox) checks the comments and dunks a linter error if
unwanted comment is written with specific keywords. I encountered this linter after an
incident that caused a prod deployment blockage due to me deleting TODO and hacky code
section that were passing on all tests except prod environment tests. Long story short,
there was no way for me to avoid TODO section logic because my task was interferring with
already written hacky solution.

The whole aim of this linter is to avoid this hackyness in the first place. Need a TODO?
great, you can open a jira ticket and communicate with others instead of going the hacky
route and throwing TODO for the next victim 😄 I am very big fan of this linter after that
nasty experience.

## 7 Gci

```yaml
# .golangci.yaml
linters-settings:
  gci:
    custom-order: true
    sections:
      - standard # Standard section: captures all standard packages.
      - default # Default section: contains all imports that could not be matched to another section type.
      - prefix(github.com/myorg/myproject) # Custom section: groups all imports with the specified Prefix.
```

```go
import (
	"context"
	"flag"
	"github.com/myorg/myproject/abc"
	"github.com/sourcegraph/conc"
	"log"
	"os"
	"runtime"
)
```

```shell
❯ golangci-lint run ./...
main.go:6:1: File is not properly formatted (gci)
        "github.com/myorg/myproject/abc"
^
main.go:10:1: File is not properly formatted (gci)
        "runtime"
^
```

[Gci](https://github.com/daixiang0/gci) is very similar to what `goimports` does but
manages import blocks the custom way that respects standard, 3rd party and local project
imports. Basically more strict `goimports` that is visually pleasant to look at.

I had initially not considered something like this given the fact that `goimports` is good
enough, but between different editors, I saw the issue that insertion of import line
differs between X editor and Y editor due to automatic completions. On top of that
`goimports` were passing as long as in the same block things were sorted. I didn't like
the idea of having standard, 3rd party and local project imports in 1 block since it
turned into a soup of imports.

## 6 Revive's exported

```yaml
# .golangci.yaml
linters-settings:
  revive:
    max-open-files: 2048 # Maximum number of open files at the same time.
    ignore-generated-header: false # When set to false, ignores files with "GENERATED" header, similar to golint.
    severity: warning # Sets the default severity.
    enable-all-rules: false # Enable all available rules.
    confidence: 0.8 # This means that linting errors with less than 0.8 confidence will be ignored.
    rules:
      - name: exported
        severity: warning
        disabled: false
        arguments:
          - "checkPrivateReceivers"
          - "sayRepetitiveInsteadOfStutters"
```

```go
func DoThat() {
  // some logic that is used by 3rd party person
}
```

```shell
❯ golangci-lint run ./...
main.go:18:1: exported: exported function DoThat should have comment or be unexported (revive)
func DoThat() {
^
```

As you may know, revive is a meta-linter which means it contains a lot of linter rules.
You may not like that since some features are from deprecated golint. Today's most IDEs
support what golint does or real kings such as `staticcheck` and `govet` do most of the
work revive does. It is not recommended to run multiple meta-linters since there will be
conflict.

However, there is one unique linter rule of revive, it is called
[exported](https://github.com/mgechev/revive/blob/master/RULES_DESCRIPTIONS.md#exported)
and helps you write down the comment for whatever is exported. This is quite useful as
people forget to add comments for exported things. If it is a toy project, you probably
don't need this. But if you are designing a library for someone else, you better have
comments for the public.

## 5 Tparallel

```go
func TestScenarioOne(t *testing.T) {
	tests := []struct {
		name string
	}{
		{
			name: "handles basic case",
		},
		{
			name: "handles edge case",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			call(tt.name)
		})
	}
}

func TestScenarioTwo(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
	}{
		{
			name: "processes valid input",
		},
		{
			name: "handles invalid input",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			call(tt.name)
		})
	}
}
```

```shell
❯ golangci-lint run ./...
abc_test.go:140:6: TestScenarioTwo's subtests should call t.Parallel (tparallel)
func TestScenarioTwo(t *testing.T) {
     ^
abc_test.go:120:6: TestScenarioOne should call t.Parallel on the top level as well as its subtests (tparallel)
func TestScenarioOne(t *testing.T) {
     ^
```

[Tparallel](https://github.com/moricho/tparallel) Pretty self-descriptive, if you called
`t.Parallel()` on top and have a table of tests that are not calling `t.Parallel()`, it
warns you to call again during table tests. And you may have forgetten to call
`t.Parallel()` on top but called only during table tests. Ensures correct usage of
`t.Parallel()` basically.

## 4 Usestdlibvars

```shell
❯ golangci-lint run ./...
abc.go:18:30: "200" can be replaced by http.StatusOK
abc.go:203:46: "POST" can be replaced by http.MethodPost (usestdlibvars)
    req, err := http.NewRequestWithContext(ctx, "POST", URL, bytes.NewBufferString(formData))
```

Ever used something such as 200 or "POST" but forgot that these exist in standard library,
meet [usesstdlibvars](https://github.com/sashamelentyev/usestdlibvars), it is a nice eye
candy which encourages more standard library usage.

## 3 Usetesting

```yaml
# .golangci.yaml
linters-settings:
  usetesting:
    os-create-temp: true # Enable/disable `os.CreateTemp("", ...)` detections.
    os-mkdir-temp: true # Enable/disable `os.MkdirTemp()` detections
    os-setenv: true # Enable/disable `os.Setenv()` detections.
    os-temp-dir: true # Enable/disable `os.TempDir()` detections.
    os-chdir: true # Enable/disable `os.Chdir()` detections. Disabled if Go < 1.24.
    context-background: true # Enable/disable `context.Background()` detections. Disabled if Go < 1.24.
    context-todo: true # Enable/disable `context.TODO()` detections. Disabled if Go < 1.24.
```

```shell
❯ golangci-lint run ./...
abc_test.go:104:6: os.Setenv() could be replaced by t.Setenv() in TestStoreCreateABC (usetesting)
        _ = os.Setenv("ABC", "GET")
            ^
```

this linter is quite new [usetesting](https://github.com/ldez/usetesting) and supersedes
the good old [tenv](https://github.com/sivchari/tenv) , its aim is to purposely replace os
and context operations with `t *testing.T` equivelants in your tests. I am looking forward
to Go 1.24 so that all of `ctx := context.Background()` will be able to replaced by
`t.Context()`, you can find more details in this
[context support in testing writeup](https://devcenter.upsun.com/posts/go-124/#context-support-in-the-testing-package)

## 2 Nilnil

```go
type something struct{}

func searchSomething() (*something, error) {
	return nil, nil
}
```

```shell
❯ golangci-lint run ./...
abc.go:79:2: return both a `nil` error and an invalid value: use a sentinel error instead (nilnil)
        return nil, nil
        ^
```

the linter [nilnil](https://github.com/Antonboom/nilnil) is here to avoid ambigious
`nil,nil` returns. It could be a developer choice to do so. Famous Gorm has [this
issue](https://github.com/go-gorm/gorm/issues/4416) which is a form of ambiguity in its
public methods. It is like a code smell often.

Technically consistency matters before introducing semantic errors, however I find myself
more aligned with semantic errors rather than `nil, nil` return type of person. I think
having a linter that checks this breach of contract is quite nice and elegant. I haven't
seen any false positives with this linter ever.

## 1 Wrapcheck

```go
func (q *Queries) ListHighscores(ctx context.Context) ([]Highscore, error) {
	rows, err := q.db.QueryContext(ctx, listHighscores)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []Highscore
	for rows.Next() {
		var i Highscore
		if err := rows.Scan(&i.ID, &i.Username, &i.Score); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}
```

```shell
❯ go install github.com/tomarrell/wrapcheck/v2/cmd/wrapcheck@v2
❯ wrapcheck ./...
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:24:12: error returned from external package is unwrapped: sig: func (*database/sql.Row).Scan(dest ...any) error
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:34:9: error returned from interface method should be wrapped: sig: func (github.com/occamist/highscore-api/repository.DBTX).ExecContext(context.Context, string, ...interface{}) (database/sql.Result, error)
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:46:12: error returned from external package is unwrapped: sig: func (*database/sql.Row).Scan(dest ...any) error
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:57:15: error returned from interface method should be wrapped: sig: func (github.com/occamist/highscore-api/repository.DBTX).QueryContext(context.Context, string, ...interface{}) (*database/sql.Rows, error)
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:64:16: error returned from external package is unwrapped: sig: func (*database/sql.Rows).Scan(dest ...any) error
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:69:15: error returned from external package is unwrapped: sig: func (*database/sql.Rows).Close() error
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:72:15: error returned from external package is unwrapped: sig: func (*database/sql.Rows).Err() error
/home/occamist/Desktop/Hobby/highscore-api/repository/queries.sql.go:92:12: error returned from external package is unwrapped: sig: func (*database/sql.Row).Scan(dest ...any) error
```

[Wrapcheck](https://github.com/tomarrell/wrapcheck) as the name suggests enforce you to
wrap errors with useful information. It doesn't check `%v` vs `%w`, it only checks you
don't do `if err != nil { return err }`, I actually quite like this linter because [google
styling
guide](https://google.github.io/styleguide/go/best-practices#adding-information-to-errors)
enforces us to decorate the error with what's being called such as
`fmt.Errorf("something.Do(): %v", err)`

One fun fact, sqlc generated code suffers from this dizziness a lot 😄 next time you are thinking about code generation, I suggest you think at least 10 more times.

## The Ending

Thanks for reading, if you made it this far, I hope you learnt something new or
productive. I have been using a huge bundle of linters for last 5 years. If you are
interested in a golangci-linter config. Check out my
[golangci-lint config gist](https://gist.github.com/occamist/a2f775c9a3b8932135ab4a80ebdedfd8), this is based
on my opinions so you can tweak accordingly based on your project.
