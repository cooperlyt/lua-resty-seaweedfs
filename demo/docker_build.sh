#!/usr/bin/env bash

docker buildx build . --platform linux/amd64,linux/arm64 --push -t coopersoft/seaweedfs-gateway:1.0.0