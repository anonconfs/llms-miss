
_backup_restore_vm-wsl2-rsync-exclude() {
    local currentSource
    local currentDestination

    currentSource="$1"
    currentDestination="$2"

    if [[ "$currentSource" == "" ]] || [[ "$currentSource" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: source'
        return 1
    fi
    if [[ "$currentDestination" == "" ]] || [[ "$currentDestination" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: destination'
        return 1
    fi

    if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

    [[ "$currentSource" != *"/." ]] && currentSource="$1"/.
    [[ "$currentDestination" != *"/." ]] && currentDestination="$2"/.


	if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

	_messagePlain_probe_cmd rsync -ax --delete  --exclude= '.ubtmp' --exclude "VirtualBox VMs" --exclude "KlipperScreen" --exclude "crowsnest" --exclude "kiauh" --exclude "kiauh-backups" --exclude "klipper" --exclude "klippy-env" --exclude "mainsail" --exclude "mainsail-config" --exclude "moonraker" --exclude "moonraker-env" --exclude "printer_data" --exclude ".Xauthority" --exclude ".bash_history" --exclude ".bash_logout" --exclude ".cache" --exclude ".face" --exclude ".face.icon" --exclude ".gEDA" --exclude ".gcloud" --exclude ".gnome" --exclude ".kde.bak" --exclude ".nix-channels" --exclude ".nix-defexpr" --exclude ".nix-profile" --exclude ".python_history" --exclude ".pythonrc" --exclude ".sudo_as_admin_successful" --exclude ".terraform.d" --exclude ".xsession-errors" --exclude "Downloads" --exclude "___quick" --exclude "_unix_renice_execDaemon.log" --exclude "core" --exclude "package_kde.tar.xz" --exclude "project" --exclude "rottenScript.sh" --exclude "ubDistBuild" --exclude "ubDistFetch" --exclude "ubiquitous_bash.sh" --exclude ".config" --exclude ".kde" --exclude ".local" --exclude ".xournal" --exclude ".license_package_kde" --exclude ".bash_profile" --exclude ".bashrc" --exclude ".config" --exclude ".gitconfig" --exclude ".inputrc" --exclude ".lesshst" --exclude ".octave_hist" --exclude ".octaverc" --exclude ".profile" --exclude ".ubcore" --exclude ".ubcorerc_pythonrc.py" --exclude ".ubcorerc-gnuoctave.m" --exclude ".viminfo" --exclude ".wget-hsts" --exclude "bin" "$currentSource" "$currentDestination"
}
_backup_restore_vm-wsl2-rsync-basic() {
    local currentSource
    local currentDestination

    currentSource="$1"
    currentDestination="$2"

    if [[ "$currentSource" == "" ]] || [[ "$currentSource" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: source'
        return 1
    fi
    if [[ "$currentDestination" == "" ]] || [[ "$currentDestination" == "./." ]]
    then
        _messagePlain_bad 'fail: empty: destination'
        return 1
    fi

    if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

    [[ "$currentSource" != *"/." ]] && currentSource="$1"/.
    [[ "$currentDestination" != *"/." ]] && currentDestination="$2"/.


	if [[ ! -e "$currentSource" ]]
	then
		_messagePlain_bad 'fail: missing source: '"$currentSource"
		return 1
	fi
	if [[ ! -e "$currentDestination" ]]
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi
	if ! mkdir -p "$currentSource"
	then
		_messagePlain_bad 'fail: mkdir: source: '"$currentSource"
		return 1
	fi
	if ! mkdir -p "$currentDestination"
	then
		_messagePlain_bad 'fail: missing destination: '"$currentDestination"
		return 1
	fi

	_messagePlain_probe_cmd rsync -ax --delete "$currentSource" "$currentDestination"
}

_backup_vm-wsl2-tar-basic() {
    cd "$1"
    rm -f "$3"
    _messagePlain_probe_var PWD
    _messagePlain_probe 'tar -cf - '"$2"' | lz4 -z --fast=1 - '"$3"
    tar -cf - "$2" | lz4 -z --fast=1 - "$3"
}
_restore_vm-wsl2-tar-basic() {
    cd "$2"
    _messagePlain_probe_var PWD
    _messagePlain_probe 'lz4 -d -c '"$1"' | tar xvf -'
    lz4 -d -c "$1" | tar xvf -
}


# ATTENTION: Override with 'ops.sh' if necessary.
# WARNING: Incorrect parameters may delete data from host - rsync is used with '--delete' !
_backup_vm-wsl2() {
   ! _if_cygwin && _messagePlain_bad 'fail: Cygwin/MSW only' && return 1

    _messagePlain_request 'request: Backup is on a limited best effort basis only.'
    echo 'wait: 5seconds: Ctrl+c repeatedly to cancel'
    echo "If you don't know what this means, and you haven't extensively used 'ubdist' through WSL, then you probably have nothing to worry about."
    echo "Otherwise - you should copy your data out of WSL2 before upgrading or uninstalling."
	local currentIteration
	for currentIteration in $(seq 1 5)
	do
		sleep 1
	done
	echo 'NOT cancelled.'
    echo
    echo

    local currentBackupRootUNIX
    currentBackupRootUNIX=/cygdrive/c/core/infrastructure/uwsl-h-b-"$1"


    local currentBackupLocationUNIX
    currentBackupLocationUNIX="$currentBackupRootUNIX"/home

    if ! mkdir -p "$currentBackupLocationUNIX" || [[ ! -e "$currentBackupLocationUNIX" ]]
    then
        _messagePlain_bad 'fail: mkdir: '"$currentBackupRootUNIX"/home
        return 1
    fi

    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")
    local currentBackupLocationMSW
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")

    #wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-exclude /home/user/. "'""$currentBackupLocationMSW""'"
    echo


    currentBackupLocationUNIX="$currentBackupRootUNIX"/home/.ssh
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    if ! mkdir -p "$currentBackupLocationUNIX" || [[ ! -e "$currentBackupLocationUNIX" ]]
    then
        _messagePlain_bad 'fail: mkdir: '"$currentBackupRootUNIX"/home/.ssh
        return 1
    fi
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-basic /home/user/.ssh/. "'""$currentBackupLocationMSW""'"





    currentBackupLocationUNIX="$currentBackupRootUNIX"/project.tar.lz4
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    if ! mkdir -p "$currentBackupRootUNIX" || [[ ! -e "$currentBackupRootUNIX" ]]
    then
        _messagePlain_bad 'fail: mkdir: '"$currentBackupRootUNIX"
        return 1
    fi
    if ! echo > "$currentBackupLocationUNIX" || [[ ! -e "$currentBackupLocationUNIX" ]]
    then
        _messagePlain_bad 'fail: tee: '"$currentBackupLocationUNIX"
        return 1
    fi
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_vm-wsl2-tar-basic /home/user/ project "'""$currentBackupLocationMSW""'"
}

# ATTENTION: Override with 'ops.sh' if necessary.
# WARNING: Incorrect parameters may delete data from host - rsync is used with '--delete' !
_restore_vm-wsl2() {
    ! _if_cygwin && _messagePlain_bad 'fail: Cygwin/MSW only' && return 1

    [[ ! -e /cygdrive/c/core/infrastructure/uwsl-h-b-"$1" ]] && _messagePlain_probe 'not found: /cygdrive/c/core/infrastructure/uwsl-h-b'-"$1" && return 1

    _messagePlain_request 'request: Restore is on a limited best effort basis only.'
    echo "If you don't know what this means, and you haven't extensively used 'ubdist' through WSL, then you probably have nothing to worry about."
    echo "Otherwise - you should copy your data out of WSL2 before upgrading or uninstalling."
    echo
    echo

    local currentBackupRootUNIX
    currentBackupRootUNIX=/cygdrive/c/core/infrastructure/uwsl-h-b-"$1"


    local currentBackupLocationUNIX
    currentBackupLocationUNIX="$currentBackupRootUNIX"/home

    if ! mkdir -p "$currentBackupLocationUNIX" || [[ ! -e "$currentBackupLocationUNIX" ]]
    then
        _messagePlain_bad 'fail: mkdir: '"$currentBackupRootUNIX"/home
        return 1
    fi

    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")
    local currentBackupLocationMSW
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")

    #wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-exclude "'""$currentBackupLocationMSW""'" /home/user/.
    echo


    currentBackupLocationUNIX="$currentBackupRootUNIX"/home/.ssh
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    if ! mkdir -p "$currentBackupLocationUNIX" || [[ ! -e "$currentBackupLocationUNIX" ]]
    then
        _messagePlain_bad 'fail: mkdir: '"$currentBackupRootUNIX"/home/.ssh
        return 1
    fi
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _backup_restore_vm-wsl2-rsync-basic "'""$currentBackupLocationMSW""'" /home/user/.ssh/.

    wsl -d "ubdist" chmod 600 '~/.ssh/id_*'
    wsl -d "ubdist" chmod 755 '~/.ssh/id_*.pub'





    currentBackupLocationUNIX="$currentBackupRootUNIX"/project.tar.lz4
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    if ! mkdir -p "$currentBackupRootUNIX" || [[ ! -e "$currentBackupRootUNIX" ]]
    then
        _messagePlain_bad 'fail: mkdir: '"$currentBackupRootUNIX"
        return 1
    fi
    if [[ ! -e "$currentBackupLocationUNIX" ]]
    then
        _messagePlain_bad 'fail: missing: '"$currentBackupLocationUNIX"
        return 1
    fi
    currentBackupLocationMSW=$(cygpath -w "$currentBackupLocationUNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _restore_vm-wsl2-tar-basic "'""$currentBackupLocationMSW""'" /home/user
}


# End user function .
_setup_vm-wsl2_sequence() {
    _start
    local functionEntryPWD
    functionEntryPWD="$PWD"

    _write_wslconfig "ub_ignore_kernel_wsl"

    local backupID
    backupID=
    wsl --list | tr -dc 'a-zA-Z0-9\n' | grep '^ubdist' > /dev/null 2>&1 && backupID=$(_uid 14)

    ! _if_cygwin && _messagePlain_bad 'fail: Cygwin/MSW only' && _stop 1

    if [[ -e "$scriptLocal"/package_rootfs.tar.flx ]] && [[ ! -e "$scriptLocal"/package_rootfs.tar ]]
    then
        cat "$scriptLocal"/package_rootfs.tar.flx | lz4 -d -c > "$scriptLocal"/package_rootfs.tar
        rm -f "$scriptLocal"/package_rootfs.tar.flx
    fi

    [[ ! -e "$scriptLocal"/package_rootfs.tar ]] && _messagePlain_bad 'bad: missing: package_rootfs.tar' && _messageFAIL && _stop 1


    if [[ "$backupID" != "" ]]
    then
        _backup_vm-wsl2 "$backupID"
        wsl --unregister ubdist
    fi

    mkdir -p '/cygdrive/c/core/infrastructure/ubdist_wsl'
    _userMSW _messagePlain_probe wsl --import ubdist '/cygdrive/c/core/infrastructure/ubdist_wsl' "$scriptLocal"/package_rootfs.tar --version 2
    _userMSW wsl --import ubdist '/cygdrive/c/core/infrastructure/ubdist_wsl' "$scriptLocal"/package_rootfs.tar --version 2
    wsl -d "ubdist" sudo -n systemctl disable ollama.service
    wsl -d "ubdist" sudo -n systemctl stop ollama.service

    # Preserve fallback and rootfs if automatic test is successful. Expected to suffice for rebuilding 'ubdist' or other dist/OS from an MSW host if necessary.
    if wsl -d "ubdist" /bin/true > /dev/null 2>&1 && ! wsl -d "ubdist" /bin/false > /dev/null 2>&1 && wsl -d ubdist /home/user/ubiquitous_bash.sh _true && ! wsl -d ubdist /home/user/ubiquitous_bash.sh _false
    then
        _messagePlain_good 'good: wsl: ubdist: true/false'

        mkdir -p '/cygdrive/c/core/infrastructure/ubdist_wsl_recovery/autotest_success'
        cp "$scriptLocal"/package_rootfs.tar '/cygdrive/c/core/infrastructure/ubdist_wsl_recovery/autotest_success/package_rootfs.tar'

        mkdir -p '/cygdrive/c/core/infrastructure/ubdist_wsl_fallback'
        _userMSW _messagePlain_probe wsl --import ubdist_fallback '/cygdrive/c/core/infrastructure/ubdist_wsl_fallback' "$scriptLocal"/package_rootfs.tar --version 2
        _userMSW wsl --import ubdist_fallback '/cygdrive/c/core/infrastructure/ubdist_wsl_fallback' "$scriptLocal"/package_rootfs.tar --version 2
        wsl -d "ubdist_fallback" sudo -n systemctl disable ollama.service
        wsl -d "ubdist_fallback" sudo -n systemctl stop ollama.service

        if wsl -d "ubdist" /bin/true > /dev/null 2>&1 && ! wsl -d "ubdist" /bin/false > /dev/null 2>&1 && wsl -d ubdist /home/user/ubiquitous_bash.sh _true && ! wsl -d ubdist /home/user/ubiquitous_bash.sh _false
        then
            _messagePlain_good 'good: wsl: ubdist_fallback: true/false'
        else
            _messagePlain_bad 'fail: wsl: ubdist_fallback: true/false'
            sleep 15
            _messageFAIL
            _stop 1
            return 1
        fi

        if [[ -e '/cygdrive/c/core/infrastructure/ubdist_wsl_recovery/autotest_success/package_rootfs.tar' ]]
        then
            _messagePlain_good 'good: autotest_success: package_rootfs.tar'
        else
            _messagePlain_bad 'fail: autotest_success: package_rootfs.tar'
            sleep 15
            _messageFAIL
            _stop 1
            return 1
        fi
    else
        _messagePlain_bad 'fail: wsl: ubdist: true/false'
        sleep 15
        _messageFAIL
        _stop 1
        return 1
    fi


    _messagePlain_probe wsl --set-default ubdist
    wsl --set-default ubdist


    
    #_messagePlain_probe 'wsl: disable unnecessary systemd services'

    #wsl -d ubdist sudo -n systemctl disable exim4
    #wsl -d ubdist sudo -n systemctl disable wpa_supplicant
    #wsl -d ubdist sudo -n systemctl disable NetworkManager

    ##wsl -d ubdist sudo -n systemctl disable ssh
    ##wsl -d ubdist sudo -n systemctl disable sshd

    #wsl -d ubdist sudo -n systemctl disable nfs-blkmap
	#wsl -d ubdist sudo -n systemctl disable nfs-idmapd
	#wsl -d ubdist sudo -n systemctl disable nfs-mountd
	#wsl -d ubdist sudo -n systemctl disable nfs-server
	#wsl -d ubdist sudo -n systemctl disable nfsdcld

	#wsl -d ubdist sudo -n systemctl disable lm-sensors
	#wsl -d ubdist sudo -n systemctl disable cron

	#wsl -d ubdist sudo -n systemctl disable console-getty
	#wsl -d ubdist sudo -n systemctl disable getty@tty1.service
	#wsl -d ubdist sudo -n systemctl disable getty@tty2.service
	#wsl -d ubdist sudo -n systemctl disable getty@tty3.service
	#wsl -d ubdist sudo -n systemctl disable sddm
    
	#wsl -d ubdist sudo -n systemctl disable vboxadd
	#wsl -d ubdist sudo -n systemctl disable vboxadd-service



    wsl -d ubdist sudo -n chmod ugoa-x /usr/lib/x86_64-linux-gnu/libexec/kf5/kscreen_backend_launcher


    # WARNING: May be untested.
    # https://forum.manjaro.org/t/high-cpu-usage-from-plasmashell-kactivitymanagerd/114305
	# DANGER: Unusual. Uses 'rm -rf' directly. Presumed ONLY during dist/OS install .
	#wsl -d ubdist sudo -n rm -rf /home/user/.local/share/kactivitymanagerd/resources/*
    wsl -d ubdist /home/user/ubDistBuild/_lib/ubiquitous_bash/_lib/kit/install/cloud/cloud-init/zRotten/zMinimal/rotten_install.sh _custom_kde-limited


    # https://unix.stackexchange.com/questions/253816/restrict-size-of-buffer-cache-in-linux
    # https://learn.microsoft.com/en-us/windows/wsl/release-notes#build-19013
    # https://devblogs.microsoft.com/commandline/memory-reclaim-in-the-windows-subsystem-for-linux-2/
    # https://github.com/microsoft/WSL/issues/4166
    #  Although this issue is 'open', it seems to have been mitigated significantly as of 2023-09-04 .
    # https://www.tecmint.com/clear-ram-memory-cache-buffer-and-swap-space-on-linux/
    wsl -d ubdist sudo -n mkdir -p /etc/sysctl.d
	echo 'vm.min_free_kbytes=600000' | wsl -d ubdist sudo -n tee /etc/sysctl.d/wsl_ram.conf > /dev/null
	echo 'vm.vfs_cache_pressure=195' | wsl -d ubdist sudo -n tee -a /etc/sysctl.d/wsl_ram.conf > /dev/null


    if [[ "$backupID" != "" ]]
    then
        _restore_vm-wsl2 "$backupID"
        # DANGER: Unusual! May delete data from host!
        #_safeRMR rm -rf /cygdrive/c/core/infrastructure/uwsl-h-b-"$backupID"
        if [[ ! -e /cygdrive/c/core/infrastructure/uwsl-h-b-"$backupID" ]]
        then
            _messagePlain_bad 'fail: rm: missing: /cygdrive/c/core/infrastructure/uwsl-h-b-'"$backupID"
            _messageFAIL
            _stop 1
        fi
        rm -rf /cygdrive/c/core/infrastructure/uwsl-h-b-"$backupID"
    else
        _restore_vm-wsl2 "uninstalled"
        # DANGER: Unusual! May delete data from host!
        #_safeRMR /cygdrive/c/core/infrastructure/uwsl-h-b-uninstalled
        if [[ ! -e /cygdrive/c/core/infrastructure/uwsl-h-b-uninstalled ]]
        then
            _messagePlain_bad 'fail: rm: missing: /cygdrive/c/core/infrastructure/uwsl-h-b-uninstalled'
            echo "Missing 'restore' is only ok either on first installation or if the backup was deliberately deleted, moved, etc."
            #_messageFAIL
            _stop 1
            return 1
        fi
        rm -rf /cygdrive/c/core/infrastructure/uwsl-h-b-uninstalled
    fi


    wsl -d "ubdist" sudo -n systemctl disable ollama.service
    wsl -d "ubdist" sudo -n systemctl stop ollama.service
    wsl -d "ubdist_fallback" sudo -n systemctl disable ollama.service
    wsl -d "ubdist_fallback" sudo -n systemctl stop ollama.service
    

    _install_vm-wsl2-portForward ubdist notBooting
    


    #wsl --unregister ubdist

    cd "$functionEntryPWD"
    _stop
}
_setup_vm-wsl2() {
    "$scriptAbsoluteLocation" _setup_vm-wsl2_sequence "$@"
}
_setup_vm-wsl() {
    _setup_vm-wsl2 "$@"
}

_uninstall_vm-wsl2() {
    if wsl --list | tr -dc 'a-zA-Z0-9\n' | grep '^ubdist' > /dev/null 2>&1
    then
        _backup_vm-wsl2 "uninstalled"
        wsl --unregister ubdist
    fi
}



# End user function .
_install_wsl2() {
    _setup_wsl2 "$@"
}
_install_wsl() {
    _install_wsl2 "$@"
}

# End user function .
_install_vm-wsl2() {
    _setup_vm-wsl2 "$@"
}
_install_vm-wsl() {
    _install_vm-wsl2 "$@"
}




_write_kernelConfig_wsl2() {
    [[ "$1" != "" ]] && cd "$1"

    if [[ ! -e "./Microsoft/config-wsl" ]]
    then
        _messagePlain_bad 'fail: missing: ./Microsoft/config-wsl'
        echo 'Usually this arises due to having done 'git clone' from Cygwin/MSW and then attempting to build from Linux .'
        return 1
    fi

    cp Microsoft/config-wsl .config

    ./scripts/config --enable CONFIG_PREEMPT

    # Maybe not ideal. VR framerates are closer to fractions of 360Hz (30, 45, 60, 75, 90, !114, 120, 144, 180, 240) .
    # Expect 300Hz is ok for WSL2 . Worst case jitter or latency of ~3ms is less than one frame at usual 2D framerates, and both CPU/GPU frametime margins for 2D content are normally much greater.
    # Setting this too high might cause VR performance issues. Historically, VirtualBox has had significant performance cost (a few milliseconds per frame) against VR frametimes
    # https://www.pugetsystems.com/labs/hpc/does-enabling-wsl2-affect-performance-of-windows-10-applications-1832/
    #  Suggests approximately 2percent worst case possible performance loss (with reasonable interpretation of margin of error).
    #  Much above 2percent would be approaching significantly lower practical VR resolution, significant loss of hard earned CPU/RAM clocking gains, etc.
    #   However, these results may include the performance cost of enabling HyperV virtualization at all, which may already be a dire security necessity.
    ./scripts/config --enable CONFIG_HZ_300

    ./scripts/config --enable CONFIG_KVM
    ./scripts/config --enable CONFIG_KVM_INTEL
    ./scripts/config --enable CONFIG_KVM_AMD

    ./scripts/config --enable CONFIG_HID_GENERIC
    
    # CONFIG_HIDRAW * (devices), USB_STORAGE * (devices but NOT debug)
    #NILFS , CONFIG_USB_SERIAL * (devices NOT debug) , CONFIG_USB_SERIAL_CONSOLE

    ./scripts/config --enable CONFIG_HIDRAW

    # ATTRIBUTION - ChatGPT 3.5 2023-08-14 .
    # Here is a list of 'make menuconfig' choices.
    #
    # Here is a list of kernel symbols from '   cat drivers/usb/serial/Kconfig | grep '^config' | sed 's/config //g' | sed 's/^/\.\/scripts\/config --enable /g'   ' .
    #
    # Which items from the second list seem not to exist in the first list?

    #cat ./drivers/hid/Kconfig | grep '^config' | sed 's/config //g' | sed 's/^/\.\/scripts\/config --enable /g'
./scripts/config --enable HID_A4TECH
./scripts/config --enable HID_ACCUTOUCH
./scripts/config --enable HID_ACRUX
./scripts/config --enable HID_ACRUX_FF
./scripts/config --enable HID_APPLE
./scripts/config --enable HID_APPLEIR
./scripts/config --enable HID_ASUS
./scripts/config --enable HID_AUREAL
./scripts/config --enable HID_BELKIN
./scripts/config --enable HID_BETOP_FF
./scripts/config --enable HID_BIGBEN_FF
./scripts/config --enable HID_CHERRY
./scripts/config --enable HID_CHICONY
./scripts/config --enable HID_CORSAIR
./scripts/config --enable HID_COUGAR
./scripts/config --enable HID_MACALLY
#./scripts/config --enable HID_PRODIKEYS
./scripts/config --enable HID_CMEDIA
#./scripts/config --enable HID_CP2112
./scripts/config --enable HID_CREATIVE_SB0540
./scripts/config --enable HID_CYPRESS
./scripts/config --enable HID_DRAGONRISE
./scripts/config --enable DRAGONRISE_FF
./scripts/config --enable HID_EMS_FF
./scripts/config --enable HID_ELAN
./scripts/config --enable HID_ELECOM
./scripts/config --enable HID_ELO
./scripts/config --enable HID_EZKEY
./scripts/config --enable HID_FT260
./scripts/config --enable HID_GEMBIRD
./scripts/config --enable HID_GFRM
./scripts/config --enable HID_GLORIOUS
./scripts/config --enable HID_HOLTEK
./scripts/config --enable HOLTEK_FF
./scripts/config --enable HID_VIVALDI_COMMON
#./scripts/config --enable HID_GOOGLE_HAMMER
./scripts/config --enable HID_VIVALDI
./scripts/config --enable HID_GT683R
./scripts/config --enable HID_KEYTOUCH
./scripts/config --enable HID_KYE
./scripts/config --enable HID_UCLOGIC
./scripts/config --enable HID_WALTOP
./scripts/config --enable HID_VIEWSONIC
./scripts/config --enable HID_VRC2
./scripts/config --enable HID_XIAOMI
./scripts/config --enable HID_GYRATION
./scripts/config --enable HID_ICADE
./scripts/config --enable HID_ITE
./scripts/config --enable HID_JABRA
./scripts/config --enable HID_TWINHAN
./scripts/config --enable HID_KENSINGTON
./scripts/config --enable HID_LCPOWER
./scripts/config --enable HID_LED
./scripts/config --enable HID_LENOVO
./scripts/config --enable HID_LETSKETCH
./scripts/config --enable HID_LOGITECH
./scripts/config --enable HID_LOGITECH_DJ
./scripts/config --enable HID_LOGITECH_HIDPP
./scripts/config --enable LOGITECH_FF
./scripts/config --enable LOGIRUMBLEPAD2_FF
./scripts/config --enable LOGIG940_FF
./scripts/config --enable LOGIWHEELS_FF
./scripts/config --enable HID_MAGICMOUSE
./scripts/config --enable HID_MALTRON
./scripts/config --enable HID_MAYFLASH
./scripts/config --enable HID_MEGAWORLD_FF
./scripts/config --enable HID_REDRAGON
./scripts/config --enable HID_MICROSOFT
./scripts/config --enable HID_MONTEREY
./scripts/config --enable HID_MULTITOUCH
./scripts/config --enable HID_NINTENDO
./scripts/config --enable NINTENDO_FF
./scripts/config --enable HID_NTI
./scripts/config --enable HID_NTRIG
./scripts/config --enable HID_ORTEK
./scripts/config --enable HID_PANTHERLORD
./scripts/config --enable PANTHERLORD_FF
./scripts/config --enable HID_PENMOUNT
./scripts/config --enable HID_PETALYNX
./scripts/config --enable HID_PICOLCD
#./scripts/config --enable HID_PICOLCD_FB
#./scripts/config --enable HID_PICOLCD_BACKLIGHT
#./scripts/config --enable HID_PICOLCD_LCD
./scripts/config --enable HID_PICOLCD_LEDS
#./scripts/config --enable HID_PICOLCD_CIR
./scripts/config --enable HID_PLANTRONICS
#./scripts/config --enable HID_PLAYSTATION
#./scripts/config --enable PLAYSTATION_FF
./scripts/config --enable HID_PXRC
./scripts/config --enable HID_RAZER
./scripts/config --enable HID_PRIMAX
./scripts/config --enable HID_RETRODE
./scripts/config --enable HID_ROCCAT
./scripts/config --enable HID_SAITEK
./scripts/config --enable HID_SAMSUNG
./scripts/config --enable HID_SEMITEK
./scripts/config --enable HID_SIGMAMICRO
./scripts/config --enable HID_SONY
./scripts/config --enable SONY_FF
./scripts/config --enable HID_SPEEDLINK
./scripts/config --enable HID_STEAM
./scripts/config --enable HID_STEELSERIES
./scripts/config --enable HID_SUNPLUS
./scripts/config --enable HID_RMI
./scripts/config --enable HID_GREENASIA
./scripts/config --enable GREENASIA_FF
./scripts/config --enable HID_HYPERV_MOUSE
./scripts/config --enable HID_SMARTJOYPLUS
./scripts/config --enable SMARTJOYPLUS_FF
./scripts/config --enable HID_TIVO
./scripts/config --enable HID_TOPSEED
./scripts/config --enable HID_TOPRE
./scripts/config --enable HID_THINGM
./scripts/config --enable HID_THRUSTMASTER
./scripts/config --enable THRUSTMASTER_FF
./scripts/config --enable HID_UDRAW_PS3
./scripts/config --enable HID_U2FZERO
./scripts/config --enable HID_WACOM
./scripts/config --enable HID_WIIMOTE
./scripts/config --enable HID_XINMO
./scripts/config --enable HID_ZEROPLUS
./scripts/config --enable ZEROPLUS_FF
./scripts/config --enable HID_ZYDACRON
./scripts/config --enable HID_SENSOR_HUB
./scripts/config --enable HID_SENSOR_CUSTOM_SENSOR
./scripts/config --enable HID_ALPS
#./scripts/config --enable HID_MCP2221
    



    ./scripts/config --enable USB_STORAGE
    #./scripts/config --disable CONFIG_USB_STORAGE_DEBUG

./scripts/config --enable CONFIG_USB_STORAGE_REALTEK
./scripts/config --enable CONFIG_USB_STORAGE_DATAFAB
./scripts/config --enable CONFIG_USB_STORAGE_FREECOM
./scripts/config --enable CONFIG_USB_STORAGE_ISD200
./scripts/config --enable CONFIG_USB_STORAGE_USBAT
./scripts/config --enable CONFIG_USB_STORAGE_SDDR09
./scripts/config --enable CONFIG_USB_STORAGE_SDDR55
./scripts/config --enable CONFIG_USB_STORAGE_JUMPSHOT
./scripts/config --enable CONFIG_USB_STORAGE_ALAUDA
./scripts/config --enable CONFIG_USB_STORAGE_ONETOUCH
./scripts/config --enable CONFIG_USB_STORAGE_KARMA
./scripts/config --enable CONFIG_USB_STORAGE_CYPRESS_ATACB
./scripts/config --enable CONFIG_USB_STORAGE_ENE_UB6250
./scripts/config --enable CONFIG_USB_UAS


    

    ./scripts/config --enable CONFIG_NILFS2_FS
    #./scripts/config --enable CONFIG_NTFS_FS
    #./scripts/config --enable CONFIG_NTFS3_FS



    ./scripts/config --enable CONFIG_USB_SERIAL
    ./scripts/config --enable CONFIG_USB_SERIAL_CONSOLE
    ./scripts/config --disable CONFIG_USB_SERIAL_DEBUG

    #cat drivers/usb/serial/Kconfig | grep '^config' | sed 's/config //g' | sed 's/^/\.\/scripts\/config --enable /g'
./scripts/config --enable USB_SERIAL_SIMPLE
./scripts/config --enable USB_SERIAL_AIRCABLE
./scripts/config --enable USB_SERIAL_ARK3116
./scripts/config --enable USB_SERIAL_BELKIN
./scripts/config --enable USB_SERIAL_CH341
./scripts/config --enable USB_SERIAL_WHITEHEAT
./scripts/config --enable USB_SERIAL_DIGI_ACCELEPORT
./scripts/config --enable USB_SERIAL_CP210X
./scripts/config --enable USB_SERIAL_CYPRESS_M8
./scripts/config --enable USB_SERIAL_EMPEG
./scripts/config --enable USB_SERIAL_FTDI_SIO
./scripts/config --enable USB_SERIAL_VISOR
./scripts/config --enable USB_SERIAL_IPAQ
./scripts/config --enable USB_SERIAL_IR
./scripts/config --enable USB_SERIAL_EDGEPORT
./scripts/config --enable USB_SERIAL_EDGEPORT_TI
./scripts/config --enable USB_SERIAL_F81232
./scripts/config --enable USB_SERIAL_F8153X
./scripts/config --enable USB_SERIAL_GARMIN
./scripts/config --enable USB_SERIAL_IPW
./scripts/config --enable USB_SERIAL_IUU
./scripts/config --enable USB_SERIAL_KEYSPAN_PDA
./scripts/config --enable USB_SERIAL_KEYSPAN
./scripts/config --enable USB_SERIAL_KLSI
./scripts/config --enable USB_SERIAL_KOBIL_SCT
./scripts/config --enable USB_SERIAL_MCT_U232
./scripts/config --enable USB_SERIAL_METRO
./scripts/config --enable USB_SERIAL_MOS7720
./scripts/config --enable USB_SERIAL_MOS7715_PARPORT
./scripts/config --enable USB_SERIAL_MOS7840
./scripts/config --enable USB_SERIAL_MXUPORT
./scripts/config --enable USB_SERIAL_NAVMAN
./scripts/config --enable USB_SERIAL_PL2303
./scripts/config --enable USB_SERIAL_OTI6858
./scripts/config --enable USB_SERIAL_QCAUX
./scripts/config --enable USB_SERIAL_QUALCOMM
./scripts/config --enable USB_SERIAL_SPCP8X5
./scripts/config --enable USB_SERIAL_SAFE
./scripts/config --enable USB_SERIAL_SAFE_PADDED
./scripts/config --enable USB_SERIAL_SIERRAWIRELESS
./scripts/config --enable USB_SERIAL_SYMBOL
./scripts/config --enable USB_SERIAL_TI
./scripts/config --enable USB_SERIAL_CYBERJACK
#./scripts/config --enable USB_SERIAL_WWAN
./scripts/config --enable USB_SERIAL_OPTION
./scripts/config --enable USB_SERIAL_OMNINET
./scripts/config --enable USB_SERIAL_OPTICON
./scripts/config --enable USB_SERIAL_XSENS_MT
./scripts/config --enable USB_SERIAL_WISHBONE
./scripts/config --enable USB_SERIAL_SSU100
./scripts/config --enable USB_SERIAL_QT2
./scripts/config --enable USB_SERIAL_UPD78F0730
./scripts/config --enable USB_SERIAL_XR


    make olddefconfig
}


_install_vm-wsl2-kernel-wsl2() {
    _messageNormal 'init: _install_vm-wsl2-kernel-wsl2: guest'
    
    _messagePlain_probe '$1= '"$1"

    #mv "$1" "$1"-$(_uid 14)
    mkdir -p "$1"
    
    git config --global checkout.workers -1
    
    cd "$HOME"/core/infrastructure

    local currentTag
    currentTag=$(git ls-remote --tags https://github.com/microsoft/WSL2-Linux-Kernel.git | cut -f2 | sed "s/refs\/tags\///g" | grep linux-msft-wsl | sort -V -r | head -n1 | tr -dc "a-zA-Z0-9.:\-_")
    
    # Alternative generated by ChatGPT 3.5 2023-08-14 . Discouraged unless git tags are not well maintained.
	# curl -s "https://github.com/microsoft/WSL2-Linux-Kernel/releases" | grep -o '<a href="/microsoft/WSL2-Linux-Kernel/releases/tag/[^"]*' | sed -E 's/.*tag\/([^"]+)/\1/' | sort -V -r

    rmdir WSL2-Linux-Kernel
	git clone --depth 1 --no-checkout --branch "$currentTag" "https://github.com/microsoft/WSL2-Linux-Kernel.git"

    cd WSL2-Linux-Kernel

    # https://stackoverflow.com/questions/3404936/show-which-git-tag-you-are-on
    local currentTag_checkout
    currentTag_checkout=$(git describe --tags --exact-match | tr -dc "a-zA-Z0-9.:\-_")

    local currentTag_isObsolete
    currentTag_isObsolete="true"

    [[ "$currentTag_checkout" == "$currentTag" ]] && currentTag_isObsolete="false"
    

    # https://stackoverflow.com/questions/26617862/git-shallow-fetch-of-a-new-tag
    git fetch --depth 1 origin tag "$currentTag"

    git checkout
    git reset --hard

    _write_kernelConfig_wsl2

    [[ "$currentTag_isObsolete" == "true" ]] && make clean

    local currentProcessors
    currentProcessors=$(nproc)
    [[ "$currentProcessors" -gt "6" ]] && currentProcessors=6
    make -j$(nproc)
    
    cp arch/x86/boot/bzImage "$1"/ubdist-kernel

    local currentOutDirectory
    currentOutDirectory="$1"

    cp ./.config "$currentOutDirectory"/.config
    mkdir -p "$currentOutDirectory"/wsl-source/
    cp -r ./.git "$currentOutDirectory"/wsl-source/.git

    #https://blog-devbug-me.translate.goog/wsl2-kernel-compile/?_x_tr_sl=auto&_x_tr_tl=en&_x_tr_hl=ro&_x_tr_pto=nui
    sudo -n make modules_install

    # Expected unnecessary. Expect '+' will be present from 'uname -r' for installed custom kernel.
    #sudo mv /lib/modules/$(uname -r)+ /lib/modules/$(uname -r)
    # find /lib/modules -mindepth 1 -maxdepth 1 -type d -name '*\+' -exec sh -c 'sudo -n mv "$0" "${0%+}"' {} \;



}
_install_vm-wsl2-kernel() {
    _messageNormal 'init: _install_vm-wsl2-kernel'
    

    wsl --shutdown -d ubdist
    wsl --shutdown
    _write_wslconfig "ub_ignore_kernel_wsl"

    
    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")
    local currentKernelLocationUNIX
    currentKernelLocationUNIX=/cygdrive/c/core/infrastructure/ubdist-kernel
    local currentPreviousKernelID=$(_uid 14)
    [[ -e "$currentKernelLocationUNIX" ]] && mv "$currentKernelLocationUNIX" "$currentKernelLocationUNIX"-"$currentPreviousKernelID"
    mkdir -p "$currentKernelLocationUNIX"
    local currentKernelLocationMSW
    currentKernelLocationMSW=$(cygpath -w "$currentKernelLocationUNIX")

    _messagePlain_probe wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _install_vm-wsl2-kernel-wsl2 "'""$currentKernelLocationMSW""'"
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _install_vm-wsl2-kernel-wsl2 "'""$currentKernelLocationMSW""'"
    echo


    _messageNormal '_install_vm-wsl2-kernel: config: host'
    
    # https://en.linuxportal.info/tutorials/troubleshooting/how-to-clear-the-not-authorized-to-perform-operation-error-message-when-automatically-attaching-USB-flash-drives-and-other-external-USB-storage-devices
    _messagePlain_probe wsl -d "ubdist" sudo -n sed -i 's/auth_admin/yes/g' /usr/share/polkit-1/actions/org.freedesktop.UDisks2.policy
    wsl -d "ubdist" sudo -n sed -i 's/auth_admin/yes/g' /usr/share/polkit-1/actions/org.freedesktop.UDisks2.policy
    _messagePlain_probe wsl -d "ubdist" sudo -n sed -i 's/yes_keep/yes/g' /usr/share/polkit-1/actions/org.freedesktop.UDisks2.policy
    wsl -d "ubdist" sudo -n sed -i 's/yes_keep/yes/g' /usr/share/polkit-1/actions/org.freedesktop.UDisks2.policy

    # https://github.com/dorssel/usbipd-win/discussions/127
    _messagePlain_probe 'echo udev | wsl tee'
    echo 'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0664", GROUP="plugdev", ATTRS{idVendor}=="1050"' | wsl -d "ubdist" sudo -n tee /etc/udev/rules.d/90-fido2-own.rules


    _write_wslconfig

    wsl --shutdown -d ubdist
    wsl --shutdown

    wsl -d ubdist sudo -n /sbin/vboxconfig

    if [[ -e /cygdrive/c/core/infrastructure/ubdist-kernel/ubdist-kernel ]] && [[ -e "$currentKernelLocationUNIX"-"$currentPreviousKernelID" ]]
    then
        # DANGER: Unusual! May delete data from host!
        #_safeRMR "$currentKernelLocationUNIX"-"$currentPreviousKernelID"
        if [[ ! -e "$currentKernelLocationUNIX"-"$currentPreviousKernelID" ]] || [[ "$currentKernelLocationUNIX" == "" ]] || [[ "$currentPreviousKernelID" == "" ]]
        then
            _messagePlain_bad 'fail: rm: missing: '"$currentKernelLocationUNIX"-"$currentPreviousKernelID"
            _messageFAIL
            _stop 1
        fi
        rm -rf "$currentKernelLocationUNIX"-"$currentPreviousKernelID"
    fi
    return 0
}



_install_vm-wsl2-portForward() {
    local current_wsldist
    current_wsldist="$1"
    [[ "$current_wsldist" == "" ]] && current_wsldist="ubdist"

    if ! wsl -d "$current_wsldist" echo available | grep available > /dev/null 2>&1
    then
        _messagePlain_warn 'warn: _install_vm-wsl2-portForward: wsl: '"$current_wsldist"': missing'
        #_messageFAIL
        #_stop 1
        return 1
    fi

    local current_wsl_scriptAbsoluteLocation
    current_wsl_scriptAbsoluteLocation=$(cygpath -m "$scriptAbsoluteLocation")
    current_wsl_scriptAbsoluteLocation=$(wsl -d "$current_wsldist" wslpath "$current_wsl_scriptAbsoluteLocation")

    local current_wsl_scriptAbsoluteFolder
    current_wsl_scriptAbsoluteFolder=$(cygpath -m "$scriptAbsoluteFolder")
    current_wsl_scriptAbsoluteFolder=$(wsl -d "$current_wsldist" wslpath "$current_wsl_scriptAbsoluteFolder")

    if [[ "$2" != "notBooting" ]] && [[ "$2" != "bootingAdmin" ]] && [[ "$2" != "notBootingAdmin" ]]
    then
        _messageNormal '_install_vm-wsl2-portForward: booting'

        # TODO: Possibly enable this, if it will not keep the installer from closing and will not close ollama with the installer.
        ( nohup ollama ls > /dev/null 2>&1 & disown -r "$!" ) > /dev/null
        sleep 7
        echo .
        #-Wait
        _powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/C','$scriptAbsoluteFolder_msw\_bin.bat','_install_vm-wsl2-portForward','$current_wsldist','bootingAdmin' -Verb RunAs"
        echo .
        
        return 0
        exit 0
    fi
    
    if [[ "$2" == "bootingAdmin" ]]
    then
        _messageNormal '_install_vm-wsl2-portForward: bootingAdmin'
        
        local currentIteration
        echo
        currentIteration=0
        for (( currentIteration=0; currentIteration<25; currentIteration++ ))
        do
            echo -n .
            sleep 1
        done
        echo

        wsl -d "ubdist" sudo -n systemctl stop hostport-proxy.service
        wsl -d "ubdist" sudo -n systemctl disable hostport-proxy.service
        wsl -d "ubdist" sudo -n systemctl stop ollama.service
        wsl -d "ubdist" sudo -n systemctl disable ollama.service


        ( nohup ollama ls > /dev/null 2>&1 & disown -r "$!" ) > /dev/null


        echo
        currentIteration=0
        for (( currentIteration=0; currentIteration<10; currentIteration++ ))
        do
            echo -n .
            sleep 1
        done
        echo

        
        ( nohup ollama ls > /dev/null 2>&1 & disown -r "$!" ) > /dev/null


        echo
        currentIteration=0
        for (( currentIteration=0; currentIteration<5; currentIteration++ ))
        do
            echo -n .
            sleep 1
        done
        echo


        #return 0
        #exit 0
    fi
    
    if [[ "$2" == "notBootingAdmin" ]]
    then
        _messageNormal '_install_vm-wsl2-portForward: notBootingAdmin'
        
        local currentIteration
        echo
        currentIteration=0
        for (( currentIteration=0; currentIteration<1; currentIteration++ ))
        do
            echo -n .
            sleep 1
        done
        echo

        wsl -d "ubdist" sudo -n systemctl stop hostport-proxy.service
        wsl -d "ubdist" sudo -n systemctl disable hostport-proxy.service
        wsl -d "ubdist" sudo -n systemctl stop ollama.service
        wsl -d "ubdist" sudo -n systemctl disable ollama.service


        ( nohup ollama ls > /dev/null 2>&1 & disown -r "$!" ) > /dev/null


        echo
        currentIteration=0
        for (( currentIteration=0; currentIteration<1; currentIteration++ ))
        do
            echo -n .
            sleep 1
        done
        echo

        
        ( nohup ollama ls > /dev/null 2>&1 & disown -r "$!" ) > /dev/null


        echo
        currentIteration=0
        for (( currentIteration=0; currentIteration<5; currentIteration++ ))
        do
            echo -n .
            sleep 1
        done
        echo


        #return 0
        #exit 0
    fi

    _setup_wsl2_procedure-fw

    _setup_wsl2_procedure-portproxy "$current_wsldist"

    _setup_wsl2_guest-portForward "$current_wsldist"
}


_import_wsl2-sshid-wsl2() {
    local currentExitStatus

    cd "$1"
    _messagePlain_probe_var PWD
    _messagePlain_probe cp "$1"/id_'*' "$HOME"/.ssh/
    cp "$1"/id_* "$HOME"/.ssh/
    currentExitStatus="$?"

    chmod 600 "$HOME"/.ssh/id_*
    chmod 755 "$HOME"/.ssh/id_*.pub

    return "$currentExitStatus"
}
_export_wsl2-sshid-wsl2() {
    chmod 600 "$HOME"/.ssh/id_*
    chmod 755 "$HOME"/.ssh/id_*.pub

    local currentExitStatus

    cd "$1"
    _messagePlain_probe_var PWD
    _messagePlain_probe cp --preserve=all "$HOME"/.ssh/id_'*' ./
    cp --preserve=all "$HOME"/.ssh/id_* ./
    currentExitStatus="$?"

    chmod 600 "$1"/id_*
    chmod 755 "$1"/id_*.pub
    chmod 600 "$HOME"/.ssh/id_*
    chmod 755 "$HOME"/.ssh/id_*.pub

    return "$currentExitStatus"
}
_import_wsl2-gitconfig-wsl2() {
    local currentExitStatus

    cd "$1"
    _messagePlain_probe_var PWD
    _messagePlain_probe cp "$1"/.gitconfig "$HOME"/
    cp "$1"/.gitconfig "$HOME"/
    currentExitStatus="$?"

    chmod 600 "$HOME"/.gitconfig
    chmod 755 "$HOME"/.gitconfig

    return "$currentExitStatus"
}
_export_wsl2-gitconfig-wsl2() {
    chmod 600 "$HOME"/.gitconfig
    chmod 755 "$HOME"/.gitconfig

    local currentExitStatus

    cd "$1"
    _messagePlain_probe_var PWD
    _messagePlain_probe cp --preserve=all "$HOME"/.gitconfig ./
    cp --preserve=all "$HOME"/.gitconfig ./
    currentExitStatus="$?"

    chmod 600 "$1"/.gitconfig
    chmod 755 "$1"/.gitconfig
    chmod 600 "$HOME"/.gitconfig
    chmod 755 "$HOME"/.gitconfig

    return "$currentExitStatus"
}
_sshid-import-wsl2() {
    ! _if_cygwin && return 1
    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")

    local current_ssh_UNIX
    current_ssh_UNIX="/cygdrive/c/core/infrastructure/ubcp/cygwin/home/root/.ssh"
    mkdir -p "$current_ssh_UNIX"
    chmod 600 "$current_ssh_UNIX"
    [[ ! -e "$current_ssh_UNIX" ]] && return 1
    local current_ssh_MSW
    current_ssh_MSW=$(cygpath -w "$current_ssh_UNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _import_wsl2-sshid-wsl2 "'""$current_ssh_MSW""'"

    local current_gitconfig_UNIX
    current_gitconfig_UNIX="/cygdrive/c/core/infrastructure/ubcp/cygwin/home/root"
    mkdir -p "$current_gitconfig_UNIX"
    chmod 600 "$current_gitconfig_UNIX"
    [[ ! -e "$current_gitconfig_UNIX" ]] && return 1
    local current_gitconfig_MSW
    current_gitconfig_MSW=$(cygpath -w "$current_gitconfig_UNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _import_wsl2-gitconfig-wsl2 "'""$current_gitconfig_MSW""'"
}
_sshid-export-wsl2() {
    ! _if_cygwin && return 1
    local currentScriptAbsoluteLocationMSW
    currentScriptAbsoluteLocationMSW=$(cygpath -w "$scriptAbsoluteLocation")

    local currentExitStatus

    local current_ssh_UNIX
    current_ssh_UNIX="/cygdrive/c/core/infrastructure/ubcp/cygwin/home/root/.ssh"
    mkdir -p "$current_ssh_UNIX"
    chmod 600 "$current_ssh_UNIX"
    [[ ! -e "$current_ssh_UNIX" ]] && return 1
    local current_ssh_MSW
    current_ssh_MSW=$(cygpath -w "$current_ssh_UNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _export_wsl2-sshid-wsl2 "'""$current_ssh_MSW""'"
    currentExitStatus="$?"

    local current_gitconfig_UNIX
    current_gitconfig_UNIX="/cygdrive/c/core/infrastructure/ubcp/cygwin/home/root"
    mkdir -p "$current_gitconfig_UNIX"
    chmod 600 "$current_gitconfig_UNIX"
    [[ ! -e "$current_gitconfig_UNIX" ]] && return 1
    local current_gitconfig_MSW
    current_gitconfig_MSW=$(cygpath -w "$current_gitconfig_UNIX")
    wsl -d "ubdist" '~/.ubcore/ubiquitous_bash/ubiquitous_bash.sh' '_wrap' "'""$currentScriptAbsoluteLocationMSW""'" _export_wsl2-gitconfig-wsl2 "'""$current_gitconfig_MSW""'"
    ( [[ "$?" != "0" ]] || [[ "$currentExitStatus" != "0" ]] ) && currentExitStatus=1

    #_messagePlain_probe chmod 600 "$current_ssh_UNIX"/id_'*'
    chmod 600 "$current_ssh_UNIX"/id_*
    chmod 755 "$current_ssh_UNIX"/id_*.pub

    # Permissions apparently are NOT usable through 'cygdrive' .
    _messagePlain_probe chmod 600 "$HOME"/.ssh/id_'*'
    chmod 600 "$HOME"/.ssh/id_*
    chmod 755 "$HOME"/.ssh/id_*.pub

    # WARNING: Setting permissions through MSW, isntead of from within Cygwin itself, may result incorrectly set permissions too open.
    # Other commands to set 'chmod 600' may in fact have had the opposite effect.
    '/cygdrive/c/core/infrastructure/ubiquitous_bash/_bin.bat' chmod 600 /home/root/.ssh/id_*
    '/cygdrive/c/core/infrastructure/ubiquitous_bash/_bin.bat' chmod 755 /home/root/.ssh/id_*.pub

    return "$currentExitStatus"
}









