#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Ensure UTF-8 locale is enabled
export LANG=en_US.UTF-8

sudo apt-get update
sudo apt-get install inotify-tools -y --no-install-recommends

mix local.hex --force
mix local.rebar --force
