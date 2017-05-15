#!/bin/bash

LOGS_FOLDER="$HOME/collect-logs"

set -e
main() {
# prepare folder
    cd $LOGS_FOLDER
    [ ! -d ".git" ] && git init
    git clean -x -d -f
    git checkout .
    cd $OLDPWD

# call log collector one by one.
    lspci -vvvnn > "$LOGS_FOLDER/lspci-vvvnn.log"
    lsusb -v > "$LOGS_FOLDER/lsusb-v.log"
    dmesg > "$LOGS_FOLDER/dmesg.log"
    lsmod > "$LOGS_FOLDER/lsmod.log"
    dkms status > "$LOGS_FOLDER/dkms-status.log"
    rfkill list > "$LOGS_FOLDER/rfkill-l.log"
    hciconfig > "$LOGS_FOLDER/hciconfig.log"
    udevadm info -e > "$LOGS_FOLDER/udevadm-info-e.log"
    uname -a > "$LOGS_FOLDER/uname-a.log"
    uname -a > "$LOGS_FOLDER/uname-a.log"

    get_bios_info
    get_audio_logs
    get_nvidia_logs
    get_wwan_card_logs
    get_network_manager_logs
    get_manifest_from_recovery || true
    get_xinput_logs
    get_system_logs

    dpkg -l > "$LOGS_FOLDER/dpkg-l.log"
    ps -ef > "$LOGS_FOLDER/ps-ef.log"

# commit logs.
    cd $LOGS_FOLDER
    git add .
    git commit -m "$(git status)"
#    tar Jcvf "$LOGS_FOLDER.tar.xz $LOGS_FOLDER"
#    echo "all logs are in $LOGS_FOLDER.tar.xz "
}

get_bios_info() {
#    local bios_logs_folder=$LOGS_FOLDER/bios
#    mkdir -p "$bios_logs_folder"
#    sudo dmidecode > "$bios_logs_folder/dmidecode.log"
    sudo dmidecode > "$LOGS_FOLDER/dmidecode.log"
    [[ ! -x $(which acpidump) ]] && sudo apt-get install -y acpidump
    sudo acpidump > "$LOGS_FOLDER/acpi.log"
}

get_audio_logs() {
    [[ -e $(which alsa-info.sh) ]] && alsa-info.sh --stdout > "$LOGS_FOLDER/alsa-info.log" || true
}

get_nvidia_logs() {
    [[ -x $(which nvidia-bug-report.sh) ]] && sudo nvidia-bug-report.sh --output-file "$LOGS_FOLDER/nvidia-bug-report" || true
}

get_network_manager_logs() {
    nmcli dev > "$LOGS_FOLDER/nmcli-dev.log"
    nmcli co > "$LOGS_FOLDER/nmcli-co.log"
    # [TODO]
    # http://manpages.ubuntu.com/manpages/precise/man5/NetworkManager.conf.5.html
    # or there should be a way to raise debug level by send dbus message.

}

get_wwan_card_logs() {
    # check firmware version
    [[ -e /dev/cdc-wdm0 ]] && mbimcli -d /dev/cdc-wdm0 --query-device-caps --verbose > "$LOGS_FOLDER/mbimcli-d-cdc-wdm0.log" || true
}

get_manifest_from_recovery() {
    mount | grep "\/ type ext4" | grep sda
    if [[ $? == 0 ]]; then
        sudo mount /dev/sda2 /mnt
    else
        sudo mount /dev/nvme0n1p2 /mnt
    fi
    cp /mnt/bto.xml "$LOGS_FOLDER"
    sudo umount /mnt
    # check mount | grep "\/ type ext4" to know if currently use sda or nvme?
    # mount /dev/${recovery-partition} /mnt | cat /mnt/bto.xml
}

get_system_logs() {
    find /var/log/syslog | cpio -p --make-directories $LOGS_FOLDER
    find /var/log/Xorg.0.log | cpio -p --make-directories $LOGS_FOLDER
    journalctl > "$LOGS_FOLDER/journalctl.log"
}


get_xinput_logs() {
    xinput > "$LOGS_FOLDER/xinput.log"
}


__ScriptVersion="0.1"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
usage ()
{
    echo "Usage :  $0 [options] [--]

    This command is used to collect all logs which could be used to identify what the issues is.

    Options:
    -h|help       Display this message
    -v|version    Display script version"

}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hv" opt
do
  case $opt in

    h|help     )  usage; exit 0   ;;

    v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;

    * )  echo -e "\n  Option does not exist : $OPTARG\n"
          usage; exit 1   ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    mkdir -p $LOGS_FOLDER
    exec > >(tee -i $LOGS_FOLDER/collect-logs.log)
    main "$@"

fi

