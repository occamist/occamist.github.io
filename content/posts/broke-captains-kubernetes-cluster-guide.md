---
title: "Broke Captain's Kubernetes Cluster Guide(super simple & convenient cost)"
date: 2021-12-05T00:00:00+00:00
author: Talha Altinel
description: "What if you could run k8s cluster for 10 pounds/monthly only?"
tags:
- kubernetes
- cloudnative
- linux
- k3s
slug: "broke-captains-kubernetes-cluster-guide"
canonicalURL: https://occamist.dev/posts/broke-captains-kubernetes-cluster-guide
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
draft: false
cover:
  image: 1_O_keDnti5ZjuEFXbpa5YaQ.webp
  alt: yellow-shining-k3s-background
---

## The Intro

In this guide, I will be showing how to set up a simple Kubernetes(K3S) cluster
which will have 1 master node and 2 worker nodes on Hetzner Cloud. My main goal
is to make newcomers' transition to Kubernetes very smooth as a person who
suffered enough with complex tutorials/bills and didn't get enough chance to
poke a Kubernetes cluster.

This tutorial should be applicable to any cloud provider but be warned pricing would be
extremely different. If you come to learn Kubernetes, this could be your starting point to
set up your own cluster and get started poking around with an actual production-ready
cluster with k3s.

## Quick QA

- What is K3S?

It is a production-ready, stable and lightweight flavor of Kubernetes, think it is like
Debian being a flavor of Linux. It is also the best choice for learning multi-master and
multi-worker node architecture.

- Why not teach us minikube/kind/microk8s?

They are not good enough for production workloads.

- Why Hetzner cloud?

It is super cheap and simple cloud UI for me, you can do the same things in Vultr, Linode, Digital Ocean. **Note: I am not sponsored by Hetzner Cloud**

- Do I need to install docker?

Not needed because k3s binaries ship with everything that is needed

- What is the difference between a master node and a worker node?

A master node is often referred to a K3S server and a worker node is often referred to a
K3S agent. For high availability(HA), the recommendation is to have at least 3 master
nodes, 3 worker nodes, and 1 managed database outside of your master node instead of
having an embedded SQLite database.

![master-and-worker.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/3awe8zagg9ta58pkehsh.png)

## Setup your SSH key, network and compute instances

Before we create our compute instance(VPS), we will need SSH key setup, private network setup. Let's quickly go over it. Let's generate our ssh-key 🗝️

![ssh-keygen.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hs2guk95i0z6bnir8z23.png)

Let's add our ssh-key to our local machine and public ssh-key to the cloud UI. This panel may be different depending on your cloud provider. 🗝️

![ssh-add.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/dsgu6qp4c200md6sk4j4.png)

![hetzner-ssh-tab.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/4u78hq4mserlga6rx4l0.png)

After that, let's quickly create our private network which will be used for our compute
instances for the cluster's nodes communication between the master and the worker nodes.
☎️

![hetzner-network-tab.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8eeb5kdo1vns8fh8qlw5.png)

![nebula-network-created.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/azzu13gtv38khkghpnos.png)

We are finally ready to create our compute instances. Now I will create my master node
which can also be called as k3s server. I will call my master node's name "jack-sparrow".
I will pick "Debian 11" as my Linux distro choice for rock-solid server stability and
being a reliable open source project.

I will also take advantage of multiple instance creation and set the instance count to 3.
The other 2 instances will be my worker nodes which can also be called as k3s agents. I
will call them "black-pearl" and "flying-dutchman". If you want to extend your worker
nodes, you can keep going with all the ship names from Pirates of the Caribbean. For
master nodes, I will be using captain names 🏴‍☠️

I have picked CX11 instance which is the cheapest option available. 6GB RAM and 60GB SSD
should be sufficient enough for most of your projects. I skipped additional volume and the
firewall. I added my created network and my created SSH key. Remember, this is for broke
captains. 🚢

![hetzner-server-tab.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ftpsdccm412zt4iqhjpx.png)

![hetzner-server-tab-1.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5d5uoe2xdese9qfq5pmr.png)

![created-compute-instances.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/1lmry6esapuqj1vo6iqp.png)

## Prerequisites for K3S

SSH into **the master node and the worker nodes.** Update /etc/hosts files before we get
our great k3s binaries which has everything including containerd runtime and CNI(container
network interface). 🐋

```bash
ssh root@94.130.227.124

apt update && sudo apt upgrade

apt install apparmor apparmor-utils // Debian dependency for the Kernel
```

After you have updated **every nodes**' /etc/hosts file with GNU nano. Optionally you can
install nmap CLI tool to make sure your network is functioning properly and other
instances are connected through the web with `nmap -sn 10.0.0.1/24` 🕸️

![created-compute-instances-ip-addresses.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vkm3itty3kmkbwx8mjpx.png)

![edit-hosts-file.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ya3wtd56dxqema0rgbg1.png)

![nmap.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/6kpgxb9sghoy15xxrc1d.png)

## Installation of K3S

In jack-sparrow instance(master node), let's install k3s server.

```bash
$ curl -sfL https://get.k3s.io | sh -

$ systemctl status k3s.service
● k3s.service - Lightweight Kubernetes
     Loaded: loaded (/etc/systemd/system/k3s.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2021-12-04 17:39:07 UTC; 3min 0s ago
       Docs: https://k3s.io
    Process: 26339 ExecStartPre=/bin/sh -xc ! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service (code=exited, status=0/SUCCESS)
    Process: 26341 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=0/SUCCESS)
    Process: 26342 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 26343 (k3s-server)
      Tasks: 18
     Memory: 502.4M
        CPU: 27.604s
     CGroup: /system.slice/k3s.service
             └─26343 /usr/local/bin/k3s server

$ kubectl get nodes -o wide
NAME           STATUS   ROLES                  AGE    VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
jack-sparrow   Ready    control-plane,master   4m4s   v1.21.7+k3s1   94.130.227.124   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11
```

Let's configure incoming/outgoing ports for jack-sparrow, our k3s server. Also obtain the token which will be used during k3s agents setup.

```bash
$ apt install ufw
$ ufw default allow outgoing
$ ufw default deny incoming
$ ufw allow 22,80,443,6443,10250/tcp
$ ufw --force enable
Firewall is active and enabled on system startup

$ cat /var/lib/rancher/k3s/server/node-token
bc3f7dee0308f09e5a3645f4b06343eea2644296cdK1d79a977d0e193a10187497f::server:9ae1e45b8b58be56a8282a84c7e3715b
```

Let's install k3s agents in our computing instances which are called black-pearl and
flying-dutchman! Our master IP (jack-sparrow) is `10.0.0.4` in our nebula network. And our
token is
`bc3f7dee0308f09e5a3645f4b06343eea2644296cdK1d79a977d0e193a10187497f::server:9ae1e45b8b58be56a8282a84c7e3715b`

```bash
curl -sfL http://get.k3s.io | K3S_URL=https://10.0.0.4:6443 K3S_TOKEN=bc3f7dee0308f09e5a3645f4b06343eea2644296cdK1d79a977d0e193a10187497f::server:9ae1e45b8b58be56a8282a84c7e3715b sh -
[INFO]  Finding release for channel stable
[INFO]  Using v1.21.7+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.21.7+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.21.7+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  systemd: Starting k3s-agent
```

Perfect! Let's jump into Jack Sparrow! and see what we got!

```bash
root@jack-sparrow:~# kubectl get nodes -o wide
NAME              STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
jack-sparrow      Ready    control-plane,master   50m   v1.21.7+k3s1   94.130.227.124   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11
black-pearl       Ready    <none>                 28s   v1.21.7+k3s1   116.203.32.141   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11
flying-dutchman   Ready    <none>                 12s   v1.21.7+k3s1   116.203.90.71    <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11
```

## Extras(Install LENS)

Lens is a Kubernetes UI for managing your cluster resources. It comes bundled with Helm
and kubectl for your local workstation. You can install lens binary from the github under
the name lensapp/lens. We will be taking the kube config from jack sparrow and pasting it
into your Lens. To do that let's find our kube config and copy paste. And change the
server IP address to external IP address of our jack sparrow instead of 127.0.0.1

```bash
root@jack-sparrow:~# cat /etc/rancher/k3s/k3s.yaml
```

![lens-intro.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/h7158c41j7rfhfv4p5b7.png)

![kubeconfig-on-lens.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/kaqo49fgn19ik3obiwqc.png)

![lens-nodes.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/kra7vdvo3aoh8st6a86s.png)

Let's create pirate-deployment.yaml, pirate-service.yaml and traefik-ingress.yaml to see generated lens metrics. And apply them in our cluster.

```yaml
# pirate-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pirate-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pirate-app
  template:
    metadata:
      labels:
        app: pirate-app
    spec:
      containers:
        - name: simple-pirate
          image: mrwormhole/simple-pirate
          ports:
            - containerPort: 80
```

```yaml
# pirate-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: pirate-svc
spec:
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  selector:
    app: pirate-app
```

```yaml
# traefik-ingress.yaml
apiVersion: networking.k8s.io/v1 
kind: Ingress
metadata:
  name: pirate-ingress
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: 
            name: pirate-svc
            port: 
              number: 80
```

```yaml
$ kubectl create -f pirate-deployment.yaml
$ kubectl create -f pirate-service.yaml
$ kubectl create -f traefik-ingress.yaml
$ kubectl get ingress
NAME             CLASS    HOSTS   ADDRESS                                       PORTS   AGE
pirate-ingress   <none>   *       116.203.32.141,116.203.90.71,94.130.227.124   80      136m
```

Now we can enable the lens metrics from pinned clusters and go to its settings and install
all of the required things via lens metrics tab. We will need prometheus, kube state
metrics and node exporter from lens metrics section.

![lens-metrics-1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/3w9nasytexinft7blrl6.png)

![lens-metrics-2.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/nu0g3352lpzsi7zuo6k2.png)

![final-lens.png](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5gh8vstcrg5ahamofjhf.png)

## The End

I really thank you for making it to the end! I tried to simplify things as much as possible 🙂

I want to send special thanks and give credit to **[Victor
Shamallah](https://computingforgeeks.com/author/cloud_eng/)** and **[Alex
Ellis](https://www.alexellis.io/)** I also hope this guide was helpful to the readers and
the newcomers. If you have learned something new, feel free to share. If you have any
feedback/suggestions/problems, spam in the comments section. Have a good day!

## References

- [Install K3S on Ubuntu with Docker](https://computingforgeeks.com/install-kubernetes-on-ubuntu-using-k3s/)
- [K3S Installation Requirements](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/)
- [Kubernetes Ingress - Traefik](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
