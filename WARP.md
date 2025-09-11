# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This repository contains Kubernetes deployment manifests and scripts for ThingsBoard Professional Edition (PE) across multiple cloud platforms: AWS, Azure, GCP, Oracle Cloud (OCI), Minikube, and OpenShift.

## High-Level Architecture

### Deployment Types
- **Monolith**: Single-node deployment with all ThingsBoard components in one container
- **Microservices**: Distributed deployment with separate services for core, transport, integration executor, web UI, and web report services

### Core Components
- **ThingsBoard Node**: Core application server with rule engine and APIs
- **Transport Services**: MQTT, HTTP, CoAP, LwM2M, SNMP protocol handlers
- **Integration Executor**: Handles external integrations and data processing
- **Web UI**: Frontend React application
- **Web Report**: PDF report generation service
- **JS Executor**: Remote JavaScript evaluation service

### Third-party Dependencies
- **Database**: PostgreSQL (Amazon RDS, Azure Database, GCP Cloud SQL, Oracle Autonomous DB)
- **Message Queue**: Apache Kafka or in-memory queues
- **Cache**: Redis/Valkey for session and cache storage
- **Coordination**: Apache Zookeeper for distributed coordination

## Common Development Tasks

### Deploy to a new cloud platform
1. Create platform-specific folder structure: `platform/monolith/` and `platform/microservices/`
2. Adapt configmaps for platform-specific database and service endpoints
3. Update storage classes and load balancer annotations
4. Create deployment scripts following the naming pattern: `k8s-deploy-resources.sh`, `k8s-install-tb.sh`, `k8s-upgrade-tb.sh`, `k8s-delete-resources.sh`

### Deploy using Helm (Recommended)
```bash
# Deploy microservices with Helm
helm install my-thingsboard ./charts/thingsboard-pe \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="your-db-host.oci.com" \
  --set database.password="your-db-password"

# Deploy monolith with Helm
helm install my-thingsboard ./charts/thingsboard-pe \
  --values ./charts/thingsboard-pe/values-monolith.yaml \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.host="your-db-host.oci.com" \
  --set database.password="your-db-password"
```

### Test deployments (Legacy kubectl)
```bash
# For monolith deployment
cd platform/monolith
./k8s-deploy-resources.sh
./k8s-install-tb.sh

# For microservices deployment  
cd platform/microservices
./k8s-deploy-resources.sh
./k8s-install-tb.sh
```

### Upgrade ThingsBoard version

**Using Helm:**
```bash
helm upgrade my-thingsboard ./charts/thingsboard-pe \
  --set global.license.key="YOUR_LICENSE_KEY" \
  --set database.password="your-db-password"
```

**Using kubectl (Legacy):**
1. Update image tags in YAML manifests (typically `thingsboard/tb-pe-*:X.Y.ZPE`)
2. Run platform-specific upgrade script: `./k8s-upgrade-tb.sh`

### Debug deployment issues
```bash
# Check pod status
kubectl get pods -n thingsboard

# Check logs
kubectl logs -f <pod-name> -n thingsboard

# Check services and external IPs
kubectl get svc -n thingsboard

# Check persistent volumes
kubectl get pv,pvc -n thingsboard
```

## Platform-Specific Considerations

### AWS
- Uses ELB/ALB for load balancers
- Storage class: `gp2` or `gp3`
- Node selectors for dedicated instance groups

### Azure  
- Uses Azure Load Balancer
- Storage class: `default` or `managed-premium`
- Availability zone spread

### GCP
- Uses GCP Load Balancer
- Storage class: `standard-rwo`
- Regional persistent disks

### Oracle Cloud (OCI)
- Uses OCI Load Balancer with flexible shapes
- Storage class: `oci-bv` (Block Volume)
- Integration with OCI managed services (Cache, Streaming)

### OpenShift
- Uses OpenShift Routes instead of Ingress
- Security context constraints
- Template-based deployments

### Minikube
- Uses NodePort services for external access
- Local storage
- Simplified configuration for development

## Configuration Patterns

### Database Configuration
All platforms use similar database configuration via ConfigMaps:
```yaml
SPRING_DATASOURCE_URL: jdbc:postgresql://endpoint:5432/thingsboard
SPRING_DATASOURCE_USERNAME: username
SPRING_DATASOURCE_PASSWORD: password
```

### Kafka Configuration
Microservices deployments use Kafka configuration:
```yaml
TB_QUEUE_TYPE: kafka
TB_KAFKA_SERVERS: kafka-service:9092
```

### Cache Configuration  
Redis/Valkey configuration for session storage:
```yaml
CACHE_TYPE: redis
REDIS_HOST: redis-service
```

## Security Considerations

### License Management
ThingsBoard PE requires a license key stored as Kubernetes secret:
```bash
kubectl create secret generic tb-license \
  --from-literal=license-key="YOUR_LICENSE_KEY"
```

### Database Credentials
Store database passwords as secrets, not in ConfigMaps.

### Transport Security
MQTT/HTTP transport services support SSL/TLS termination.

## Bitnami Image Migration

**Important**: This repository is affected by Bitnami's image archival. Images like `bitnami/kafka` and `bitnami/valkey` are being moved to `bitnamilegacy/*` as of August 28, 2025. See `BITNAMI-IMAGE-MIGRATION.md` for migration guidance.

## File Structure Patterns

Each platform follows this structure:
```
platform/
├── README.md
├── monolith/
│   ├── tb-namespace.yml
│   ├── tb-node-db-configmap.yml  
│   ├── tb-node-configmap.yml
│   ├── tb-node.yml
│   ├── database-setup.yml
│   └── k8s-*.sh scripts
└── microservices/
    ├── tb-namespace.yml
    ├── thirdparty.yml (Kafka, Zookeeper, Redis)
    ├── tb-*-configmap.yml files
    ├── tb-services.yml
    ├── transports/ (MQTT, HTTP, CoAP, etc.)
    ├── database-setup.yml  
    └── k8s-*.sh scripts
```

## Helm Chart Structure

The repository also includes a comprehensive Helm chart:
```
charts/
└── thingsboard-pe/
    ├── Chart.yaml
    ├── values.yaml (default microservices)
    ├── values-monolith.yaml (monolith configuration)
    ├── README.md
    └── templates/
        ├── _helpers.tpl
        ├── namespace.yaml
        ├── secrets.yaml
        ├── configmaps.yaml
        ├── node.yaml
        ├── web-ui.yaml
        ├── thirdparty.yaml
        └── transports/
            ├── mqtt-transport.yaml
            ├── http-transport.yaml
            └── coap-transport.yaml
```

## Important Notes

- Always update database connection details before deployment
- Ensure proper storage classes are available in target cluster
- Load balancer annotations vary significantly between cloud providers
- Resource requests/limits should be adjusted based on expected load
- Third-party services (Kafka, Redis, Zookeeper) should be ready before ThingsBoard services
- Database initialization is required for fresh deployments using `install.sh --loadDemo`
