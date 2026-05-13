---
title: "Localstack with Terraform and Docker for running AWS locally"
date: 2021-07-03T00:00:00+00:00
author: Talha Altinel
description: "Did you know you can run AWS locally?"
tags:
- go
- aws
- terraform
- docker
slug: localstack-with-terraform-and-docker-for-running-aws-locally
canonicalURL: https://occamist.dev/posts/localstack-with-terraform-and-docker-for-running-aws-locally/
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: https://res.cloudinary.com/practicaldev/image/fetch/s--ea7XJS8j--/c_imagga_scale,f_auto,fl_progressive,h_420,q_auto,w_1000/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/h4c6buxj2aacuo4v7xs5.jpg
  alt: blue-gopher-background
---

## The Intro
&nbsp;&nbsp;&nbsp;&nbsp;Hello everyone, in this post I will be demonstrating how you can run localstack with Terraform and Docker and give you a proof of concept go application so you can tweak it according to your logic and follow anything you want to do such as integration/system tests for AWS services in your own CI/CD or localhost.

Github Repository for PoC(proof of concept):
[hotdog-PoC-repository](https://github.com/occamist/hotdog-localstack-PoC)

Requirements:
* Docker
* docker-compose
* Terraform
* Go
* aws CLI
* A bit of lambda, dynamodb and kinesis knowledge

Localstack is a testing/mocking framework for developing Cloud applications locally. Where in theory, you can stick any AWS service and emulate them in localhost without ever needing the real AWS account.
Localstack’s primary goal to make integration/system testing less painful for developers.


### What was built?
![flow-diagram](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/omwafkqkirsigsvqjxts.png)
&nbsp;&nbsp;&nbsp;&nbsp;I built an imaginary hotdog food chain! (Note: No dogs were harmed in this process). Essentially PoC logic was I had 1 dogs dynamodb table which consist a dog model with 3 attributes ID, name, isAlive and isEaten. Then I had 3 lambdas dogCatcher, dogProcessor and hotDogDespatcher. dog catcher's responsibility is to get alive dogs via external API requests(I generated data for simplicity) with unique IDs and different names. Dog processor's responsibility is to kill the dogs and persist the data that was sent from dog catcher. Hot dog despatcher's responsibility is to give processed dogs(hot dogs) to people and observe which ones were eaten via external API requests(I assumed hot dogs get eaten if their name has case-insensitive "e" or "a" letter)

Aside from lambdas, I had 3 kinesis streams and 3 kinesis triggers in order to make lambdas talk to each other. The named kinesis streams is as follows; caughtDogs, hotDogs, eatenHotDogs.

### Starting Localstack docker container with docker-compose
```yaml
version: '3.8'

services:
    localstack:
        container_name: "localstack_main"
        image: localstack/localstack:latest
        environment: 
            - SERVICES=dynamodb,lambda,kinesis
            - LAMBDA_EXECUTOR=docker_reuse
            - DOCKER_HOST=unix:///var/run/docker.sock
            - DEFAULT_REGION=ap-southeast-2
            - DEBUG=1
            - DATA_DIR=/tmp/localstack/data
            - PORT_WEB_UI=8080
            - LAMBDA_DOCKER_NETWORK=localstack-tutorial
            - KINESIS_PROVIDER=kinesalite
        ports:
            - "53:53"
            - "53:53/udp"
            - "443:443"
            - "4566:4566"
            - "4571:4571"
            - "8080:8080"
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - localstack_data:/tmp/localstack/data
        networks:
            default:

volumes:
    localstack_data:
networks:
    default:
        external:
            name: localstack-tutorial
```
```shell
docker-compose up -d --build
```
### Bootstrapping our infra with Terraform
```tf
provider "aws" {
  region                      = "ap-southeast-2"
  access_key                  = "fake"
  secret_key                  = "fake"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    kinesis  = "http://localhost:4566"
  }
}

// DYNAMODB TABLES
resource "aws_dynamodb_table" "dogs" {
  name           = "dogs"
  read_capacity  = "20"
  write_capacity = "20"
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}

// KINESIS STREAMS
resource "aws_kinesis_stream" "caught_dogs_stream" {
  name = "caughtDogs"
  shard_count = 1
  retention_period = 30

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}

resource "aws_kinesis_stream" "hot_dogs_stream" {
  name = "hotDogs"
  shard_count = 1
  retention_period = 30

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}

resource "aws_kinesis_stream" "eaten_hot_dogs_stream" {
  name="eatenHotDogs"
  shard_count = 1
  retention_period = 30

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}

// LAMBDA FUNCTIONS
resource "aws_lambda_function" "dog_catcher_lambda" {
  function_name = "dogCatcher"
  filename      = "dogCatcher.zip"
  handler       = "main"
  role          = "fake_role"
  runtime       = "go1.x"
  timeout       = 5
  memory_size   = 128
}

resource "aws_lambda_function" "dog_processor_lambda" {
  function_name = "dogProcessor"
  filename      = "dogProcessor.zip"
  handler       = "main"
  role          = "fake_role"
  runtime       = "go1.x"
  timeout       = 5
  memory_size   = 128
}

resource "aws_lambda_function" "hot_dog_despatcher_lambda" {
  function_name = "hotDogDespatcher"
  filename      = "hotDogDespatcher.zip"
  handler       = "main"
  role          = "fake_role"
  runtime       = "go1.x"
  timeout       = 5
  memory_size   = 128
}

// LAMBDA TRIGGERS
resource "aws_lambda_event_source_mapping" "dog_processor_trigger" {
  event_source_arn              = aws_kinesis_stream.caught_dogs_stream.arn
  function_name                 = "dogProcessor"
  batch_size                    = 1
  starting_position             = "LATEST"
  enabled                       = true
  maximum_record_age_in_seconds = 604800
}

resource "aws_lambda_event_source_mapping" "dog_processor_trigger_2" {
  event_source_arn              = aws_kinesis_stream.eaten_hot_dogs_stream.arn
  function_name                 = "dogProcessor"
  batch_size                    = 1
  starting_position             = "LATEST"
  enabled                       = true
  maximum_record_age_in_seconds = 604800
}

resource "aws_lambda_event_source_mapping" "hot_dog_despatcher_trigger" {
  event_source_arn = aws_kinesis_stream.hot_dogs_stream.arn
  function_name = "hotDogDespatcher"
  batch_size = 1
  starting_position = "LATEST"
  enabled = true
  maximum_record_age_in_seconds = 604800
}
```
```shell
./zip-it.sh
terraform init
terraform plan
terraform apply --auto-approve
```

### Checking with aws CLI if everything is setup correctly
![aws-cli-outputs](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ia14j0l3e49c4um78yaq.png)
To see if everything was working correctly, I invoke dogCatcher and check out the dynamodb table;
```shell
aws lambda invoke --function-name dogCatcher --endpoint-url=http://localhost:4566 --payload '{"quantity": 2}' output.txt
```
```shell
aws dynamodb scan --endpoint-url http://localhost:4566 --table-name dogs
```
![aws-cli-results](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/117i7343k9c4t75yio5b.png)

### Result
I had pretty much great experience with Localstack. I think even though Localstack is quite new, it seems like it can be used for learning AWS SDKs as a developer without actually using live AWS services and getting billed for it. This can also speed up developer's integration tests(along with CI/CD) and debugging processes if configured properly because there are many services Localstack provides and I have only configured and used 3 of them here. This also saves lots of costs for any companies.

Also don't forget to check out Localstack's slack channel, they are really helpful for any issues you run into or for further questions!
- [localstack-community.slack](https://localstack-community.slack.com)
