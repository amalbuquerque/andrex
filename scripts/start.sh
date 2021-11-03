#!/bin/bash

set -ex

echo "RUNNING scripts/start.sh"

mix deps.get
mix setup
mix phx.server
