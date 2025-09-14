# ThingsBoard Community Edition Helm Chart

This Helm chart deploys ThingsBoard Community Edition on Kubernetes with support for both monolith and microservices architectures, optimized for Oracle Cloud Infrastructure (OCI).

## Prerequisites

- Kubernetes 1.16+
- Helm 3.2.0+
- PostgreSQL database (external or in-cluster)
- For microservices mode: Kafka and Redis/Valkey

## Installation

### Quick Start (Monolith Mode)

```bash
# Add the ThingsBoard repository
helm repo add thingsboard https://your-repo-url

# Install with default values (monolith mode)
helm install thingsboard-ce charts/thingsboard-ce \
  --set database.host=your-postgres-host \
  --set database.username=thingsboard \
  --set database.password=thingsboard
```

### Microservices Mode

```bash
# Install in microservices mode
helm install thingsboard-ce charts/thingsboard-ce \
  --set global.deploymentMode=microservices \
  --set database.host=your-postgres-host \
  --set database.username=thingsboard \
  --set database.password=thingsboard \
  --set queue.type=kafka \
  --set queue.kafka.servers=kafka:9092 \
  --set cache.redis.enabled=true \
  --set cache.redis.host=redis
```

### Oracle Cloud Infrastructure (OCI) Optimized

```bash
# Deploy with OCI optimizations
helm install thingsboard-ce charts/thingsboard-ce \
  --set global.oracle.enabled=true \
  --set global.oracle.storageClass=oci-bv \
  --set global.oracle.loadBalancer.enabled=true \
  --set global.oracle.loadBalancer.shape=flexible \
  --set service.type=LoadBalancer
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.deploymentMode` | Deployment mode: `monolith` or `microservices` | `monolith` |
| `image.repository` | ThingsBoard CE image repository | `thingsboard/tb-postgres` |
| `image.tag` | ThingsBoard CE image tag | `3.6.4SNAPSHOT` |
| `database.host` | Database host | `localhost` |
| `database.port` | Database port | `5432` |
| `database.name` | Database name | `thingsboard` |
| `database.username` | Database username | `thingsboard` |
| `database.password` | Database password | `thingsboard` |
| `service.type` | Service type | `ClusterIP` |
| `service.httpPort` | HTTP service port | `8080` |

### Global Configuration

#### Oracle Cloud Infrastructure

```yaml
global:
  oracle:
    enabled: true
    storageClass: "oci-bv"
    loadBalancer:
      enabled: true
      shape: "flexible"
      minBandwidth: "10"
      maxBandwidth: "100"
```

#### Deployment Mode

```yaml
global:
  deploymentMode: "monolith"  # or "microservices"
```

### Database Configuration

```yaml
database:
  type: "postgresql"
  host: "postgres.default.svc.cluster.local"
  port: 5432
  name: "thingsboard"
  username: "thingsboard"
  password: "thingsboard"
  existingSecret: ""  # Use existing secret instead of creating one
```

### Monolith Configuration

```yaml
monolith:
  replicaCount: 1
  loadDemo: false
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
```

### Microservices Configuration

```yaml
microservices:
  core:
    replicaCount: 1
    loadDemo: false
    resources:
      requests:
        cpu: "1"
        memory: "2Gi"
      limits:
        cpu: "2"
        memory: "4Gi"

transports:
  mqtt:
    enabled: true
    replicaCount: 1
    image:
      repository: "thingsboard/tb-ce-mqtt-transport"
      tag: ""
    service:
      type: "ClusterIP"
      port: 1883

  http:
    enabled: true
    replicaCount: 1
    image:
      repository: "thingsboard/tb-ce-http-transport"
      tag: ""
    service:
      type: "ClusterIP"
      port: 8081

  coap:
    enabled: true
    replicaCount: 1
    image:
      repository: "thingsboard/tb-ce-coap-transport"
      tag: ""
    service:
      type: "ClusterIP"
      port: 5683
```

### Queue Configuration

```yaml
queue:
  type: "in-memory"  # or "kafka"
  kafka:
    servers: "kafka:9092"
    host: "kafka.default.svc.cluster.local"
    port: 9092
```

### Cache Configuration

```yaml
cache:
  redis:
    enabled: false
    host: "redis.default.svc.cluster.local"
    port: 6379
    password: ""
    existingSecret: ""
```

### Persistence

```yaml
persistence:
  enabled: true
  size: "20Gi"
  storageClass: "oci-bv"
```

### Service Configuration

```yaml
service:
  type: "ClusterIP"  # or "LoadBalancer", "NodePort"
  httpPort: 8080
  mqttPort: 1883      # Only for monolith mode
  coapPort: 5683      # Only for monolith mode
  annotations: {}
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
```

## Deployment Examples

### 1. Development Environment (Monolith)

```yaml
# values-dev.yaml
global:
  deploymentMode: monolith

monolith:
  replicaCount: 1
  loadDemo: true

database:
  host: "postgres.default.svc.cluster.local"
  username: "thingsboard"
  password: "thingsboard"

persistence:
  enabled: true
  size: "10Gi"

service:
  type: "NodePort"
```

Deploy:
```bash
helm install tb-dev charts/thingsboard-ce -f values-dev.yaml
```

### 2. Production Environment (Microservices)

```yaml
# values-prod.yaml
global:
  deploymentMode: microservices
  oracle:
    enabled: true
    loadBalancer:
      enabled: true

microservices:
  core:
    replicaCount: 2
    resources:
      requests:
        cpu: "2"
        memory: "4Gi"
      limits:
        cpu: "4"
        memory: "8Gi"

transports:
  mqtt:
    enabled: true
    replicaCount: 2
  http:
    enabled: true
    replicaCount: 2
  coap:
    enabled: false

queue:
  type: "kafka"
  kafka:
    servers: "kafka.kafka.svc.cluster.local:9092"

cache:
  redis:
    enabled: true
    host: "redis.redis.svc.cluster.local"

database:
  host: "postgres.database.svc.cluster.local"
  username: "thingsboard"
  password: "your-secure-password"

service:
  type: "LoadBalancer"
```

Deploy:
```bash
helm install tb-prod charts/thingsboard-ce -f values-prod.yaml
```

## Upgrading

```bash
# Upgrade to a new chart version
helm upgrade thingsboard-ce charts/thingsboard-ce

# Upgrade with new values
helm upgrade thingsboard-ce charts/thingsboard-ce -f new-values.yaml
```

## Uninstalling

```bash
helm uninstall thingsboard-ce
```

## Monitoring and Logging

The chart includes:
- Health checks for all services
- Resource requests and limits
- Pod anti-affinity rules for high availability
- Log volume mounts for centralized logging

Access logs:
```bash
kubectl logs -f deployment/thingsboard-ce
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Verify database connectivity
   - Check database credentials in secrets
   - Ensure database is initialized

2. **Pod Startup Issues**
   - Check init container logs
   - Verify resource limits
   - Check persistent volume availability

3. **Service Discovery Issues (Microservices)**
   - Verify Kafka connectivity
   - Check Redis connectivity
   - Ensure proper service naming

### Debugging Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=thingsboard-ce

# View pod logs
kubectl logs -f pod/thingsboard-ce-xxx

# Describe resources
kubectl describe statefulset/thingsboard-ce

# Check services
kubectl get svc -l app.kubernetes.io/name=thingsboard-ce
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## License

This Helm chart is licensed under the Apache License 2.0.
