---
title: "[DEV PART 2/2] Serverless Highscore Go API with Faasd and CockroachDB"
date: 2021-09-08T00:00:00+00:00
author: Talha Altinel
description: "Let's make a vendor independent serverless backend API"
tags:
- go
- openfaas
- cockroachdb
- serverless
slug: serverless-highscore-go-api-with-faasd-and-cockroachdb-part-two
canonicalURL: https://occamist.dev/posts/serverless-highscore-go-api-with-faasd-and-cockroachdb-part-two
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: https://res.cloudinary.com/practicaldev/image/fetch/s--LlQw-qDZ--/c_imagga_scale,f_auto,fl_progressive,h_420,q_auto,w_1000/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7wil7ysrogww2w5tsklt.png
  alt: turquoise-gopher-background
---

## The Intro
&nbsp;&nbsp;&nbsp;&nbsp;Hi everyone, this is the 2nd part of the series, we will be developing our API in this part. I will assume you have already followed the previous part and setup faasd and CockroachDB in your cloud server instance and have faas-cli in your both client computer and cloud server instance. I will also assume you have Go on your computer and a proper text editor. Let's quickly get started.

[highscore-api-github-repo](https://github.com/occamist/highscore-api)

Requirements:
- Go knowledge
- docker hub account
- faas-cli
- up and running faasd server
- basic SQL knowledge

First, we would like to make sure your faas-cli works correctly in your server, you should already know your server IP address, your username and your password for faasd. Let's see if the server instance validates us.
```bash
faas-cli login -g http://23.88.60.124:8080 -u admin -p jackthegiant
```
![faas-cli_login_command](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/in0ja6sunlyulasg1nyv.png)

## Faasd Project Init
```bash
faas-cli template store pull golang-http
faas-cli new --lang golang-http get-highscores
```
![faasd-cli_project_command](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/z8yvbv0n654x3oqeyci7.png)
The above command will create a yml file and a function handler that we will have to adjust for faasd. As an initial clean up, I will rename my get-highscores.yml to stack.yml, this file will contain our functions for faasd. It is general practice to have it as stack.yml because you will need 1 less flag during `faas-cli up -f filename.yml`

I will also change the provider's gateway to my server cloud instance which is **http://[[SERVER_IP]]:8080**.In my case, It is http://23.88.60.124:8080.

The other most important part is to give your docker hub container name to image names and turn on go modules in environment variables. Here is what it looks like after tidying up stack.yml. **Make sure you login to your docker hub account and create a repository there first**

```yaml
version: 1.0
provider:
  name: openfaas
  gateway: http://23.88.60.124:8080
functions:
  get-highscores:
    lang: golang-http
    handler: ./get-highscores
    image: mrwormhole/get-highscores:latest
    build_args:
      GO111MODULE: on
    environment:
      POSTGRES_HOST: 23.88.60.124
      POSTGRES_PORT: 26257
      POSTGRES_USER: root
      POSTGRES_DB: highscore_db
```
![docker-hub-repo-creation](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/27uld13o4985gisvg6zf.png)


Now you have the initial configuration setup, let's deploy your generated handler to see if it is getting deployed. Your template code should look like this. The best part is now you can deploy very easily with a single command. This single up command will build your container(faas-cli build), deploy your code to the container registry(faas-cli push) then pull that container to your
cloud server(faas-cli deploy) instance.

**get-highscores/handler.go**
```go
package function

import (
	"fmt"
	"net/http"

	handler "github.com/openfaas/templates-sdk/go-http"
)

// Handle a function invocation
func Handle(req handler.Request) (handler.Response, error) {
	var err error

	message := fmt.Sprintf("Body: %s", string(req.Body))

	return handler.Response{
		Body:       []byte(message),
		StatusCode: http.StatusOK,
	}, err
}
```
```bash
docker login
faas-cli up
```
![docker-login](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/j2td6n7qgtablsjuhf0e.png)![faas-cli-up](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qfzt7obafazub0zglzxr.png)

You can additionally use faas-cli list to see running functions. Now I will grab sqlc to generate a repository layer for our Go function handler. To use sqlc, you will install its CLI, sqlc.json file which will point to our queries.sql and schema.sql

```bash
go get github.com/kyleconroy/sqlc/cmd/sqlc
```

Here is how my sqlc.json, schema.sql and queries.sql look like. If you don't know basic SQL, I strongly suggest you to visit [W3C SQL docs](https://www.w3schools.com/sql/default.Asp) for quick recap and have a look at [sqlc docs](https://docs.sqlc.dev/en/latest/index.html)

sqlc.json
```json
{
  "version": "1",
  "packages": [
    {
      "path": "repository",
      "name": "repository",
      "queries": "queries.sql",
      "schema": "schema.sql"
    }
  ]
}
```

schema.sql
```sql
CREATE TABLE highscores (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  score BIGINT NOT NULL
);
```

queries.sql
```sql
-- name: GetHighscore :one
SELECT * FROM highscores
WHERE username = $1 LIMIT 1;

-- name: ListHighscores :many
SELECT * FROM highscores
ORDER BY score;

-- name: CreateHighscore :one
INSERT INTO highscores(username, score) 
VALUES ($1, $2) RETURNING *;

-- name: UpdateHighscore :one
UPDATE highscores
SET score = $2
WHERE id = $1 RETURNING *;

-- name: DeleteHighscore :exec
DELETE FROM highscores
WHERE username = $1;
```

Now we can generate our repository layer since we have completed all of the database interactions. The below command will generate all of the repository code for Go from SQL.

```bash
sqlc generate
```

I will initialize go modules and get [pq](https://github.com/lib/pq) which is a pure Go postgres driver. Why do we use postgres driver for CockroachDB? CockroachDB supports PostgreSQL wire protocol. This means it is almost fully compatible with postgres drivers and ORMs.

```
go mod init github.com/occamist/highscore-api
go get github.com/lib/pq
```

Let's finish up our handler for get-highscores. I will establish a database connection and check for the correct HTTP method. I will also check if there is a username query for the highscore. If yes, I will return a specific user's highscore. Otherwise, I will return all of the highscores in the database. *Please make sure to import lib/pq manually.*

**get-highscores/handler.go**
```go
package function

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	_ "github.com/lib/pq"
	"github.com/occamist/highscore-api/repository"
	handler "github.com/openfaas/templates-sdk/go-http"
)

func Handle(req handler.Request) (handler.Response, error) {
	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=disable",
		os.Getenv("POSTGRES_HOST"),
		os.Getenv("POSTGRES_PORT"),
		os.Getenv("POSTGRES_USER"),
		os.Getenv("POSTGRES_DB")))
	defer func() {
		err = db.Close()
		if err != nil {
			log.Printf("failed to close db: %v", err)
		}
	}()
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to connect to db: %v", err)
	}
	if req.Method != http.MethodGet {
		return handler.Response{
			StatusCode: http.StatusBadRequest,
		}, fmt.Errorf("invalid http method %s", req.Method)
	}

	values, err := url.ParseQuery(req.QueryString)
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to parse query string: %v", err)
	}

	var rawBody []byte
	queries := repository.New(db)
	username := values.Get("username")

	if strings.TrimSpace(username) != "" {
		highscore, err := queries.GetHighscore(req.Context(), username)
		if err != nil {
			if err == sql.ErrNoRows {
				return handler.Response{
					StatusCode: http.StatusNotFound,
				}, nil
			}
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to get highscore for username %s: %v", username, err)
		}

		rawBody, err = json.Marshal(highscore)
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to marshal a highscore: %v", err)
		}
	} else {
		highscores, err := queries.ListHighscores(req.Context())
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to list highscores: %v", err)
		}

		rawBody, err = json.Marshal(highscores)
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to marshal highscores: %v", err)
		}
	}

	return handler.Response{
		Body:       rawBody,
		StatusCode: http.StatusOK,
	}, nil
}

```

Now I will create my second function and create its docker hub repo and tidy up stack.yml. I will also add a token credential so that not everyone can add highscore to my database.

```
faas-cli new --lang golang-http post-highscore --append stack.yml
```

```yaml
version: 1.0
provider:
  name: openfaas
  gateway: http://23.88.60.124:8080
functions:
  get-highscores:
    lang: golang-http
    handler: ./get-highscores
    image: mrwormhole/get-highscores:latest
    build_args:
      GO111MODULE: on
    environment:
      POSTGRES_HOST: 23.88.60.124
      POSTGRES_PORT: 26257
      POSTGRES_USER: root
      POSTGRES_DB: highscore_db
      
  post-highscore:
    lang: golang-http
    handler: ./post-highscore
    image: mrwormhole/post-highscore:latest
    build_args:
      GO111MODULE: on
    environment:
      POSTGRES_HOST: 23.88.60.124
      POSTGRES_PORT: 26257
      POSTGRES_USER: root
      POSTGRES_DB: highscore_db
      BEARER_TOKEN: QeV5f7eSvJnO0dDYCc9DcH5BEwpm7P3j
```

I will create a package called model and middleware. My model will only contain how a request should look like and my middleware will look like a basic auth header check against our specified BEARER_TOKEN env variable.

**model/highscore.go**
```go
package model

type Highscore struct {
	Username string `json:"username"`
	Score    int64  `json:"score"`
}
```

**middleware/auth.go**
```go
package middleware

import (
	"errors"
	"os"
	"strings"

	handler "github.com/openfaas/templates-sdk/go-http"
)

func Authorization(req handler.Request) error {
	authHeader := req.Header.Get("Authorization")
	authHeaderValues := strings.Split(authHeader, " ")
	if len(authHeaderValues) != 2 || authHeaderValues[0] != "Bearer" {
		return errors.New("authorization header is in the wrong format")
	}
	if authHeaderValues[1] != os.Getenv("BEARER_TOKEN") {
		return errors.New("bearer token is not valid")
	}

	return nil
}
```

Finishing up the handler for post-highscore. I will establish a database connection and check for the correct HTTP method. I will check for the authorization header. If there are no users with that username, we will create a new one and return that in the body. If there is someone with that username, we will check the incoming request's highscore and compare it with the one that highscore that is persisted. If that is higher, we can go ahead and update then return that in the body. Otherwise, we return empty 200 to the request.

**post-highscore/handler.go**
```go
package function

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
	"github.com/occamist/highscore-api/middleware"
	"github.com/occamist/highscore-api/model"
	"github.com/occamist/highscore-api/repository"
	handler "github.com/openfaas/templates-sdk/go-http"
)

func Handle(req handler.Request) (handler.Response, error) {
	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=disable",
		os.Getenv("POSTGRES_HOST"),
		os.Getenv("POSTGRES_PORT"),
		os.Getenv("POSTGRES_USER"),
		os.Getenv("POSTGRES_DB")))
	defer func() {
		err = db.Close()
		if err != nil {
			log.Printf("failed to close db: %v", err)
		}
	}()
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to connect to db: %v", err)
	}
	if req.Method != http.MethodPost {
		return handler.Response{
			StatusCode: http.StatusBadRequest,
		}, fmt.Errorf("invalid http method %s", req.Method)
	}

	err = middleware.Authorization(req)
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusBadRequest,
		}, fmt.Errorf("%v", err)
	}

	var highscore model.Highscore
	err = json.Unmarshal(req.Body, &highscore)
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to unmarshal highscore")
	}

	queries := repository.New(db)
	existingHighscore, err := queries.GetHighscore(req.Context(), highscore.Username)
	if err != nil && err != sql.ErrNoRows {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to get a highscore: %v", err)
	}

	if existingHighscore.ID == 0 {
		params := repository.CreateHighscoreParams{Username: highscore.Username, Score: highscore.Score}
		createdHighscore, err := queries.CreateHighscore(req.Context(), params)
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to create a highscore: %v", err)
		}

		raw, err := json.Marshal(createdHighscore)
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to marshal created highscore")
		}

		return handler.Response{
			Body:       []byte(raw),
			StatusCode: http.StatusOK,
		}, nil
	}

	if highscore.Score > existingHighscore.Score {
		params := repository.UpdateHighscoreParams{ID: existingHighscore.ID, Score: highscore.Score}
		updatedHighscore, err := queries.UpdateHighscore(req.Context(), params)
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to update a highscore: %v", err)
		}

		raw, err := json.Marshal(updatedHighscore)
		if err != nil {
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to marshal updated highscore")
		}

		return handler.Response{
			Body:       []byte(raw),
			StatusCode: http.StatusOK,
		}, nil
	}

	return handler.Response{
		StatusCode: http.StatusOK,
	}, nil
}

```

Now I will create my third and final handler and respectively its docker hub repo. I will add a token credential to this handler as well. Because not everyone needs to delete someone else's highscore :) your final yaml structure is given below.

```
faas-cli new --lang golang-http delete-highscore --append stack.yml
```

```yaml
version: 1.0
provider:
  name: openfaas
  gateway: http://23.88.60.124:8080
functions:
  get-highscores:
    lang: golang-http
    handler: ./get-highscores
    image: mrwormhole/get-highscores:latest
    build_args:
      GO111MODULE: on
    environment:
      POSTGRES_HOST: 23.88.60.124
      POSTGRES_PORT: 26257
      POSTGRES_USER: root
      POSTGRES_DB: highscore_db
      
  post-highscore:
    lang: golang-http
    handler: ./post-highscore
    image: mrwormhole/post-highscore:latest
    build_args:
      GO111MODULE: on
    environment:
      POSTGRES_HOST: 23.88.60.124
      POSTGRES_PORT: 26257
      POSTGRES_USER: root
      POSTGRES_DB: highscore_db
      BEARER_TOKEN: QeV5f7eSvJnO0dDYCc9DcH5BEwpm7P3j

  delete-highscore:
    lang: golang-http
    handler: ./delete-highscore
    image: mrwormhole/delete-highscore:latest
    build_args:
      GO111MODULE: on
    environment:
      POSTGRES_HOST: 23.88.60.124
      POSTGRES_PORT: 26257
      POSTGRES_USER: root
      POSTGRES_DB: highscore_db
      BEARER_TOKEN: Ru4BXyL7ALkey34cUJIIXBF67t1qrw37
```

This handler will also handle its database connection and validate the authorization header then check the username in the URL query. Afterward, we delete the highscore that matches that username.

**delete-highscore/handler.go**
```go
package function

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	_ "github.com/lib/pq"
	"github.com/occamist/highscore-api/middleware"
	"github.com/occamist/highscore-api/repository"
	handler "github.com/openfaas/templates-sdk/go-http"
)

func Handle(req handler.Request) (handler.Response, error) {
	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=disable",
		os.Getenv("POSTGRES_HOST"),
		os.Getenv("POSTGRES_PORT"),
		os.Getenv("POSTGRES_USER"),
		os.Getenv("POSTGRES_DB")))
	defer func() {
		err = db.Close()
		if err != nil {
			log.Printf("failed to close db: %v", err)
		}
	}()
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to connect to db: %v", err)
	}
	if req.Method != http.MethodDelete {
		return handler.Response{
			StatusCode: http.StatusBadRequest,
		}, fmt.Errorf("invalid http method %s", req.Method)
	}

	err = middleware.Authorization(req)
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusBadRequest,
		}, fmt.Errorf("%v", err)
	}

	values, err := url.ParseQuery(req.QueryString)
	if err != nil {
		return handler.Response{
			StatusCode: http.StatusInternalServerError,
		}, fmt.Errorf("failed to parse query string: %v", err)
	}

	queries := repository.New(db)
	username := values.Get("username")

	if strings.TrimSpace(username) != "" {
		err = queries.DeleteHighscore(req.Context(), username)
		if err != nil {
			if err == sql.ErrNoRows {
				return handler.Response{
					StatusCode: http.StatusNotFound,
				}, nil
			}
			return handler.Response{
				StatusCode: http.StatusInternalServerError,
			}, fmt.Errorf("failed to delete a highscore for username %s: %v", username, err)
		}
	}

	return handler.Response{
		StatusCode: http.StatusOK,
	}, nil
}
```

Now we can do `faas-cli up` and see the deployed functions. You can also check out the dashboard to get the endpoint names.
![all-funcs-deployed](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/2unrlv2ucln97mhio7tt.png)

If you are getting internal server error 500, that means you are returning an error to the function handler and you can easily debug your server. For example, I am returning an error for invalid HTTP methods. I can easily see logs with this command
```
journalctl -t openfaas-fn:get-highscores -r --lines 20
```
![checking-faasd-logs](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jnnca6diw43dfockh3cn.png)

## The end
- http://23.88.60.124:8080/function/get-highscores
- http://23.88.60.124:8080/function/post-highscore
- http://23.88.60.124:8080/function/delete-highscore

These are the endpoints we have created. Overall, I enjoyed how we can have a serverless developer experience without the need for any giant cloud service that is impossible to move around. Faasd is still a young but promising project for developers who don't want to deal with k8s infra complexity. Hope you enjoyed and learned something new. If you have any questions/issues, feel free to let me know. Take care!

