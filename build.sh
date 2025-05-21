#!/bin/bash
set -e

# Get latest release tag
VERSION=$(curl -s "https://api.github.com/repos/elastic/elasticsearch/releases/latest" | jq -r .tag_name)
if [ -z "$VERSION" ]; then
  echo "Failed to get latest release tag"
  exit 1
fi
es_version=$(echo $VERSION | cut -d'v' -f2)

REGISTRY=ghcr.io
REPO=elastic-ee/elasticsearch
IMAGE=$REGISTRY/$REPO:$VERSION
LATEST_IMAGE=$REGISTRY/$REPO:latest

# Check if the version is already built
TOKEN=$(curl -s https://ghcr.io/token\?scope\="repository:$REPO:pull" | jq -r .token)
if curl -f -s -H "Authorization: Bearer $TOKEN" https://ghcr.io/v2/$REPO/manifests/$VERSION >/dev/null; then
  echo "Image $IMAGE already exists"
  exit 0
fi

# Build image
docker build --build-arg VERSION=$es_version -t $IMAGE --cache-from type=registry,ref=$LATEST_IMAGE .
docker push $IMAGE
docker tag $IMAGE $LATEST_IMAGE
docker push $LATEST_IMAGE
