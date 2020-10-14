#!/bin/bash

ssh root@"$1" mount /dev/mmcblk1p1 /mnt/emmc

#scp workdir/staging/* root@"$1":/mnt/emmc
scp workdir/staging/bcbuildr_rootfs.squash root@"$1":/mnt/emmc

ssh root@"$1" /sbin/reboot
