# Kubernetes Hands-On — Exercise 1: Hello Pod

Run your first app inside Kubernetes and access it in the browser.

## Business Problem (Zepto Example)

You are a DevOps Engineer at **Zepto**. The product team just built a lightweight
web app that shows the storefront and delivery-status page for customers.

**Your task:** Deploy this app on Kubernetes so it is always running, portable, and
can be scaled later. We simulate the app using the popular `nginx` container image
(think of it as Zepto's storefront web app).

---

## Prerequisites

You need **Docker** or a VM driver (VirtualBox, Hyper-V) installed, plus `kubectl`
and **Minikube**.

### Install Minikube (one-time setup)

**Linux**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**macOS (Homebrew)**
```bash
brew install minikube
```

**Windows (PowerShell, run as Administrator)**
```powershell
choco install minikube
```

**WSL (Windows Subsystem for Linux)**
```bash
# Update system
sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https virtualbox virtualbox-ext-pack

# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube binary
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

---

## Steps — Deploy the Nginx image as a Pod (imperative)

**1. Start a local Kubernetes cluster with Minikube**
```bash
minikube start
```

**2. Create your first Pod (using the Nginx image)**
```bash
kubectl run hello-k8s --image=nginx --port=80
```

**3. Verify the Pod is running**
```bash
kubectl get pods
```

**4. Expose the Pod as a Service**
```bash
kubectl expose pod hello-k8s --type=NodePort --port=80
```

**5. Open the app in your browser**
```bash
minikube service hello-k8s
```

You should see the **Nginx welcome page**. Congratulations — you just deployed your
first container in Kubernetes! 🎉

---

## Alternative — the declarative way (recommended for DevOps)

Instead of typing imperative `kubectl run` commands, keep your desired state in YAML
files under version control. This repo ships both manifests in [`manifests/`](manifests/).

```bash
# Apply the Pod and the Service
kubectl apply -f manifests/pod.yaml
kubectl apply -f manifests/service.yaml

# Check status
kubectl get pods
kubectl get svc hello-k8s

# Open it
minikube service hello-k8s
```

To tear everything down:
```bash
kubectl delete -f manifests/service.yaml
kubectl delete -f manifests/pod.yaml
```

---

## What happens under the hood?

See [`docs/architecture.md`](docs/architecture.md) for a step-by-step walkthrough of
how `kubectl run hello-k8s` travels through the Control Plane and onto a Worker Node.

## Cleanup

```bash
minikube stop      # stop the cluster (keeps state)
minikube delete    # delete the cluster entirely
```
