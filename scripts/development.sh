#!/bin/bash

set -ex

mix deps.get

echo "run '\e[92mdocker exec -it ${HOSTNAME} sh\e[0m' in another console to jump into the container!"

tail -f /dev/null
