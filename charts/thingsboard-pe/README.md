# ThingsBoard PE Helm Chart

This Helm chart deploys ThingsBoard Professional Edition on Oracle Cloud Infrastructure (OCI) with support for both monolith and microservices architectures.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Oracle Container Engine for Kubernetes (OKE) cluster
- OCI Block Volume storage class (`oci-bv`)
- ThingsBoard PE License Key

## Quick Start

### 1. Add the repository (if applicable)
```bash
helm repo add thingsboard-pe ./charts
```

### 2. Install with default microservices configuration
```bash
helm install my-thingsboard thingsboard-pe/thingsboard-pe \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="your-db-host.oci.com" \
  --set database.password="your-db-password"
```

### 3. Install with monolith configuration
```bash
helm install my-thingsboard thingsboard-pe/thingsboard-pe \
  --set global.deploymentMode="monolith" \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="your-db-host.oci.com" \
  --set database.password="your-db-password"
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.deploymentMode` | Deployment mode: "monolith" or "microservices" | `"microservices"` |
| `global.license.key` | ThingsBoard PE license key | `""` |
| `global.license.existingSecret` | Name of existing secret containing license | `""` |
| `global.oracle.storageClass` | OCI storage class | `"oci-bv"` |
| `global.oracle.loadBalancer.enabled` | Enable OCI Load Balancer | `true` |
| `global.oracle.loadBalancer.shape` | OCI LB shape | `"flexible"` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.host` | Database host | `"YOUR_OCI_DB_ENDPOINT"` |
| `database.port` | Database port | `5432` |
| `database.name` | Database name | `"thingsboard"` |
| `database.username` | Database username | `"thingsboard"` |
| `database.password` | Database password | `"YOUR_OCI_DB_PASSWORD"` |
| `database.existingSecret` | Existing secret for DB password | `""` |

### Queue Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `queue.type` | Queue type: "kafka" or "in-memory" | `"kafka"` |
| `queue.kafka.servers` | Kafka servers | `"tb-kafka:9092"` |
| `queue.kafka.replicationFactor` | Replication factor | `1` |

### Cache Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cache.type` | Cache type: "redis" or "caffeine" | `"redis"` |
| `cache.redis.host` | Redis host | `"tb-valkey"` |
| `cache.redis.port` | Redis port | `6379` |

## Installation Examples

### Monolith with External Database
```bash
helm install tb-monolith thingsboard-pe/thingsboard-pe \
  --set global.deploymentMode="monolith" \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="mydb.oci.com" \
  --set database.username="tbuser" \
  --set database.password="mypassword" \
  --set thirdParty.zookeeper.enabled=false \
  --set thirdParty.kafka.enabled=false \
  --set thirdParty.valkey.enabled=false
```

### Microservices with OCI Managed Services
```bash
helm install tb-micro thingsboard-pe/thingsboard-pe \
  --set global.deploymentMode="microservices" \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="autonomous-db.oci.com" \
  --set database.password="mypassword" \
  --set queue.kafka.servers="oci-streaming.us-ashburn-1.oci.oraclecloud.com:9092" \
  --set cache.redis.host="oci-cache.us-ashburn-1.rds.cloud.com" \
  --set thirdParty.zookeeper.enabled=false \
  --set thirdParty.kafka.enabled=false \
  --set thirdParty.valkey.enabled=false
```

### Development Setup with All Services
```bash
helm install tb-dev thingsboard-pe/thingsboard-pe \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="localhost" \
  --set database.password="password" \
  --set thirdParty.zookeeper.enabled=true \
  --set thirdParty.kafka.enabled=true \
  --set thirdParty.valkey.enabled=true
```

## Upgrading

```bash
helm upgrade my-thingsboard thingsboard-pe/thingsboard-pe \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.password="your-db-password"
```

## Uninstalling

```bash
helm uninstall my-thingsboard
```

## Architecture Modes

### Monolith Mode
- Single ThingsBoard node with all capabilities
- Includes transport protocols (MQTT, HTTP, CoAP)
- Suitable for smaller deployments
- Uses in-memory queuing by default

### Microservices Mode
- Separate services for core, transports, and executors
- Scalable architecture with Kafka and Redis
- Recommended for production deployments
- Transport services exposed via LoadBalancer

## Service Access

After installation, get the external IP addresses:

```bash
kubectl get svc -n thingsboard -o wide
```

### Web UI Access
- **Service**: `<release-name>-web-ui`
- **Port**: 80
- **Default credentials**: System Administrator / tenant@thingsboard.org / tenant

### Transport Access (Microservices)
- **MQTT**: `<release-name>-mqtt-transport` (port 1883)
- **HTTP**: `<release-name>-http-transport` (port 8080)  
- **CoAP**: `<release-name>-coap-transport` (port 5683/UDP)

## Troubleshooting

### Check pod status
```bash
kubectl get pods -n thingsboard
```

### Check logs
```bash
kubectl logs -f <pod-name> -n thingsboard
```

### Check persistent volumes
```bash
kubectl get pv,pvc -n thingsboard
```

### Database connectivity issues
```bash
kubectl exec -it <node-pod> -n thingsboard -- cat /config/thingsboard.conf
```

## Oracle Cloud Specific Notes

1. **Storage**: Uses `oci-bv` storage class for persistent volumes
2. **Load Balancer**: Configured with flexible shapes (10-100 Mbps)
3. **Networking**: Ensure security lists allow required ports
4. **Database**: Compatible with Oracle Autonomous Database for PostgreSQL
5. **Cache**: Works with OCI Cache with Valkey
6. **Streaming**: Compatible with OCI Streaming (Kafka-compatible)

## Values Files

See the `values.yaml` file for all configuration options.

For production deployments, create custom values files:

```bash
helm install my-thingsboard thingsboard-pe/thingsboard-pe -f production-values.yaml
```

## Support


