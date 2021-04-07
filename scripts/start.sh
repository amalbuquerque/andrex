#!/bin/bash

set -ex

mix deps.get
mix phx.server
