#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to start with a clean 'manifests' dir
# rm -rf build
mkdir -p build/manifests

# optional, but we would like to generate yaml, not json
jsonnet -J vendor -m build "${1-main.jsonnet}" # | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}
cp ../manifests/* build/manifests/
