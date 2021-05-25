#!/bin/bash
docker run -it --cpus 10 -v$PWD/workdir:/workdir:z -v/dev/shm:/dev/shm:z bxb-builder:latest

