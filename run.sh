#!/bin/bash
docker run -t --network=host --cpus $(cat /proc/cpuinfo | grep siblings | awk '{print $3}' | tail -1) -u$(id -u) -v$PWD/workdir:/workdir:z -v/dev/shm:/dev/shm:z -v/etc/resolv.conf:/etc/resolv.conf:z bxb-builder:latest

