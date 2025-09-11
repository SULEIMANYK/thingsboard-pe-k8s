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

# Deploy namespace
kubectl apply -f tb-namespace.yml || echo "namespace already exists"

# Set the current namespace context
kubectl config set-context --current --namespace=thingsboard

# Deploy third-party services (Zookeeper, Kafka, Valkey)
kubectl apply -f thirdparty.yml

# Deploy config maps
kubectl apply -f tb-node-db-configmap.yml
kubectl apply -f tb-cache-configmap.yml
kubectl apply -f tb-kafka-configmap.yml
kubectl apply -f tb-node-configmap.yml
kubectl apply -f tb-ie-configmap.yml

# Deploy ThingsBoard services
kubectl apply -f tb-services.yml

# Deploy transport services
kubectl apply -f transports/

# Deploy database setup
kubectl apply -f database-setup.yml

echo "ThingsBoard PE microservices have been deployed to Oracle Cloud!"
echo ""
echo "Wait for third-party services to be ready before proceeding with installation:"
echo "kubectl wait --for=condition=Ready pod -l app=zookeeper --timeout=300s"
echo "kubectl wait --for=condition=Ready pod -l app=tb-kafka --timeout=300s"
echo "kubectl wait --for=condition=Ready pod -l app=tb-valkey --timeout=300s"
echo ""
echo "Then run: ./k8s-install-tb.sh"
