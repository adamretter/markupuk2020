#!/usr/bin/env bash

set -x

docker run --publish 3030:3030 stain/jena-fuseki
