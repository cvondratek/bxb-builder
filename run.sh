#!/bin/bash
docker run -it --cpus 10 -v$PWD/workdir:/workdir:z -v/dev/shm:/dev/shm:z 10.10.10.1:5000/bcbuildr:latest
