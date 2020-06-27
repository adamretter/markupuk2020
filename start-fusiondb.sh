#!/usr/bin/env bash

set -x

docker run --publish 4059:4059 repo.evolvedbinary.com:9443/evolvedbinary/fusiondb-server:latest
