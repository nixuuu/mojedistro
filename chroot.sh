#!/bin/bash

SCRIPT_URI="https://raw.githubusercontent.com/nixuuu/mojedistro/main"

setup_timezone() {
    ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
    hwclock --systohc
    echo "[OK] Timezone"
}

setup_locale() {
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=EN_US.UTF-8" > /etc/locale.conf
    echo "KEYMAP=pl" > /etc/vconsole.conf
    echo "[OK] Locale generated"
}

setup_hostname() {
    echo "nixos" > /etc/hostname
    echo "[OK] Hostname changed"
}

init_ramfs() {
    mkinitcpio -P > /dev/null
    echo "[OK] init ramfs"
}

install_grub() {
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB > /dev/null
    grub-mkconfig -o /boot/grub/grub.cfg > /dev/null
    echo "[OK] Grub installed"
}

set_root_password() {
    echo "root:root" | chpasswd
    echo "[OK] Changed root password to root"
}

create_user() {
    useradd nix -m
    usermod -aG wheel nix
    echo "nix:nix" | chpasswd
    echo "[OK] Created user nix"
}

install_packages() {
    pacman --noconfirm -Syyuu - < /packages.x86_64
    mkdir -p /etc/sudoers.d
    echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/10_wheel
    echo "[OK] Added wheel to sudoers.d"
}

enable_systemd_services() {
    # NetworkManager
    ln -s /usr/lib/systemd/system/NetworkManager.service /etc/systemd/system/multi-user.target.wants/NetworkManager.service
    ln -s /usr/lib/systemd/system/NetworkManager-dispatcher.service /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service
    mkdir -p /etc/systemd/system/network-online.target.wants
    ln -s /usr/lib/systemd/system/NetworkManager-wait-online.service /etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
    echo "[OK] enabled NetworkManager"
    # sddm
    ln -s /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service;
    echo "[OK] Enabled SDDM"
}

setup_pacman_conf() {
    sed -i '/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
    sed -i '/^#Color.*/Color/' /etc/pacman.conf
}

setup_chaotic_aur() {
    pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key FBA220DFC880C036 && \
    pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    cat >> /etc/pacman.conf <<EOF
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
    echo "[OK] Added chaotic-aur"
}

update_environment_file() {
cat > /etc/environment <<EOF
TERMINAL=alacritty
LC_ALL=en_US.UTF-8
EDITOR=vim
EOF
}

install_yay() {
    cd /root;
    pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
    cd /;
}

install_aur_packages() {
    yay --noconfirm -Syyuu - < /packages.aur > /dev/null
}

setup_user_env() {
    cd /home/nix
    curl "${SCRIPT_URI}/setup_user.sh" --output setup.sh -s
    chmod +x setup.sh && chown nix:nix setup.sh
    sudo -u nix ./setup.sh
}

setup_pacman_conf;
setup_timezone;
setup_locale;
setup_hostname;
init_ramfs;
install_grub;
setup_chaotic_aur;
install_packages;
install_yay;
set_root_password;
create_user;
enable_systemd_services;
setup_user_env;
install_aur_packages;
update_environment_file;