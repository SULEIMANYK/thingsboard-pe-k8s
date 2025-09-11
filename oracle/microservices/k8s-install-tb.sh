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

# Create tb-license secret
echo "Creating ThingsBoard license secret..."
echo "Please enter your ThingsBoard PE license key:"
read -s TB_LICENSE_KEY

kubectl create secret generic tb-license \
  --from-literal=license-key="$TB_LICENSE_KEY" \
  --namespace=thingsboard \
  || echo "License secret already exists"

# Wait for third-party services
echo "Waiting for third-party services to be ready..."
kubectl wait --for=condition=Ready pod -l app=zookeeper --timeout=600s
kubectl wait --for=condition=Ready pod -l app=tb-kafka --timeout=600s
kubectl wait --for=condition=Ready pod -l app=tb-valkey --timeout=600s

# Wait for database setup pod to be ready
echo "Waiting for database setup pod to be ready..."
kubectl wait --for=condition=Ready pod/tb-db-setup --timeout=600s

# Run database installation
echo "Initializing ThingsBoard database..."
kubectl exec tb-db-setup -- sh -c 'export INSTALL_TB=true; export LOAD_DEMO=true; /usr/share/thingsboard/bin/install/install.sh --loadDemo && touch /tmp/install-finished'

echo "ThingsBoard database has been initialized successfully!"

# Wait for core services to be ready
echo "Waiting for ThingsBoard services to be ready..."
kubectl wait --for=condition=Ready pod -l app=tb-node --timeout=600s

echo ""
echo "Installation completed! Check the status of your deployment:"
echo "kubectl get pods -n thingsboard"
echo "kubectl get svc -n thingsboard"
echo ""
echo "Access ThingsBoard UI using the tb-web-ui LoadBalancer external IP."
echo "Default credentials: System Administrator / tenant@thingsboard.org / tenant"
