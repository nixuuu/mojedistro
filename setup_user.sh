#!/bin/bash

prepare_dotfiles() {
    cd ~ && git clone https://github.com/nixuuu/dotfiles.git && cd dotfiles && ./setup.sh
}

install_yay() {
    cd ~ && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
}

install_aur_packages() {
    yay --noconfirm -Syyuu picom-jonaburg-git > /dev/null
}


prepare_dotfiles;
install_yay;
install_aur_packages;
