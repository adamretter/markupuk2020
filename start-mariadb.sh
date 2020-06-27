#!/usr/bin/env bash

set -x

docker run --env MYSQL_ALLOW_EMPTY_PASSWORD=true --publish 3306:3306 mariadb:latest
