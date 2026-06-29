# solar-deployment

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

- Open the file: `sudo nano /etc/hosts`
- Add the entry: `127.0.0.1 host.docker.internal`

or run
- `echo "127.0.0.1 host.docker.internal" | sudo tee -a /etc/hosts`

## ☸️ Local Development with Kubernetes (Minikube)

On Kubernetes, Pods within the cluster access Keycloak via its Service name (e.g., `http://solar-keycloak`). However, when Spring Security redirects a user to Keycloak to log in, the browser will fail because it cannot resolve the cluster-internal hostname `solar-keycloak` outside the cluster.

To fix this, you must map the `solar-keycloak` hostname to the cluster's IP address in your local hosts file.

### 1. Identify the Cluster IP
Run the following command to get the IP address of your Minikube node:
```bash
minikube ip
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

## 🚀 Minikube — Cluster & Environment Management

| Task / Purpose                                                        | Command / Example                                                                         |
|:----------------------------------------------------------------------|:------------------------------------------------------------------------------------------|
| Start a local cluster                                                 | `minikube start` ([Roy's Blog][mk-1])                                                     |
| Start with custom resources (memory, CPU, K8s version)                | `minikube start --cpus 2 --memory 4g --driver docker --profile dev` ([Jacob Weber][mk-2]) |
| Stop the cluster (pause the VM, keep state)                           | `minikube stop` ([Cloudutsuk][mk-3])                                                      |
| Delete the cluster (clean up VM + config)                             | `minikube delete` ([Cloudutsuk][mk-3])                                                    |
| Check cluster/VM status                                               | `minikube status` ([Cloudutsuk][mk-3])                                                    |
| Get the IP address of Minikube VM / node                              | `minikube ip` ([Cloudutsuk][mk-3])                                                        |
| Open the Kubernetes Dashboard in browser                              | `minikube dashboard` ([John CD][mk-4])                                                    |
| Use Minikube’s Docker daemon to build images for cluster              | `eval $(minikube docker-env)` then `docker build ...` ([John CD][mk-4])                   |
| View logs of Kubernetes components / Minikube VM                      | `minikube logs` ([Cloudutsuk][mk-3])                                                      |
| SSH into the Minikube VM (for debugging/container runtime inspection) | `minikube ssh` ([Jacob Weber][mk-2])                                                      |
| Manage Minikube per-profile (if using multiple clusters)              | `minikube profile list`, `minikube start -p <profile>`, etc. ([Cloudutsuk][mk-3])         |
| Enable or disable addons (e.g. ingress, metrics-server, etc.)         | `minikube addons enable <addon>`, `minikube addons disable <addon>` ([Jacob Weber][mk-2]) |

[mk-1]: https://shantoroy.com/kubernetes/learn-kubernetes-commands-operations-using-minikube/?utm_source=chatgpt.com "#100daysofSRE (Day 30): Learn Kubernetes Commands and Operations using Minikube - Roy’s Blog"
[mk-2]: https://jacobbweber.com/cheat-sheets/?utm_source=chatgpt.com "Cheat Sheets | Jacob Weber"
[mk-3]: https://cloudutsuk.com/posts/devops/orchestration/miscellaneous/minikube-commands-cheatsheet/?utm_source=chatgpt.com "Minikube CMDsheet | Cloudutsuk"
[mk-4]: https://john-cd.com/cheatsheets/Containers/Kubernetes_Cheatsheet/?utm_source=chatgpt.com "Kubernetes Cheatsheet - John's Cheatsheets"

## 🔧 kubectl — Cluster / Resource Management & Inspection

| Purpose / Use                                       | Sample Commands                                                                                                                |
|:----------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------|
| Check kubectl / cluster version / info              | `kubectl version`, `kubectl cluster-info` ([Mirantis][kc-1])                                                                   |
| View current kubeconfig / contexts                  | `kubectl config view`, `kubectl config get-contexts`, `kubectl config use-context <context>` ([Technology to the Point][kc-2]) |
| List nodes in the cluster                           | `kubectl get nodes`, `kubectl get nodes -o wide` ([Mirantis][kc-1])                                                            |
| Describe a node (or other resource)                 | `kubectl describe node <node-name>` ([GeeksforGeeks][kc-3])                                                                    |
| List all pods (possibly across namespaces)          | `kubectl get pods`, `kubectl get pods -A`, `kubectl get pods -o wide` ([Mirantis][kc-1])                                       |
| Describe a pod (see details/status)                 | `kubectl describe pod <pod-name>` ([Mirantis][kc-1])                                                                           |
| View logs of a pod (container)                      | `kubectl logs <pod-name>`, or with namespace/container flags, or follow: `-f` ([Metric Insights Help][kc-4])                   |
| Execute a command / get shell inside a container    | `kubectl exec -it <pod-name> -- /bin/sh` (or `/bin/bash`) ([Mirantis][kc-1])                                                   |
| Create resources (deployments/pods) imperatively    | `kubectl run <name> --image=<image> --replicas=2 --port=...` ([John CD][kc-5])                                                 |
| Create / apply resources declaratively              | `kubectl apply -f <manifest.yaml>` or `kubectl create -f <manifest.yaml>` ([HowtoForge][kc-6])                                 |
| Get various resources (deployments, services, etc.) | `kubectl get deployments`, `kubectl get services`, `kubectl get all` (or `--all-namespaces`) ([Developer Tools][kc-7])         |
| Describe / show details of resources                | `kubectl describe <resource> <name>` (e.g. deployment, service, pod) ([Cheat Sheet Factory][kc-8])                             |
| Delete resource(s)                                  | `kubectl delete <resource-type> <name>`; or delete all in namespace / all resources from a file ([Metric Insights Help][kc-4]) |
| View available API resources                        | `kubectl api-resources` ([HowtoForge][kc-6])                                                                                   |

[kc-1]: https://www.mirantis.com/blog/kubernetes-cheat-sheet/?utm_source=chatgpt.com "Kubernetes Cheat Sheet | Mirantis"
[kc-2]: https://www.technologytothepoint.com/2025/03/kubectl-essentials-must-know-commands.html?utm_source=chatgpt.com "Kubectl Essentials: Must-Know Commands for Kubernetes"
[kc-3]: https://www.geeksforgeeks.org/kubectl-cheatsheet/?utm_source=chatgpt.com "Kubectl Command Cheat Sheet - GeeksforGeeks"
[kc-4]: https://help.metricinsights.com/m/Deployment_and_Configuration/l/1234773-kubectl-commands-cheat-sheet?utm_source=chatgpt.com "Kubectl Commands Cheat Sheet | Deployment & Configuration | Help & Documentation"
[kc-5]: https://john-cd.com/cheatsheets/Containers/Kubernetes_Cheatsheet/?utm_source=chatgpt.com "Kubernetes Cheatsheet - John's Cheatsheets"
[kc-6]: https://www.howtoforge.com/kubernetes_commands/?utm_source=chatgpt.com "Cheat Sheet for Kubernetes Commands"
[kc-7]: https://devtoolcafe.com/tools/kubernetes-cheatsheet?utm_source=chatgpt.com "Kubernetes Cheatsheet - Quick Reference for Common kubectl Commands - Developer Tools"
[kc-8]: https://cheatsheetfactory.geekyhacker.com/container/kubectl?utm_source=chatgpt.com "kubectl cheatsheet"