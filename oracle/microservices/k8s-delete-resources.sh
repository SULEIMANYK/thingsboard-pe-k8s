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

# Delete transport services
kubectl delete -f transports/ --ignore-not-found

# Delete ThingsBoard services
kubectl delete -f tb-services.yml --ignore-not-found

# Delete database setup
kubectl delete -f database-setup.yml --ignore-not-found

# Delete config maps
kubectl delete -f tb-ie-configmap.yml --ignore-not-found
kubectl delete -f tb-node-configmap.yml --ignore-not-found
kubectl delete -f tb-kafka-configmap.yml --ignore-not-found
kubectl delete -f tb-cache-configmap.yml --ignore-not-found
kubectl delete -f tb-node-db-configmap.yml --ignore-not-found

# Delete third-party services
kubectl delete -f thirdparty.yml --ignore-not-found

# Optionally delete namespace
if [ "$1" == "--all" ]; then
  kubectl delete namespace thingsboard --ignore-not-found
fi

echo "ThingsBoard PE microservices have been deleted from Oracle Cloud."
