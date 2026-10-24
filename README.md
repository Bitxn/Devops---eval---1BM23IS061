# Scaling a Flask App on a Single Node with ReplicaSets

**Use case — E-commerce flash sale.** A single Pod crashes when traffic spikes from
100 to 10,000 req/min. A **ReplicaSet** runs N identical Pods and keeps that number
alive: scale out during the sale, scale back after, and self-heal if a Pod dies.

## What you'll see
- **Pod distribution** — each Pod is an identical clone of the app.
- **Resiliency** — kill a Pod and the ReplicaSet recreates it automatically.
- **Efficiency / scalability** — add Pods on demand, remove them when idle (how
  Netflix, YouTube, Swiggy handle peak hours).

The app reports which Pod served each request (`socket.gethostname()`), so you can
watch load spread across replicas.

## Repo contents
```
.
├── app.py                        # Flask flash-sale app: / , /buy , /health
├── Dockerfile                    # python:3.11-slim, gunicorn on :5000
├── flashsale-replicaset.yaml     # ReplicaSet (3 replicas) + ClusterIP Service
└── README.md
```

### Endpoints
- `/` — welcome message + pod name
- `/buy` — simulated checkout; random product, or `?user=123`; shows serving pod
- `/health` — readiness/liveness probe target

---

## ⚠️ Fixes applied to the handout (it was internally inconsistent)

The original exercise contradicted itself. This repo uses one coherent set of names:

| Thing | Handout said | Used here | Why |
|---|---|---|---|
| App file in Dockerfile | `COPY ex3-flash-sale.py .` | `COPY app.py .` | `gunicorn app:app` imports module **app** (app.py). `ex3-flash-sale` has hyphens → not a valid Python module. |
| Image tag (Step 5) | `docker build -t flask-app .` | `docker build -t flashsale:1.0 .` | The ReplicaSet references `image: flashsale:1.0`, not `flask-app`. |
| ReplicaSet name (Steps 6–11) | `flask-app-rs` | `flashsale-rs` | The YAML's `metadata.name` is `flashsale-rs`. The `flask-app-rs` lines in the handout are leftovers from the previous exercise. |

> **Tag note:** image `flashsale:1.0` (a non-`latest` tag) defaults to pull policy
> `IfNotPresent`, so once you build it inside Minikube's Docker daemon the cluster
> uses the local image without any registry — no `imagePullPolicy: Never` needed.

---

## Step 1 — Clean up any existing cluster
```bash
minikube stop
minikube delete
```

## Step 2 — Start a single-node cluster
```bash
minikube start --nodes=1
kubectl get nodes
```

## Step 3 — Build the image inside Minikube's Docker daemon
Point Docker at Minikube, then build so the cluster can see the image locally:
```bash
minikube docker-env                 # shows the vars that will be set
eval $(minikube docker-env)         # bash / WSL
docker build -t flashsale:1.0 .
```
On **Windows PowerShell** instead of `eval`:
```bash
& minikube docker-env --shell powershell | Invoke-Expression
docker build -t flashsale:1.0 .
```

> Alternative (push to Docker Hub instead of local build): build & push
> `<your-dockerhub-username>/flashsale:1.0`, then change `image:` in the YAML to match.

## Step 4 — Apply the ReplicaSet + Service
```bash
kubectl apply -f flashsale-replicaset.yaml
# replicaset.apps/flashsale-rs created
# service/flashsale-svc created
```

## Step 5 — Verify pods and the ReplicaSet
```bash
kubectl get pods
kubectl get rs
```

## Step 6 — Scale out to 5 replicas
```bash
kubectl scale rs flashsale-rs --replicas=5
kubectl get rs
kubectl get pods
```

## Step 7 — Test self-healing (delete a Pod)
```bash
kubectl delete pod <one-pod-name>     # from `kubectl get pods`
kubectl get pods                      # ReplicaSet recreates it → still 5
```

## Step 8 — See pod distribution across nodes
```bash
kubectl get pods -o wide              # single node: all 5 land on `minikube`
```

## Step 9 — Reach the app (Service is ClusterIP, internal only)
ClusterIP isn't exposed to your host, so use port-forward:
```bash
kubectl port-forward svc/flashsale-svc 8080:80
# then in another terminal:
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/buy?user=123     # repeat → "served_by_pod" changes
curl http://127.0.0.1:8080/health
```

---

## Q&A (quick answers)
1. Initial replicas: **3**
2. Pods after apply: **3**
3. Scaling to 5: Kubernetes adds **2** more pods → 5 running.
4. Delete a pod: the ReplicaSet **recreates** one → back to 5.
5. How it's maintained: the controller continuously **reconciles** actual vs desired count.
6. Nodes running: **1**
7. All 5 pods run on the **single** node (`minikube`).

## Additional challenges
- Swap the image for a different one.
- Convert the ReplicaSet into a **Deployment** (gains rolling updates/rollbacks).
- `kubectl describe rs flashsale-rs` and `kubectl describe pod <name>` to inspect events.
- `kubectl logs <pod>` and `kubectl exec -it <pod> -- sh` to poke inside.

## Cleanup
```bash
kubectl delete -f flashsale-replicaset.yaml
minikube stop
```
