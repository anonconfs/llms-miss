##### Core


# WARNING: May be untested.
_custom_uninstall_nvidia() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	#_chroot find /lib/modules -iname '*nvidia*' -path '*-mainline/kernel/drivers/video*' -exec sudo -n truncate -s 0 {} \;
	_chroot /root/_get_nvidia.sh _uninstall
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
}

_custom_uninstall_vbox() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	#_chroot find /lib/modules -iname '*vbox*' -path '*-mainline/misc*' -exec sudo -n truncate -s 0 {} \;
	_chroot apt-get remove -y 'virtualbox*'
	_chroot /sbin/vbox-uninstall-guest-additions
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
}




# WARNING: May be untested.
_custom_kernel_server-sequence() {
	local functionEntryPWD
	functionEntryPWD="$PWD"
	_start
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	## Formal naming convention is [-distllc,][-lts,-mainline,][-desktop,-server,] . ONLY requirement is dotglob removal of all except server OR all purpose lts .
	
	##'linux-headers*desktop'
	#_chroot apt-get -y remove 'linux-image*desktop'
	##'linux-headers*mainline'
	#_chroot apt-get -y remove 'linux-image*mainline'
	#'linux-headers*lts'
	#_chroot apt-get -y remove 'linux-image*lts'

	#_chroot apt-get -y remove 'linux-image*'
	
	#_chroot apt-get -y install 'linux-headers-amd64'


	# ATTENTION: For reliability, remove all linux-image packages, then install new kernel, resulting in only the desired kernel definitely becoming default to boot.
	_messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*'
    _messagePlain_probe_cmd _chroot apt-get -y purge 'linux-image*'

    _messagePlain_probe_cmd _chroot dpkg --get-selections | grep 'linux-image'
	
	
	
	
	cd "$safeTmp"
	if [[ -e "$scriptLocal"/"linux-mainline-server-amd64-debian.tar.gz" ]]
	then
		sudo -n cp -f "$scriptLocal"/"linux-mainline-server-amd64-debian.tar.gz" "$globalVirtFS"/
	elif _wget_githubRelease_internal "soaringDistributions/mirage335KernelBuild" "linux-mainline-server-amd64-debian.tar.gz" && [[ -e "$safeTmp"/"linux-mainline-server-amd64-debian.tar.gz" ]]
	then
		sudo -n cp -f "$safeTmp"/"linux-mainline-server-amd64-debian.tar.gz" "$globalVirtFS"/
	else
		sudo -n cp -f "$globalVirtFS"/home/user/core/installations/kernel_linux/linux-mainline-server-amd64-debian.tar.gz "$globalVirtFS"/
	fi
	_chroot tar xf /linux-mainline-server-amd64-debian.tar.gz
	_messagePlain_probe_cmd _chroot bash -c 'dpkg -i ./mainline-server/*headers*.deb'
	_messagePlain_probe_cmd _chroot bash -c 'ls -l /usr/src/*'
	_messagePlain_probe_cmd _chroot bash -c 'dpkg -i ./mainline-server/*.deb'
	_chroot rm -f ./mainline-server/.config './mainline-server/linux-*' ./mainline-server/statement.sh.out.txt
	_chroot rm -f ./mainline-server/linux-mainline-server-amd64-debian.tar.gz
	_chroot rm -f /linux-mainline-server-amd64-debian.tar.gz
	
	
	
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	cd "$functionEntryPWD"
	_stop 0
}
_custom_kernel_server() {
	"$scriptAbsoluteLocation" _custom_kernel_server-sequence "$@"
}

# WARNING: May be untested.
# NOTICE: May be necessary for VirtualBox Guest Additions .
_custom_kernel_lts-sequence() {
	local functionEntryPWD
	functionEntryPWD="$PWD"
	_start
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	
	## Formal naming convention is [-distllc,][-lts,-mainline,][-desktop,-server,] . ONLY requirement is dotglob removal of all except server OR all purpose lts .
	
	##'linux-headers*server'
	#_chroot apt-get -y remove 'linux-image*server'
	##'linux-headers*mainline'
	#_chroot apt-get -y remove 'linux-image*mainline'
	
	#_chroot apt-get -y install 'linux-headers-amd64'

	#_chroot apt-get -y remove 'linux-image*'


	# ATTENTION: For reliability, remove all linux-image packages, then install new kernel, resulting in only the desired kernel definitely becoming default to boot.
	_messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*'
    _messagePlain_probe_cmd _chroot apt-get -y purge 'linux-image*'

    _messagePlain_probe_cmd _chroot dpkg --get-selections | grep 'linux-image'




	cd "$safeTmp"
	if [[ -e "$scriptLocal"/"linux-lts-amd64-debian.tar.gz" ]]
	then
		sudo -n cp -f "$scriptLocal"/"linux-lts-amd64-debian.tar.gz" "$globalVirtFS"/
	elif _wget_githubRelease_internal "soaringDistributions/mirage335KernelBuild" "linux-lts-amd64-debian.tar.gz" && [[ -e "$safeTmp"/"linux-lts-amd64-debian.tar.gz" ]]
	then
		sudo -n cp -f "$safeTmp"/"linux-lts-amd64-debian.tar.gz" "$globalVirtFS"/
	else
		sudo -n cp -f "$globalVirtFS"/home/user/core/installations/kernel_linux/linux-lts-amd64-debian.tar.gz "$globalVirtFS"/
	fi
	_chroot tar xf /linux-lts-amd64-debian.tar.gz
	_messagePlain_probe_cmd _chroot bash -c 'dpkg -i ./lts/*headers*.deb'
	_messagePlain_probe_cmd _chroot bash -c 'ls -l /usr/src/*'
	_messagePlain_probe_cmd _chroot bash -c 'dpkg -i ./lts/*.deb'
	_chroot rm -f ./lts/.config './lts/linux-*' ./lts/statement.sh.out.txt
	_chroot rm -f ./lts/linux-lts-amd64-debian.tar.gz
	_chroot rm -f /linux-lts-amd64-debian.tar.gz


	

	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	cd "$functionEntryPWD"
	_stop 0
}
_custom_kernel_lts() {
	"$scriptAbsoluteLocation" _custom_kernel_lts-sequence "$@"
}




















# WARNING: Defaults for 'ops.sh'. Do NOT expect function overrides to persist if set elsewhere, due to "$scriptAbsoluteLocation" calls, such functions as '_editVBox' and '_editQemu' will ONLY use the function definitions that are always redefined by the script itself.
_set_ubDistBuild() {
	#Enable search if "vm.img" and related files are missing.
	export ubVirtImageLocal="true"
	
	export vboxOStype=Debian_64
	
	
	# _vboxGUI() {
	# 	_workaround_VirtualBoxVM "$@"
	# 	
	# 	#VirtualBoxVM "$@"
	# 	#VirtualBox "$@"
	# 	#VBoxSDL "$@"
	# }
	
	
	# _set_instance_vbox_features_app() {
	# 	VBoxManage modifyvm "$sessionid" --usbxhci on
	# 	VBoxManage modifyvm "$sessionid" --rtcuseutc on
	# 	
	# 	VBoxManage modifyvm "$sessionid" --graphicscontroller vmsvga --accelerate2dvideo off --accelerate3d off
	# 	#VBoxManage modifyvm "$sessionid" --graphicscontroller vmsvga --accelerate2dvideo off --accelerate3d on
	# 	
	# 	VBoxManage modifyvm "$sessionid" --paravirtprovider 'default'
	# }
	
	
	# _set_instance_vbox_features_app_post() {
	# 	true
	# 	
	# 	# Optional. Test live ISO image produced by '_live' .
	# 	if ! _messagePlain_probe_cmd VBoxManage storageattach "$sessionid" --storagectl "SATA Controller" --port 2 --device 0 --type dvddrive --medium "$scriptLocal"/vm-live.iso
	# 	then
	# 		_messagePlain_warn 'fail: vm-live'
	# 	fi
	# 	
	# 	if ! _messagePlain_probe_cmd VBoxManage storageattach "$sessionid" --storagectl "SATA Controller" --port 2 --device 0 --type dvddrive --medium "$scriptLib"/super_grub2/super_grub2_disk_hybrid_2.04s1.iso
	# 	then
	# 		_messagePlain_warn 'fail: super_grub2'
	# 	fi
	# 	
	# 	# Having attached and then detached the iso image, adds it to the 'media library' and creates the extra disk controller for conveinence, while preventing it from being booted by default.
	# 	# Unfortunately, it seems VirtualBox ignores directives to attempt to boot hard disk before CD image. Possibly due to CD image being a hybrid USB/disk image as well.
	# 	if ! _messagePlain_probe_cmd VBoxManage storageattach "$sessionid" --storagectl "SATA Controller" --port 2 --device 0 --type dvddrive --medium emptydrive
	# 	then
	# 		_messagePlain_warn 'fail: iso: emptydrive'
	# 	fi
	# }
	
	
	
	
	# # ATTENTION: Override with 'ops' or similar.
	# _integratedQemu_x64_display() {
	# 	
	# 	qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=on)
	# 	
	# 	true
	# }
	
	
	
	[[ "$ubVirtImage_doNotOverride" == "true" ]] && return 0
	
	
	
	###
	
	# ATTENTION: Explicitly override platform. Not all backends support all platforms.
	# chroot , qemu
	# x64-bios , raspbian , x64-efi
	export ubVirtPlatformOverride='x64-efi'
	
	###
	
	
	
	###
	
	# ATTENTION: Override with 'ops' or similar.
	# WARNING: Do not override unnecessarily. Default rules are expected to accommodate typical requirements.
	
	# WARNING: Only applies to imagedev (text) loopback device.
	# x64 bios , raspbian , x64 efi (respectively)
	
	#export ubVirtImagePartition='p1'
	
	#export ubVirtImagePartition='p2'
	
	#export ubVirtImagePartition='p3'
	#export ubVirtImageEFI=p2
	
	
	export ubVirtPlatformOverride='x64-efi'
	export ubVirtImageBIOS=p1
	export ubVirtImageEFI=p2
	export ubVirtImageNTFS=
	export ubVirtImageRecovery=
	export ubVirtImageSwap=p3
	export ubVirtImageBoot=p4
	export ubVirtImagePartition=p5
	
	
	# ATTENTION: Unusual 'x64-efi' variation.
	#export ubVirtImagePartition='p2'
	#export ubVirtImageEFI='p1'
	
	###
}
# ATTENTION: NOTICE: Most stuff from 'ops.sh' from kit is here.
type _set_ubDistBuild > /dev/null 2>&1 && _set_ubDistBuild




_create_ubDistBuild-create() {
	_messageNormal '##### init: _create_ubDistBuild-create'
	
	
	mkdir -p "$scriptLocal"
	
	_set_ubDistBuild
	
	
	
	if [[ ! -e "$scriptLocal"/vm-ingredient.img ]]
	then

		_createVMimage "$@"
		
		
		
		_messageNormal 'os: globalVirtFS: debootstrap'
		
		! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
		local imagedev
		imagedev=$(cat "$scriptLocal"/imagedev)
		
		
		# https://gist.github.com/superboum/1c7adcd967d3e15dfbd30d04b9ae6144
		# https://gist.github.com/dyejon/8e78b97c4eba954ddbda7ae482821879
		#http://deb.debian.org/debian/
		#--components=main --include=inetutils-ping,iproute
		#! sudo -n debootstrap --variant=minbase --arch amd64 bullseye "$globalVirtFS" && _messageFAIL
		! sudo -n debootstrap --variant=minbase --arch amd64 bookworm "$globalVirtFS" && _messageFAIL
		
	
		! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL
	else
		mv -f "$scriptLocal"/vm-ingredient.img "$scriptLocal"/vm.img
		[[ -e "$scriptLocal"/vm-ingredient.img ]] && _messagePlain_bad 'bad: fail: mv: vm-ingredient.img' && _messageFAIL
		[[ ! -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'bad: fail: mv: vm-ingredient.img' && _messageFAIL

		unset ubVirtImageOverride
		_createVMimage-micro-expand
	fi



	! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)

	
	_createVMfstab
	
	
	
	_messageNormal 'os: globalVirtFS: write: fs'
	
	
	
	echo "default" | sudo -n tee "$globalVirtFS"/etc/hostname
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/hosts > /dev/null
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	default

CZXWXcRMTo8EmM8i4d
	
	
	sudo -n mkdir -p "$globalVirtFS"/etc/sddm.conf.d
	
	echo '[Autologin]
User=user
Session=plasma
Relogin=true
' | sudo -n tee "$globalVirtFS"/etc/sddm.conf.d/autologin.conf
	
	
	# WARNING: Do NOT login as same user as display manager (ie. 'sddm') login! Must continue to exist after all 'user' processes are terminated!
	# https://wiki.gentoo.org/wiki/Automatic_login_to_virtual_console
	# https://forums.debian.net/viewtopic.php?t=140452
	# https://forums.debian.net/viewtopic.php?f=16&t=123694
	# https://man7.org/linux/man-pages/man8/agetty.8.html
	# https://unix.stackexchange.com/questions/459942/using-systemctl-edit-via-bash-script
	#ExecStart=-/sbin/agetty -o '-p -- \\u' --noclear %I $TERM
	#ExecStart=-/sbin/agetty --autologin user --noclear %I 38400 linux
	_write_autologin_tty() {
	sudo -n mkdir -p "$globalVirtFS"/etc/systemd/system/getty@tty"$1".service.d
	cat << 'CZXWXcRMTo8EmM8i4d' | sudo -n tee "$globalVirtFS"/etc/systemd/system/getty@tty"$1".service.d/override.conf
[Service]
Type=simple
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
CZXWXcRMTo8EmM8i4d
	}
	_write_autologin_tty 1
	_write_autologin_tty 2
	_write_autologin_tty 3
	_write_autologin_tty 4
	_write_autologin_tty 5
	_write_autologin_tty 6
	_write_autologin_tty 7
	
	
	sudo -n mkdir -p "$globalVirtFS"/etc/sysctl.d
	echo 'kernel.sysrq=1' | sudo -n tee "$globalVirtFS"/etc/sysctl.d/magicsysrq.conf
	
	
	
	sudo -n mkdir -p "$globalVirtFS"/root
	sudo -n cp -f "$scriptLib"/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/
	sudo -n chmod 755 "$globalVirtFS"/root/_get_nvidia.sh
	
	
	
	
	! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL
	
	
	
	
	
	
	_messageNormal 'chroot: config'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	#local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	_chroot dd if=/dev/zero of=/swapfile bs=1 count=1
	#_chroot dd if=/dev/zero of=/swapfile bs=1M count=1536
	_chroot chmod 0600 /swapfile
	#_chroot mkswap /swapfile
	#_chroot swapon /swapfile
	#_chroot echo '/swapfile swap swap defaults 0 0' | _chroot tee -a /etc/fstab
	
	
	
	# https://gist.github.com/varqox/42e213b6b2dde2b636ef#install-firmware
	
	export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"
	
	_getMost_backend apt-get update
	_getMost_backend_aptGetInstall auto-apt-proxy
	
	
	_messagePlain_nominal 'ca-certificates, repositories, mirrors, tasksel standard, hostnamectl'
	_getMost_backend_aptGetInstall ca-certificates
	
	
	
	
	
	# https://askubuntu.com/questions/135339/assign-highest-priority-to-my-local-repository
	#  'There is no way to assign highest priority to local repository without using sources.list file. you must put them in top of "sources.list" if you want to assign highest priority to your local repo.'
	sudo -n mv "$globalVirtFS"/etc/apt/sources.list "$globalVirtFS"/etc/apt/sources.list.upstream
	sudo -n rm -f "$globalVirtFS"/etc/apt/sources.list
	
	# https://wiki.debian.org/Cloud/MicrosoftAzure
	# http://azure.archive.ubuntu.com/ubuntu
	#  From ubuntu.com . Apparently used by Github Actions, but apparently not a fast internal Azure mirror.
	# http://debian-archive.trafficmanager.net/debian
	#  Apparently responds to external (from outside Azure) wget .
	#[[ "$CI" != "" ]]
	
	# https://docs.hetzner.com/robot/dedicated-server/operating-systems/hetzner-aptitude-mirror/
	# ATTENTION: Disabled by default (ie. 'if false').
	if wget -qO- --dns-timeout=15 --connect-timeout=15 --read-timeout=15 --timeout=15 https://mirror.hetzner.com > /dev/null
	then
		cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/apt/sources.list.hetzner > /dev/null
deb https://mirror.hetzner.com/debian/packages  bookworm           main contrib non-free non-free-firmware
deb https://mirror.hetzner.com/debian/packages  bookworm-updates   main contrib non-free non-free-firmware
deb https://mirror.hetzner.com/debian/security  bookworm-security  main contrib non-free non-free-firmware
#deb https://mirror.hetzner.com/debian/packages  bookworm-backports main contrib non-free non-free-firmware



CZXWXcRMTo8EmM8i4d
	fi
	
	# https://www.reddit.com/r/debian/comments/zm6o86/why_does_debian_uses_azure_mirrors/
	# https://www.debian.org/mirror/list
	# http://debian-archive.trafficmanager.net/debian/
	if true
	then
		cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/apt/sources.list.azure > /dev/null
deb http://debian-archive.trafficmanager.net/debian/  bookworm           main contrib non-free non-free-firmware
deb-src http://debian-archive.trafficmanager.net/debian/  bookworm           main contrib non-free non-free-firmware

deb http://debian-archive.trafficmanager.net/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://debian-archive.trafficmanager.net/debian-security bookworm-security main contrib non-free non-free-firmware
#deb http://debian-archive.trafficmanager.net/debian/  bookworm-security  main contrib non-free non-free-firmware

deb http://debian-archive.trafficmanager.net/debian/  bookworm-updates   main contrib non-free non-free-firmware
deb-src http://debian-archive.trafficmanager.net/debian/  bookworm-updates   main contrib non-free non-free-firmware

deb http://debian-archive.trafficmanager.net/debian bookworm-backports main contrib

CZXWXcRMTo8EmM8i4d
	fi


		cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/apt/sources.list.modern > /dev/null
deb https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware

#deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
#deb-src http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware



CZXWXcRMTo8EmM8i4d
	
	
	cat << CZXWXcRMTo8EmM8i4d | sudo -n tee "$globalVirtFS"/etc/apt/sources.list.default > /dev/null
#https://wiki.debian.org/AptCacherNg
deb http://ftp.us.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://ftp.us.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware

#deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
#deb-src http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware



CZXWXcRMTo8EmM8i4d
	
	# APT sources here may not provide all packages, and thus are not exclusive of other lists.
	if false && sudo -n ls "$globalVirtFS"/etc/apt/sources.list.hetzner > /dev/null 2>&1 && wget -qO- --dns-timeout=15 --connect-timeout=15 --read-timeout=15 --timeout=15 https://mirror.hetzner.com > /dev/null
	then
		sudo -n cat "$globalVirtFS"/etc/apt/sources.list.hetzner | _getMost_backend tee -a /etc/apt/sources.list > /dev/null
	fi
	
	# APT sources here provide all packages, and thus can be exclusive of other lists.
	if [[ "$RUNNER_OS" != "" ]] && sudo -n ls "$globalVirtFS"/etc/apt/sources.list.azure > /dev/null 2>&1
	then
		sudo -n cat "$globalVirtFS"/etc/apt/sources.list.azure | _getMost_backend tee -a /etc/apt/sources.list > /dev/null
	elif false
	then
		false
	else
		#sudo -n cat "$globalVirtFS"/etc/apt/sources.list.default | _getMost_backend tee -a /etc/apt/sources.list > /dev/null
		sudo -n cat "$globalVirtFS"/etc/apt/sources.list.modern | _getMost_backend tee -a /etc/apt/sources.list > /dev/null
	fi
	
	
	echo 'deb http://deb.debian.org/debian bookworm-backports main contrib' | _getMost_backend tee /etc/apt/sources.list.d/ub_backports.list > /dev/null


	_getMost_backend apt-get update
	
	
	_messagePlain_nominal 'ca-certificates'
	_getMost_backend_aptGetInstall ca-certificates
	
	_getMost_backend_aptGetInstall apt-utils


	_getMost_backend_aptGetInstall aria2 curl gpg
	_getMost_backend_aptGetInstall gnupg
	_getMost_backend_aptGetInstall lsb-release
	
	echo 'deb [signed-by=/etc/apt/keyrings/apt-fast.gpg] http://ppa.launchpad.net/apt-fast/stable/ubuntu jammy main' | _getMost_backend tee /etc/apt/sources.list.d/apt-fast.list > /dev/null
	_getMost_backend mkdir -p /etc/apt/keyrings
	_getMost_backend curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA2166B8DE8BDC3367D1901C11EE2FF37CA8DA16B' | _getMost_backend gpg --dearmor -o /etc/apt/keyrings/apt-fast.gpg
	# ATTRIBUTION-AI: ChatGPT o3-mini-high 2025-02-13
	_getMost_backend apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1E2824A7F22B44BD 1EE2FF37CA8DA16B
	_getMost_backend apt-get update
	_getMost_backend_aptGetInstall apt-fast

	echo debconf apt-fast/maxdownloads string 16 | _getMost_backend debconf-set-selections
	echo debconf apt-fast/dlflag boolean true | _getMost_backend debconf-set-selections
	echo debconf apt-fast/aptmanager string apt-get | _getMost_backend debconf-set-selections
	
	
	# ATTENTION: WARNING: tasksel
	_chroot tasksel install standard
	
	
	_getMost_backend_aptGetInstall hostnamectl
	#_getMost_backend_aptGetInstall systemd
	_chroot hostnamectl set-hostname default
	
	
	
	_getMost_backend_aptGetInstall btrfs-tools
	_getMost_backend_aptGetInstall btrfs-progs
	_getMost_backend_aptGetInstall btrfs-compsize
	_getMost_backend_aptGetInstall zstd
	
	_getMost_backend_aptGetInstall libwxgtk3.0-gtk3-0v5
	
	
	
	
	_messagePlain_nominal 'firmware-linux'
	_getMost_backend_aptGetInstall firmware-linux
	_getMost_backend_aptGetInstall firmware-linux-free
	_getMost_backend_aptGetInstall firmware-linux-nonfree
	_getMost_backend_aptGetInstall firmware-misc-nonfree
	
	_getMost_backend_aptGetInstall firmware-iwlwifi
	_getMost_backend_aptGetInstall firmware-realtek
	_getMost_backend_aptGetInstall firmware-ralink
	_getMost_backend_aptGetInstall firmware-qcom-media
	_getMost_backend_aptGetInstall firmware-qcom-soc
	_getMost_backend_aptGetInstall firmware-ti-connectivity
	_getMost_backend_aptGetInstall firmware-amd-graphics
	_getMost_backend_aptGetInstall firmware-myricom
	_getMost_backend_aptGetInstall firmware-ath9k-htc
	_getMost_backend_aptGetInstall firmware-samsung
	_getMost_backend_aptGetInstall firmware-atheros
	_getMost_backend_aptGetInstall firmware-libertas
	_getMost_backend_aptGetInstall firmware-netxen
	_getMost_backend_aptGetInstall firmware-intelwimax
	_getMost_backend_aptGetInstall firmware-brcm80211
	_getMost_backend_aptGetInstall firmware-intel-sound
	_getMost_backend_aptGetInstall firmware-cavium
	_getMost_backend_aptGetInstall firmware-b43legacy-installer
	_getMost_backend_aptGetInstall firmware-qlogic
	_getMost_backend_aptGetInstall firmware-adi
	_getMost_backend_aptGetInstall firmware-tomu
	_getMost_backend_aptGetInstall firmware-zd1211
	_getMost_backend_aptGetInstall firmware-crystalhd
	_getMost_backend_aptGetInstall firmware-netronome
	#_getMost_backend_aptGetInstall firmware-b43-installer
	_getMost_backend_aptGetInstall firmware-bnx2x
	_getMost_backend_aptGetInstall firmware-ath9k-htc-dbgsym
	_getMost_backend_aptGetInstall firmware-b43-lpphy-installer
	_getMost_backend_aptGetInstall firmware-bnx2
	_getMost_backend_aptGetInstall firmware-siano
	_getMost_backend_aptGetInstall firmware-sof-signed
	
	_getMost_backend_aptGetInstall bladerf-firmware-fx3
	_getMost_backend_aptGetInstall bluez-firmware
	_getMost_backend_aptGetInstall atmel-firmware
	
	_getMost_backend_aptGetInstall amd64-microcode
	_getMost_backend_aptGetInstall intel-microcode
	_getMost_backend_aptGetInstall iucode-tool

	
	
	sudo -n cp "$scriptLib"/setup/debian/b43-fwcutter_019-14_amd64.deb "$globalVirtFS"/
	if _chroot ls -A -1 /b43-fwcutter_019-14_amd64.deb > /dev/null
	then
		_chroot dpkg -i /b43-fwcutter_019-14_amd64.deb
	else
		# WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		#_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/b43-fwcutter_019-14_amd64.deb
		#_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/b43-fwcutter_019-14_amd64.deb
		
		_chroot dpkg -i ./b43-fwcutter_019-14_amd64.deb
	fi
	
	sudo -n cp "$scriptLib"/setup/debian/firmware-b43-installer_019-14_all.deb "$globalVirtFS"/
	if _chroot ls -A -1 /firmware-b43-installer_019-14_all.deb > /dev/null
	then
		_chroot dpkg -i /firmware-b43-installer_019-14_all.deb
	else
		# WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		#_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-b43-installer_019-14_all.deb
		#_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-b43-installer_019-14_all.deb
		
		_chroot dpkg -i ./firmware-b43-installer_019-14_all.deb
	fi
	
	
	_getMost_backend_aptGetInstall firmware-ipw2x00
	_chroot sh -c 'echo "debconf firmware-ipw2x00/license/accepted select true" | debconf-set-selections'
	# https://github.com/unman/notes/blob/master/apt_automation
	
	# ATTENTION: Obviously, broadcast TV is not a 'bootstrapping' prerequsite, this can be easily removed from default if necessary.
	_chroot sh -c 'echo "debconf firmware-ivtv/license/accepted select true" | debconf-set-selections'
	_getMost_backend_aptGetInstall firmware-ivtv
	
	
	# https://gist.github.com/eighthave/7285154
	
	sudo -n cp "$scriptLib"/setup/debian/firmware-realtek_20210818-1_all.deb "$globalVirtFS"/
	if _chroot ls -A -1 /firmware-realtek_20210818-1_all.deb > /dev/null
	then
		_chroot dpkg -i /firmware-realtek_20210818-1_all.deb
	else
		# WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		#_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-realtek_20210818-1_all.deb
		#_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-realtek_20210818-1_all.deb
		
		_chroot dpkg -i ./firmware-realtek_20210818-1_all.deb
	fi

	sudo -n cp "$scriptLib"/setup/debian/firmware-iwlwifi_20230515-3_all.deb "$globalVirtFS"/
	if _chroot ls -A -1 /firmware-iwlwifi_20230515-3_all.deb > /dev/null
	then
		_chroot dpkg -i /firmware-iwlwifi_20230515-3_all.deb
	else
		# WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		#_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-iwlwifi_20230515-3_all.deb
		#_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-iwlwifi_20230515-3_all.deb
		
		_chroot dpkg -i ./firmware-iwlwifi_20230515-3_all.deb
	fi

	sudo -n cp "$scriptLib"/setup/debian/firmware-misc-nonfree_20230210-5_all.deb "$globalVirtFS"/
	if _chroot ls -A -1 /firmware-misc-nonfree_20230210-5_all.deb > /dev/null
	then
		_chroot dpkg -i /firmware-misc-nonfree_20230210-5_all.deb
	else
		# WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		#_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-misc-nonfree_20230210-5_all.deb
		#_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-misc-nonfree_20230210-5_all.deb
		
		_chroot dpkg -i ./firmware-misc-nonfree_20230210-5_all.deb
	fi
	
	#sudo -n cp "$scriptLib"/setup/debian/firmware-misc-nonfree_20230625-2_all.deb "$globalVirtFS"/
	#if _chroot ls -A -1 /firmware-misc-nonfree_20230625-2_all.deb > /dev/null
	#then
		#_chroot dpkg -i /firmware-misc-nonfree_20230625-2_all.deb
	#else
		## WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		##_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-misc-nonfree_20230625-2_all.deb
		##_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-misc-nonfree_20230625-2_all.deb
		
		#_chroot dpkg -i ./firmware-misc-nonfree_20230625-2_all.deb
	#fi
	
	#sudo -n cp "$scriptLib"/setup/debian/firmware-amd-graphics_20210818-1_all.deb "$globalVirtFS"/
	#if _chroot ls -A -1 /firmware-amd-graphics_20210818-1_all.deb > /dev/null
	#then
		#_chroot dpkg -i /firmware-amd-graphics_20210818-1_all.deb
		#_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y firmware-linux-nonfree firmware-linux
		#_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y firmware-linux-nonfree
		#_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y firmware-linux
	#else
		##_chroot wget http://ftp.us.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-amd-graphics_20210818-1_all.deb
		#_chroot wget https://mirrorservice.org/sites/ftp.debian.org/debian/pool/non-free/f/firmware-nonfree/firmware-amd-graphics_20210818-1_all.deb
		
		#_chroot dpkg -i ./firmware-amd-graphics_20210818-1_all.deb
	#fi
	
	# May include slightly more recent amdgpu firmware. May not be worth the ~500MB compressed disk usage. May interfere with debian firmware packages. Some firmware files (ie. for recent 'mainline' kernel) may still be missing.
	#if _chroot ls -A -1 -d /linux-firmware > /dev/null
	#then
		#true
	#else
		## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
		#_chroot git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git /linux-firmware
		#_chroot rm -rf /linux-firmware/.git
		#_chroot rsync -ax /linux-firmware/. /lib/firmware
	#fi
	

	_messagePlain_nominal 'special (ie. packages missed by Debian Stable distribution, etc)'

	sudo -n cp "$scriptLib"/"setup/debian/curlftpfs_0.9.2-9+b1_amd64.deb" "$globalVirtFS"/
	if _chroot ls -A -1 "/curlftpfs_0.9.2-9+b1_amd64.deb" > /dev/null
	then
		_chroot dpkg -i "/curlftpfs_0.9.2-9+b1_amd64.deb"
	else
		# WARNING: HTTP (as opposed to HTTPS) strongly discouraged.
		#_chroot wget 'http://ftp.debian.org/debian/pool/main/c/curlftpfs/curlftpfs_0.9.2-9+b1_amd64.deb'
		_chroot wget 'https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/c/curlftpfs/curlftpfs_0.9.2-9+b1_amd64.deb'
		
		_chroot dpkg -i "./curlftpfs_0.9.2-9+b1_amd64.deb"
	fi

	_getMost_backend_aptGetInstall curlftpfs

	
	
	_messagePlain_nominal 'tzdata, locales'
	_getMost_backend_aptGetInstall tzdata
	_getMost_backend_aptGetInstall locales
	
	_messagePlain_nominal 'timedatectl, update-locale, localectl'
	[[ -e "$globalVirtFS"/usr/share/zoneinfo/America/New_York ]] && _chroot ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
	_chroot timedatectl set-timezone US/Eastern
	_chroot update-locale LANG=en_US.UTF-8 LANGUAGE
	_chroot localectl set-locale LANG=en_US.UTF-8
	_chroot localectl --no-convert set-x11-keymap us pc104
	
	
	
	
	
	
	
	
	_messageNormal 'chroot: _getMost'
	
	export getMost_backend="chroot"
	_getMost_debian12
	_getMost_debian12
	
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade
	
	
	
	_messageNormal 'chroot: bootloader'

	_messagePlain_nominal 'install intel-acm'

	sudo -n cp "$scriptLib"/setup/intel-acm/copyright-intel_acm-from_deb.txt "$globalVirtFS"/boot/
	sudo -n cp "$scriptLib"/setup/intel-acm/README-intel_acm.md "$globalVirtFS"/boot/
	sudo -n cp "$scriptLib"/setup/intel-acm/*.txt "$globalVirtFS"/boot/
	sudo -n cp "$scriptLib"/setup/intel-acm/*.md "$globalVirtFS"/boot/
	sudo -n cp "$scriptLib"/setup/intel-acm/*.deb "$globalVirtFS"/boot/
	sudo -n cp -r "$scriptLib"/setup/intel-acm/* "$globalVirtFS"/boot/
	sudo -n cp "$scriptLib"/setup/intel-acm/630744_003/* "$globalVirtFS"/boot/
	_chroot ls -A -1 /boot/*.bin > /dev/null
	
	
	#imagedev=$(cat "$scriptLocal"/imagedev)
	
	#export ubVirtImageEFI=p1
	#export ubVirtImageSwap=p2
	#export ubVirtImagePartition=p3
	
	
	_nouveau_disable_procedure
	
	# https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting
	#  'NVIDIA driver does not provide an fbdev driver for the high-resolution console for the kernel compiled-in vesafb'
	#   lsmod should show a modsetting driver in use ...
	#echo 'GRUB_CMDLINE_LINUX="nvidia-drm.modeset=1"' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	echo 'options nvidia-drm modeset=1' | sudo -n tee "$globalVirtFS"/etc/modprobe.d/nvidia-kms.conf
	
	#echo 'GRUB_CMDLINE_LINUX="nouveau.modeset=0 nvidia-drm.modeset=1"' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	
	
	_messagePlain_nominal 'install grub'
	export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"

	_getMost_backend_aptGetInstall tboot
	_getMost_backend_aptGetInstall trousers
	_getMost_backend_aptGetInstall tpm-tools
	_getMost_backend_aptGetInstall trousers-dbg
	
	_getMost_backend_aptGetInstall grub-pc-bin
	
	_chroot env DEBIAN_FRONTEND=noninteractive debconf-set-selections <<< "grub-efi-amd64 grub2/update_nvram boolean false"
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y grub-efi grub-efi-amd64
	_getMost_backend_aptGetInstall linux-image-amd64 linux-headers-amd64 grub-efi

	_getMost_backend_aptGetInstall tboot
	_getMost_backend_aptGetInstall trousers
	_getMost_backend_aptGetInstall tpm-tools
	_getMost_backend_aptGetInstall trousers-dbg
	
	
	
	_getMost_backend apt-get -y clean
	
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	# Install Hybrid/UEFI bootloader by default. May be rewritten later if appropriate.
	_createVMbootloader-bios
	_createVMbootloader-efi
	
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	echo 'GRUB_TIMEOUT=1' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	_chroot update-grub
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	return 0
}










_create_ubDistBuild-rotten_install() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)


	_getMost_backend apt-get -y remove langford-dkms
	_getMost_backend apt-get -y purge langford-dkms

	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	[[ ! -e "$scriptLib"/custom/package_kde.tar.xz ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ ! -e "$globalVirtFS"/package_kde.tar.xz ]] && _messageFAIL
	sudo -n chmod 644 "$globalVirtFS"/package_kde.tar.xz
	
	sudo -n cp -f "$scriptAbsoluteLocation" "$globalVirtFS"/ubiquitous_bash.sh
	[[ ! -e "$globalVirtFS"/ubiquitous_bash.sh ]] && _messageFAIL
	sudo -n chmod 755 "$globalVirtFS"/ubiquitous_bash.sh
	
	
	
	
	
	
	
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _install && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	
	#'linux-headers*'
	#_chroot apt-get -y remove 'linux-image*'

    _messagePlain_probe_cmd _chroot apt-get -y remove 'linux-image*'
    _messagePlain_probe_cmd _chroot apt-get -y purge 'linux-image*'
    #_messagePlain_probe_cmd _chroot apt-get autoremove -y --purge

    _messagePlain_probe_cmd _chroot dpkg --get-selections | grep 'linux-image'

	! _chroot /rotten_install.sh _custom_kernel && _messageFAIL

	_messagePlain_probe_cmd _chroot apt-get -y install -f
	
	# Mainline kernel will be available from usual "core/installations" folders , however, is no longer booted by default, due to apparently frequent regressions (not just out-of-tree module compatibility issues but in-tree issues) with mainline kernels acceptably recent (ie. latest stable branch still apparently has too many regressions) .
	#'linux-headers*mainline'
	_chroot apt-get -y remove 'linux-image*mainline'
	
	_chroot apt-get -y install 'linux-headers-amd64'
	
	
	
	# Significant issues with 'user.max_user_namespaces' affecting KDE , etc .
	#_getMost_backend_aptGetInstall hardening-runtime
	
	_chroot mkdir -p /etc/default/grub.d/
	sudo -n cp -f "$scriptLib"/custom/ubdist_hardening/grub/01_hardening_ubdist.cfg "$globalVirtFS"/etc/default/grub.d/
	sudo -n chmod 644 "$globalVirtFS"/etc/default/grub.d/01_hardening_ubdist.cfg
	
	sudo -n cp -f "$scriptLib"/custom/ubdist_hardening/grub/01_hardening_ubdist-moduleSig.cfg "$globalVirtFS"/etc/default/grub.d/
	sudo -n chmod 644 "$globalVirtFS"/etc/default/grub.d/01_hardening_ubdist-moduleSig.cfg
	
	_chroot mkdir -p /usr/lib/sysctl.d/
	sudo -n cp -f "$scriptLib"/custom/ubdist_hardening/sysctl/10-hardening_ubdist.conf "$globalVirtFS"/usr/lib/sysctl.d/10-hardening.conf
	sudo -n chmod 644 "$globalVirtFS"/usr/lib/sysctl.d/10-hardening_ubdist.conf.conf
	
	
	
	
	
	
	
	_chroot env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --install-recommends -y upgrade
	
	
	_chroot apt-get -y clean
	_chroot sudo -n apt-get autoremove -y --purge

	# https://forum.manjaro.org/t/high-cpu-usage-from-plasmashell-kactivitymanagerd/114305
	# Apparently prevents excessive CPU usage from plasmashell , etc .
	## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
	# DANGER: Unusual. Uses 'rm -rf' directly. Presumed ONLY during dist/OS install .
	#_chroot rm -rf /home/user/.local/share/kactivitymanagerd/resources/*
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# WARNING: No production use.
_create_ubDistBuild-rotten_install-bootOnce() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install: bootOnce'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _custom_bootOnce && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}
# WARNING: No production use.
_create_ubDistBuild-rotten_install-kde() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install: kde'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	sudo -n mv -f "$globalVirtFS"/home/user/package_kde.tar.xz "$globalVirtFS"/home/user/package_kde.tar.xz.$(_uid) > /dev/null 2>&1
	
	[[ ! -e "$scriptLib"/custom/package_kde.tar.xz ]] && [[ ! -e "$scriptLocal"/custom/package_kde.tar.xz ]] && [[ ! -e "$scriptLocal"/package_kde.tar.xz ]] && _messageFAIL
	[[ -e "$scriptLib"/custom/package_kde.tar.xz ]] && sudo -n cp -f "$scriptLib"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ -e "$scriptLocal"/custom/package_kde.tar.xz ]] && sudo -n cp -f "$scriptLocal"/custom/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ -e "$scriptLocal"/package_kde.tar.xz ]] && sudo -n cp -f "$scriptLocal"/package_kde.tar.xz "$globalVirtFS"/package_kde.tar.xz
	[[ ! -e "$globalVirtFS"/package_kde.tar.xz ]] && _messageFAIL
	sudo -n chmod 644 "$globalVirtFS"/package_kde.tar.xz
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	#echo | sudo -n tee "$globalVirtFS"/in_chroot
	! _chroot /rotten_install.sh _custom_kde_drop && _messageFAIL
	#sudo rm -f "$globalVirtFS"/in_chroot
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}



_create_ubDistBuild-install-ubDistBuild() {
	_messageNormal 'chroot: install: ubDistBuild'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	sudo -n mkdir -p "$globalVirtFS"/home/user/ubDistBuild/
	[[ ! -e "$scriptAbsoluteFolder"/.git ]] && _messageFAIL
	#sudo -n cp -r "$scriptAbsoluteFolder"/.git "$globalVirtFS"/home/user/ubDistBuild/
	#sudo -n cp -a "$scriptAbsoluteFolder"/. "$globalVirtFS"/home/user/ubDistBuild/
	#--delete
	
	sudo -n rsync -ax --exclude "_local" "$scriptAbsoluteFolder"/. "$globalVirtFS"/home/user/ubDistBuild/
	sudo -n rsync -ax "$scriptAbsoluteFolder"/_lib/. "$globalVirtFS"/home/user/ubDistBuild/_lib/
	sudo -n rsync -ax "$scriptAbsoluteFolder"/_local/ops.sh "$globalVirtFS"/home/user/ubDistBuild/_local/
	sudo -n rsync -ax "$scriptAbsoluteFolder"/_local/ops.example.sh "$globalVirtFS"/home/user/ubDistBuild/_local/
	sudo -n rsync -ax "$scriptAbsoluteFolder"/_local/TODO-example.txt "$globalVirtFS"/home/user/ubDistBuild/_local/
	sudo -n rsync -ax "$scriptAbsoluteFolder"/_local/.gitignore "$globalVirtFS"/home/user/ubDistBuild/_local/
	sudo -n rsync -ax "$scriptAbsoluteFolder"/_local/ubcp "$globalVirtFS"/home/user/ubDistBuild/_local/
	
	#--exclude "gsysd.log"
	sudo -n rsync -ax --exclude "vm.img" --exclude "vm-live.iso" --exclude "package_rootfs.tar" --exclude "vm.img.*" --exclude "vm-live.iso.*" --exclude "package_rootfs.tar.*" --exclude "WARNING" --exclude "l_o" --exclude "l_o-chrt" --exclude "imagedev" "$scriptAbsoluteFolder"/_local/. "$globalVirtFS"/home/user/ubDistBuild/_local/
	
	_chroot chown -R user:user /home/user/ubDistBuild
	_chroot chmod 700 /home/user/ubDistBuild
	#--quiet
	_chroot sudo -n -u user bash -c 'cd /home/user/ubDistBuild ; git reset --hard ; git submodule update --force --no-fetch --recursive'

	
	_chroot find /home/user/ubDistBuild/.git -name config -exec sed -i 's/.*extraheader.*//g' {} \;

	_messageNormal 'chroot: install: ubDistBuild: report: df'
	_chroot df -h / /boot /boot/efi | _chroot tee /df
	_chroot mount | grep '^.* on / ' | _chroot tee -a /df
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

_create_ubDistBuild-rotten_install-core() {
	_messageNormal '##### init: _create_ubDistBuild-rotten_install'
	
	_messageNormal 'chroot: rotten_install: core'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)

	if [[ -e "$scriptLocal"/ubDistFetch ]] && ! [[ -e "$scriptLocal"/ubDistFetch/_lib/core/FAIL ]]
	then
		## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
		_chroot rm -rf /home/user/core
		sudo -n cp -a "$scriptLocal"/ubDistFetch/_lib/core "$globalVirtFS"/home/user/
		_chroot chown -R user:user /home/user/core

		## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
		_chroot rm -rf /home/user/ubDistFetch
		if [[ -e "$scriptLocal"/core ]]
		then
			_messageFAIL
			_stop 1
			return 1
		fi
		sudo -n mv -f "$scriptLocal"/ubDistFetch/_lib/core "$scriptLocal"/
		sudo -n cp -a "$scriptLocal"/ubDistFetch "$globalVirtFS"/home/user/
		sudo -n mv -f "$scriptLocal"/core "$scriptLocal"/ubDistFetch/_lib/
		_chroot chown -R user:user /home/user/ubDistFetch
	fi

	
	if [[ -e "$scriptLocal"/core.tar.xz ]]
	then
		[[ ! -e "$scriptLocal"/core.tar.xz ]] && _messageFAIL
		#sudo -n cp -f "$scriptLocal"/core.tar.xz "$globalVirtFS"/core.tar.xz
		#[[ ! -e "$globalVirtFS"/core.tar.xz ]] && _messageFAIL
		#sudo -n chmod 644 "$globalVirtFS"/core.tar.xz
		
		
		if [[ "$skimfast" != "true" ]]
		then
			tar -xvf "$scriptLocal"/core.tar.xz -C "$globalVirtFS"/home/user/
		else
			tar -xf "$scriptLocal"/core.tar.xz -C "$globalVirtFS"/home/user/
		fi
		
		_chroot chown -R user:user /home/user/core
	fi
	
	
	[[ ! -e "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh ]] && _messageFAIL
	sudo -n cp -f "$scriptLib"/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh "$globalVirtFS"/rotten_install.sh
	[[ ! -e "$globalVirtFS"/rotten_install.sh ]] && _messageFAIL
	sudo -n chmod 700 "$globalVirtFS"/rotten_install.sh
	
	
	if ! [[ -e "$scriptLocal"/core.tar.xz ]] && ! [[ -e "$scriptLocal"/ubDistFetch/_lib/core ]]
	then
		#echo | sudo -n tee "$globalVirtFS"/in_chroot
		! _chroot /rotten_install.sh _custom_core_drop && _messageFAIL
		#sudo rm -f "$globalVirtFS"/in_chroot
	else
		_messagePlain_good 'good: core.tar.xz  OR  "$scriptLocal"/ubDistFetch/_lib/core'
		rm -f "$scriptLocal"/core.tar.xz
	fi
	



	_chroot find /home/user/core/installations /home/user/core/infrastructure /home/user/core/variant /home/user/core/info -not \( -path \*.git\* -prune \) | grep -v '_local/h' | sudo -n tee "$globalVirtFS"/coreReport > /dev/null
	sudo -n cp -f "$globalVirtFS"/coreReport "$scriptLocal"/coreReport
	sudo -n chown "$USER":"$USER" "$scriptLocal"/coreReport




	_messageNormal 'chroot: rotten_install: core: extra'

	
	
	_chroot rm -f /etc/modprobe.d/thinkfan.conf
	echo "options thinkpad_acpi fan_control=1" | sudo -n tee -a "$globalVirtFS"/etc/modprobe.d/thinkfan.conf
	
	
	
	export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"
	
	_getMost_backend apt-get update
	
	
	
	_getMost_backend_aptGetInstall zip
	_getMost_backend_aptGetInstall unzip
	
	_getMost_backend_aptGetInstall par2
	
	

	_getMost_backend_aptGetInstall w3m


	# Building out-of-tree kernel modules is an essential feature of ubdist/OS , ubDistBuild , etc . If these packages are added to '_getMost' for "ubiquitous_bash", the then redundant install commands here will still remain important.
	_getMost_backend_aptGetInstall dh-dkms
	_getMost_backend_aptGetInstall dkms devscripts debhelper dh-dkms build-essential
	
	
	_getMost_backend_aptGetInstall adb
	
	
	
	
	_getMost_backend_aptGetInstall okteta
	
	
	
	
	_getMost_backend_aptGetInstall kruler
	
	
	
	
	_getMost_backend_aptGetInstall git-lfs
	
	_getMost_backend_aptGetInstall libtorch-dev
	_getMost_backend_aptGetInstall libtorch-test

	_getMost_backend_aptGetInstall python3-torch
	_getMost_backend_aptGetInstall python3-torchaudio
	_getMost_backend_aptGetInstall python3-torchtext
	_getMost_backend_aptGetInstall python3-torchvision
	

	

	# WARNING: May be obsolete versions.
	# WARNING: If these system installed 3DPrinting utilities cause conflicts with standalone versions, they will then be removed.
	_getMost_backend_aptGetInstall prusa-slicer
	_getMost_backend_aptGetInstall slic3r
	_getMost_backend_aptGetInstall cura
	
	_getMost_backend_aptGetInstall pronterface

	# https://pycam.sourceforge.net/requirements/
	_getMost_backend_aptGetInstall python3-gi python3-opengl gir1.2-gtk-3.0
	
	
	
	_getMost_backend_aptGetInstall meshlab



	
	#_getMost_backend_aptGetInstall fldigi
	#_getMost_backend_aptGetInstall flamp
	#_getMost_backend_aptGetInstall psk31lx
	
	# Seems capable for rx .
	#_getMost_backend_aptGetInstall multimon-ng
	
	
	#_getMost_backend_aptGetInstall minimodem
	
	_getMost_backend_aptGetInstall gnucash
	
	_getMost_backend_aptGetInstall libslvs1
	_getMost_backend_aptGetInstall libslvs1-dev
	
	_getMost_backend_aptGetInstall wsjtx

	_getMost_backend_aptGetInstall gnuradio
	_getMost_backend_aptGetInstall gnuradio-doc
	_getMost_backend_aptGetInstall gnuradio-dev

	# Apparent suggested/recommends/etc of gnuradio, which as another bad dkms thing, has been found to apparently break several critically essential things: apt , linux kernel , initramfs , live boot .
	_getMost_backend apt-get -y remove langford-dkms
	_getMost_backend apt-get -y purge langford-dkms

	_chroot sudo -n -u user bash -c 'cd /home/user/core/installations/gr-pipe ; mkdir -p ./build ; cd ./build ; cmake .. ; make ; sudo -n make install'

	_getMost_backend_aptGetInstall gr-air-modes
	_getMost_backend_aptGetInstall gr-fosphor
	_getMost_backend_aptGetInstall gr-funcube
	_getMost_backend_aptGetInstall gr-gsm
	_getMost_backend_aptGetInstall gr-iqbal
	_getMost_backend_aptGetInstall gr-radar
	_getMost_backend_aptGetInstall gr-radar-doc
	_getMost_backend_aptGetInstall gr-rds
	_getMost_backend_aptGetInstall gr-satellites

	_getMost_backend_aptGetInstall inspectrum


	# https://github.com/merbanan/rtl_433
	_chroot rm -f /etc/modprobe.d/blacklist-dvb-rtl.conf
	echo 'blacklist dvb_usb_rtl28xxu' | sudo -n tee -a "$globalVirtFS"/etc/modprobe.d/blacklist-dvb-rtl.conf

	_getMost_backend_aptGetInstall rtl-433


	_getMost_backend_aptGetInstall gqrx-sdr

	_getMost_backend_aptGetInstall rtl-sdr


	_getMost_backend_aptGetInstall hamradio-sdr
	#_getMost_backend env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install --no-install-recommends -y hamradio-sdr
	_getMost_backend apt-get -y remove langford-dkms
	_getMost_backend apt-get -y purge langford-dkms

	_getMost_backend_aptGetInstall airspy
	_getMost_backend_aptGetInstall bladerf
	_getMost_backend_aptGetInstall cubicsdr
	_getMost_backend_aptGetInstall cutesdr
	_getMost_backend_aptGetInstall gnss-sdr
	_getMost_backend_aptGetInstall gr-hpsdr
	_getMost_backend_aptGetInstall gr-limesdr
	_getMost_backend_aptGetInstall gr-osmosdr
	_getMost_backend_aptGetInstall hackrf
	_getMost_backend_aptGetInstall indi-limesdr
	_getMost_backend_aptGetInstall limesuite
	_getMost_backend_aptGetInstall limesuite-udev
	_getMost_backend_aptGetInstall miri-sdr
	_getMost_backend_aptGetInstall osmo-fl2k
	_getMost_backend_aptGetInstall osmo-sdr
	_getMost_backend_aptGetInstall osmo-trx
	_getMost_backend_aptGetInstall python3-bladerf
	_getMost_backend_aptGetInstall python3-soapysdr
	_getMost_backend_aptGetInstall python3-qthid-fcd-controller
	_getMost_backend_aptGetInstall quisk
	_getMost_backend_aptGetInstall soapysdr-tools
	_getMost_backend_aptGetInstall soapysdr-module-all
	_getMost_backend_aptGetInstall soapysdr-module xtrx
	_getMost_backend_aptGetInstall uhd-soapysdr
	
	_getMost_backend_aptGetInstall hackrf-firmware
	_getMost_backend_aptGetInstall libhackrf-dev
	_getMost_backend_aptGetInstall hackrf-doc
	_getMost_backend_aptGetInstall librtlsdr-dev
	
	_getMost_backend apt-get -y remove langford-dkms
	_getMost_backend apt-get -y purge langford-dkms
	

	_getMost_backend apt-get remove -y xtrx-dkms
	_getMost_backend apt-get remove -y xtrx-fft
	#_getMost_backend_aptGetInstall xtrx-dkms
	#_getMost_backend_aptGetInstall xtrx-fft

	
	_getMost_backend_aptGetInstall wfview
	

	_getMost_backend_aptGetInstall gpsbabel
	
	
	_getMost_backend_aptGetInstall lirc
	_getMost_backend_aptGetInstall lirc-x
	_getMost_backend_aptGetInstall lirc-compat-remotes
	_getMost_backend_aptGetInstall lirc-drv-irman
	_getMost_backend_aptGetInstall lirc-doc
	_getMost_backend_aptGetInstall ir-keytable
	
	_getMost_backend_aptGetInstall setserial
	
	_getMost_backend_aptGetInstall statserial

	
	_getMost_backend_aptGetInstall chirp


	_getMost_backend_aptGetInstall sox
	
	_getMost_backend_aptGetInstall ladspa-sdk
	#_getMost_backend_aptGetInstall ladspa-plugin
	_getMost_backend_aptGetInstall swh-plugins
	_getMost_backend_aptGetInstall tap-plugins
	_getMost_backend_aptGetInstall cmt
	_getMost_backend_aptGetInstall bs2b-ladspa

	_getMost_backend_aptGetInstall mplayer
	_getMost_backend_aptGetInstall w-scan
	
	


	_getMost_backend_aptGetInstall marble
	_getMost_backend_aptGetInstall marble-qt
	
	_getMost_backend_aptGetInstall qgis

	
	_getMost_backend_aptGetInstall stellarium
	
	_getMost_backend_aptGetInstall gpredict
	
	_getMost_backend_aptGetInstall audacious
	
	
	_getMost_backend_aptGetInstall sloccount
	
	_getMost_backend apt-get -y remove langford-dkms
	_getMost_backend apt-get -y purge langford-dkms
	
	
	# May not be usable with VirtualBox compatible kernel .
	# May break:
#ccp
#irqbypass
#kvm
#kvm_amd
#vboxdrv
#vboxnetadp
#vboxnetflt
	#_getMost_backend_aptGetInstall xen-system-amd64
	#_getMost_backend_aptGetInstall xen-tools


	_getMost_backend_aptGetInstall virt-manager
	_getMost_backend_aptGetInstall virt-viewer
	_getMost_backend_aptGetInstall virtinst


	_getMost_backend apt-get remove -y avahi-daemon
	_getMost_backend apt-get remove -y avahi-utils
	_getMost_backend apt-get remove -y ipp-usb

	_getMost_backend apt-get remove -y kdeconnect
	
	
	# DANGER: ChRoot or similar incomplete use of entire dist/OS may invalidate essential presumptions.
	#  DANGER: Presuming trust for these binaries is already equivalent to trust of an entire dist/OS .
	#  CAUTION: Presuming conflicts with other installed software is a non-issue for an entire dist/OS .
	_getMost_backend_aptGetInstall yubikey-manager
	_getMost_backend_aptGetInstall yubico-piv-tool
	
	
	_getMost_backend_aptGetInstall tftpd-hpa
	_getMost_backend_aptGetInstall nginx
	_getMost_backend_aptGetInstall vsftpd
	_getMost_backend_aptGetInstall vsftpd-dbg
	
	_getMost_backend_aptGetInstall filezilla
	
	
	# Responsible and technical use ONLY .
	_getMost_backend_aptGetInstall pcsxr
	_getMost_backend_aptGetInstall mupen64plus-qt
	_getMost_backend_aptGetInstall libmupen64plus-dev
	
	
	
	# Though not configured as part of the default desktop environment, for the niche constrained use cases, this can be configured very quickly.
	_getMost_backend_aptGetInstall yakuake
	
	
	
	_getMost_backend_aptGetInstall asciinema
	
	
	# Recommend 'pv' , 'stdbuf' , etc, instead, available for both ubdist/OS (ie. UNIX/Linux), as well as Cygwin/MSW .
	#_getMost_backend_aptGetInstall buffer
	#_getMost_backend_aptGetInstall mbuffer
	
	_getMost_backend_aptGetInstall busybox
	
	
	_getMost_backend apt-get -y clean


	#codex
	#claude
	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _gitBest pull ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _gitBest submodule update --recursive ; ./ubiquitous_bash.sh _setup_codex ; ./ubiquitous_bash.sh _setup_claude_code'

	
	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _gitBest pull ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _gitBest submodule update --recursive ; ./ubiquitous_bash.sh _setup_asciinema_convert'

	

	# Alternative generated by ChatGPT 3.5 2023-08-14 . Discouraged unless git tags are not well maintained.
	# curl -s "https://github.com/microsoft/WSL2-Linux-Kernel/releases" | grep -o '<a href="/microsoft/WSL2-Linux-Kernel/releases/tag/[^"]*' | sed -E 's/.*tag\/([^"]+)/\1/' | sort -V -r

	#--shallow-since="Fri Jan 13 12:43:26 2023 +0000"
	#_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure ; rmdir WSL2-Linux-Kernel ; git config --global checkout.workers -1 ; git clone --depth 1 --no-checkout "https://github.com/microsoft/WSL2-Linux-Kernel.git"'
	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure ; rmdir WSL2-Linux-Kernel ; git config --global checkout.workers -1 ; git clone --depth 1 --no-checkout --branch $(git ls-remote --tags https://github.com/microsoft/WSL2-Linux-Kernel.git | cut -f2 | sed "s/refs\/tags\///g" | grep linux-msft-wsl | sort -V -r | head -n1 | tr -dc "a-zA-Z0-9.:\-_") "https://github.com/microsoft/WSL2-Linux-Kernel.git"'



	_chroot sudo -n -u user bash -c 'cd /home/user/core/installations/huggingface_cli ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _huggingface_cli -h'
	

	
	# WARNING: May be untested.
	# Eventually, a custom function may be necessary. Despite the name, the 'ubuntu-22.04' install script may have a better chance with recent versions of debian.
	# https://github.com/Klipper3d/klipper/issues/5523
	#_chroot sudo -n -u user bash -c 'cd /home/user/core/installations/klipper ; chmod 755 ./scripts/install-ubuntu-22.04.sh ; ./scripts/install-ubuntu-22.04.sh'

	# systemctl status klipper
	# cat /tmp/klippy.log



	_chroot sudo -n -u user bash -c 'cd /home/user/core/installations/kiauh-automatic ; chmod 755 ./magic.sh ; ./magic.sh'
	#_chroot sudo -n -u user bash -c 'cd /home/user/core/installations/kiauh-automatic ; chmod 755 ./auto.sh ; ./auto.sh'
	
	
	# NOTICE: End-user or scripts modifying the dist/OS may do this. These large files are not very practical to include in ubdist/OS .
	#_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/iconArt ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _fetch_iconArt'
	

	
	# WARNING: Do NOT install 'Assembly3' workbench here , as that may be untested.
	
	_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; wget "https://github.com/kbwbe/A2plus/archive/refs/tags/v0.4.60.zip" -O /dev/stdout | busybox unzip /dev/stdin ; mv -f A2plus-0.4.60 A2Plus'
	
	_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; wget "https://github.com/shaise/FreeCAD_SheetMetal/archive/refs/tags/V0.4.02-beta.zip" -O /dev/stdout | busybox unzip /dev/stdin ; mv -f FreeCAD_SheetMetal-0.4.02-beta SheetMetal'
	
	_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; wget "https://github.com/shaise/FreeCAD_FastenersWB/archive/refs/tags/V0.5.13-beta.zip" -O /dev/stdout | busybox unzip /dev/stdin ; mv -f FreeCAD_FastenersWB-0.5.13-beta FastenersWB'
	
	_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; wget "https://github.com/easyw/Manipulator/archive/471787b8d47504665d350960f9fb507052154edb.zip" -O /dev/stdout | busybox unzip /dev/stdin ; mv -f Manipulator-471787b8d47504665d350960f9fb507052154edb Manipulator'
	#_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; git config --global checkout.workers -1 ; git clone --recursive --depth 1 "https://github.com/easyw/Manipulator.git"'
	
	_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; wget "https://github.com/DanMiel/QuickMeasure/archive/7735801eb174e1527ee94ae532139a47d50694ff.zip" -O /dev/stdout | busybox unzip /dev/stdin ; mv -f QuickMeasure-7735801eb174e1527ee94ae532139a47d50694ff QuickMeasure'
	#_chroot sudo -n -u user bash -c 'mkdir -p /home/user/.FreeCAD/Mod ; cd /home/user/.FreeCAD/Mod ; git config --global checkout.workers -1 ; git clone --recursive --depth 1 "https://github.com/DanMiel/QuickMeasure.git"'
	
	

	# DANGER: Klipper services should be started by a script, possibly called by cron, automatically detecting relevant CAN bus attached hardware, if any, and installing appropriate configuration files. Thus, Klipper services are disabled by default.
	_chroot mkdir -p /root/systemd/etc--systemd--system
	_chroot mkdir -p /root/systemd/lib--systemd--system
	
	_chroot sudo -n systemctl disable KlipperScreen
	_chroot systemctl disable KlipperScreen.service
	_chroot sudo -n systemctl stop KlipperScreen
	_chroot systemctl stop KlipperScreen.service

	_chroot sudo -n systemctl disable crowsnest
	_chroot systemctl disable crowsnest.service
	_chroot sudo -n systemctl stop crowsnest
	_chroot systemctl stop crowsnest.service

	_chroot sudo -n systemctl disable mainsail
	_chroot systemctl disable mainsail.service
	_chroot sudo -n systemctl stop mainsail
	_chroot systemctl stop mainsail.service

	_chroot sudo -n systemctl disable nginx
	_chroot systemctl disable nginx.service
	_chroot sudo -n systemctl mask nginx
	_chroot systemctl mask nginx.service
	_chroot sudo -n systemctl stop nginx
	_chroot systemctl stop nginx.service

	_chroot sudo -n systemctl disable moonraker
	_chroot systemctl disable moonraker.service
	_chroot sudo -n systemctl stop moonraker
	_chroot systemctl stop moonraker.service

	_chroot sudo -n systemctl disable klipper
	_chroot systemctl disable klipper.service
	_chroot sudo -n systemctl stop klipper
	_chroot systemctl stop klipper.service





	_chroot sudo -n systemctl disable SoapySDRServer
	_chroot systemctl disable SoapySDRServer.service
	_chroot sudo -n systemctl mask SoapySDRServer
	_chroot systemctl mask SoapySDRServer.service
	_chroot sudo -n systemctl stop SoapySDRServer
	_chroot systemctl stop SoapySDRServer.service




	_chroot sudo -n systemctl disable tor
	_chroot systemctl disable tor.service
	_chroot sudo -n systemctl mask tor
	_chroot systemctl mask tor.service
	_chroot sudo -n systemctl stop tor
	_chroot systemctl stop tor.service




	_chroot sudo -n systemctl disable ssh
	_chroot systemctl disable ssh.service

	_chroot sudo -n systemctl disable sshd
	_chroot systemctl disable sshd.service


	_chroot systemctl disable man-db
	
	
	
	
	
	
	_chroot sudo -n systemctl disable gpsd
	_chroot systemctl disable gpsd.service
	_chroot sudo -n systemctl mask gpsd
	_chroot systemctl mask gpsd.service
	_chroot sudo -n systemctl stop gpsd
	_chroot systemctl stop gpsd.service
	
	_chroot sudo -n systemctl disable lircd
	_chroot systemctl disable lircd.service
	_chroot sudo -n systemctl mask lircd
	_chroot systemctl mask lircd.service
	_chroot sudo -n systemctl stop lircd
	_chroot systemctl stop lircd.service
	
	
	_chroot sudo -n systemctl disable nfs-blkmap
	_chroot systemctl disable nfs-blkmap.service
	_chroot sudo -n systemctl stop nfs-blkmap
	_chroot systemctl stop nfs-blkmap.service
	
	_chroot sudo -n systemctl disable nfs-idmapd
	_chroot systemctl disable nfs-idmapd.service
	_chroot sudo -n systemctl stop nfs-idmapd
	_chroot systemctl stop nfs-idmapd.service
	
	_chroot sudo -n systemctl disable nfs-mountd
	_chroot systemctl disable nfs-mountd.service
	_chroot sudo -n systemctl stop nfs-mountd
	_chroot systemctl stop nfs-mountd.service
	
	_chroot sudo -n systemctl disable nfsdcld
	_chroot systemctl disable nfsdcld.service
	_chroot sudo -n systemctl stop nfsdcld
	_chroot systemctl stop nfsdcld.service
	
	_chroot sudo -n systemctl disable nfs-server
	_chroot systemctl disable nfs-server.service
	_chroot sudo -n systemctl stop nfs-server
	_chroot systemctl stop nfs-server.service
	
	
	_chroot sudo -n systemctl disable apache2
	_chroot systemctl disable apache2.service
	_chroot sudo -n systemctl mask apache2
	_chroot systemctl mask apache2.service
	_chroot sudo -n systemctl stop apache2
	_chroot systemctl stop apache2.service
	
	
	# DANGER: Also provides MS netbios .
	#  DANGER: Will only enable if, which should not be, strictly necessary for _userQemu/etc , etc .
	_chroot sudo -n systemctl disable rpc-statd
	_chroot systemctl disable rpc-statd.service
	_chroot sudo -n systemctl mask rpc-statd
	_chroot systemctl mask rpc-statd.service
	_chroot sudo -n systemctl stop rpc-statd
	_chroot systemctl stop rpc-statd.service
	
	_chroot sudo -n systemctl disable rpcbind
	_chroot systemctl disable rpcbind.service
	_chroot sudo -n systemctl mask rpcbind
	_chroot systemctl mask rpcbind.service
	_chroot sudo -n systemctl stop rpcbind
	_chroot systemctl stop rpcbind.service
	
	_chroot sudo -n systemctl disable nmbd
	_chroot systemctl disable nmbd.service
	_chroot sudo -n systemctl stop nmbd
	_chroot systemctl stop nmbd.service
	
	_chroot sudo -n systemctl disable smbd
	_chroot systemctl disable smbd.service
	_chroot sudo -n systemctl stop smbd
	_chroot systemctl stop smbd.service
	
	
	
	
	_chroot sudo -n systemctl disable tftpd-hpa
	_chroot systemctl disable tftpd-hpa.service
	_chroot sudo -n systemctl mask tftpd-hpa
	_chroot systemctl mask tftpd-hpa.service
	_chroot sudo -n systemctl stop tftpd-hpa
	_chroot systemctl stop tftpd-hpa.service
	
	_chroot sudo -n systemctl disable tftpd
	_chroot systemctl disable tftpd.service
	_chroot sudo -n systemctl mask tftpd
	_chroot systemctl mask tftpd.service
	_chroot sudo -n systemctl stop tftpd
	_chroot systemctl stop tftpd.service
	
	_chroot sudo -n systemctl disable tftp
	_chroot systemctl disable tftp.service
	_chroot sudo -n systemctl mask tftp
	_chroot systemctl mask tftp.service
	_chroot sudo -n systemctl stop tftp
	_chroot systemctl stop tftp.service

	_chroot sudo -n systemctl disable nginx
	_chroot systemctl disable nginx.service
	_chroot sudo -n systemctl mask nginx
	_chroot systemctl mask nginx.service
	_chroot sudo -n systemctl stop nginx
	_chroot systemctl stop nginx.service
	
	_chroot sudo -n systemctl disable vsftpd
	_chroot systemctl disable vsftpd.service
	_chroot sudo -n systemctl stop vsftpd
	_chroot systemctl stop vsftpd.service
	
	
	




	#if [[ ! -e "$globalVirtFS"/binReport ]]
	#then
		_chroot find /bin/ /usr/bin/ /sbin/ /usr/sbin/ | sudo -n tee "$globalVirtFS"/binReport > /dev/null
		_chroot find /home/user/.nix-profile/bin | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null 2>&1
		_chroot find /home/user/.gcloud/google-cloud-sdk/bin | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null
		_chroot find /home/user/.ebcli-virtual-env/executables | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null 2>&1
		sudo -n cp -f "$globalVirtFS"/binReport "$scriptLocal"/binReport
		sudo -n chown "$USER":"$USER" "$scriptLocal"/binReport
	#fi








	_messageNormal 'chroot: rotten_install: core: _setup_prog'

	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/PanelBoard ; ./ubiquitous_bash.sh _setup_prog'







	_messageNormal 'chroot: rotten_install: core: _cfgFW'

    _writeFW_ip-github-port "$globalVirtFS"
	_writeFW_ip-google-port "$globalVirtFS"
	_writeFW_ip-misc-port "$globalVirtFS"
    _writeFW_ip-googleDNS-port "$globalVirtFS"
    _writeFW_ip-cloudfareDNS-port "$globalVirtFS"
	_writeFW_ip-DUBIOUS "$globalVirtFS"
	_writeFW_ip-DUBIOUS-more "$globalVirtFS"


	# ### ATTENTION: Block comment. ### #
	if false
	then
	
	sudo -n mv "$globalVirtFS"/usr/bin/iptables "$globalVirtFS"/usr/bin/iptables-orig
	sudo -n mv "$globalVirtFS"/bin/iptables "$globalVirtFS"/bin/iptables-orig
	sudo -n mv "$globalVirtFS"/usr/sbin/iptables "$globalVirtFS"/usr/sbin/iptables-orig
	sudo -n mv "$globalVirtFS"/sbin/iptables "$globalVirtFS"/sbin/iptables-orig
	sudo -n mv "$globalVirtFS"/usr/bin/ip6tables "$globalVirtFS"/usr/bin/ip6tables-orig
	sudo -n mv "$globalVirtFS"/bin/ip6tables "$globalVirtFS"/bin/ip6tables-orig
	sudo -n mv "$globalVirtFS"/usr/sbin/ip6tables "$globalVirtFS"/usr/sbin/ip6tables-orig
	sudo -n mv "$globalVirtFS"/sbin/ip6tables "$globalVirtFS"/sbin/ip6tables-orig

	sudo -n rm -f "$globalVirtFS"/usr/bin/iptables
	sudo -n rm -f "$globalVirtFS"/bin/iptables
	sudo -n rm -f "$globalVirtFS"/usr/sbin/iptables
	sudo -n rm -f "$globalVirtFS"/sbin/iptables
	sudo -n rm -f "$globalVirtFS"/usr/bin/ip6tables
	sudo -n rm -f "$globalVirtFS"/bin/ip6tables
	sudo -n rm -f "$globalVirtFS"/usr/sbin/ip6tables
	sudo -n rm -f "$globalVirtFS"/sbin/ip6tables

	cat << 'CZXWXcRMTo8EmM8i4d' | sudo -n tee "$globalVirtFS"/usr/bin/iptables > /dev/null
#!/bin/bash

if [[ "$1" == "--version" ]] || [[ "$1" == "-V" ]]
then
	echo "iptables v1.8.7 (nf_tables)"
	exit 0
fi

true

exit 0
CZXWXcRMTo8EmM8i4d
	cat << 'CZXWXcRMTo8EmM8i4d' | sudo -n tee "$globalVirtFS"/usr/bin/ip6tables > /dev/null
#!/bin/bash

if [[ "$1" == "--version" ]] || [[ "$1" == "-V" ]]
then
	echo "ip6tables v1.8.7 (nf_tables)"
	exit 0
fi

true

exit 0
CZXWXcRMTo8EmM8i4d

	sudo -n chown root:root "$globalVirtFS"/usr/bin/iptables
	sudo -n chmod 755 "$globalVirtFS"/usr/bin/iptables
	sudo -n chown root:root "$globalVirtFS"/usr/bin/ip6tables
	sudo -n chmod 755 "$globalVirtFS"/usr/bin/ip6tables

	_messagePlain_probe '__________________________________________________'
	# Stricter rules (ie. '_cfgFW-terminal' ) may be applied later if appropriate.
	#_chroot sudo -n -u user bash -c 'cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW'
	#echo
	#echo
	#echo
	#_chroot sudo -n -u user bash -c 'cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW'
	_chroot sudo -n -u user bash -c 'cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW-desktop'
	echo
	echo
	echo
	_chroot sudo -n -u user bash -c 'cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW-desktop'
	_messagePlain_probe '__________________________________________________'

	sudo -n rm -f "$globalVirtFS"/usr/bin/iptables
	sudo -n rm -f "$globalVirtFS"/bin/iptables
	sudo -n rm -f "$globalVirtFS"/usr/sbin/iptables
	sudo -n rm -f "$globalVirtFS"/sbin/iptables
	sudo -n rm -f "$globalVirtFS"/usr/bin/ip6tables
	sudo -n rm -f "$globalVirtFS"/bin/ip6tables
	sudo -n rm -f "$globalVirtFS"/usr/sbin/ip6tables
	sudo -n rm -f "$globalVirtFS"/sbin/ip6tables

	sudo -n mv -f "$globalVirtFS"/usr/bin/iptables-orig "$globalVirtFS"/usr/bin/iptables
	sudo -n mv -f "$globalVirtFS"/bin/iptables-orig "$globalVirtFS"/bin/iptables
	sudo -n mv -f "$globalVirtFS"/usr/sbin/iptables-orig "$globalVirtFS"/usr/sbin/iptables
	sudo -n mv -f "$globalVirtFS"/sbin/iptables-orig "$globalVirtFS"/sbin/iptables
	sudo -n mv -f "$globalVirtFS"/usr/bin/ip6tables-orig "$globalVirtFS"/usr/bin/ip6tables
	sudo -n mv -f "$globalVirtFS"/bin/ip6tables-orig "$globalVirtFS"/bin/ip6tables
	sudo -n mv -f "$globalVirtFS"/usr/sbin/ip6tables-orig "$globalVirtFS"/usr/sbin/ip6tables
	sudo -n mv -f "$globalVirtFS"/sbin/ip6tables-orig "$globalVirtFS"/sbin/ip6tables

	fi
	# ### ATTENTION: Block comment. ### #




	_messageNormal 'chroot: rotten_install: core: special: hardware'


	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _gitBest pull ; chmod 755 ./ubiquitous_bash.sh ; ./ubiquitous_bash.sh _gitBest submodule update --recursive ; chmod 755 ./_lib/setup/hardware/_get_hardware.sh ; ./_lib/setup/hardware/_get_hardware.sh _install'


	_messageNormal 'chroot: rotten_install: core: special'

	sudo -n cat "$globalVirtFS"/etc/apt/sources.list.default | _getMost_backend tee /etc/apt/sources.list > /dev/null

	_getMost_backend apt-get update

	# Have been known to apparently break several critically essential things: apt , linux kernel , initramfs , live boot . Redundant remove commands are placed here.
	_getMost_backend apt-get -y remove langford-dkms
	_getMost_backend apt-get -y purge langford-dkms
	
	_getMost_backend apt-get -y clean
	
	_chroot systemctl set-default graphical.target

	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}


_create_ubDistBuild-bootOnce-qemu_sequence() {
	! type qemu-system-x86_64 > /dev/null 2>&1 && _stop 1

	local currentExitStatus
	
	( [[ "$qemuHeadless" != "false" ]] || [[ "$DISPLAY" == "" ]] ) && export qemuHeadless="true"
	
	[[ "$qemuXvfb" == "true" ]] && export qemuHeadless="false"
	
	if [[ "$qemuXvfb" == "true" ]]
	then
		local currentPID_xvfb
		Xvfb :30 > /dev/null 2>&1 &
		currentPID_xvfb="$!"
		sleep 1
		export DISPLAY=":30"
	fi
	
	
	export qemuBootOnce="true"
	
	local currentPID
	local currentPID_qemu
	local currentNumProc
	
	"$scriptAbsoluteLocation" _zSpecial_qemu "$@" &
	currentPID="$!"
	sleep 6
	currentPID_qemu=$(ps -ef --sort=start_time | grep qemu | grep -v grep | tr -dc '0-9 \n' | tail -n1 | sed 's/\ *//' | cut -f1 -d\  )
	
	
	##disown -h $currentPID
	#disown -a -h -r
	#disown -a -r
	
	# Up to 700s per kernel (ie. modules), plus 500s, total of 1147s for one kernel, 1749s to wait for three kernels.
	#6200s ... had a track record of a few years
	# Prefer 6200s, as this is normally sufficient for both the apparent ~1900s without compiling vbox kernel modules, and longer times if compiling under qemu virtualizaton.
	# The longer 13500s wait is mostly only beneficial ONLY to make the exit status a clearly unambigious statement that FAIL actually happened, not merely timeout before compiling could complete.
	_messagePlain_nominal 'wait: 13500s'
	local currentIterationWait
	currentIterationWait=0
	pgrep qemu-system
	pgrep qemu
	ps -p "$currentPID"
	while [[ "$currentIterationWait" -lt 13500 ]] && ( pgrep qemu-system > /dev/null 2>&1 || pgrep qemu > /dev/null 2>&1 || ps -p "$currentPID" > /dev/null 2>&1 )
	do
		if ( [[ "$qemuXvfb" == "true" ]] && ( [[ "$currentIterationWait" -le 320 ]] && [[ $(bc <<< "$currentIterationWait % 5") == 0 ]] ) || [[ $(bc <<< "$currentIterationWait % 30") == 0 ]] )
		then
			mkdir -p "$scriptLocal"/analysis/screenshots
			#xwd -root -silent | convert xwd:- png:"$scriptLocal"/analysis/screenshots/qemu-01-"$currentIterationWait".png
			xwd -root -silent | convert xwd:- -quality 35 jpg:"$scriptLocal"/analysis/screenshots/qemu-01-"$currentIterationWait".jpg
			#jp2a --background=dark --colors --width=280 "$scriptLocal"/analysis/screenshots/qemu-01-"$currentIterationWait".jpg
		fi
		
		
		
		sleep 1
		let currentIterationWait=currentIterationWait+1
	done
	_messagePlain_probe_var currentIterationWait
	[[ "$currentIterationWait" -ge 13500 ]] && _messagePlain_bad 'bad: fail: bootdisc: poweroff' && currentExitStatus=1
	sleep 27
	
	
	# May not be necessary. Theoretically redundant.
	local currentStopJobs
	currentStopJobs=$(jobs -p -r 2> /dev/null)
	_messagePlain_probe_var currentStopJobs
	[[ "$currentStopJobs" != "" ]] && kill "$currentStopJobs"
	
	#disown -h $currentPID
	disown -a -h -r
	disown -a -r
	
	
	currentNumProc=$(ps -e | grep qemu-system-x86 | wc -l | tr -dc '0-9')
	_messagePlain_probe_var currentNumProc
	_messagePlain_probe '$$= '$$
	_messagePlain_probe_var currentPID
	kill "$currentPID"
	_messagePlain_probe_var currentPID_qemu
	kill "$currentPID_qemu"
	sleep 1
	
	if [[ "$currentNumProc" == "1" ]]
	then
		pkill qemu-system-x86
		sleep 3
		pkill -KILL qemu-system-x86
		sleep 3
	fi
	
	
	echo
	
	if [[ "$qemuXvfb" == "true" ]]
	then
		kill "$currentPID_xvfb"
		sleep 3
		kill -KILL "$currentPID_xvfb"
		pkill Xvfb
	fi
	
	rm -f "$scriptLocal"/FAIL_bootOnce
	if [[ "$currentExitStatus" == "1" ]]
	then
		echo ${FUNCNAME[0]} > "$scriptLocal"/FAIL_bootOnce
		return 1
	fi
	return 0
}
_create_ubDistBuild-bootOnce-fsck_sequence() {
	_messagePlain_nominal 'fsck'
	
	_set_ubDistBuild
	
	! "$scriptAbsoluteLocation" _openLoop && _messagePlain_bad 'fail: _openLoop' && _messageFAIL
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	
	_messagePlain_probe sudo -n fsck -p "$imagedev""$ubVirtImageEFI"
	sudo -n fsck -p "$imagedev""$ubVirtImageEFI"
	sudo -n fsck -p "$imagedev""$ubVirtImageEFI"
	[[ "$?" != "0" ]] && _messageFAIL
	
	#_messagePlain_probe sudo -n e2fsck -p "$imagedev""$ubVirtImagePartition"
	#sudo -n e2fsck -p "$imagedev""$ubVirtImagePartition"
	#sudo -n e2fsck -p "$imagedev""$ubVirtImagePartition"
	_messagePlain_probe sudo -n fsck -p "$imagedev""$ubVirtImagePartition"
	sudo -n fsck -p "$imagedev""$ubVirtImagePartition"
	sudo -n fsck -p "$imagedev""$ubVirtImagePartition"
	[[ "$?" != "0" ]] && _messageFAIL
	
	! "$scriptAbsoluteLocation" _closeLoop && _messagePlain_bad 'fail: _closeLoop' && _messageFAIL
	return 0
}
# Causes gschem to compile a bunch of scheme files so there may not be as much delay when otherwise running gschem for the first time.
_create_ubDistBuild-bootOnce-geda_chroot() {
	local functionEntryDISPLAY
	functionEntryDISPLAY="$DISPLAY"

	#. "$HOME"/.ubcore/.ubcorerc
	[[ -e "$HOME"/.nix-profile/etc/profile.d/nix.sh ]] && . "$HOME"/.nix-profile/etc/profile.d/nix.sh
	
	local currentPID
	Xvfb :30 > /dev/null 2>&1 &
	currentPID="$!"
	sleep 1

	export DISPLAY=:30
	_timeout 180 gschem


	kill "$currentPID"
	sleep 3
	kill -KILL "$currentPID"
	pkill Xvfb


	local currentStopJobs
	currentStopJobs=$(jobs -p -r 2> /dev/null)
	_messagePlain_probe_var currentStopJobs
	[[ "$currentStopJobs" != "" ]] && kill "$currentStopJobs"
	
	#disown -h $currentPID
	disown -a -h -r
	disown -a -r

	export DISPLAY="$functionEntryDISPLAY"
	[[ "$functionEntryDISPLAY" == "" ]] && unset DISPLAY
	return 0
}
_create_ubDistBuild-bootOnce-geda_procedure() {
	sudo -n cp "$scriptAbsoluteLocation" "$globalVirtFS"/home/user/tmp_bootOnce-geda.sh
	_chroot chown user:user /home/user/tmp_bootOnce-geda.sh
	_chroot chmod 755 /home/user/tmp_bootOnce-geda.sh

	_chroot sudo -n -u user bash -c 'cd /home/user/ ; ./tmp_bootOnce-geda.sh _create_ubDistBuild-bootOnce-geda_chroot'
}
_create_ubDistBuild-bootOnce() {
	_messageNormal '##### init: _create_ubDistBuild-bootOnce'
	
	
	_messageNormal 'chroot'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	# WARNING: Do NOT use twice. Usually already effectively called by '_create_ubDistBuild-rotten_install' .
	#_create_ubDistBuild-rotten_install-bootOnce
	
	
	## ATTENTION: NOTICE: Resets any changes to crontab (ie. by rotten_install ).
	##echo | _chroot crontab '-'
	##echo | sudo -n -u user bash -c "crontab -"
	##echo '@reboot cd '/home/user'/ ; '/home/user'/rottenScript.sh _run' | sudo -n -u user bash -c "crontab -"
	
	##sudo -n mkdir -p "$globalVirtFS"/home/user/.config/autostart
	##_here_bootdisc_startup_xdg | sudo -n tee "$globalVirtFS"/home/user/.config/autostart/startup.desktop > /dev/null
	##_chroot chown -R user:user /home/user/.config
	##_chroot chmod 555 /home/user/.config/autostart/startup.desktop
	
	
	##sudo -n mkdir -p "$globalVirtFS"/home/user/___quick
	##echo 'sudo -n mount -t fuse.vmhgfs-fuse -o allow_other,uid=$(id -u "$USER"),gid=$(id -g "$USER") .host: "$HOME"/___quick' | sudo -n tee "$globalVirtFS"/home/user/___quick/mount.sh
	##_chroot chown -R user:user /home/user/___quick
	##_chroot chmod 755 /home/user/___quick/mount.sh
	
	##( _chroot crontab -l ; echo '@reboot /media/bootdisc/rootnix.sh > /var/log/rootnix.log 2>&1' ) | _chroot crontab '-'
	
	##( _chroot sudo -n -u user bash -c "crontab -l" ; echo '@reboot cd /home/'"$custom_user"'/.ubcore/ubiquitous_bash/lean.sh _unix_renice_execDaemon' ) | _chroot sudo -n -u user bash -c "crontab -"
	
	# ### NOTICE
	# /usr/lib/virtualbox/vboxdrv.sh
	#  KERN_VER=`uname -r`
	#  ! $MODPROBE vboxdrv > /dev/null 2>&1
	# /usr/share/virtualbox/src/vboxhost/build_in_tmp
	#  MAKE_JOBS


	sudo -n mv "$globalVirtFS"/usr/bin/uname "$globalVirtFS"/usr/bin/uname-orig
	sudo -n mv "$globalVirtFS"/bin/uname "$globalVirtFS"/bin/uname-orig

	sudo -n rm -f "$globalVirtFS"/usr/bin/uname
	sudo -n rm -f "$globalVirtFS"/bin/uname

	cat << 'CZXWXcRMTo8EmM8i4d' | sudo -n tee "$globalVirtFS"/usr/bin/uname > /dev/null
#!/bin/bash

local currentTopKernel 2>/dev/null
currentTopKernel=$(sudo -n cat /boot/grub/grub.cfg 2>/dev/null | awk -F\' '/menuentry / {print $2}' | grep -v "Advanced options" | grep 'Linux [0-9]' | sed 's/ (.*//' | awk '{print $NF}' | head -n1)

if [[ "$1" == "-r" ]] && [[ "$currentTopKernel" != "" ]]
then
	echo "$currentTopKernel"
	exit "$?"
fi

if [[ -e /usr/bin/uname-orig ]]
then
	/usr/bin/uname-orig "$@"
	exit "$?"
fi

if [[ -e /bin/uname-orig ]]
then
	/bin/uname-orig "$@"
	exit "$?"
fi

exit 1
CZXWXcRMTo8EmM8i4d

	sudo -n chown root:root "$globalVirtFS"/usr/bin/uname
	sudo -n chmod 755 "$globalVirtFS"/usr/bin/uname


	_messagePlain_probe _chroot /sbin/rcvboxdrv setup
	_chroot /sbin/rcvboxdrv setup

	_messagePlain_probe /sbin/rcvboxdrv setup all
	_chroot /sbin/rcvboxdrv setup all

	_messagePlain_probe /sbin/rcvboxdrv setup $(_chroot cat /boot/grub/grub.cfg 2>/dev/null | awk -F\' '/menuentry / {print $2}' | grep -v "Advanced options" | grep 'Linux [0-9]' | sed 's/ (.*//' | awk '{print $NF}' | head -n1)
	_chroot /sbin/rcvboxdrv setup $(_chroot cat /boot/grub/grub.cfg 2>/dev/null | awk -F\' '/menuentry / {print $2}' | grep -v "Advanced options" | grep 'Linux [0-9]' | sed 's/ (.*//' | awk '{print $NF}' | head -n1)


	_messagePlain_probe _chroot /sbin/vboxconfig
	_chroot /sbin/vboxconfig

	_messagePlain_probe _chroot /sbin/vboxconfig
	_chroot /sbin/vboxconfig --nostart
	
	_messagePlain_probe '__________________________________________________'
	_messagePlain_probe 'probe: kernel modules: '"sudo -n find / -xdev -name 'vboxdrv.ko'"
	sudo -n find "$globalVirtFS" -xdev -name 'vboxdrv.ko'
	_messagePlain_probe '__________________________________________________'

	sudo -n rm -f "$globalVirtFS"/usr/bin/uname
	sudo -n rm -f "$globalVirtFS"/bin/uname

	sudo -n mv -f "$globalVirtFS"/usr/bin/uname-orig "$globalVirtFS"/usr/bin/uname
	sudo -n mv -f "$globalVirtFS"/bin/uname-orig "$globalVirtFS"/bin/uname





	_create_ubDistBuild-bootOnce-geda_procedure




	_chroot sudo -n -u user bash -c 'cd /home/user/ ; kded5 --check'



	
	_chroot systemctl set-default graphical.target
	


	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	


	
	
	_messageNormal 'qemu'
	
	local currentIteration
	local currentIterationTotal
	currentIterationTotal=2
	# May need 3 iterations, especially if "package_kde" is from a previous version of Debian Stable (ie. if KDE upgrade must happen automatically).
	#currentIterationTotal=3
	[[ "$skimfast" == "true" ]] && currentIterationTotal=1

	#for currentIteration in $(seq 1 3)
	for currentIteration in $(seq 1 "$currentIterationTotal")
	do
		_messagePlain_probe_var currentIteration
		
		if ! "$scriptAbsoluteLocation" _create_ubDistBuild-bootOnce-qemu_sequence "$@"
		then
			_messageFAIL
		fi
		
		if ! "$scriptAbsoluteLocation" _create_ubDistBuild-bootOnce-fsck_sequence "$@"
		then
			_messageFAIL
		fi
	done
	
	
	_messageNormal '##### _create_ubDistBuild-bootOnce: chroot'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	# https://stackoverflow.com/questions/8579330/appending-to-crontab-with-a-shell-script-on-ubuntu
	
	( _chroot crontab -l ; echo '@reboot /root/_get_nvidia.sh _autoinstall > /var/log/_get_nvidia.log 2>&1' ) | _chroot crontab '-'
	_nouveau_disable_procedure
	
	
	sudo -n mkdir -p "$globalVirtFS"/root/core_rG/flipKey/_local
	sudo -n cp -f "$scriptLib"/setup/rootGrab/_rootGrab.sh "$globalVirtFS"/root/_rootGrab.sh
	sudo -n chmod 700 "$globalVirtFS"/root/_rootGrab.sh
	sudo -n cp -f "$scriptLib"/flipKey/flipKey "$globalVirtFS"/root/core_rG/flipKey/flipKey
	sudo -n chmod 700 "$globalVirtFS"/root/core_rG/flipKey/flipKey
	
	! _chroot /root/_rootGrab.sh _hook && _messageFAIL
	
	
	
	_chroot dpkg -l | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
	
	
	_chroot rmdir /var/lib/docker/runtimes
	
	echo | sudo -n tee "$globalVirtFS"/regenerate > /dev/null
	
	echo | sudo -n tee "$globalVirtFS"/regenerate_rootGrab > /dev/null
	
	
	# WARNING: Important. May drastically reduce image size, especially if large temporary files (ie. apt cache) have been used. *Very* compressible zeros.
	# https://fedoraproject.org/wiki/Changes/BtrfsTransparentCompression
	#  'btrfs property' 'Unsetting it is...tricky' 'doesn't unset compression, it prevents the compress mount option from working'
	_chroot mount -o remount,compress=none /
	_chroot rm -f /fill > /dev/null 2>&1
	_chroot dd if=/dev/zero of=/fill bs=1M count=1 oflag=append conv=notrunc status=progress
	#_chroot btrfs property set /fill compression ""
	_chroot dd if=/dev/zero of=/fill bs=1M oflag=append conv=notrunc status=progress
	_chroot rm -f /fill
	
	if [[ "$skimfast" == "true" ]]
	then
		_chroot mount -o remount,compress=zstd:2 /
	else
		_chroot mount -o remount,compress=zstd:9 /
	fi
	
	# Run only once. If used two or more times, apparently may decrease available storage by ~1GB .
	# Apparently, if defrag is run once with compression, rootfs usage may reduce from ~6.6GB to ~5.9GB . However, running again may expand usage back to ~6.6GB.
	# https://github.com/kdave/btrfs-progs/issues/184
	_chroot btrfs filesystem defrag -r -czstd /
	
	_messagePlain_nominal 'chroot: report: df'
	_chroot df -h /
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	
	
	return 0
}


_create_ubDistBuild() {
	if ! _create_ubDistBuild-create "$@"
	then
		_messageFAIL
	fi
	if ! _create_ubDistBuild-rotten_install "$@"
	then
		_messageFAIL
	fi
	if ! _create_ubDistBuild-bootOnce "$@"
	then
		_messageFAIL
	fi
	
	if ! _create_ubDistBuild-rotten_install-core "$@"
	then
		_messageFAIL
	fi
	
	if ! _create_ubDistBuild-install-ubDistBuild "$@"
	then
		_messageFAIL
	fi
	
	return 0
}




_custom_ubDistBuild() {
	# TODO: _setup for all infrastructure/installations
	
	# TODO: _test/_setup all programs from 'core/infrastructure' and such
		# WARNING: Maybe not. May be better to run as a 'rotten_install' function (possibly normally already called by '_install_and_run') instead.
	
	true
}



_package_ubDistBuild_image() {
	cd "$scriptLocal"
	
	if ! [[ -e "$scriptLocal"/ops.sh ]]
	then
		#echo >> "$scriptLocal"/ops.sh
		echo >> "$scriptLocal"/ops.sh
		echo 'export vboxOStype=Debian_64' >> "$scriptLocal"/ops.sh
		echo >> "$scriptLocal"/ops.sh
	fi
	
	rm -f "$scriptLocal"/package_image.tar.flx > /dev/null 2>&1
	
	# https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/
	# https://stephane.lesimple.fr/blog/lzop-vs-compress-vs-gzip-vs-bzip2-vs-lzma-vs-lzma2xz-benchmark-reloaded/
	#if [[ "$skimfast" != "true" ]]
	#then
		#env XZ_OPT="-1 -T0" tar -cJvf "$scriptLocal"/package_image.tar.flx ./vm.img ./ops.sh
	#else
		#env XZ_OPT="-0 -T0" tar -cJvf "$scriptLocal"/package_image.tar.flx ./vm.img ./ops.sh
	#fi

	# https://unix.stackexchange.com/questions/724795/lz4-what-is-the-max-ultra-fast-compression-level
	# https://github.com/lz4/lz4/blob/e3974e5a1476190afdd8b44e67106cfb7097a1d5/doc/lz4_manual.html#L144
	# each successive value providing roughly +~3% to speed
	#--fast=65537
	tar -cf - ./vm.img ./ops.sh | lz4 -z --fast=1 - "$scriptLocal"/package_image.tar.flx
	
	! [[ -e "$scriptLocal"/package_image.tar.flx ]] && _messageFAIL
	
	return 0
}

# CAUTION: WSL2 can be used to host this conversion, but Cygwin/MSW cannot.
# For WSL2.
_package_ubDistBuild_rootfs() {
	cd "$scriptLocal"
	
	_set_ubDistBuild
	
	rm -f "$scriptLocal"/package_rootfs.tar.flx > /dev/null 2>&1

	
	cd "$scriptLocal"
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

	# If systemctl is usable when 'booting' an instance of 'rootfs', this is usually WSL2, and some services (eg. ollama) could conflict with the host.
	# Else, if systemctl is not usable, this is usually Docker containers, etc, and such services can be started as needed (ie. _service_ollama_augment ).

	_chroot sudo -n systemctl disable ollama
	_chroot systemctl disable ollama.service
	_chroot sudo -n systemctl stop ollama
	_chroot systemctl stop ollama.service

	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

	
	cd "$scriptLocal"
	! "$scriptAbsoluteLocation" _openImage && _messagePlain_bad 'fail: _openImage' && _messageFAIL
	#_mountChRoot_image_x64_prog
	_mountChRoot_image_x64_prog




	cd "$globalVirtFS"
	_messagePlain_probe_cmd ls .
	_messagePlain_probe_cmd ls ./boot
	
	#--exclude './usr/bin/ksplashqml'
	sudo -n tar -cf - --exclude='./etc/fstab' --exclude='./etc/resolv.conf' --exclude='./etc/hosts' --exclude='./root/_rootGrab.sh' . | lz4 -z --fast=1 - "$scriptLocal"/package_rootfs.tar.flx




	cd "$scriptLocal"
	#_umountChRoot_image
	[[ -d "$globalVirtFS"/boot/efi ]] && mountpoint "$globalVirtFS"/boot/efi >/dev/null 2>&1 && _wait_umount "$globalVirtFS"/boot/efi >/dev/null 2>&1
	[[ -d "$globalVirtFS"/boot ]] && mountpoint "$globalVirtFS"/boot >/dev/null 2>&1 && _wait_umount "$globalVirtFS"/boot >/dev/null 2>&1
	! "$scriptAbsoluteLocation" _closeImage && _messagePlain_bad 'fail: _closeImage' && _messageFAIL


	#! [[ -e "$scriptLocal"/package_image.tar.flx ]] && _messageFAIL
	
	return 0
}
_convert-rootfs() {
	_package_ubDistBuild_rootfs "$@"
}


_ubDistBuild_join() {
	local functionEntryPWD
	functionEntryPWD="$PWD"
	_messageNormal 'init: _ubDistBuild_join'

	cd "$scriptLocal"

	rm -f "$scriptLocal"/_hash-ubdist-join.txt > /dev/null 2>&1

	local currentIteration

	if [[ -e "$scriptLocal"/package_image.tar.flx.part00 ]]
	then
		_messagePlain_nominal '_ubDistBuild_join: package_image.tar.flx'
		rm -f "$scriptLocal"/package_image.tar.flx > /dev/null 2>&1
		currentIteration=""
		for currentIteration in $(seq -w 0 50 | sort -r)
		do
			_messagePlain_probe_var currentIteration
			[[ -e "$scriptLocal"/package_image.tar.flx.part"$currentIteration" ]] && dd if="$scriptLocal"/package_image.tar.flx.part"$currentIteration" bs=1M status=progress >> "$scriptLocal"/package_image.tar.flx
		done
		_messagePlain_probe 'extract: package_image.tar.flx'
		dd if="$scriptLocal"/package_image.tar.flx bs=1M status=progress | _get_extract_ubDistBuild
		rm -f "$scriptLocal"/package_image.tar.flx.part* > /dev/null 2>&1
		rm -f "$scriptLocal"/package_image.tar.flx* > /dev/null 2>&1
		
		_messagePlain_probe 'hash: vm.img'
		#_hash_img
		_hash_file ubdist-join vm.img "$scriptLocal"/vm.img dd bs=1M status=progress
		rm -f "$scriptLocal"/_hash-ubdist-join.txt > /dev/null 2>&1
	fi

	if [[ -e "$scriptLocal"/vm-live.iso.part00 ]]
	then
		_messagePlain_nominal '_ubDistBuild_join: vm-live.iso'
		rm -f "$scriptLocal"/vm-live.iso > /dev/null 2>&1
		currentIteration=""
		for currentIteration in $(seq -w 0 50 | sort -r)
		do
			_messagePlain_probe_var currentIteration
			[[ -e "$scriptLocal"/vm-live.iso.part"$currentIteration" ]] && dd if="$scriptLocal"/vm-live.iso.part"$currentIteration" bs=1M status=progress >> "$scriptLocal"/vm-live.iso
		done
		rm -f "$scriptLocal"/vm-live.iso.part* > /dev/null 2>&1

		_messagePlain_probe 'hash: vm-live.iso'
		#_hash_live
		_hash_file ubdist-join vm-live.iso "$scriptLocal"/vm-live.iso dd bs=1M status=progress
		rm -f "$scriptLocal"/_hash-ubdist-join.txt > /dev/null 2>&1
	fi

	if [[ -e "$scriptLocal"/package_rootfs.tar.flx.part00 ]]
	then
		_messagePlain_nominal '_ubDistBuild_join: package_rootfs.tar.flx'
		rm -f "$scriptLocal"/package_rootfs.tar.flx > /dev/null 2>&1
		currentIteration=""
		for currentIteration in $(seq -w 0 50 | sort -r)
		do
			_messagePlain_probe_var currentIteration
			[[ -e "$scriptLocal"/package_rootfs.tar.flx.part"$currentIteration" ]] && dd if="$scriptLocal"/package_rootfs.tar.flx.part"$currentIteration" bs=1M status=progress >> "$scriptLocal"/package_rootfs.tar.flx
		done
		_messagePlain_probe 'extract: package_rootfs.tar.flx'
		dd if="$scriptLocal"/package_rootfs.tar.flx bs=1M status=progress | lz4 -d -c > "$scriptLocal"/package_rootfs.tar
		rm -f "$scriptLocal"/package_rootfs.tar.flx.part* > /dev/null 2>&1
		rm -f "$scriptLocal"/package_rootfs.tar.flx > /dev/null 2>&1

		_messagePlain_probe 'hash: package_rootfs.tar'
		#_hash_rootfs
		#_hash_file ubdist package_rootfs.tar "$scriptLocal"/package_rootfs.tar cat
		_hash_file ubdist-join package_rootfs.tar "$scriptLocal"/package_rootfs.tar dd bs=1M status=progress
		rm -f "$scriptLocal"/_hash-ubdist-join.txt > /dev/null 2>&1
	fi

	_messagePlain_request 'Done. Press ENTER to continue.'
	read
}
_join() {
	_ubDistBuild_join "$@"
}


# NOTICE: Most well tested and expected most reliable .
_ubDistBuild_split-tail_procedure() {
	# https://unix.stackexchange.com/questions/628747/split-large-file-into-chunks-and-delete-original
	local currentIteration
	for currentIteration in $(seq -w 0 50)
	do
		[[ -s ./"$1" ]] && [[ -e ./"$1" ]] && tail -c 1997537280 "$1" > "$1".part"$currentIteration" && truncate -s -1997537280 "$1"
	done
	return 0
}

# Expected fastest.
# ATTRIBUTION-AI: ChatGPT o1 2025-01-14 
_ubDistBuild_split-reflink_procedure() {
    local inputFile=""$1""
    local chunkSize=1997537280  # ~1.86 GiB
    local currentIteration=0

    # Sanity check
    [[ ! -e "$inputFile" ]] && return 1

    while [[ -s "$inputFile" ]]; do
        local fileSize
        fileSize="$(stat -c%s "$inputFile")"

        # Zero-pad the iteration index (2 digits)
        local iterationStr
        iterationStr="$(printf "%02d" "$currentIteration")"

        # If the file is smaller than (or equal to) chunkSize, then this is our final chunk
        if [[ $fileSize -le $chunkSize ]]; then
            cp --reflink=always "$inputFile" "${inputFile}.part${iterationStr}"
            rm -f "$inputFile"
            break
        else
            # 1. Make a reflink copy of the whole file
            cp --reflink=always "$inputFile" "${inputFile}.part${iterationStr}"

            # 2. Punch out everything except the last $chunkSize bytes in the new part file
            fallocate --punch-hole --offset 0 --length $((fileSize - chunkSize)) \
                      "${inputFile}.part${iterationStr}"

            # 3. Truncate the *original* file by the chunk size from the end
            truncate -s -"$chunkSize" "$inputFile"
        fi

        ((currentIteration++))
    done
	return 0
}

# Expected to avoid repeatedly reading most of file through 'tail', however, not as fast as near-instant sector mapping.
# ATTRIBUTION-AI: ChatGPT o1 2025-01-14
_ubDistBuild_split-dd_procedure() {
local functionEntryPWD="$PWD"
    cd "$scriptLocal" || exit 1

    # 5 MiB in bytes
    local blockSize=5242880

    # Each file chunk will be 381 blocks of 5 MiB each
    local chunkBlocks=381

    # Total chunk size in bytes (5 MiB * 381 = 1,997,537,280)
    local chunkSize=$(( blockSize * chunkBlocks ))

    local currentIteration

    for currentIteration in $(seq -w 0 50); do
        # Make sure the file still exists and is non-empty.
        if [[ -s "$1" && -e "$1" ]]; then
            # Get the current file size.
            local fileSize
            fileSize=$(stat -c %s "$1")

            # If the file is already smaller than the chunk size, just move all of it.
            if (( fileSize <= chunkSize )); then
                mv "$1" "$1.part${currentIteration}"
            else
                # Number of bytes that remain after removing one chunk
                local skipBytes=$(( fileSize - chunkSize ))

                # Number of 5 MiB blocks to skip
                local skipBlocks=$(( skipBytes / blockSize ))

                # Copy the last chunk (381 blocks of 5 MiB) into a new file.
                dd if="$1" \
                   of="$1.part${currentIteration}" \
                   bs="${blockSize}" \
                   skip="${skipBlocks}" \
                   count="${chunkBlocks}" \
                   status=none

                # Truncate the original file, removing the last chunk.
                truncate -s "${skipBytes}" "$1"
            fi
        fi
    done

    rm -f "$1"
    cd "$functionEntryPWD" || exit 1
	return 0
}

_ubDistBuild_split_procedure() {
	_ubDistBuild_split-tail_procedure "$@"
}


_ubDistBuild_split() {
	local functionEntryPWD
	functionEntryPWD="$PWD"


	cd "$scriptLocal"
	##split -b 1997537280 -d package_image.tar.flx package_image.tar.flx.part

	## https://unix.stackexchange.com/questions/628747/split-large-file-into-chunks-and-delete-original
	#local currentIteration
	#for currentIteration in $(seq -w 0 50)
	#do
		#[[ -s ./package_image.tar.flx ]] && [[ -e ./package_image.tar.flx ]] && tail -c 1997537280 package_image.tar.flx > package_image.tar.flx.part"$currentIteration" && truncate -s -1997537280 package_image.tar.flx
	#done

	_ubDistBuild_split_procedure ./package_image.tar.flx

	rm -f ./package_image.tar.flx

	cd "$functionEntryPWD"
}
_ubDistBuild_split_beforeBoot() {
	mv -f "$scriptLocal"/package_image.tar.flx "$scriptLocal"/package_image_beforeBoot.tar.flx
	
	local functionEntryPWD
	functionEntryPWD="$PWD"


	cd "$scriptLocal"
	##split -b 1997537280 -d package_image_beforeBoot.tar.flx package_image_beforeBoot.tar.flx.part

	## https://unix.stackexchange.com/questions/628747/split-large-file-into-chunks-and-delete-original
	#local currentIteration
	#for currentIteration in $(seq -w 0 50)
	#do
		#[[ -s ./package_image_beforeBoot.tar.flx ]] && [[ -e ./package_image_beforeBoot.tar.flx ]] && tail -c 1997537280 package_image_beforeBoot.tar.flx > package_image_beforeBoot.tar.flx.part"$currentIteration" && truncate -s -1997537280 package_image_beforeBoot.tar.flx
	#done

	_ubDistBuild_split_procedure ./package_image_beforeBoot.tar.flx

	rm -f ./package_image_beforeBoot.tar.flx

	cd "$functionEntryPWD"
}
_ubDistBuild_split_before_noBoot() {
	mv -f "$scriptLocal"/package_image.tar.flx "$scriptLocal"/package_image_before_noBoot.tar.flx
	
	local functionEntryPWD
	functionEntryPWD="$PWD"


	cd "$scriptLocal"
	##split -b 1997537280 -d package_image_before_noBoot.tar.flx package_image_before_noBoot.tar.flx.part

	## https://unix.stackexchange.com/questions/628747/split-large-file-into-chunks-and-delete-original
	#local currentIteration
	#for currentIteration in $(seq -w 0 50)
	#do
		#[[ -s ./package_image_before_noBoot.tar.flx ]] && [[ -e ./package_image_before_noBoot.tar.flx ]] && tail -c 1997537280 package_image_before_noBoot.tar.flx > package_image_before_noBoot.tar.flx.part"$currentIteration" && truncate -s -1997537280 package_image_before_noBoot.tar.flx
	#done

	_ubDistBuild_split_procedure ./package_image_before_noBoot.tar.flx

	rm -f ./package_image_before_noBoot.tar.flx

	cd "$functionEntryPWD"
}

_ubDistBuild_split-live() {
	local functionEntryPWD
	functionEntryPWD="$PWD"


	cd "$scriptLocal"
	##split -b 1997537280 -d vm-live.iso vm-live.iso.part


	## https://unix.stackexchange.com/questions/628747/split-large-file-into-chunks-and-delete-original
	#local currentIteration
	#for currentIteration in $(seq -w 0 50)
	#do
		#[[ -s ./vm-live.iso ]] && [[ -e ./vm-live.iso ]] && tail -c 1997537280 vm-live.iso > vm-live.iso.part"$currentIteration" && truncate -s -1997537280 vm-live.iso
	#done

	_ubDistBuild_split_procedure ./vm-live.iso

	rm -f ./vm-live.iso

	cd "$functionEntryPWD"
}

_ubDistBuild_split-rootfs() {
	local functionEntryPWD
	functionEntryPWD="$PWD"


	cd "$scriptLocal"

	## https://unix.stackexchange.com/questions/628747/split-large-file-into-chunks-and-delete-original
	#local currentIteration
	#for currentIteration in $(seq -w 0 50)
	#do
		#[[ -s ./package_rootfs.tar.flx ]] && [[ -e ./package_rootfs.tar.flx ]] && tail -c 1997537280 package_rootfs.tar.flx > package_rootfs.tar.flx.part"$currentIteration" && truncate -s -1997537280 package_rootfs.tar.flx
	#done

	_ubDistBuild_split_procedure ./package_rootfs.tar.flx

	rm -f ./package_rootfs.tar.flx

	cd "$functionEntryPWD"
}



# WARNING: OBSOLETE .
# Call '_nouveau_enable', or similar, to create a 'vm-nouveau.img', or similar file.
_upload_ubDistBuild_image() {
	_package_ubDistBuild_image "$@"
	cd "$scriptLocal"
	
	! [[ -e "$scriptLocal"/package_image.tar.flx ]] && _messageFAIL
	
	_rclone_limited --progress copy "$scriptLocal"/package_image.tar.flx distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messageFAIL
	
	if ls -A -1 "$scriptLocal"/*.log
	then
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_create_ubDistBuild-create.log distLLC_build_ubDistBuild:
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_create_ubDistBuild-rotten_install.log distLLC_build_ubDistBuild:
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_create_ubDistBuild-bootOnce.log distLLC_build_ubDistBuild:
		_rclone_limited --progress --ignore-size copy "$scriptLocal"/_upload_ubDistBuild_image.log distLLC_build_ubDistBuild:
	fi
	return 0
}

# WARNING: OBSOLETE .
_upload_ubDistBuild_custom() {
	cd "$scriptLocal"
	
	#package_custom.tar.xz
	# TODO
	
	true
}


_custom_report() {
    local functionEntryPWD
    functionEntryPWD="$PWD"
    
    echo
    echo 'init: _custom_report'
    echo

	! _messagePlain_probe_cmd _openChRoot && _messagePlain_bad 'fail: openChroot' && _messageFAIL

	_messageNormal 'init: _custom_report: customReport, cronUserReport, cronRootReport'

    _chroot find /etc /var/lib/docker | grep -v 'docker/fuse-overlayfs' | grep -v 'docker/image/fuse-overlayfs' | sudo -n tee "$globalVirtFS"/customReport > /dev/null
    sudo -n cp -f "$globalVirtFS"/customReport "$scriptLocal"/customReport
    sudo -n chown "$USER":"$USER" "$scriptLocal"/customReport

	_chroot sudo -n -u user bash -c "crontab -l" | sudo -n tee "$globalVirtFS"/cronUserReport > /dev/null
    sudo -n cp -f "$globalVirtFS"/cronUserReport "$scriptLocal"/cronUserReport
	_chroot sudo -n -u root bash -c "crontab -l" | sudo -n tee "$globalVirtFS"/cronRootReport > /dev/null
	sudo -n cp -f "$globalVirtFS"/cronRootReport "$scriptLocal"/cronRootReport

    _messagePlain_nominal 'PASS'
    _messagePlain_good 'good: success: _custom_report: customReport, cronUserReport, cronRootReport'
	
	! _messagePlain_probe_cmd _closeChRoot && _messagePlain_bad 'fail: closeChroot' && _messageFAIL

    cd "$functionEntryPWD"
    echo
    echo '          PASS'
    echo '          good: success: _custom_report'
    echo
}


# WARNING: OBSOLETE .
_get_vmImg_ubDistBuild-tempFile() {
	mkdir -p "$scriptLocal"
	cd "$scriptLocal"
	
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part00"
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part01" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part02" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part03" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part04" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part05" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part06" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part07" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part08" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part09" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part10" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part11" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part12" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part13" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part14" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part15" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part16" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part17" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part18" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part19" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part20" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part21" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part22" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part23" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part24" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part25" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part26" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part27" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part28" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part29" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part30" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part31" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part32" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part33" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part34" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part35" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part36" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part37" > /dev/null
	_wget_githubRelease_internal "soaringDistributions/ubDistBuild" "package_image.tar.flx.part38" > /dev/null

	cat "package_image.tar.flx.part"* > "package_image.tar.flx"
	rm -f "package_image.tar.flx.part"*

	! [[ -e "$scriptLocal"/package_image.tar.flx ]] && _messageFAIL

	tar -xvf "$scriptLocal"/package_image.tar.flx
}



_croc_ubDistBuild_image_out_message() {
	sleep 3
	while pgrep '^croc$' || ps -p "$currentPID"
	#while true
	do
		[[ -e "$scriptLocal"/croc.log ]] && tail "$scriptLocal"/croc.log
		sleep 3
	done
}

_croc_ubDistBuild_image_out() {
	_mustHaveCroc
	cd "$scriptLocal"
	
	! [[ -e "$scriptLocal"/package_image.tar.flx ]] && _messageFAIL
	
	
	local currentPID
	
	"$scriptAbsoluteLocation" _croc_ubDistBuild_image_out_message &
	
	currentPID="$!"
	
	
	croc send "$scriptLocal"/package_image.tar.flx 2>&1 | tee "$scriptLocal"/croc.log
	
	
	
	
	
	kill "$currentPID"
	sleep 3
	kill -KILL "$currentPID"
	
	return 0
}

_croc_ubDistBuild_image() {
	_mustHaveCroc
	
	_package_ubDistBuild_image "$@"
	
	_croc_ubDistBuild_image_out "$@"
}



# ATTENTION: Override with 'ops.sh' or similar.
_zSpecial_qemu_memory() {
	# Must have at least 4096MB for 'livecd' , unless even larger memory allocation has been configured .
	# Must have >=8704MB for MSW10 or MSW11 . GNU/Linux may eventually follow with similar expectations.
	# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
	#  '7 GB of RAM memory'
	#  '14 GB of SSD disk space'
	#qemuUserArgs+=(-m "8704")
	#qemuUserArgs+=(-m "3072")
	qemuUserArgs+=(-m "1664")
}

_zSpecial_report_procedure() {
	if [[ ! -e "$globalVirtFS"/dpkg ]]
	then
		#_chroot dpkg -l | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
		_chroot dpkg --get-selections | cut -f1 | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
		sudo -n cp -f "$globalVirtFS"/dpkg "$scriptLocal"/dpkg
		sudo -n chown "$USER":"$USER" "$scriptLocal"/dpkg
	fi
	
	#if [[ ! -e "$globalVirtFS"/binReport ]]
	#then
		_chroot find /bin/ /usr/bin/ /sbin/ /usr/sbin/ | sudo -n tee "$globalVirtFS"/binReport > /dev/null
		_chroot find /home/user/.nix-profile/bin | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null 2>&1
		_chroot find /home/user/.gcloud/google-cloud-sdk/bin | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null
		_chroot find /home/user/.ebcli-virtual-env/executables | sudo -n tee -a "$globalVirtFS"/binReport > /dev/null 2>&1
		sudo -n cp -f "$globalVirtFS"/binReport "$scriptLocal"/binReport
		sudo -n chown "$USER":"$USER" "$scriptLocal"/binReport
	#fi
	
	#if [[ ! -e "$globalVirtFS"/coreReport ]]
	#then
		_chroot find /home/user/core/installations /home/user/core/infrastructure /home/user/core/variant /home/user/core/info -not \( -path \*.git\* -prune \) | grep -v '_local/h' | sudo -n tee "$globalVirtFS"/coreReport > /dev/null
		sudo -n cp -f "$globalVirtFS"/coreReport "$scriptLocal"/coreReport
		sudo -n chown "$USER":"$USER" "$scriptLocal"/coreReport
	#fi

	if [[ -e "$globalVirtFS"/lsmodReport ]]
	then
		sudo -n cp -f "$globalVirtFS"/lsmodReport "$scriptLocal"/lsmodReport
		sudo -n chown "$USER":"$USER" "$scriptLocal"/lsmodReport
	fi
	if [[ -e "$globalVirtFS"/cfgFW.log ]]
	then
		sudo -n cp -f "$globalVirtFS"/cfgFW.log "$scriptLocal"/cfgFW.log
		sudo -n chown "$USER":"$USER" "$scriptLocal"/cfgFW.log
	fi

	#_chroot cat /boot/grub/grub.cfg | sudo -n tee "$globalVirtFS"/grub.cfg > /dev/null
	sudo -n cp -f "$globalVirtFS"/boot/grub/grub.cfg "$scriptLocal"/grub.cfg
	sudo -n chown "$USER":"$USER" "$scriptLocal"/grub.cfg
	
	sudo -n cp -f "$globalVirtFS"/boot/grub/grubenv "$scriptLocal"/grubenv
	sudo -n chown "$USER":"$USER" "$scriptLocal"/grubenv
}
_zSpecial_report() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	_zSpecial_report_procedure "$@"
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# WARNING: No production use. Standardizes extra commands in customization scripts to force recreation and copying of otherwise existing files.
_zSpecial_report-FORCE() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	_chroot dpkg --get-selections | cut -f1 | sudo -n tee "$globalVirtFS"/dpkg > /dev/null
	sudo -n cp -f "$globalVirtFS"/dpkg "$scriptLocal"/dpkg
	sudo -n chown "$USER":"$USER" "$scriptLocal"/dpkg
	
	_zSpecial_report_procedure "$@"
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# ATTENTION: Override with 'ops.sh' or similar.
_zSpecial_qemu_chroot() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	_zSpecial_report_procedure "$@"


	_chroot rmdir /var/lib/docker/runtimes
	


	
	echo | sudo -n tee "$globalVirtFS"/regenerate > /dev/null
	
	echo | sudo -n tee "$globalVirtFS"/regenerate_rootGrab > /dev/null
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}


_zSpecial_qemu_sequence_prog() {
	# A rather complicated issue with VirtualBox vboxdrv kernel module.
	# Module vboxdrv build may be attempted for running kernel of ChRoot host.
	# Sevice vboxdrv will attempt to build, may timeout in ~5 minutes (due to slow qemu without kvm), fail, every boot.
	# Since this should not take much time or power for modern CPUs, and should only affect the ability run VirtualBox guests on first boot (ie. does not affect guest additions), this is expected at most a minor inconvenience.
	
	# sudo -n systemctl status vboxdrv
	echo '#!/usr/bin/env bash' >> "$hostToGuestFiles"/cmd.sh
	echo 'date +"%Y-%m-%d" | sudo -n tee /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo 'sudo -n update-grub' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: update-grub" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo '_detect_process_compile() {
	pgrep cc1 && return 0
	pgrep apt && return 0
	pgrep dpkg && return 0
	top -b -n1 | tail -n+8 | head -n1 | grep packagekit && return 0
	sudo -n systemctl status vboxdrv | grep loading && return 0
	return 1
} ' >> "$hostToGuestFiles"/cmd.sh
	
	# Commenting this may reduce first iteration 'currentIterationWait' by ~120s , possibly improving opportunity to successfully compile through slow qemu without kvm.
	# If uncommented, any indefinite delay in '_detect_process_compile' may cause failure.
	#echo 'while _detect_process_compile && sleep 27 && _detect_process_compile && sleep 27 && _detect_process_compile ; do sleep 27 ; done' >> "$hostToGuestFiles"/cmd.sh
	
	echo 'echo done: "_detect_process_compile (if uncommented)" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo 'sleep 15' >> "$hostToGuestFiles"/cmd.sh
	echo '! sudo -n lsmod | grep -i vboxdrv && sudo -n /sbin/vboxconfig' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: vboxconfig" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo 'sleep 75' >> "$hostToGuestFiles"/cmd.sh
	echo 'sudo -n lsmod | cut -f1 -d\  | sudo -n tee /lsmodReport' >> "$hostToGuestFiles"/cmd.sh
	echo 'cat /lsmodReport | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: lsmodReport" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo '[[ ! -e /kded5-done ]] && kded5 --check' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: kded5 --check (1 of 2)" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo '[[ ! -e /kded5-done ]] && sleep 90' >> "$hostToGuestFiles"/cmd.sh

	echo '[[ ! -e /FW-done ]] && cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW-desktop | sudo -n tee /cfgFW.log ; cd' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: cfgFW-desktop (1 of 2)" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo '[[ ! -e /FW-done ]] && cd /home/user/.ubcore/ubiquitous_bash ; ./ubiquitous_bash.sh _cfgFW-desktop | sudo -n tee /cfgFW.log ; cd' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: cfgFW-desktop (2 of 2)" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh

	echo '[[ ! -e /kded5-done ]] && kded5 --check' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: kded5 --check (2 of 2)" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo '( [[ ! -e /kded5-done ]] || [[ ! -e /FW-done ]] ) && sleep 420' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo | sudo -n tee /kded5-done' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo | sudo -n tee /FW-done' >> "$hostToGuestFiles"/cmd.sh
	echo 'echo "done: sleep , /kded5-done , /FW-done" | sudo -n tee -a /var/log/bootOnce.log' >> "$hostToGuestFiles"/cmd.sh
	echo 'sudo -n poweroff' >> "$hostToGuestFiles"/cmd.sh
}

# ATTENTION: Override with 'ops.sh' or similar.
_zSpecial_qemu_sequence() {
	_messagePlain_nominal 'init: _zSpecial_qemu'
	_start
	
	
	if [[ "$qemuHeadless" == "true" ]] || [[ "$qemuBootOnce" == "true" ]] || [[ "$qemu_custom" == "true" ]]
	then
		#_commandBootdisc
		
		! _prepareBootdisc && _messageFAIL
		
		cp "$scriptAbsoluteLocation" "$hostToGuestFiles"/
		"$scriptBin"/.ubrgbin.sh _ubrgbin_cpA "$scriptBin" "$hostToGuestFiles"/_bin
		
		
		_zSpecial_qemu_sequence_prog "$@"
		
		
		
		! _writeBootdisc && _messageFAIL
	fi
	
	
	
	[[ "$qemuHeadless" == "true" ]] && qemuArgs+=(-nographic)
	
	
	qemuArgs+=(-usb)
	
	# *nested* x64 hardware vt
	#qemuArgs+=(-cpu host)
	
	# CPU >2 may force more compatible SMP kernel, etc.
	#qemuArgs+=(-smp 2)
	local hostThreadCount
	hostThreadCount=$(cat /proc/cpuinfo | grep MHz | wc -l | tr -dc '0-9')
	qemuArgs+=(-smp "$hostThreadCount")
	
	
	
	# vm.img
	qemuUserArgs+=(-drive format=raw,file="$scriptLocal"/vm.img)
	
	# LiveCD
	#qemuUserArgs+=(-drive file="$ub_override_qemu_livecd",media=cdrom)
	
	# LiveUSB, hibernate/bup, etc
	#qemuUserArgs+=(-drive format=raw,file="$ub_override_qemu_livecd_more")
	
	# Installation CD image.
	#qemuUserArgs+=(-drive file="$scriptLocal"/netinst.iso,media=cdrom -boot c)
	
	
	
	
	[[ -e "$hostToGuestISO" ]] && qemuUserArgs+=(-drive file="$hostToGuestISO",media=cdrom)
	
	# Boot from whichever emulated disk connected ('-boot c' for emulated disc 'cdrom')
	qemuUserArgs+=(-boot d)
	
	
	
	
	# Must have at least 4096MB for 'livecd' , unless even larger memory allocation has been configured .
	# Must have >=8704MB for MSW10 or MSW11 . GNU/Linux may eventually follow with similar expectations.
	# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
	#  '7 GB of RAM memory'
	#  '14 GB of SSD disk space'
	#qemuUserArgs+=(-m "8704")
	#qemuUserArgs+=(-m "3072")
	#qemuUserArgs+=(-m "1664")
	_zSpecial_qemu_memory "$@"
	
	
	[[ "$qemuUserArgs_netRestrict" == "" ]] && qemuUserArgs_netRestrict="n"
	qemuUserArgs+=(-net nic,model=rtl8139 -net user,restrict="$qemuUserArgs_netRestrict")
	#,smb="$sharedHostProjectDir"
	
	
	qemuArgs+=(-device usb-tablet)
	
	
	#qemuArgs+=(-device ich9-intel-hda -device hda-duplex)
	
	# https://github.com/elisa-tech/meta-elisa/issues/23
	# https://wiki.qemu.org/ChangeLog/6.0
	# qemuArgs+=(-show-cursor)
	if [[ $(_qemu_system_x86_64 -version | grep version | sed 's/.*version\ //' | sed 's/\ .*//' | cut -f1 -d\. | tr -dc '0-9') -lt "6" ]]
	then
		qemuArgs+=(-show-cursor)
	fi
	
	
	#qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=off)
	##qemuArgs+=(-device virtio-vga,virgl=on -display gtk,gl=on)
	
	qemuArgs+=(-device qxl-vga)
	
	#qemuArgs+=(-vga cirrus)
	
	#qemuArgs+=(-vga std)
	
	
	
	# hardware vt
	if _testQEMU_hostArch_x64_hardwarevt
	then
		# Apparently, qemu kvm, can be unreliable if nested (eg. within VMWare Workstation VM).
		#[[ "$qemuHeadless" == "true" ]] || 
		_messagePlain_good 'found: kvm'
		if [[ "$qemuNoKVM" == "true" ]] || [[ "$qemuNoKVM" != "false" ]]
		then
			_messagePlain_good 'ignored: kvm'
		else
			qemuArgs+=(-machine accel=kvm)
		fi
	else
		_messagePlain_warn 'missing: kvm'
	fi
	
	
	# https://www.kraxel.org/repos/jenkins/edk2/
	# https://www.kraxel.org/repos/jenkins/edk2/edk2.git-ovmf-x64-0-20200515.1447.g317d84abe3.noarch.rpm
	if [[ -e "$HOME"/core/installations/ovmf/OVMF_CODE-pure-efi.fd ]] && [[ -e "$HOME"/core/installations/ovmf/OVMF_VARS-pure-efi.fd ]]
	then
		qemuArgs+=(-drive if=pflash,format=raw,readonly,file="$HOME"/core/installations/ovmf/OVMF_CODE-pure-efi.fd -drive if=pflash,format=raw,file="$HOME"/core/installations/ovmf/OVMF_VARS-pure-efi.fd)
	elif [[ -e /usr/share/OVMF/OVMF_CODE.fd ]]
	then
		qemuArgs+=(-bios /usr/share/OVMF/OVMF_CODE.fd)
	fi
	
	qemuArgs+=("${qemuSpecialArgs[@]}" "${qemuUserArgs[@]}")
	
	_messagePlain_probe _qemu_system_x86_64 "${qemuArgs[@]}"
	
	
	local currentExitStatus
	
	ls -l /dev/kvm

	if [[ "$qemuHeadless" != "true" ]]
	then
		_qemu_system_x86_64 "${qemuArgs[@]}"
		currentExitStatus="$?"
	else
		_qemu_system_x86_64 "${qemuArgs[@]}" | tr -dc 'a-zA-Z0-9\n'
		currentExitStatus=${PIPESTATUS[0]}
		#currentExitStatus="$?"
	fi
	
	
	_zSpecial_qemu_chroot "$@"
	
	
	if [[ -e "$instancedVirtDir" ]] && ! _safeRMR "$instancedVirtDir"
	then
		_messageFAIL
	fi
	
	_stop "$currentExitStatus"
}
_zSpecial_qemu() {
	if ! "$scriptAbsoluteLocation" _zSpecial_qemu_sequence "$@"
	then
		_stop 1
	fi
	return 0
}






_chroot_test_sequence() {
	_messageNormal '##### init: _chroot_test'
	_start

	echo
	
	local functionEntryPWD="$PWD"
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	

	#sudo -n mkdir -p "$globalVirtFS"/root/temp/test_"$ubiquitiousBashIDnano"
	#sudo -n cp -a "$scriptLib"/ubiquitous_bash "$globalVirtFS"/root/temp/test_"$ubiquitousBashIDnano"/
	
	#_chroot chown -R root:root /root/temp/test_"$ubiquitiousBashIDnano"/
	
	#if ! _chroot /root/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh _test
	#then
		#_messageFAIL
	#fi

	## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
	##_chroot rm -rf /root/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh _test
	#_chroot rm -rf /root/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/
	#_chroot rmdir /root/temp/test_"$ubiquitiousBashIDnano"/
	#_chroot rmdir /root/temp/
	


	# https://superuser.com/questions/1559417/how-to-discard-only-mode-changes-with-git
	cd "$scriptLib"/ubiquitous_bash
	_messagePlain_probe_cmd ls -ld _lib/kit/app/researchEngine
	local currentConfig
	currentConfig=$(git config core.fileMode)
	_messagePlain_probe_cmd git config core.fileMode true
	_messagePlain_probe_cmd find . -type f -exec chmod 644 {} \;
	_messagePlain_probe_cmd find . -type d -exec chmod 755 {} \;
	#git reset --hard
	_messagePlain_probe "git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/'"
	#git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/'
	#git diff -p | grep -E '^(diff|old mode|new mode)' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | git apply

	# ATTRIBUTION: ChatGPT o1-preview 2024-11-18
	git diff -p | awk '
	  /^diff --git/ { diff = $0; next }
	  /^old mode/   { old_mode = $0; next }
	  /^new mode/   { new_mode = $0;
	                  print diff;
	                  print old_mode;
	                  print new_mode;
	                }' | sed -e 's/^old/NEW/;s/^new/old/;s/^NEW/new/' | tee /dev/stdout > "$safeTmp"/patch.txt
	cat "$safeTmp"/patch.txt | git apply

	sleep 9
	git config core.fileMode "$currentConfig"
	cd "$functionEntryPWD"

	_messagePlain_probe_cmd ls -l "$scriptLib"/ubiquitous_bash/ubiquitous_bash.sh

	sudo -n mkdir -p "$globalVirtFS"/home/user/temp/test_"$ubiquitiousBashIDnano"
	sudo -n cp -a "$scriptLib"/ubiquitous_bash "$globalVirtFS"/home/user/temp/test_"$ubiquitousBashIDnano"/
	
	_chroot chown -R user:user /home/user/temp/test_"$ubiquitiousBashIDnano"/
	#_chroot sudo -n -u user bash -c 'cd /home/user/temp/test_"'"$ubiquitousBashIDnano"'"/ ; git reset --hard'

	_messagePlain_probe_cmd _chroot ls -l /home/user/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh

	if ! _chroot sudo -n --preserve-env=devfast -u user bash -c 'cd /home/user/temp/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ ; /home/user/temp/test_'"$ubiquitiousBashIDnano"'/ubiquitous_bash/ubiquitous_bash.sh _test'
	then
		_messageFAIL
	fi

	## DANGER: Rare case of 'rm -rf' , called through '_chroot' instead of '_safeRMR' . If not called through '_chroot', very dangerous!
	#_chroot rm -rf /home/user/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/ubiquitous_bash.sh _test
	_chroot rm -rf /home/user/temp/test_"$ubiquitiousBashIDnano"/ubiquitous_bash/
	_chroot rmdir /home/user/temp/test_"$ubiquitiousBashIDnano"/
	_chroot rmdir /home/user/temp/
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

	cd "$functionEntryPWD"
	_stop
	#return 0
}
_chroot_test() {
	if ! "$scriptAbsoluteLocation" _chroot_test_sequence "$@"
	then
		_stop 1
	fi
	return 0
}

# WARNING: DANGER: NOTICE: Do NOT distribute!
# WARNING: No production use. End-user function ONLY.
_nvidia_force_install() {
	_messageError 'WARNING: DANGER: Do NOT distribute!'
	_messagePlain_warn 'WARNING: DANGER: Do NOT distribute!'
	_messagePlain_bad 'WARNING: DANGER: Do NOT distribute!'
	_messageError 'WARNING: DANGER: Do NOT distribute!'
	_messageNormal '##### init: _nvidia_force_install'
	echo
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	sudo -n mkdir -p "$globalVirtFS"/root
	sudo -n cp -f "$scriptLib"/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/
	sudo -n cp -f "$scriptLib"/ubDistBuild/_lib/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/ > /dev/null 2>&1
	sudo -n chmod 755 "$globalVirtFS"/root/_get_nvidia.sh
	
	_chroot /root/_get_nvidia.sh _force_install
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# WARNING: DANGER: NOTICE: Do NOT distribute!
# WARNING: No production use. End-user function ONLY.
_nvidia_fetch_nvidia() {
	_messageError 'WARNING: DANGER: Do NOT distribute!'
	_messagePlain_warn 'WARNING: DANGER: Do NOT distribute!'
	_messagePlain_bad 'WARNING: DANGER: Do NOT distribute!'
	_messageError 'WARNING: DANGER: Do NOT distribute!'
	_messageNormal '##### init: _nvidia_force_install'
	echo
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	sudo -n mkdir -p "$globalVirtFS"/root
	sudo -n cp -f "$scriptLib"/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/
	sudo -n cp -f "$scriptLib"/ubDistBuild/_lib/setup/nvidia/_get_nvidia.sh "$globalVirtFS"/root/ > /dev/null 2>&1
	sudo -n chmod 755 "$globalVirtFS"/root/_get_nvidia.sh
	
	chmod u+x "$scriptLocal"/NVIDIA-Linux-*.run
	ls -1 -A "$scriptLocal"/NVIDIA-Linux-*.run > /dev/null 2>&1 && sudo -n cp "$scriptLocal"/NVIDIA-Linux-*.run "$globalVirtFS"/root/
	#sudo -n chmod u+x "$globalVirtFS"/root/NVIDIA-Linux-*.run
	_chroot /root/_get_nvidia.sh _fetch_nvidia
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}



# ATTENTION: Override if necessary (ie. if 'nouveau modeset=1' is necessary for specific hardware).
_write_modprobe_nvidia_nouveau() {
	sudo -n rm -f "$globalVirtFS"/etc/modprobe.d/blacklist-nvidia-nouveau.conf
	
	#_nouveau_disable
	# https://linuxconfig.org/how-to-disable-blacklist-nouveau-nvidia-driver-on-ubuntu-20-04-focal-fossa-linux
	# https://askubuntu.com/questions/747314/is-nomodeset-still-required
	#echo 'GRUB_CMDLINE_LINUX="nouveau.modeset=0"' | sudo -n tee -a "$globalVirtFS"/etc/default/grub
	sudo -n rm -f "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo 'blacklist nouveau' | sudo -n tee "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo 'blacklist lbm-nouveau' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo 'alias nouveau off' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo 'alias lbm-nouveau off' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo 'options nouveau modeset=0' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo '#nouveau.modeset=0' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	echo '#modprobe.blacklist=nouveau' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf
	
	
	
	#_nouveau_enable (also nvidia disable)
	sudo -n rm -f "$globalVirtFS"/modprobe-disable_nvidia--blacklist-nvidia-nouveau.conf
	echo 'blacklist nvidia' | sudo -n tee "$globalVirtFS"/modprobe-disable_nvidia--blacklist-nvidia-nouveau.conf
	echo 'blacklist nvidia_modeset' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nvidia--blacklist-nvidia-nouveau.conf
	echo 'blacklist nvidia_drm' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nvidia--blacklist-nvidia-nouveau.conf
	echo 'options nouveau modeset=0' | sudo -n tee -a "$globalVirtFS"/modprobe-disable_nvidia--blacklist-nvidia-nouveau.conf
}

# Minimal NVIDIA compatibility.
_nouveau_enable_procedure() {
	_write_modprobe_nvidia_nouveau
	sudo -n cp -f "$globalVirtFS"/modprobe-disable_nvidia--blacklist-nvidia-nouveau.conf "$globalVirtFS"/etc/modprobe.d/blacklist-nvidia-nouveau.conf
	
	#_chroot chmod 644 /root/_get_nvidia.sh
	_chroot chmod 755 /root/_get_nvidia.sh
	
	_chroot update-initramfs -u -k all
}
_nouveau_enable() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	_nouveau_enable_procedure "$@"
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}

# No NVIDIA compatibility (at least not immediate compatibility). No NVIDIA compatibility may be a reasonable default until unambigious usability.
_nouveau_disable_procedure() {
	_write_modprobe_nvidia_nouveau
	sudo -n cp -f "$globalVirtFS"/modprobe-disable_nouveau--blacklist-nvidia-nouveau.conf "$globalVirtFS"/etc/modprobe.d/blacklist-nvidia-nouveau.conf
	
	_chroot chmod 755 /root/_get_nvidia.sh
	
	_chroot update-initramfs -u -k all
}
_nouveau_disable() {
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	_nouveau_disable_procedure "$@"
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}



_unattended_enable() {
	_messagePlain_nominal 'init: _unattended_enable'
	
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	
	
	
	export getMost_backend="chroot"
	_set_getMost_backend "$@"
	_set_getMost_backend_debian "$@"
	_test_getMost_backend "$@"
	
	_getMost_backend apt-get update
	
	
	
	_getMost_backend_aptGetInstall unattended-upgrades
	_getMost_backend_aptGetInstall apt-listchanges
	#_getMost_backend_aptGetInstall bsd-mailx
	
	_chroot cp -f "$scriptLib"/custom/ubdist_unattended/20auto-upgrades "$globalVirtFS"/etc/apt/apt.conf.d/20auto-upgrades
	_chroot chmod 644 "$globalVirtFS"/etc/apt/apt.conf.d/20auto-upgrades
	
	_chroot cp -f "$scriptLib"/custom/ubdist_unattended/50unattended-upgrades "$globalVirtFS"/etc/apt/apt.conf.d/50unattended-upgrades
	_chroot chmod 644 "$globalVirtFS"/etc/apt/apt.conf.d/50unattended-upgrades
	
	#--dry-run --debug
	_messagePlain_probe unattended-upgrades
	_chroot unattended-upgrades
	
	
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL
	return 0
}






_ubDistBuild() {
	
	_create_ubDistBuild
	#_create_ubDistBuild-create
	#_create_ubDistBuild-rotten_install
	#_create_ubDistBuild-bootOnce
	#_create_ubDistBuild-rotten_install-core
	
	rm -f "$scriptLocal"/core.tar.xz > /dev/null 2>&1
	
	
	#_upload_ubDistBuild_image
	
	
	
	_custom_ubDistBuild
	
	
	
}





# WARNING: DANGER: No production use. Developer function. Creates a package from "$HOME" KDE and related configuration.
_create_kde() {
	mkdir -p "$scriptLocal"
	
	cd "$HOME"
	
	
	mkdir -p "$HOME"/.license_package_kde
	cp -a "$scriptLib"/custom/license_package_kde/. "$HOME"/.license_package_kde/
	
	rm -f "$scriptLocal"/package_kde.tar.xz > /dev/null 2>&1
	#-T0
	tar --exclude='./.ubtmp' --exclude='./.config/chromium' --exclude='./.config/systemd/user/bootdiscStartup.service' --exclude='./.config/startup.sh' --exclude='./.config/autostart/startup.desktop' --exclude='./.config/plasma-workspace/env/startup.sh' --exclude='./.config/plasma-workspace/env/profile.sh' --exclude='./.config/plasma-workspace/env/w540_display_start.sh' --exclude='./.config/qt5ct' --exclude='./.local/state' --exclude='./.local/share/virtualenv' --exclude='./.config/VirtualBox' --exclude='./.config/gcloud' --exclude='./.config/qalculate' --exclude='./.config/pulse' --exclude='./.config/systemd' --exclude='./.local/share/RecentDocuments' --exclude='./.local/share/recently-used.xbel' --exclude='./.local/share/kwalletd' --exclude='./.local/share/keyrings' -cvf "$scriptLocal"/package_kde.tar ./.config ./.kde ./.local ./.xournal/config ./.license_package_kde
	
	# WARNING: May be untested.
	if [[ -e "$scriptLib"/custom/special_package_kde ]] && cd "$scriptLib"/custom/special_package_kde
	then
		tar -rvf "$scriptLocal"/package_kde.tar './' 
	elif [[ -e "$scriptLib"/ubDistBuild/_lib/custom/special_package_kde ]] && cd "$scriptLib"/ubDistBuild/_lib/custom/special_package_kde
	then
		tar -rvf "$scriptLocal"/package_kde.tar './' 
	else
		_messagePlain_bad 'bad: fail: missing: 'custom/special_package_kde
		_messageFAIL
	fi
	
	env XZ_OPT="-e9" cat "$scriptLocal"/package_kde.tar | xz -z - > "$scriptLocal"/package_kde.tar.xz
	rm -f "$scriptLocal"/package_kde.tar
	
	rm -f "$HOME"/.license_package_kde/license.txt
	rm -f "$HOME"/.license_package_kde/CC0_license.txt
	rmdir "$HOME"/.license_package_kde
	
	return 0
}


_package_rm() {
	rm -f "$scriptLocal"/package_image.tar.flx
	rm -f "$scriptLocal"/package_image.tar.flx.part*
	
	rm -f "$scriptLocal"/vm-live.iso
	rm -f "$scriptLocal"/vm-live.iso.part*

	rm -f "$scriptLocal"/package_rootfs.tar
	rm -f "$scriptLocal"/package_rootfs.tar.flx
	rm -f "$scriptLocal"/package_rootfs.tar.flx.part*

	return 0
}

_convert_rm() {
	rm -f "$scriptLocal"/vm.vdi
	rm -f "$scriptLocal"/vm.vmdk
	rm -f "$scriptLocal"/vm.vhd > /dev/null 2>&1
	rm -f "$scriptLocal"/vm.vhdx

	rm -f "$scriptLocal"/package_rootfs.tar

	return 0
}

_convert-vdi() {
	_override_bin_vbox
	
	# NOTICE: _convert_rm

	[[ ! -e "$scriptLocal"/vm.img ]] && _messageFAIL
	rm -f "$scriptLocal"/package_image.tar.flx
	rm -f "$scriptLocal"/package_image.tar.flx.part*
	
	_messageNormal '_convert: vm.vdi'
	_vm_convert_vdi
	[[ ! -e "$scriptLocal"/vm.vdi ]] && _messageFAIL
	return 0
}

_convert-vmdk() {
	_override_bin_vbox
	
	# NOTICE: _convert_rm
	
	[[ ! -e "$scriptLocal"/vm.img ]] && _messageFAIL
	rm -f "$scriptLocal"/package_image.tar.flx
	rm -f "$scriptLocal"/package_image.tar.flx.part*
	
	_messageNormal '_convert: vm.vmdk'
	_vm_convert_vmdk
	[[ ! -e "$scriptLocal"/vm.vmdk ]] && _messageFAIL
	return 0
}

# https://learn.microsoft.com/en-us/powershell/module/hyper-v/convert-vhd?view=windowsserver2022-ps
_convert-vhdx() {
	_override_bin_vbox
	
	# NOTICE: _convert_rm
	
	[[ ! -e "$scriptLocal"/vm.img ]] && _messageFAIL
	rm -f "$scriptLocal"/package_image.tar.flx
	rm -f "$scriptLocal"/package_image.tar.flx.part*
	
	_messageNormal '_convert: vm.vhdx: convert: vm.vhd'
	_vm_convert_vhd

	_at_userMSW_probeCmd_discoverResource-cygwinNative-ProgramFiles qemu-img qemu false

	# https://bugs.launchpad.net/cinder/+bug/1692816
	# https://forum.level1techs.com/t/qemu-img-convert-vmdk-to-vhdx/169632
	# https://manpages.ubuntu.com/manpages/focal/en/man7/qemu-block-drivers.7.html
	qemu-img convert -f vpc -O vhdx -o subformat=fixed "$scriptLocal"/vm.vhd "$scriptLocal"/vm.vhdx -p

	#rm -f "$scriptLocal"/vm.vhd

	[[ ! -e "$scriptLocal"/vm.vhd ]] && _messageFAIL
	[[ ! -e "$scriptLocal"/vm.vhdx ]] && _messageFAIL
	return 0
}

_create_ubDistBuild_feedAccessories() {
	_messageNormal '_convert-live: _create_ubDistBuild_feedAccessories'

	_messagePlain_nominal 'Attempt: _openChRoot'
	! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL
	

	#[[ -e "$scriptLocal"/extendedInterface ]] && [[ -e "$scriptLocal"/ubDistBuild ]] && 
	if [[ -e "$scriptLocal"/extendedInterface-accessories ]] && [[ -e "$scriptLocal"/ubDistBuild-accessories ]]
	then
		_chroot sudo -n -u user bash -c 'mkdir -p /home/user/core/infrastructure/'

		sudo -n cp -a "$scriptLocal"/extendedInterface-accessories "$globalVirtFS"/home/user/core/infrastructure/
		sudo -n cp -a "$scriptLocal"/ubDistBuild-accessories "$globalVirtFS"/home/user/core/infrastructure/

		_chroot chown -R user:user /home/user/core/infrastructure/extendedInterface-accessories
		_chroot chown -R user:user /home/user/core/infrastructure/ubDistBuild-accessories
	fi


	# WARNING: May be untested.
	#if [[ -e "$scriptLocal"/package_ubcp-core.7z ]]
	#then
		#[[ ! -e "$scriptLocal"/package_ubcp-core.7z ]] && _messageFAIL
		#sudo -n cp -f "$scriptLocal"/package_ubcp-core.7z "$globalVirtFS"/package_ubcp-core.7z
		#[[ ! -e "$globalVirtFS"/package_ubcp-core.7z ]] && _messageFAIL
		#sudo -n chmod 644 "$globalVirtFS"/package_ubcp-core.7z
		#_chroot chown -R user:user /package_ubcp-core.7z

		#_chroot sudo -n -u user bash -c 'mkdir -p /home/user/core/infrastructure/extendedInterface-accessories/parts ; cd /home/user/core/infrastructure/extendedInterface-accessories/parts && mv -f /package_ubcp-core.7z ./'
		#_chroot sudo -n -u user bash -c 'mkdir -p /home/user/core/infrastructure/ubDistBuild-accessories/parts ; cd /home/user/core/infrastructure/extendedInterface-accessories/parts && mv -f /package_ubcp-core.7z ./'
	#fi



	# Provide more information to convert 'vm-live.iso' back to 'vm.img' (and other things), while offline from only a Live BD-ROM disc (or other source of the squashfs root filesystem) .
	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/extendedInterface && [[ ! -e /home/user/core/infrastructure/extendedInterface-accessories/parts ]] && ./ubiquitous_bash.sh _build_extendedInterface-fetch'
	_chroot sudo -n -u user bash -c 'cd /home/user/core/infrastructure/ubDistBuild && [[ ! -e /home/user/core/infrastructure/ubDistBuild-accessories/parts ]] && ./ubiquitous_bash.sh _build_ubDistBuild-fetch'



	_messagePlain_nominal 'chroot: report: df-live'
	_chroot df -h / /boot /boot/efi | _chroot tee /df-live
	_chroot mount | grep '^.* on / ' | _chroot tee -a /df-live

	_messagePlain_nominal 'Attempt: _closeChRoot'
	! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

	return 0
}
_convert-live_ISO() {
	_messageNormal '_convert: vm-live.iso'

	
	if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"
	then
		_stop 1
	fi
	
	[[ "$current_diskConstrained" == "true" ]] && rm -f "$scriptLocal"/vm.img
	
	if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"
	then
		_stop 1
	fi
	
	_safeRMR "$scriptLocal"/livefs

	if [[ -e "$scriptLocal"/livefs ]]
	then
		_messagePlain_bad 'fail: exists: livefs'
		_stop 1
		return 1
	fi

	return 0
}
_convert-live() {
	#_messageNormal '_convert: vm-live.iso'


	
	_create_ubDistBuild_feedAccessories "$@"
	

	_convert-live_ISO "$@"
	
}


_convert() {
	# NOTICE: _convert_rm

	[[ ! -e "$scriptLocal"/vm.img ]] && _messageFAIL
	rm -f "$scriptLocal"/package_image.tar.flx
	rm -f "$scriptLocal"/package_image.tar.flx.part*


	_convert-vdi "$@"
	

	_convert-vmdk "$@"


	_convert-rootfs "$@"
	
	
	_messageNormal '_convert: vm-live.iso'
	
	#export current_diskConstrained="false"
	_convert-live "$@"
	
	
	
	_messageNormal '_convert: vm-live-more.iso'
	
	_live_more_copy
	"$scriptAbsoluteLocation" _live_more_sequence "$@"
	
	[[ ! -e "$scriptLocal"/vm-live-more.iso ]] && _messageFAIL
	
	
	
	
	_messageNormal '_convert: vm-live-more.vdi'
	_live_more_convert_vdi
	
	[[ ! -e "$scriptLocal"/vm-live-more.vdi ]] && _messageFAIL
	
	
	
	
	_messageNormal '_convert: vm-live-more.vmdk'
	_live_more_convert_vmdk
	
	[[ ! -e "$scriptLocal"/vm-live-more.vmdk ]] && _messageFAIL
	
	return 0
}


# Call '_nouveau_enable' before, or similar, to create a 'vm-live-nouveau.iso', or similar file(s).
# WARNING: Deletes 'vm.img' .
_upload_convert() {
	[[ ! -e "$scriptLocal"/vm.img ]] && _messageFAIL
	rm -f "$scriptLocal"/package_image.tar.flx
	
	
	
	
	_messageNormal '_upload_convert: vm.vdi'
	_vm_convert_vdi
	[[ ! -e "$scriptLocal"/vm.vdi ]] && _messageFAIL
	_rclone_limited --progress copy "$scriptLocal"/vm.vmdk distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messageFAIL
	_rclone_limited --progress copy "$scriptLocal"/vm.vmdk.uuid distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messagePlain_bad 'bad: fail'
	rm -f "$scriptLocal"/vm.vmdk "$scriptLocal"/vm.vmdk.uuid
	
	
	_messageNormal '_upload_convert: vm.vmdk'
	_vm_convert_vmdk
	[[ ! -e "$scriptLocal"/vm.vmdk ]] && _messageFAIL
	_rclone_limited --progress copy "$scriptLocal"/vm.vmdk distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messageFAIL
	_rclone_limited --progress copy "$scriptLocal"/vm.vmdk.uuid distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messagePlain_bad 'bad: fail'
	rm -f "$scriptLocal"/vm.vmdk "$scriptLocal"/vm.vmdk.uuid
	
	
	
	_messageNormal '_upload_convert: vm-live.iso'
	
	if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"
	then
		_stop 1
	fi
	
	rm -f "$scriptLocal"/vm.img
	
	if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"
	then
		_stop 1
	fi
	
	_safeRMR "$scriptLocal"/livefs
	
	_rclone_limited --progress copy "$scriptLocal"/vm-live.iso distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messageFAIL
	#rm -f "$scriptLocal"/vm-live.iso
	
	
	
	_messageNormal '_upload_convert: vm-live-more.iso'
	
	_live_more_move
	"$scriptAbsoluteLocation" _live_more_sequence "$@"
	
	[[ ! -e "$scriptLocal"/vm-live-more.iso ]] && _messageFAIL
	#_rclone_limited --progress copy "$scriptLocal"/vm-live-more.iso distLLC_build_ubDistBuild:
	#[[ "$?" != "0" ]] && _messageFAIL
	#rm -f "$scriptLocal"/vm-live-more.iso
	
	
	
	
	_messageNormal '_upload_convert: vm-live-more.vdi'
	_live_more_convert_vdi
	
	[[ ! -e "$scriptLocal"/vm-live-more.vdi ]] && _messageFAIL
	#_rclone_limited --progress copy "$scriptLocal"/vm-live-more.vdi distLLC_build_ubDistBuild:
	#[[ "$?" != "0" ]] && _messageFAIL
	_rclone_limited --progress copy "$scriptLocal"/vm-live-more.vdi.uuid distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messagePlain_bad 'bad: fail'
	#rm -f "$scriptLocal"/vm-live-more.vdi
	
	
	
	
	_messageNormal '_upload_convert: vm-live-more.vmdk'
	_live_more_convert_vmdk
	
	[[ ! -e "$scriptLocal"/vm-live-more.vmdk ]] && _messageFAIL
	#_rclone_limited --progress copy "$scriptLocal"/vm-live-more.vmdk distLLC_build_ubDistBuild:
	#[[ "$?" != "0" ]] && _messageFAIL
	_rclone_limited --progress copy "$scriptLocal"/vm-live-more.vmdk.uuid distLLC_build_ubDistBuild:
	[[ "$?" != "0" ]] && _messagePlain_bad 'bad: fail'
	#rm -f "$scriptLocal"/vm-live-more.vmdk
	
	return 0
}



# WARNING: Deletes 'vm.img' .
_assessment() {
	[[ ! -e "$scriptLocal"/vm.img ]] && _messageFAIL
	rm -f "$scriptLocal"/package_image.tar.flx
	
	
	_messageNormal '_convert: vm-live.iso'
	
	if ! "$scriptAbsoluteLocation" _live_sequence_in "$@"
	then
		_stop 1
	fi
	
	rm -f "$scriptLocal"/vm.img
	
	if ! "$scriptAbsoluteLocation" _live_sequence_out "$@"
	then
		_stop 1
	fi
	
	_safeRMR "$scriptLocal"/livefs
	
	du -sh "$scriptLocal"/vm-live.iso
	
	
	
	_messageNormal '_convert: vm-live-more.iso'
	
	_live_more_move
	"$scriptAbsoluteLocation" _live_more_sequence "$@"
	
	[[ ! -e "$scriptLocal"/vm-live-more.iso ]] && _messageFAIL
	
	du -sh "$scriptLocal"/vm-live-more.iso
}


_refresh_anchors() {
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_bin.bat

	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_revert-fromLive.bat


	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_join.bat

	
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_get_vmImg_ubDistBuild.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_get_vmImg_ubDistBuild-live.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_get_vmImg_ubDistBuild-rootfs.bat

	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_install_wsl2.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_install_vm-wsl2.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_uninstall_vm-wsl2.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_install_vm-wsl2-kernel.bat
	
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_install_vm-wsl2-portForward.bat

	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_sshid-import-wsl2.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_sshid-export-wsl2.bat

	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_convert-vdi.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_convert-vmdk.bat
	cp -a "$scriptAbsoluteFolder"/_anchor.bat "$scriptAbsoluteFolder"/_convert-vhdx.bat



	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_get_core_ubDistFetch
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install-kde
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install-core
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-install-ubDistBuild
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-create
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-bootOnce
	#cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-rotten_install-core
	#cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_ubDistBuild-install-ubDistBuild
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_custom_ubDistBuild
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_package_ubDistBuild_image
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_upload_ubDistBuild_image
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_upload_ubDistBuild_custom
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_croc_ubDistBuild_image
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_croc_ubDistBuild_image_out
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_ubDistBuild
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_gparted
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_openImage
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_closeImage
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_openChRoot
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_closeChRoot
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_closeVBoxRaw
	
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_chroot
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_labVBox
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_zSpecial_qemu
	
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_create_kde
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_convert
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_upload_convert
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_assessment
	
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_true
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_false
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_chroot_test
	
	
	# WARNING: DANGER: NOTICE: Do NOT distribute!
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_nvidia_force_install
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_nouveau_enable
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_nouveau_disable
}

