# bcbuildr - containerized flash-image automation

## Purpose
bcbuildr was created to automate the flash-image generation for read-only & stateless embedded Linux systems booting from 16MB NOR flash. While many build
automation tools like yocto & buildroot exist, none provide both the level of customization required for rapid prototyping AND a good-base for long-term
support of a product. User-defined bcb project structures define bin layers that can be anything from a full-blown openembedded/yocto build to a simple blob dd copy.

## Status
* Everything builds.
* U-boot works but is still mostly stock. am335x_evm_bcb_defconfig doesn't support reading anything into 0x82000000... WIP 
* Kernel isn't setup for squashfs in RAM - suspect yocto needs to be kicked to rebuild with new defconfig
	-->did confirm that badgR kernel (hib0x, etc) boots so this is only kernel config issue

## Build system requirements

### Software
Docker 19+

### Hardware
Currently, we build on /dev/shm for speed & wear reduction. Total build is approx. 20GB; 48GB RAM is recommended.

### Network
Network access required for container build. Can be run air-gapped once built.

## Build Process

### 1. Get bcbuildr & build
git clone -b <arch_branch> https://github.com/cvondratek/bcbuildr
./build.sh
## --OR--
docker pull 10.10.10.1:5000/bcbuildr:latest

### 2. Get a bcbuildr project (example bcbprj)
git clone -b <arch_branch> https://github.com/cvondratek/usb-boot-adapter.bcbprj
git submodule update --init < all submodules>

### 3. Link a project to workdir to "activate" it. 
ln -s usb-boot-adapter.bcbprj workdir

### 4. Run the container to start the build
screen
./run.sh

