#!/bin/bash

# Защита от краша, если будет краш вкоманде скрипт прервётся
set -Eeuo pipefail

# узнаем путь скрипта
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#check root
if [ "$(id -u)" = 0 ]; then
    echo "This script MUST NOT be run as root user."
    exit 1
fi

#colors
CRE=$(tput setaf 1)
CYE=$(tput setaf 3)
CGR=$(tput setaf 2)
CBL=$(tput setaf 4)
BLD=$(tput bold)
CNC=$(tput sgr0)

date=$(date +%Y%m%d-%H%M%S)

home_dir=$HOME

#Ставим русскую локаль
echo "Устанавливаю русскую локаль"
sudo sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
localectl set-locale LANG="ru_RU.UTF-8"

sudo echo "setfont cyr-sun16" > /etc/profile.d/rus.sh

#Очищаем кеш и обновляем зеркала
sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sudo sed -i '/^\[multilib\]$/,/^\[/ s/^#\(Include = \/etc\/pacman\.d\/mirrorlist\)/\1/' /etc/pacman.conf
sudo pacman -Sy
sudo pacman -Scc
sudo pacman -Syy

#Список пакетов
PACKAGES="sxhkd bspwm tumbler ffmpegthumbnailer lsd alacritty bat brightnessctl calc \
    automake blueman bluez bluez-utils dunst fakeroot feh firefox \
    dpkg gcc gedit git gnu-netcat htop btop nano lxappearance \
    mat2 mpd mpv thunar ncmpcpp neofetch network-manager-applet nitrogen \
    pamixer papirus-icon-theme pavucontrol polybar autoconf mpc pulseaudio \
    pulseaudio-alsa python-pyalsa ranger redshift reflector rofi rofi-calc calcurse \
    rofi-emoji scrot sudo slop tree unrar zip unzip uthash xarchiver \
    xfce4-power-manager xfce4-settings xorg-xbacklight zathura zathura-djvu zathura-pdf-mupdf \
    cmake clang gzip imagemagick make openssh pulseaudio-bluetooth shellcheck \
    vlc usbutils picom networkmanager-openvpn alsa-plugins alsa-tools alsa-utils ffmpeg \
    p7zip gparted sshfs openvpn xclip gpick wget ueberzug netctl libreoffice \
    breeze vulkan-intel intel-ucode ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-fira-code \
    ttf-iosevka-nerd xdg-user-dirs mesa lib32-mesa xf86-video-nouveau xf86-video-intel vulkan-intel \
    xorg xorg-xinit"
 
AUR_PACKAGES="cava light web-greeter"
##i3lock-color ptpython
#GNOME_PACKAGES="evince gnome-calculator gnome-disk-utility gucharmap gthumb gnome-clocks"

#Ускоряем pacman
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf

echo Устанавливаю пакеты...
if sudo pacman -Sy $PACKAGES; then
    printf "%s%spackages %shas been installed succesfully.%s\n" "${BLD}" "${CYE}" "${CBL}" "${CNC}"
    sleep 1
else
    printf "%s%spackages%shas not been installed correctly. See %sScriptError.log %sfor more details.%s\n" "${BLD}" "${CYE}" "$paquete" "${CRE}" "${CBL}" "${CRE}" "${CNC}"
    exit 1
    sleep 1
fi

#Ставим yay
echo Устанавливаю yay...
git -C /tmp clone https://aur.archlinux.org/yay.git
cd /tmp/yay && makepkg -si

#Ставим yay пакеты
echo Устанавливаю yay пакеты...
yay -S $AUR_PACKAGES

#Устанавливаем LightDm тему
echo Устанавливаю LightDm тему...
sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=web-greeter/' /etc/lightdm/lightdm.conf
sudo sed -i 's/background_images_dir: \/usr\/share\/backgrounds/background_images_dir: \/usr\/share\/web-greeter\/themes\/shikai\/assets\/media\/wallpapers\//' /etc/lightdm/web-greeter.yml
sudo sed -i 's/logo_image: \/usr\/share\/web-greeter\/themes\/default\/img\/antergos-logo-user.png /logo_image: \/usr\/share\/web-greeter\/themes\/shikai\/assets\/media\/logos\//' /etc/lightdm/web-greeter.yml
sudo sed -i 's/theme: gruvbox/theme: shikai/' /etc/lightdm/web-greeter.yml
sudo cp -r $script_dir/shikai /usr/share/web-greeter/themes/
#Ставим тему firefox
#echo Ставлю тему для Firefox...
#timeout 10 firefox --headless
#sh $script_dir/firefox/install.sh


#Создаем домашние папки
echo Создаю домашние папки...
if [ ! -e "$HOME/.config/user-dirs.dirs" ]; then
    xdg-user-dirs-update
fi

#Копирование конфигов
echo Копирую конфиги...
mkdir -p ~/.config
cp -r $script_dir/Images/ ~/
cp -r $script_dir/config/* ~/.config/
cp $script_dir/Xresources ~/.Xresources
cp $script_dir/gtkrc-2.0 ~/.gtkrc-2.0
cp -r $script_dir/local ~/.local
cp -r $script_dir/themes ~/.themes
cp $script_dir/xinitrc ~/.xinitrc
cp -r $script_dir/bin/ ~/

#Выставляем права
sudo chmod -R 700 ~/.config/*
sudo chmod -R +x ~/bin/*

sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth.service
sudo systemctl enable lightdm.service
sudo systemctl start bluetooth.service
