---
title: "[INFRA PART 1/2] Serverless Highscore Go API with Faasd and CockroachDB"
date: 2021-09-08T00:00:00+00:00
author: Talha Altinel
description: "Let's make a vendor independent serverless backend API"
tags:
- go
- openfaas
- cockroachdb
- serverless
slug: serverless-highscore-go-api-with-faasd-and-cockroachdb-part-one
canonicalURL: https://occamist.dev/posts/serverless-highscore-go-api-with-faasd-and-cockroachdb-part-one/
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
---

## The Series Intro

&nbsp;&nbsp;&nbsp;&nbsp;Hi everyone, in this series we will be creating serverless highscore REST API in Go and
utilize the most advanced and bleeding-edge open-source technologies such as
Faasd(OpenFaaS engine) and CockroachDB(our cluster database). **Keep in mind that we will
actually need a server to do serverless computing :)** *(Plot Twist)*

In this 1st part, we will be setting up the infrastructure side for Hetzner Cloud with
Terraform then in the 2nd part we will develop/deploy our functions with help of faas-cli.
Faasd is developed by OpenFaaS to make self-hosted serverless functions much easier to
develop/deploy without any vendor lock-in giant cloud company or K8s requirement. We will
also be using CockroachDB as a single node database for our cloud server instance. There
are some requirements but keep in mind that Terraform and Hetzner Cloud are not mandatory
requirements.

## The Aim

The aim is to give everyone self-hosted basic serverless REST API understanding, the
DevOps cycle of it and how to interact with the self-hosted distributed/resilient
open-source database CockroachDB from serverless REST API.

## The High-level Diagram

![faasd-cockroachdb](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ra800efhu89t69ynnu4r.png)

Requirements:

* Non-windows based Terminal(Must have, could be WSL, Linux Terminal or Mac Terminal, just not Windows Powershell)
* Faas-cli in your client computer (Must have, we will be using this for pushing our code to our cloud server instance)
* CockroachDB (Must have, we will be using this as a database in our cloud server instance)
* Docker in your client computer (Must have, we will be using this for docker container registry)
* Terraform(optional)
* Hetzner Cloud account and API access token(optional)
* SSH key and key name created in Hetzner Cloud(optional)

### Why Hetzner Cloud?

At least 1GB is required to be safe. So the pricing for CX11 and 2 gigs of RAM is really
nice. You are free to use any cloud you like but I suggest small cloud providers instead
of giant cloud providers due to the simplicity. Other alternatives could be Vultr, Linode,
DigitalOcean...

### Why Faasd and CockroachDB?

Faasd is open-source serverless container technology which uses an actual physical server
and manages your functions in AWS lambda fashion with so little cost and being extremely
lightweight. If you need global scale geo-distributed serverless container technology, you
can also port your serverless functions to OpenFaaS(uses k8s under the hood) at any time.
Faasd gets rid of any vendor-lock in serverless X cloud technology and allows you to focus
only on your code. You also get a great dashboard.

CockroachDB is a global scale geo-distributed open-source database. I will be using
CockroachDB due to its simplicity and resilience to setup as a single node in our cloud
server instance. If you need the managed production database, you can always switch to the
free tier of cockroach cloud which gives you ultimate powers of geo-distributed feature
and auto-TLS. Again, you also get a perfect dashboard.

**Note: In your faasd server, running a local database with docker can confuse containerd
runtime. It is a must to install only faasd server via faasd github repository's
"./hack/install.sh" which will only install what is necessary such as containerd, faasd
and faas-cli.**

For demo purposes and purity, we won't be adding TLS to our server and database but I will
leave links at the end. You should never run this in production without TLS certificates
and you will at least need 3 nodes for your production CockroachDB cluster.

### Intro

First of all, you need faas-cli in your client local machine. You should get the binary
and set it to your path. If you are on linux or mac machine, moving the binary into
"/usr/local/bin" will work. For windows machines, you need to set environment variables in
Control Panel>System and Security>System>Advanced System
Settings([single-binary-faas-cli](https://github.com/openfaas/faasd/releases))

For setting up faasd in your cloud server instance, easiest way to install faas-cli and
faasd is to run commands below. Then visit the dashboard and login with your credentials
on **http://[[SERVER_IP]]:8080/ui/** Skip the manual commands below if you have Terraform.

```bash
git clone https://github.com/openfaas/faasd --depth=1
./faasd/hack/install.sh
sudo cat /var/lib/faasd/secrets/basic-auth-user; echo
sudo cat /var/lib/faasd/secrets/basic-auth-password; echo
```

Having Terraform and Hetzner Cloud is not a hard requirement. But if you are into
Terraform and you have a Hetzner Cloud account, that's great, you can run Terraform to
provision your infrastructure faster and get a verbose output from your CLI. Just make
sure to set your Hetzner api token and Hetzner ssh key name in vars.tf file.

```bash
git clone https://github.com/occamist/hetzner-terraform-faasd
cd hetzner-terraform-faasd
terraform init
terraform plan
terraform apply --auto-approve
terraform output --json
```

![terraform-hetzner-outputs](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xuv1p039rdbknj7o6o89.png)
After you visit the URL and enter your username and password, you should be seeing the pretty OpenFaaS dashboard.
![openfaas-dashboard](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/1s80639no8ht6stl50tp.png)
If you are stuck with a problem, make sure faas-cli installed properly in your client and
server by checking faas-cli version. You should also check if faasd.service is running on
systemd.

```bash
systemctl status faasd.service
```

![faasd-service-status](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/d6ko6nbi0tqge51no3w3.png)
After you SSH into your cloud instance, you can setup your single node CockroachDB. And
check out the dashboard and the databases at **http://[[SERVER_IP]]:7070**.

```bash
curl https://binaries.cockroachdb.com/cockroach-v21.1.7.linux-amd64.tgz | tar -xz; sudo cp -i cockroach-v21.1.7.linux-amd64/cockroach /usr/local/bin/

cockroach start-single-node \
--insecure \
--listen-addr=0.0.0.0:26257 \
--http-addr=0.0.0.0:7070 \
--background \
--accept-sql-without-tls
```

![cockroachdb-cli](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/q2sdfxgc767msyknqk7v.png)
![cockroachdb-dashboard](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/drk0u8dqlh64mluwqn4c.png)
Before we close cockroachDB, let's create our schema and sample records.

```shell
cockroach sql --insecure --host=localhost:26257
CREATE DATABASE highscore_db;
USE highscore_db;
SHOW TABLES;
CREATE TABLE highscores (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  score BIGINT NOT NULL
);
INSERT INTO highscores(username, score) VALUES ('SCORPION', 100);
INSERT INTO highscores(username, score) VALUES ('SUBZERO', 100);
INSERT INTO highscores(username, score) VALUES ('KITANA', 300);
INSERT INTO highscores(username, score) VALUES ('MILEENA', 400);
SELECT * FROM highscores;
```

![db-sample-record-creation](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jg6c8fxmrahdlr0ixp89.png)

To quit, we can use this

```bash
cockroach quit --insecure --host=localhost:26257
```

This sums up this infrastructure part. Let's move to the actual development
<br />
> "it is actually so easy after you did it once" -The ancient old devops guy who died during the renewal of a manual TLS certificate

### The end

* How to secure faasd server with caddy: [tls-caddy-faasd-server](https://www.openfaas.com/blog/faasd-tls-terraform/)
* How to secure CockroachDB as a whole cluster: -> [tls-cockroachdb](https://www.cockroachlabs.com/docs/v21.1/secure-a-cluster.html)

### The references

* Faasd in-depth look: [faasd-book](https://openfaas.gumroad.com/l/serverless-for-everyone-else)
* CockroachDB in-depth look: [cockroachdb-university](https://www.cockroachlabs.com/cockroach-university/)
