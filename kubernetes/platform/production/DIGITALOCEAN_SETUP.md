# Setup for DigitalOcean

## 1. Install doctl

install [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) for your os

## 2. Running k8s cluster on DigitalOcean

### Choose a region by running

```shell
doctl k8s options regions
```

### Create cluster

we are creating a cluster named `solar-cluster` with region `blr1`

```shell
doctl k8s cluster create solar-cluster \
    --node-pool "name=basicnp;size=s-2vcpu-4gb;count=3;label=type=basic;" \
    --region blr1
```

Use the `doctl kubernetes options sizes` command for a list of available options. Check out [docs](https://docs.digitalocean.com/reference/doctl/reference/kubernetes/cluster/create/) for more info.

confirm by running command:

```shell
doctl kube cluster list
```

At the end of the cluster provisioning, doctl will also configure the context for your Kubernetes CLI so that you can interact with the cluster running on DigitalOcean from your computer:

```shell
kubectl config current-context
```

Once the cluster is provisioned, you can get information about the worker nodes as follows:

```shell
kubectl get nodes
```

## 3. Running a PostgreSQL database on DigitalOcean

```shell
doctl databases create solar-db \
   --engine pg \
   --region blr1 \
   --version 18
```

get available db version using `doctl databases options versions`

Verify the installation using `doctl databases list`

```shell
doctl databases firewalls append <postgres_id> --rule k8s:<cluster_id>
```

let’s create two databases to be used by Catalog Service (solardb_catalog) and Order Service (solardb_order)

```shell
doctl databases db create <postgres_id> solardb_catalog
```

```shell
doctl databases db create <postgres_id> solardb_order
```

Get connection details

```shell
doctl databases connection <postgres_id> --format Host,Port,User,Password
```

Before concluding this section, let’s create some Secrets in the Kubernetes cluster with the PostgreSQL credentials required by the two applications. In a real-world scenario, we should create dedicated users for the two applications and grant limited privileges. For simplicity, we’ll use the admin account for both.

```shell
kubectl create secret generic solar-postgres-catalog-credentials \
   --from-literal=spring.datasource.url=
jdbc:postgresql://<postgres_host>:<postgres_port>/solardb_catalog \
   --from-literal=spring.datasource.username=<postgres_username> \
   --from-literal=spring.datasource.password=<postgres_password>
```

Similarly, create a Secret for Order Service. Pay attention to the slightly different syntax required by Spring Data R2DBC for the URL:

```shell
kubectl create secret generic solar-postgres-order-credentials \
   --from-literal="spring.flyway.url=
jdbc:postgresql://<postgres_host>:<postgres_port>/solardb_order" \
   --from-literal="spring.r2dbc.url=
r2dbc:postgresql://<postgres_host>:<postgres_port>/solardb_order?
ssl=true&sslMode=require" \
   --from-literal=spring.r2dbc.username=<postgres_username> \
   --from-literal=spring.r2dbc.password=<postgres_password>
```

## 4. Running Valkey(~~Redis~~) on DigitalOcean

> DigitalOcean no longer supports creating managed Redis clusters.

- Valkey 8 is redis protocol compatible
- Most Redis clients (Jedis, Lettuce, Spring Data Redis, node-redis, etc.) work without code changes.
- Suitable for caching, sessions, pub/sub, queues, and most common Redis use cases.

```shell
doctl databases create solar-valkey \
  --engine valkey \
  --region blr1 \
  --version 8
```

To mitigate unnecessary attack vectors, we can configure a firewall so that the Valkey server is only accessible from the Kubernetes cluster created previously.

```shell
doctl databases firewalls append <valkey_id> --rule k8s:<cluster_id>
```

Finally, let’s retrieve the details for connecting to Redis.

```shell
doctl databases connection <valkey_id> --format Host,Port,User,Password
```

let’s create a Secret in the Kubernetes cluster with the Valkey credentials required by Edge Service.

```shell
kubectl create secret generic solar-valkey-credentials \
   --from-literal=spring.redis.host=<redis_host> \
   --from-literal=spring.redis.port=<redis_port> \
   --from-literal=spring.redis.username=<redis_username> \
   --from-literal=spring.redis.password=<redis_password> \
   --from-literal=spring.redis.ssl=true
```

## 5. Running RabbitMQ using a Kubernetes Operator

A popular and convenient way of deploying and managing services like RabbitMQ in a Kubernetes cluster is to use the operator pattern. Operators are “software extensions to Kubernetes that make use of custom resources to manage applications and their components” ([Kubernetes documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/operator)). The RabbitMQ project provides an official Operator to run the event broker on a Kubernetes cluster ([RabbitMQ Cluster Operator](https://github.com/rabbitmq/cluster-operator)).

run [deploy.sh](./rabbitmq/deploy.sh) script to deploy RabbitMQ to your production Kubernetes cluster

Verify that the secret has been created successfully:

```shell
kubectl get secrets solar-rabbitmq-credentials
```

The RabbitMQ broker is deployed in a dedicated rabbitmq-system namespace. Applications can interact with it at `solar-rabbitmq.rabbitmq-system.svc.cluster.local` on port `5672`.

## 6. Running Keycloak using a Helm chart

Go ahead and install Helm on your computer. You can find the instructions on the [official website](https://helm.sh).

Then run the [deploy.sh](./keycloak/deploy.sh) to deploy Keycloak to your production Kubernetes cluster.

Finally, the script will create a `solar-keycloak-client-credentials` Secret with the Client secret that Edge Service will need to authenticate with Keycloak. You can verify that the Secret has been successfully created as follows. The script generates the value randomly:

```shell
kubectl get secrets solar-keycloak-client-credentials
```

The Keycloak server is deployed in a dedicated `keycloak-system` namespace. Applications can interact with it at solar-keycloak.`keycloak-system.svc.cluster.local` on port `80` from within the cluster. It’s also exposed outside the cluster via a public IP address. You can find the external IP address with the following command:

```shell
kubectl get service solar-keycloak -n keycloak-system
```

The platform might take a few minutes to provision a load balancer. During the provisioning, the `EXTERNAL-IP` column will show a `<pending>` status. Wait and try again until an IP address is shown. Note it down, since we’re going to use it in multiple scenarios.

Since Keycloak is exposed via a public load balancer, you can use the external IP address to access the Admin Console. Open a browser window, navigate to `http://<external-ip>/admin`, and log in with the credentials returned by the previous deployment script.

Now that you have a public DNS name for Keycloak, you can define a couple of Secrets to configure the Keycloak integration in Edge Service (OAuth2 Client), Catalog Service, and Order Service (OAuth2 Resource Servers) using following command:

```shell
./create-secrets.sh http://<external-ip>/realms/SolarBookshop
```

## 7. Running Solar UI

Solar UI is a single-page application built with Angular and served by NGINX. Run the [deploy.sh](./solar-ui/deploy.sh) to deploy Polar UI to your production Kubernetes cluster.

## 8. Deleting all cloud resources

When you’re done experimenting with the Solar Bookshop project, follow the instructions in this section to delete all the cloud resources created on DigitalOcean.

First, delete the Kubernetes cluster:

```shell
doctl k8s cluster delete solar-cluster
```

Next, delete the PostgreSQL and Redis databases. You’ll need to know their IDs first, so run this command to extract that information:

```shell
doctl databases list
```

```markdown
ID            Name         Engine  Version  Nodes  Region  Status  Size            Storage (MiB)
<solar-db-id> solar-db     pg      18       1      blr1    online  db-s-1vcpu-1gb  10240
<solar-db-id> solar-valkey valkey  8        1      blr1    online  db-s-1vcpu-1gb  0
```

Then go ahead and delete both of them using the resource identifiers returned by the previous command:

```shell
doctl databases delete <polar-db-id>
doctl databases delete <valkey-db-id>
```

Finally, open a browser window, navigate to the [DigitalOcean web interface](https://cloud.digitalocean.com), and go through the different categories of cloud resources in your account to verify that there’s no outstanding services. If there are, delete them. There could be load balancers or persistent volumes created as a side effect of creating a cluster or a database, and that may not have been deleted by the previous commands.
