#!/bin/bash

set -ex

export OSH_INFRA_PATH="../openstack-helm-infra"
export OSH_PATH="../openstack-helm"

echo "Rendering armada-rally manifest"
envsubst < ./multinode/manifests/armada-rally.yaml > /tmp/armada-rally.yaml
