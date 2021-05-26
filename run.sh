#!/bin/bash
docker run -t --cpus $(cat /proc/cpuinfo | grep siblings | awk '{print $3}' | tail -1) -u$(id -u) -v$PWD/workdir:/workdir:z -v/dev/shm:/dev/shm:z bxb-builder:latest

