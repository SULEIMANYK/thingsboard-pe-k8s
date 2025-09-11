#!/bin/bash
#
# Copyright © 2016-2020 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

kubectl config set-context --current --namespace=thingsboard

# Patch the database setup pod for upgrade
echo "Preparing database for upgrade..."
kubectl patch pod tb-db-setup -p '{"spec":{"containers":[{"name":"tb-db-setup","command":["sh","-c","while [ ! -f /tmp/upgrade-finished ]; do sleep 2; done;"]}]}}' || echo "Database setup pod not found, creating new one..."

if ! kubectl get pod tb-db-setup &> /dev/null; then
    kubectl apply -f database-setup.yml
    kubectl wait --for=condition=Ready pod/tb-db-setup --timeout=300s
fi

# Run database upgrade
echo "Upgrading ThingsBoard database..."
kubectl exec tb-db-setup -- sh -c 'export UPGRADE_TB=true; /usr/share/thingsboard/bin/install/upgrade.sh && touch /tmp/upgrade-finished'

# Update the configmaps
echo "Updating configuration..."
kubectl apply -f tb-node-configmap.yml
kubectl apply -f tb-node-db-configmap.yml
kubectl apply -f tb-cache-configmap.yml
kubectl apply -f tb-kafka-configmap.yml
kubectl apply -f tb-ie-configmap.yml

# Update the ThingsBoard deployments
echo "Updating ThingsBoard deployments..."
kubectl apply -f tb-services.yml
kubectl apply -f transports/

# Wait for rollout to complete
echo "Waiting for deployment to complete..."
kubectl rollout status statefulset/tb-node --timeout=600s
kubectl rollout status statefulset/tb-integration-executor --timeout=600s
kubectl rollout status deployment/tb-web-ui --timeout=300s
kubectl rollout status deployment/tb-js-executor --timeout=300s
kubectl rollout status deployment/tb-web-report --timeout=300s

echo "ThingsBoard microservices upgrade completed successfully!"
echo ""
echo "Checking deployment status..."
kubectl get pods -n thingsboard
