#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Ensure UTF-8 locale is enabled
export LANG=en_US.UTF-8

# Ensure apt is updated
sudo apt-get update

mix local.hex --force
mix local.rebar --force
