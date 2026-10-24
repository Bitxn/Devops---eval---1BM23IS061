# Multi-Node Kubernetes Cluster — E-commerce (ReplicaSets across nodes)

Deploy two Python services on a **3-node Minikube cluster**, each with multiple
replicas spread across different nodes for high availability and fault tolerance.

| Service | App | Replicas | Endpoint |
|---|---|---|---|
| Product Catalog | `AppA` (Flask) | 2 | `GET /products` |
| Shopping Cart | `AppB` (Flask) | 3 | `GET /cart`, `POST /cart` |

Pod **anti-affinity** (`topologyKey: kubernetes.io/hostname`) forces each replica of
a service onto a **different node**, so no single node failure takes the service down.

## Repo contents

```
.
├── product_catalog.py                 # AppA – Flask product catalog
├── shopping_cart.py                   # AppB – Flask shopping cart
├── Dockerfile.product                 # image: product-catalog:latest
├── Dockerfile.shopping                # image: shopping-cart:latest
├── product_catalog_deployment.yaml    # Deployment, 2 replicas, anti-affinity
├── shopping_cart_deployment.yaml      # Deployment, 3 replicas, anti-affinity
├── product_catalog_service.yaml       # NodePort service
└── shopping_cart_service.yaml         # NodePort service
```

> ⚠️ **Known gotcha (kept faithful to the exercise):**
> `shopping_cart_deployment.yaml` declares `namespace: devops-exercise`, but its
> Service is in `default`. A Service only selects Pods in its **own** namespace, so
> the Shopping Cart service will match **zero** pods as written. Fix one of these:
> - change the deployment to `namespace: default` (simplest), **or**
> - `kubectl create namespace devops-exercise` and move the Service there too.

---

## Step 0 — Clean up any existing Minikube
```bash
minikube stop
minikube delete
```

## Step 1a — Start Minikube with 3 nodes
```bash
minikube start --nodes 3 -p devops-multinode --force
```
`--force` is only needed because the docker driver normally refuses to run as root.

## Step 1b — Enable the registry add-on (shares images across nodes)
```bash
minikube -p devops-multinode addons enable registry
```
In a multi-node cluster you can't use `eval $(minikube docker-env)`; the registry
add-on lets all nodes pull the images you load.

## Step 2–3 — The apps
Already in this repo: `product_catalog.py` (`/products`) and `shopping_cart.py`
(`/cart` GET/POST). Both listen on port **80**.

## Step 4 — Build the images
```bash
docker build -t product-catalog:latest -f Dockerfile.product .
docker build -t shopping-cart:latest -f Dockerfile.shopping .
docker images   # should list product-catalog and shopping-cart
```

## Step 5 — Load images into the cluster
```bash
minikube -p devops-multinode image load product-catalog:latest
minikube -p devops-multinode image load shopping-cart:latest

# verify
minikube -p devops-multinode ssh -- docker images
```

## Step 6 — Deploy (ReplicaSets)
```bash
kubectl apply -f product_catalog_deployment.yaml
kubectl apply -f shopping_cart_deployment.yaml
```

## Step 7 — Expose the services
```bash
kubectl apply -f product_catalog_service.yaml
kubectl apply -f shopping_cart_service.yaml
```

## Step 8 — Verify distribution across nodes
```bash
kubectl get pods -o wide
```
Each replica should land on a different `NODE` (devops-multinode / -m02 / -m03).

## Step 9 — Access the services (keep each terminal open)
```bash
minikube -p devops-multinode service product-catalog-service
minikube -p devops-multinode service shopping-cart-service
```
Each prints a `http://127.0.0.1:<port>` tunnel URL. Note both URLs.

## Step 10 — Test with curl
```bash
# Product catalog
curl http://127.0.0.1:<catalog-port>/products

# Shopping cart (empty initially)
curl http://127.0.0.1:<cart-port>/cart

# Add an item
curl -X POST http://127.0.0.1:<cart-port>/cart \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "name": "Laptop", "quantity": 1}'
```

## Cleanup
```bash
kubectl delete -f product_catalog_service.yaml -f shopping_cart_service.yaml
kubectl delete -f product_catalog_deployment.yaml -f shopping_cart_deployment.yaml
minikube -p devops-multinode delete
```
