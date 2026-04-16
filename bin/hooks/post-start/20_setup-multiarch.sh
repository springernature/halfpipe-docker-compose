#!/usr/bin/env bash
set -e

echo "Setting up multi-arch build support..."

# Register QEMU binfmt handlers for arm64 emulation
/usr/bin/binfmt --install arm64

# Create and bootstrap buildx builder for multi-platform builds
docker buildx create --name multiarch --driver docker-container --use || true
echo "Multi-arch builds enabled for: linux/amd64, linux/arm64"
