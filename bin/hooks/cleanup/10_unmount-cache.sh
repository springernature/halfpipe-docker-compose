#!/usr/bin/env bash

readonly cache_mount="/mnt/halfpipe-cache"

echo 'unmounting Halfpipe shared cache'
umount ${cache_mount}
