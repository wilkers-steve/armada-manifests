#!/bin/bash

set -ex

echo "Validating Tempest manifest"
armada validate /tmp/armada-tempest.yaml
