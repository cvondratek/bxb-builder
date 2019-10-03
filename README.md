# bcbuildr - containerized flash-image automation

## Purpose
bcbuildr was created to automate the flash-image generation for read-only & stateless embedded Linux systems booting from 16MB NOR flash. While many build
automation tools like yocto & buildroot exist, none provide both the level of customization required for rapid prototyping AND a good-base for long-term
support of a product. User-defined bcb project structures define bin layers that can be anything from a full-blown openembedded/yocto build to a simple blob dd copy.

## Status
Work in progress. 

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

