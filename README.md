# Deploy a Flask App on Minikube (kubectl + YAML)

Single-node Kubernetes exercise: build a Flask app into a local Docker image,
deploy it with a Deployment, then expose it with a NodePort Service so you can
reach it from your machine.

## Repo contents

```
.
├── app.py                  # Flask app, listens on 0.0.0.0:15000, returns a hello string
├── Dockerfile              # python:3.8-slim, installs flask, runs app.py
├── flask-deployment.yaml   # Deployment (1 replica) + NodePort Service, both on 15000
└── README.md
```

> The Deployment uses `imagePullPolicy: Never` so Kubernetes uses the **local**
> `flask-app:latest` image you build into Minikube's Docker daemon, instead of
> pulling from a registry like Docker Hub.

---

## Minikube cheat sheet
```bash
minikube start            # start cluster (default settings)
minikube stop             # stop without deleting
minikube delete           # delete the cluster
minikube status           # check status
kubectl cluster-info      # cluster info
minikube service <name>   # open a service in the browser
minikube dashboard        # open the k8s dashboard
minikube ssh              # ssh into the VM
```

## Step 1 — Start Minikube
```bash
minikube start
```

## Step 2–3 — The app & image
`app.py` and `Dockerfile` are in this repo. The app serves
`"Hello from Flask on Kubernetes!"` on port **15000**.

## Step 4 — Build the image inside Minikube's Docker daemon
```bash
minikube docker-env        # shows the variables that will be set
eval $(minikube docker-env)
docker build -t flask-app .
```
`eval $(minikube docker-env)` points your Docker CLI at Minikube's daemon, so the
image is built **inside** the cluster and is available locally to Kubernetes.

> On Windows PowerShell, use `& minikube -p minikube docker-env --shell powershell | Invoke-Expression`
> instead of `eval $(...)`. The `eval` form is for bash/WSL.

## Step 5–6 — Deploy
```bash
kubectl apply -f flask-deployment.yaml
```

## Step 7–8 — Verify
```bash
kubectl get deployments
kubectl get pods -l app=flask-app        # STATUS should be Running
```

## Step 9–10 — Inspect
```bash
kubectl describe deployment flask-app
kubectl logs <flask-app-pod-name>        # from `kubectl get pods`
```

## Step 11–12 — Why curl fails directly
```bash
kubectl get services
curl http://127.0.0.1:15000   # fails: port 15000 is internal to the cluster, not exposed on your host
```

## Step 13 — Expose with the Service and access it
The `Service` block in `flask-deployment.yaml` maps
**external request → Service (15000) → container targetPort (15000)**.

```bash
kubectl apply -f flask-deployment.yaml      # creates flask-app-service

# Get a reachable URL (keep this terminal open — required with the Docker driver)
minikube service flask-app-service --url
# e.g. http://127.0.0.1:36157
```

In a second terminal:
```bash
curl http://127.0.0.1:<port-from-above>
# Hello from Flask on Kubernetes!
```

### port vs targetPort
- **port** — the port the Service is exposed on (what clients hit).
- **targetPort** — the port the container/Flask app listens on.

Here both are `15000`, so: `localhost:15000 → Service:15000 → container:15000`.

## Cleanup
```bash
kubectl delete -f flask-deployment.yaml
minikube stop
```
