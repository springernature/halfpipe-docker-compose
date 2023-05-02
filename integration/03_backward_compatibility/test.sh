#!/usr/bin/env bash
set -ex

if [ ! -f /halfpipe-shared-cache/cached_file ]; then
    # first time execeution? create the fucking file
    touch /halfpipe-shared-cache/cached_file
    (>&2 echo "Failed to find cached_file on nfs volume")
    exit 0
fi

(>&2 echo "Yea found cached_file on deprecated nfs volume")
