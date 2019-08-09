#!/bin/bash
docker run -itv $PWD/workdir:/workdir:z -p 8080:8080 bcbuildr:v01
#--entrypoint override.sh
