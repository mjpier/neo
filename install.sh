#!/usr/bin/env bash

## Copyright (C) 2020-2023 Aditya Shakya <adi1090x@gmail.com>
##
## Archcraftify your Void Linux Installation
##
## It is advised that you install this on a fresh installation of Void Linux.
## Created on : void-live-x86_64-20230628-base.iso (https://repo-default.voidlinux.org/live/current/void-live-x86_64-20230628-base.iso)

## General --------------------------------------------

## ANSI Colors
RED="$(printf '\033[31m')"      GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"   BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"    BLACK="$(printf '\033[30m')"

## Global Variables
_dir="`pwd`"
_rootfs="$_dir/files"
_copy_cmd='doas cp --preserve=mode --force --recursive'

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

## Messages
show_msg() {
	if [[ "$1" == '-r' ]]; then
		{ echo -e ${RED}"$2"; reset_color; }
	elif [[ "$1" == '-g' ]]; then
		{ echo -e ${GREEN}"$2"; reset_color; }
	elif [[ "$1" == '-o' ]]; then
		{ echo -e ${ORANGE}"$2"; reset_color; }
	elif [[ "$1" == '-b' ]]; then
		{ echo -e ${BLUE}"$2"; reset_color; }
	elif [[ "$1" == '-m' ]]; then
		{ echo -e ${MAGENTA}"$2"; reset_color; }
	elif [[ "$1" == '-c' ]]; then
		{ echo -e ${CYAN}"$2"; reset_color; }
	fi
}

## Script termination
exit_on_signal_SIGINT() {
	show_msg -r "\n[!] Script interrupted.\n"
	exit 1
}

exit_on_signal_SIGTERM() {
	show_msg -r "\n[!] Script terminated.\n"
	exit 1
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Packages -------------------------------------------

## List of packages
_failed_to_install=()
_packages=(
		  # full x11 server
		  xorg-minimal

		  # authorization tools
		  polkit
		  elogind
		  xfce-polkit

		  # network management daemon
		  NetworkManager

		  # bluetooth tools
		  bluez

		  # disk management and filesystem
		  gvfs
		  gvfs-mtp
		  
		  # file manager functionalities
		  ffmpegthumbnailer
		  highlight
		  tumbler
		  ueberzug
		  xdg-user-dirs
		  xdg-user-dirs-gtk

		  # audio
		  pipewire
		  wireplumber
		  pavucontrol
		  alsa-pipewire
		  alsa-plugins-jack
		  alsa-plugins-pulseaudio

		  # video
		  libde265
		  libmpeg2
		  libtheora
		  libvpx
		  x264
		  x265
		  xvidcore
		  gstreamer1
		  ffmpeg
		  gst-libav
		  gst-plugins-good1
		  gst-plugins-bad1
		  gst-plugins-ugly1
		  mesa-vaapi
		  mesa-vdpau

		  # images
		  jasper
		  libwebp
		  libavif
		  libheif

		  # fonts
		  noto-fonts-ttf 
		  noto-fonts-emoji
		  noto-fonts-ttf-extra

		  # bspwm
		  bspwm
		  sxhkd
		  feh
		  xsettingsd

		  # basic gui apps
		  alacritty
		  firefox
		  geany
		  geany-plugins
		  Thunar
		  viewnior
		  atril

		  # basic cli apps
		  htop
		  nethogs
		  ncdu
		  powertop
		  ranger
		  vim

		  # archives
		  bzip2
		  gzip
		  lrzip
		  lz4
		  lzip
		  lzop
		  p7zip
		  unzip
		  xz
		  xarchiver
		  zstd
		  zip

		  # utilities : qt
		  kvantum
		  qt5ct

		  # utilities : internet
		  curl
		  git
		  inetutils
		  wget

		  # utilities : multimedia
		  mpc
		  mpd
		  ncmpcpp
		  mplayer
		  pulsemixer

		  # utilities : common tools
		  betterlockscreen
		  dunst
		  ksuperkey
		  nitrogen
		  pastel
		  picom
		  polybar
		  pywal
		  rofi
		  maim
		  slop

		  # utilities : power management
		  acpi
		  light
		  xfce4-power-manager

		  # utilities : misc
		  arandr
		  bc
		  dialog
		  galculator
		  gparted
		  gtk3-nocsd
		  gtk-engine-murrine
		  gnome-keyring
		  inotify-tools
		  jq
		  meld
		  nano
		  psmisc
		  sound-theme-freedesktop
		  wmctrl
		  wmname
		  xclip
		  xcolor
		  xdotool
		  yad
		  zsh
)

## Banner
banner() {
	clear
    cat <<- EOF
		${GREEN}░█░█░█▀█░▀█▀░█▀▄░█▀▀░█▀▄░█▀█░█▀▀░▀█▀
		${GREEN}░▀▄▀░█░█░░█░░█░█░█░░░█▀▄░█▀█░█▀▀░░█░
		${GREEN}░░▀░░▀▀▀░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀░░░░▀░${WHITE}
		
		${CYAN}Voidcraft    ${WHITE}: ${MAGENTA}Install Archcraft on Void Linux
		${CYAN}Developed By ${WHITE}: ${MAGENTA}Aditya Shakya (@adi1090x)
		
		${RED}Recommended  ${WHITE}: ${ORANGE}Install this on a fresh installation of Void Linux ${WHITE}
	EOF
}

## Check command status
check_cmd_status() {
	if [[ "$?" != '0' ]]; then
		{ show_msg -r "\n[!] Failed to $1 '$2' ${3}.\n"; exit 1; }
	fi
}

## Check internet connection
check_internet() {
	show_msg -b "\n[*] Checking for internet connection..."
	if ping -c 3 www.google.com &>/dev/null; then
		show_msg -g "[+] Connected to internet."
	else
		show_msg -r "[-] No internet connectivity.\n[!] Connect to internet and run the script again.\n"
		exit 1;
	fi
}

## Perform system upgrade
upgrade_system() {
	check_internet
	show_msg -b "\n[*] Performing system upgrade..."

	# update xbps package
	show_msg -o "\n[*] Updating 'xbps' package..."
	doas xbps-install --sync --update --yes xbps
	check_cmd_status 'install' 'xbps' 'package'
	
	# upgrade entire system
	show_msg -o "\n[*] Updating system..."
	doas xbps-install --sync --update --yes
	check_cmd_status 'perform' 'system' 'upgrade'
}

## Install packages
install_pkgs() {
	upgrade_system
	show_msg -b "\n[*] Installing required packages..."
	for _pkg in "${_packages[@]}"; do
		show_msg -o "\n[+] Installing package : $_pkg"
		doas xbps-install --yes "$_pkg"
		if [[ "$?" != '0' ]]; then
			show_msg -r "\n[!] Failed to install package: $_pkg"
			_failed_to_install+=("$_pkg")
		fi
	done

	# List failed packages
	if [[ -n "${_failed_to_install}" ]]; then
		echo
		for _failed in "${_failed_to_install[@]}"; do
			show_msg -r "[!] Failed to install package : ${ORANGE}${_failed}"
		done
		{ show_msg -r "\n[!] Install these packages manually to continue, exiting...\n"; exit 1; }
	fi
}

## Files ----------------------------------------------

## Install shared files
install_shared_files() {
	_bindir='/usr/local/bin'
	_sharedir='/usr/share'

	show_msg -b "\n[*] Installing shared files..."

	_shared_files=(backgrounds fonts icons themes)
	for _sfile in "${_shared_files[@]}"; do
		show_msg -o "[+] Installing '${_sfile}'"
		${_copy_cmd} "$_rootfs"/shared/"$_sfile" "$_sharedir"
		check_cmd_status 'install' "$_sfile" "in $_sharedir directory"
	done

	show_msg -b "\n[*] Installing openbox menu libraries and pipemenus..."
	${_copy_cmd} "$_rootfs"/shared/archcraft "$_sharedir"
	check_cmd_status 'install' 'archcraft' "in $_sharedir directory"

	show_msg -b "\n[*] Installing scripts..."
	${_copy_cmd} --verbose "$_rootfs"/scripts/* "$_bindir"
	check_cmd_status 'install' 'scripts' "in $_bindir directory"

	show_msg -b "\n[*] Installing theme files..."
	_shared_themes=(grub plymouth sddm)
	for _stheme in "${_shared_themes[@]}"; do
		if [[ ! -d "$_sharedir/$_stheme/themes" ]]; then
			doas mkdir -p "$_sharedir/$_stheme/themes"
		fi
		show_msg -o "[+] Installing theme for '${_stheme}'"
		${_copy_cmd} "$_rootfs"/${_stheme}/void "$_sharedir"/${_stheme}/themes/
		check_cmd_status 'install' "$_stheme" "theme in $_sharedir/$_stheme directory"
	done
}

## Install skeleton
install_skeleton_files() {
	_skel='/etc/skel'

	show_msg -b "\n[*] Installing skeleton files..."

	_skel_files=(`ls --almost-all --group-directories-first ${_rootfs}/skel/`)
	for _skfile in "${_skel_files[@]}"; do
		show_msg -o "[+] Installing ${_skfile} files..."
		${_copy_cmd} "$_rootfs"/skel/${_skfile} "$_skel"
		check_cmd_status 'install' "$_skfile" "files in $_skel directory"	
	done
}

## Copy files in user's directory
copy_files_in_home() {
	_cp_cmd='cp --preserve=mode --force --recursive'
	_skel_dir='/etc/skel'
	_bnum=`echo $RANDOM`

	show_msg -b "\n[*] Copying config files in $HOME directory..."
	_cfiles=(
		  '.cache'
		  '.config'
		  '.icons'
		  '.mpd'
		  '.ncmpcpp'
		  '.oh-my-zsh'
		  '.vim_runtime'
		  '.dmrc'
		  '.face'
		  '.fehbg'
		  '.gtkrc-2.0'
		  '.hushlogin'
		  '.vimrc'
		  '.zshrc'
		  'Music'
		  'Pictures'
		  )
	
	for _file in "${_cfiles[@]}"; do
		if [[ -e "$HOME/$_file" ]]; then
			show_msg -m "\n[-] Backing-up : $HOME/$_file"
			mv "$HOME/$_file" "$HOME/${_file}_backup_${_bnum}"
			show_msg -c "[!] Backup stored in : $HOME/${_file}_backup_${_bnum}"
		fi
		show_msg -o "[+] Copying $_skel_dir/$_file in $HOME directory"
		${_cp_cmd} "$_skel_dir/$_file" "$HOME"
	done
}

## Copy files in root directory
copy_files_in_root() {
	_skel_dir='/etc/skel'
	_bnum=`echo $RANDOM`

	show_msg -b "\n[*] Copying config files in /root directory..."
	_cfiles=(
		  '.config'
		  '.gtkrc-2.0'
		  '.oh-my-zsh'
		  '.vimrc'
		  '.vim_runtime'
		  '.zshrc'
		  )
	
	for _file in "${_cfiles[@]}"; do
		if doas test -e "/root/$_file"; then
			show_msg -m "\n[-] Backing-up : /root/$_file"
			doas mv "/root/$_file" "/root/${_file}_backup_${_bnum}"
			show_msg -c "[!] Backup stored in : /root/${_file}_backup_${_bnum}"
		fi
		show_msg -o "[+] Copying $_skel_dir/$_file in /root directory"
		${_copy_cmd} "$_skel_dir/$_file" /root
	done
}

## Misc -----------------------------------------------

## Enable runit services
enable_services() {
	_runit_services=(NetworkManager
					 bluetoothd
					 dbus
					 polkitd)

	_serv_disable=(dhcpcd wpa_supplicant)

	show_msg -b "\n[*] Enabling runit services..."
	
	for _serv in "${_runit_services[@]}"; do
		if ! doas sv status "$_serv" &>/dev/null; then
			show_msg -o "\n[+] Enabling '$_serv' service..."
			doas ln -v -s /etc/sv/"$_serv" /var/service/
		fi
	done

	if [[ -L '/var/service/NetworkManager' ]]; then
		show_msg -c "\n[!] NetworkManager service is enabled, So..."
		for _servd in "${_serv_disable[@]}"; do
			if doas sv status "$_servd" &>/dev/null; then
				show_msg -m "[-] Disabling '$_servd' service..."
				doas rm -v /var/service/"$_servd"
			fi
		done
	fi
} 

## Finalization
finalization() {
	show_msg -b "\n[*] Performing cleanup..."

	# Remove all unused packages
	show_msg -o "[-] Removing unused packages..."
	doas xbps-remove --clean-cache --remove-orphans --yes

	# Completed
	show_msg -g "\n[*] Installation Completed, You may now reboot your computer.\n"
}

## Main --------------------------------------
banner
install_pkgs
install_shared_files
install_skeleton_files
copy_files_in_home
copy_files_in_root
enable_services
finalization
