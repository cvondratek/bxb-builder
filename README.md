# bcbuildr - containerized flash-image automation

## Status
Work in progress. 
Configuration assumes 10.10.10.1 for proxy & other services.

## Build system requirements

### Software
Docker 19+

### Hardware
Currently, we build on /dev/shm for speed & wear reduction. Total build is approx. 20GB; 48GB RAM is recommended.

### Network
Network access required for container build. Can be run air-gapped once built.

## Build Process

### 1. Get bcbuildr
git clone -b <arch_branch> https://github.com/cvondratek/bcbuildr
### 2. Build container image
./build.sh
### 3. Get a bcbuildr project (example bcbprj)
git clone -b <arch_branch> https://github.com/cvondratek/usb-boot-adapter.bcbprj
ln -s usb-boot-adapter.bcbprj workdir
### 4. Run the container to start the build
screen
./run.sh

