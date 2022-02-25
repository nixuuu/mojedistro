#!/bin/bash

IS_EFI="no"
INSTALL_DISK="$1"

verify_boot_mode() {
    ls /sys/firmware/efi/efivars > /dev/null
    if [ "$?" == "0" ]; then
        IS_EFI="yes"
    fi;

    if [ "$IS_EFI" == "no" ]; then
        _error_msg "NON EFI SYSTEM IS NOT SUPPORTED"
        _critical
    fi;

    _msg "EFI: $IS_EFI"
}

set_ntp() {
    _msg "SETUP NTP"
    timedatectl set-ntp true;
    
}

_error_msg() {
    echo ""
    echo "======================"
    echo " $@"
    echo "======================"
    echo ""
}

_msg() {
    echo "======================"
    echo "$@"
    echo "======================"
}

_critical() {
    _error_msg "INSTALLATION STOPPED"
    swapoff "${INSTALL_DISK}2"
    exit 1
}

verify_install_disk() {
    _msg "VERIFY INSTALL DISK"
    if [ "$INSTALL_DISK" == "" ]; then
        _error_msg "PICK DISK TO INSTALL OS";
        fdisk -l | grep -E "^Disk \/dev";
        _critical
    fi;
    
    umount -R /mnt

    if [ -f "${INSTALL_DISK}2" ]; then
        swapoff "${INSTALL_DISK}2";
    fi
}

setup_disk() {
    _msg "SETUP DISK"
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${INSTALL_DISK}
  g # set GPT
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +500M # 500 MB boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # start at beginning
  +5G # default, start immediately after preceding partition
  n # new partition
  p # primary partition
  3 # partition number
    # start at begin
    # fill entire disk
  t # change partition type
  1 # efi partition
  4 # EFI System
  t # change partition
  2 # swap partition
  swap # swap type
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF
    mkfs.ext4 "${INSTALL_DISK}3"
    mkswap "${INSTALL_DISK}2"
    swapon "${INSTALL_DISK}2"
    mkfs.fat -F 32 "${INSTALL_DISK}1"
}

mount_disk() {
    umount -R /mnt
    _msg "MOUNT DISK"
    mount "${INSTALL_DISK}3" /mnt
    echo "[OK] ${INSTALL_DISK}3 /mnt"
    mkdir -p /mnt/boot
    mount "${INSTALL_DISK}1" /mnt/boot
    echo "[OK] ${INSTALL_DISK}1 /mnt/boot"
}

install_packages() {
    _msg "INSTALL PACKAGES"
    curl https://nixcode.it/packages.x86_64 --output /mnt/packages.x86_64 -s
    curl https://nixcode.it/packages.aur --output /mnt/packages.aur -s
    pacstrap /mnt base linux linux-firmware grub efibootmgr vim networkmanager git base-devel > /dev/null
    echo "[OK]"
}

setup_fstab() {
    _msg "SETUP FSTAB"
    genfstab -U /mnt > /mnt/etc/fstab
    echo "[OK]"
}

run_chroot() {
    _msg "CHROOT"
    curl https://nixcode.it/chroot.sh --output /mnt/chroot.sh -s
    chmod +x /mnt/chroot.sh
    arch-chroot /mnt /bin/bash -c /chroot.sh
    _error_msg "FINISHED"
}

set_ntp;
verify_boot_mode;
verify_install_disk;
setup_disk;
mount_disk;
install_packages;
run_chroot;