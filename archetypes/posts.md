---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
author: {{ .Site.Params.Author }}
description: "description text"
tags:
- myFirstTag
- mySecondTag
- myThirdTag
- myFourthTag
slug: "{{ .Name | urlize }}"
canonicalURL: https://occamist.gitlab.io/posts/slug
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: true
---

