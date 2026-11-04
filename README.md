# solar-deployment

## Why maintain a separate repository for deployment configuration ?

- It makes it possible to control the deployment of all the system components from a single place.
- It allows focused version-control, auditing, and compliance checks before deploying anything to production.
- It fits the GitOps approach, where delivery and deployment tasks are decoupled.

## 🐳 Local Development with Docker (Linux)

When running the system via Docker Compose on Linux, the `host.docker.internal` hostname is not resolved automatically inside containers or on the host machine. This hostname is required so that both the services (inside Docker) and your browser (outside Docker) can use the same OIDC Issuer URL for Keycloak.

### 1. `docker-compose.yml` Configuration

The `edge-service` is configured with `extra_hosts` to map `host.docker.internal` to the host's gateway:

```yaml
  edge-service:
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      - SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_KEYCLOAK_ISSUER_URI=http://host.docker.internal:8080/realms/SolarBookshop
```

### 2. Host Machine Configuration

To allow your web browser to reach Keycloak via the same URL, add `host.docker.internal` to your local `/etc/hosts` file:

- Open the file: `sudo nano /etc/hosts` then add `127.0.0.1 host.docker.internal`
- Or run `echo "127.0.0.1 host.docker.internal" | sudo tee -a /etc/hosts`

## ☸️ Local Development with Kubernetes (Minikube)

On Kubernetes, Pods within the cluster access Keycloak via its Service name (e.g., `http://solar-keycloak`). However, when Spring Security redirects a user to Keycloak to log in, the browser will fail because it cannot resolve the cluster-internal hostname `solar-keycloak` outside the cluster.

To fix this, you must map the `solar-keycloak` hostname to the cluster's IP address in your local hosts file.

### 1. Identify the Cluster IP

Run the following command to get the IP address of your Minikube node:

```bash
minikube profile list
```

### 2. Update Host Machine Configuration

Map the solar-keycloak hostname to the IP returned by the previous command.

- Linux / macOS:

```bash
# Replace <ip-address> with the result of 'minikube ip'
echo "<ip-address> solar-keycloak" | sudo tee -a /etc/hosts
```

- Windows (PowerShell as Admin):

```bash
Add-Content C:\Windows\System32\drivers\etc\hosts "127.0.0.1 solar-keycloak"
```

## ⚙️ Configuration & Secrets Management

For details on externalized configuration, ConfigMaps, Secrets, Kustomize bases/overlays, and automated zero-downtime rolling restarts (with `catalog-service` as reference): 👉 **[Configuration & Secrets Management Guide](CONFIG_SECRET_MANAGEMENT.md)**

## 🚢 Continuous Delivery & GitOps

For details on the continuous delivery pipeline (Commit Stage, Acceptance/Staging Stage, Production Delivery, and GitOps with Argo CD): 👉 **[Continuous Delivery & GitOps Guide](CONTINUOUS_DELIVERY.md)**

## 🔭 Observability & Monitoring

For details on the observability and monitoring stack (Grafana, Prometheus, Loki, Fluent Bit, Tempo, OpenTelemetry, and Spring Boot Actuator) and how to query logs, metrics, and traces: 👉 **[Observability & Monitoring Guide](OBSERVABILITY.md)**

## 🚀 Minikube Cheatsheet

### 1. Cluster Lifecycle & Environment

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **Start cluster** | `minikube start` | Starts default single-node cluster |
| **Start with custom resources** | `minikube start --cpus 4 --memory 8192 --driver docker` | Recommended allocation for microservice suites |
| **Check cluster status** | `minikube status` | Verify control plane, kubelet, and runtime status |
| **Get cluster node IP** | `minikube ip` | IP used for `/etc/hosts` resolution and routing |
| **Pause / Stop cluster** | `minikube pause` / `minikube stop` | `stop` pauses container/VM while preserving state |
| **Delete cluster** | `minikube delete` | Cleans up VM, container, and all cluster state |
| **List profiles** | `minikube profile list` | View all configured local clusters |
| **Start specific profile** | `minikube start -p <profile-name>` | Switch to and start a specific cluster profile |

### 2. Networking & Service Access

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **Network tunnel** | `minikube tunnel` | Routes `LoadBalancer` services directly to localhost *(keeps shell open)* |
| **Open service in browser** | `minikube service <service-name>` | Automatically opens browser or prints external URL |
| **List exposed services** | `minikube service list` | View reachable URLs across all active services |
| **Kubernetes Dashboard** | `minikube dashboard` | Launches the web-based administrative dashboard |

### 3. Addons & Docker Runtime

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **List addons** | `minikube addons list` | View available and enabled addons |
| **Enable addon** | `minikube addons enable <addon>` | Common addons: `ingress`, `metrics-server` |
| **Use Minikube's Docker daemon** | `eval $(minikube docker-env)` | Build images directly inside Minikube (`docker build ...`) |
| **Load local image into cluster** | `minikube image load <image:tag>` | Push an existing host image directly into Minikube |

### 4. Diagnostics & Maintenance

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **SSH into cluster node** | `minikube ssh` | Direct shell access to inspect node and container runtime |
| **View Minikube logs** | `minikube logs` | Inspect VM boot, kubelet, and driver logs |
| **Mount local directory** | `minikube mount <local-path>:<node-path>` | Mount local files/directories into the Minikube node |

---

## 🔧 kubectl Cheatsheet

### 1. Cluster Context & Namespaces

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **Cluster info** | `kubectl cluster-info` | Verify API server connection and control plane |
| **Version check** | `kubectl version` | Verify client and server Kubernetes versions |
| **List contexts** | `kubectl config get-contexts` | View all available kubeconfig contexts |
| **Switch context** | `kubectl config use-context <context>` | Switch active cluster/user context |
| **Set default namespace** | `kubectl config set-context --current --namespace=<ns>` | Avoid typing `-n <ns>` for every subsequent command |
| **List API resources** | `kubectl api-resources` | Reference all supported resource kinds and aliases (`po`, `svc`, `deploy`, `ing`) |

### 2. Inspecting & Querying Resources

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **List pods** | `kubectl get pods` | List pods in current namespace |
| **List pods (wide view)** | `kubectl get pods -A -o wide` | View pods across all namespaces with node and IP details |
| **Watch pods in real-time** | `kubectl get pods -w` | Stream status updates (e.g., during startup/rollouts) |
| **Inspect all resources** | `kubectl get all -n <namespace>` | High-level summary of pods, services, deployments |
| **Describe resource** | `kubectl describe <type> <name>` | Detailed status, lifecycle events, probe failures, and conditions |
| **Export resource definition** | `kubectl get deploy <name> -o yaml` | View live cluster manifest in YAML format |
| **Node resource usage** | `kubectl top nodes` | Inspect node CPU and memory consumption |
| **Pod resource usage** | `kubectl top pods` | Inspect pod CPU and memory metrics *(requires `metrics-server`)* |

### 3. Deployments & Lifecycle Management

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **Apply manifests** | `kubectl apply -f <path>/` | Declarative create or update from files/directories |
| **Delete manifests** | `kubectl delete -f <path>/` | Teardown resources defined in files/directories |
| **Restart deployment** | `kubectl rollout restart deploy/<name>` | Trigger a rolling restart (picks up new image tags / configs) |
| **Check rollout status** | `kubectl rollout status deploy/<name>` | Monitor rolling update progress in real time |
| **Rollback deployment** | `kubectl rollout undo deploy/<name>` | Revert to previous deployment revision |
| **Scale deployment** | `kubectl scale deploy/<name> --replicas=3` | Imperatively adjust replica count |

### 4. Debugging & Troubleshooting

| Task / Purpose | Command | Notes / Example |
| :--- | :--- | :--- |
| **Stream pod logs** | `kubectl logs -f <pod-name>` | Follow live log output of a specific pod |
| **Stream deployment logs** | `kubectl logs -f deployment/<name>` | Follow logs across all pods managed by a deployment |
| **View crashed container logs** | `kubectl logs <pod-name> --previous` | View logs from preceding container crash (`CrashLoopBackOff`) |
| **Interactive container shell** | `kubectl exec -it <pod-name> -- sh` | Open terminal inside container (`sh` or `bash`) |
| **Port forward to localhost** | `kubectl port-forward svc/<service-name> 8080:8080` | Route service/pod traffic directly to `localhost` |
| **Recent cluster events** | `kubectl get events --sort-by='.metadata.creationTimestamp'` | Chronological log of cluster warnings, failures, and schedules |

### 💡 Daily Productivity Tips

```bash
# Recommended shell aliases (.bashrc / .zshrc)
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deployment"
alias kl="kubectl logs -f"
alias kd="kubectl describe"

# Generate manifest boilerplate without creating resources
kubectl create deployment my-service --image=my-image:latest --dry-run=client -o yaml > deployment.yaml
```
