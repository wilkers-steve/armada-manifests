#!/bin/bash

set -ex

echo "Applying armada-tempest manifest"
armada apply /tmp/armada-tempest.yaml
