#!/bin/bash

set -ex

echo "Validating armada-rally manifest"
armada validate /tmp/armada-rally.yaml
