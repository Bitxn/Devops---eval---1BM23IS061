# What happens when you run `kubectl run hello-k8s`

This traces the lifecycle of the Pod from the command line, through the **Control
Plane**, and onto a **Worker Node** — matching the flow in the exercise diagram.

```
kubectl ──REST API──> kube-apiserver ──> etcd
                            │
                            ▼
                      kube-scheduler ──> kubelet (worker) ──> CRI-O ──> CNI
                            ▲                                    │
                            └────────── status update ──────────┘
```

## 1. kubectl → kube-apiserver
The `kubectl` CLI connects to the **kube-apiserver**. It sends a **Pod manifest**
(as JSON) describing the desired object:

- Pod name: `hello-k8s`
- Container image: `nginx`
- Container port: `80`

> "Dear Kubernetes, please create this Pod for me."

## 2. kube-apiserver → etcd
The **kube-apiserver** receives the request and stores the Pod manifest in **etcd**
(the cluster's key-value store / source of truth).

> "There should be a Pod called `hello-k8s` running an nginx container on port 80."

## 3. kube-scheduler picks a node
The **kube-scheduler** watches etcd for unscheduled Pods. It chooses a **worker node**
that has enough CPU and memory to run the Pod.

## 4. Assignment handed to the node
The scheduling decision (which node runs the Pod) is recorded, and the target node's
agent is notified.

## 5. kubelet → CRI-O
The **kubelet** is the agent running on each worker node.

> "You run this Pod on your system."

The kubelet asks the container runtime, **CRI-O** (Container Runtime), to:

- **Pull** the Nginx image from Docker Hub (or another registry)
- **Create** a container from the image
- **Set up** the filesystem and mount volumes
- **Run** the process inside an isolated Linux namespace (PID, network, cgroup)

## 6. (kube-proxy)
**kube-proxy** on the node programs the networking rules so Services can route traffic
to the Pod.

## 7. CNI assigns networking
The **CNI (Container Network Interface)** plugin:

- Assigns a **unique IP address** to the Pod
- This IP is reachable **inside the cluster**

## 8. Status reported back
The **kubelet** updates the **kube-apiserver**:

> "Pod `hello-k8s` is running."

The apiserver writes the new status to etcd, and `kubectl get pods` now shows the Pod
as `Running`.

---

## Component cheat sheet

| Component | Where | Role |
|---|---|---|
| **kubectl** | your machine | CLI; sends desired state to the API server |
| **kube-apiserver** | control plane | front door; validates & stores all cluster state |
| **etcd** | control plane | key-value store; the single source of truth |
| **kube-scheduler** | control plane | decides which node runs each Pod |
| **kube-controller-manager** | control plane | reconciles actual state toward desired state |
| **cloud-controller-manager** | control plane | integrates with the cloud provider |
| **kubelet** | worker node | node agent; makes the node match its assigned Pods |
| **kube-proxy** | worker node | network rules for Service routing |
| **CRI-O** | worker node | container runtime; pulls images & runs containers |
| **CNI** | worker node | assigns Pod IPs and wires up networking |
