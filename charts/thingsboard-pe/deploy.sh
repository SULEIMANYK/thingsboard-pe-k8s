#!/bin/bash
#
# ThingsBoard PE Helm Deployment Script
# This script simplifies the deployment of ThingsBoard PE using Helm
#

set -e

# Default values
RELEASE_NAME="thingsboard-pe"
NAMESPACE="thingsboard"
DEPLOYMENT_MODE="microservices"
CHART_DIR="."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to show help
show_help() {
    cat << EOF
ThingsBoard PE Helm Deployment Script

Usage: $0 [OPTIONS]

Options:
    -n, --name RELEASE_NAME       Helm release name (default: thingsboard-pe)
    -s, --namespace NAMESPACE     Kubernetes namespace (default: thingsboard)
    -m, --mode MODE              Deployment mode: monolith|microservices (default: microservices)
    -l, --license LICENSE_KEY    ThingsBoard PE license key (required)
    -d, --database HOST          Database host (required)
    -p, --password PASSWORD      Database password (required)
    -u, --username USERNAME      Database username (default: thingsboard)
    --dry-run                    Show what would be deployed without installing
    -h, --help                   Show this help message

Examples:
    # Deploy microservices with external database
    $0 -l "YOUR_LICENSE" -d "mydb.oci.com" -p "mypassword"

    # Deploy monolith
    $0 -m monolith -l "YOUR_LICENSE" -d "mydb.oci.com" -p "mypassword"

    # Dry run to see what will be deployed
    $0 --dry-run -l "YOUR_LICENSE" -d "mydb.oci.com" -p "mypassword"
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -s|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -m|--mode)
            DEPLOYMENT_MODE="$2"
            shift 2
            ;;
        -l|--license)
            LICENSE_KEY="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE_HOST="$2"
            shift 2
            ;;
        -p|--password)
            DATABASE_PASSWORD="$2"
            shift 2
            ;;
        -u|--username)
            DATABASE_USERNAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$LICENSE_KEY" ]]; then
    print_error "License key is required. Use -l or --license"
    exit 1
fi

if [[ -z "$DATABASE_HOST" ]]; then
    print_error "Database host is required. Use -d or --database"
    exit 1
fi

if [[ -z "$DATABASE_PASSWORD" ]]; then
    print_error "Database password is required. Use -p or --password"
    exit 1
fi

# Set default username if not provided
DATABASE_USERNAME=${DATABASE_USERNAME:-"thingsboard"}

# Validate deployment mode
if [[ "$DEPLOYMENT_MODE" != "monolith" && "$DEPLOYMENT_MODE" != "microservices" ]]; then
    print_error "Invalid deployment mode. Must be 'monolith' or 'microservices'"
    exit 1
fi

# Print deployment configuration
print_header "=== ThingsBoard PE Helm Deployment ==="
print_status "Release Name: $RELEASE_NAME"
print_status "Namespace: $NAMESPACE"
print_status "Deployment Mode: $DEPLOYMENT_MODE"
print_status "Database Host: $DATABASE_HOST"
print_status "Database Username: $DATABASE_USERNAME"
if [[ "$DRY_RUN" == "true" ]]; then
    print_warning "DRY RUN MODE - No actual deployment will occur"
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Prepare Helm command
HELM_CMD="helm"
if [[ "$DRY_RUN" == "true" ]]; then
    HELM_CMD="$HELM_CMD --dry-run"
fi

# Choose values file based on deployment mode
VALUES_FILE=""
if [[ "$DEPLOYMENT_MODE" == "monolith" ]]; then
    VALUES_FILE="--values values-monolith.yaml"
fi

# Build the installation command
INSTALL_CMD="$HELM_CMD install $RELEASE_NAME $CHART_DIR \\
    $VALUES_FILE \\
    --create-namespace \\
    --namespace $NAMESPACE \\
    --set global.license.key=\"$LICENSE_KEY\" \\
    --set database.host=\"$DATABASE_HOST\" \\
    --set database.username=\"$DATABASE_USERNAME\" \\
    --set database.password=\"$DATABASE_PASSWORD\""

print_status "Executing Helm installation..."
print_status "Command: $INSTALL_CMD"

# Execute the installation
if [[ "$DRY_RUN" != "true" ]]; then
    eval $INSTALL_CMD
    
    if [[ $? -eq 0 ]]; then
        print_status "ThingsBoard PE deployed successfully!"
        print_header "=== Post-Installation Instructions ==="
        print_status "1. Wait for all pods to be ready:"
        echo "   kubectl get pods -n $NAMESPACE -w"
        print_status "2. Get external IP addresses:"
        echo "   kubectl get svc -n $NAMESPACE"
        print_status "3. Access ThingsBoard UI using the external IP of the LoadBalancer service"
        print_status "4. Default credentials: System Administrator / tenant@thingsboard.org / tenant"
    else
        print_error "Deployment failed!"
        exit 1
    fi
else
    eval $INSTALL_CMD
    print_warning "Dry run completed. No resources were actually created."
fi
