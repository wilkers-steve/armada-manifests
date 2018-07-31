#!/bin/bash

set -ex

sudo -H -E pip install "cmd2<=0.8.7"
sudo -H -E pip install python-openstackclient python-heatclient

sudo -H mkdir -p /etc/openstack
sudo -H chown -R $(id -un): /etc/openstack
tee /etc/openstack/clouds.yaml << EOF
clouds:
  openstack_helm:
    region_name: RegionOne
    identity_api_version: 3
    auth:
      username: 'admin'
      password: 'password'
      project_name: 'admin'
      project_domain_name: 'default'
      user_domain_name: 'default'
      auth_url: 'http://keystone.openstack.svc.cluster.local/v3'
EOF

export OS_CLOUD=openstack_helm
export OSH_INFRA_PATH="../openstack-helm-infra"
export OSH_PATH="../openstack-helm"
export OSH_EXT_NET_NAME="public"
export OSH_EXT_SUBNET_NAME="public-subnet"
export OSH_EXT_SUBNET="172.24.4.0/24"
export OSH_BR_EX_ADDR="172.24.4.1/24"
openstack stack create --wait \
  --parameter network_name=${OSH_EXT_NET_NAME} \
  --parameter physical_network_name=public \
  --parameter subnet_name=${OSH_EXT_SUBNET_NAME} \
  --parameter subnet_cidr=${OSH_EXT_SUBNET} \
  --parameter subnet_gateway=${OSH_BR_EX_ADDR%/*} \
  -t ./files/heat-public-net-deployment.yaml \
  heat-public-net-deployment

export OSH_PRIVATE_SUBNET_POOL="10.0.0.0/8"
export OSH_PRIVATE_SUBNET_POOL_NAME="shared-default-subnetpool"
export OSH_PRIVATE_SUBNET_POOL_DEF_PREFIX="24"
openstack stack create --wait \
  --parameter subnet_pool_name=${OSH_PRIVATE_SUBNET_POOL_NAME} \
  --parameter subnet_pool_prefixes=${OSH_PRIVATE_SUBNET_POOL} \
  --parameter subnet_pool_default_prefix_length=${OSH_PRIVATE_SUBNET_POOL_DEF_PREFIX} \
  -t ./files/heat-subnet-pool-deployment.yaml \
  heat-subnet-pool-deployment

export IMAGE_NAME=$(openstack image show -f value -c name \
  $(openstack image list -f csv | awk -F ',' '{ print $2 "," $1 }' | \
  grep "^\"Cirros" | head -1 | awk -F ',' '{ print $2 }' | tr -d '"'))
export FLAVOR_ID=$(openstack flavor show m1.tiny -f value -c id)
export IMAGE_ID=$(openstack image show "${IMAGE_NAME}" -f value -c id)
export NETWORK_ID=$(openstack network show public -f value -c id)

if [ "x$(systemd-detect-virt)" == "xnone" ]; then
  export HYPERVISOR_TYPE="qemu"
fi

envsubst < ./multinode/manifests/armada-tempest.yaml > /tmp/armada-tempest.yaml
