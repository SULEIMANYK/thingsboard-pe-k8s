# Oracle Cloud Infrastructure deployment scripts

Here you can find scripts for different deployment scenarios using Oracle Cloud Infrastructure (OCI):

- [**monolith**](#monolith-deployment) - simplistic deployment of ThingsBoard monolith 
with Oracle Autonomous Database for PostgreSQL or OCI Database Service. 
Recommended for deployment scenarios that may sacrifice high availability to **optimize the cost**.
- [**microservices**](#microservices-deployment) - deployment of ThingsBoard microservices 
with Oracle Autonomous Database for PostgreSQL, OCI Streaming (Kafka-compatible), 
and OCI Cache with Valkey. Recommended for **scalable and highly available** deployments.

## Prerequisites

- OCI CLI configured with appropriate credentials
- kubectl installed and configured to work with your OKE cluster
- OKE cluster with at least 3 worker nodes
- OCI Block Volume storage class configured
- OCI Load Balancer service configured

## Monolith Deployment

### Step 1: Configure Database Connection

Create the database configuration by editing `monolith/tb-node-db-configmap.yml`:

```bash
cd oracle/monolith
```

Update the following environment variables with your Oracle Autonomous Database or OCI Database Service connection details:

- `SPRING_DATASOURCE_URL`: Your database JDBC URL
- `SPRING_DATASOURCE_USERNAME`: Your database username
- `SPRING_DATASOURCE_PASSWORD`: Your database password

### Step 2: Deploy ThingsBoard

```bash
./k8s-deploy-resources.sh
./k8s-install-tb.sh
```

### Step 3: Access ThingsBoard

After deployment, access the ThingsBoard UI using the OCI Load Balancer external IP.

## Microservices Deployment

### Step 1: Configure Database and Services

```bash
cd oracle/microservices
```

Update the following configuration files:
- `tb-node-db-configmap.yml`: Database connection details
- `tb-cache-configmap.yml`: OCI Cache with Valkey configuration
- `tb-kafka-configmap.yml`: OCI Streaming service configuration

### Step 2: Deploy Third-party Services

```bash
./k8s-deploy-resources.sh
```

### Step 3: Initialize Database

```bash
./k8s-install-tb.sh
```

### Step 4: Access Services

- ThingsBoard UI: Available via OCI Load Balancer
- Transport endpoints: MQTT (1883), HTTP (8080), CoAP (5683)

## OCI-Specific Considerations

### Storage Classes

The manifests use `oci-bv` storage class for persistent volumes. Ensure this is available in your OKE cluster.

### Load Balancers

OCI Load Balancer services are configured with the following annotations:
- `service.beta.kubernetes.io/oci-load-balancer-shape`: "flexible"
- `service.beta.kubernetes.io/oci-load-balancer-shape-flex-min`: "10"
- `service.beta.kubernetes.io/oci-load-balancer-shape-flex-max`: "100"

### Network Security

Ensure your OKE cluster security lists allow traffic on the required ports:
- HTTP: 80, 8080
- HTTPS: 443, 8443
- MQTT: 1883, 8883
- CoAP: 5683, 5684
- LwM2M: 5685-5688
- Edge: 7070

### Scaling Considerations

For production deployments, consider:
- Using Oracle Autonomous Database in dedicated mode
- Configuring OCI Cache with Valkey in cluster mode
- Setting up multiple availability domains for high availability
- Using OCI Container Engine for Kubernetes autoscaling features

## Troubleshooting

### Common Issues

1. **Pod Scheduling Issues**: Ensure your OKE cluster has sufficient resources and properly configured node pools.

2. **Storage Issues**: Verify that the `oci-bv` storage class is available and properly configured.

3. **Load Balancer Issues**: Check OCI Load Balancer configuration and security list rules.

4. **Database Connection Issues**: Verify network connectivity and security group rules for your database.

### Useful Commands

```bash
# Check pod status
kubectl get pods -n thingsboard

# Check logs
kubectl logs -f <pod-name> -n thingsboard

# Check services and load balancers
kubectl get svc -n thingsboard

# Check persistent volumes
kubectl get pv,pvc -n thingsboard
```
