#!/bin/bash

set -ex

echo "RUNNING scripts/start.sh"

echo "FETCHING deps (both Elixir and JS)..."
mix setup

cd assets

npm install
npm run deploy

cd ..

echo "CALCULATING the static files digest..."
mix phx.digest

echo "RUNNING the server..."
mix phx.server
