#!/usr/bin/env bash
set -ex

# write into cache folder
touch /var/halfpipe/shared-cache/cached_file

(>&2 echo "Works also without mounted nfs volume")