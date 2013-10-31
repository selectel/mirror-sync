#!/bin/bash

MIRRORROOT="/srv/www/mirror"
SCRIPTROOT=`dirname $(readlink -f $0)`

to_update=( $* )
to_switch=()

is_scheduled()
{
    echo "${to_update[@]}" | grep -i "$1" &> /dev/null
    return $?
}

################################################################################
# Update Debian
################################################################################
if is_scheduled "debian"; then
    if $SCRIPTROOT/deb-mirror "$SCRIPTROOT/config/debian.cfg"; then
        to_switch+=( "debian" )
    else
        echo Failed to update Debian mirror, skipping...
    fi
fi

################################################################################
# Update Ubuntu
################################################################################
if is_scheduled "ubuntu"; then
    if $SCRIPTROOT/deb-mirror "$SCRIPTROOT/config/ubuntu.cfg"; then
        to_switch+=( "ubuntu" )
    else
        echo Failed to update Ubuntu mirror, skipping...
    fi
fi

################################################################################
# Update Archlinux
################################################################################
if is_scheduled "archlinux"; then
    if $SCRIPTROOT/arch-mirror "$SCRIPTROOT/config/archlinux.cfg"; then
        to_switch+=( "archlinux" )
    else
        echo Failed to update archlinux mirror, skipping...
    fi
fi

################################################################################
# Update CentOS
################################################################################
if is_scheduled "centos"; then
    if $SCRIPTROOT/rpm-mirror "$SCRIPTROOT/config/centos.cfg"; then
        to_switch+=( "centos" )
    else
        echo Failed to update Centos mirror, skipping...
    fi
fi

################################################################################
# Update Opensuse
################################################################################
if is_scheduled "opensuse"; then
    if $SCRIPTROOT/rpm-mirror "$SCRIPTROOT/config/opensuse.cfg"; then
        to_switch+=( "opensuse" )
    else
        echo Failed to update OpenSUSE mirror, skipping...
    fi
fi

################################################################################
# Update epel
################################################################################
if is_scheduled "epel"; then
    if $SCRIPTROOT/rpm-mirror "$SCRIPTROOT/config/epel.cfg"; then
        to_switch+=( "epel" )
    else
        echo Failed to update EPEL mirror, skipping...
    fi
fi

################################################################################
# Update fedora
################################################################################
if is_scheduled "fedora"; then
    if $SCRIPTROOT/rpm-mirror "$SCRIPTROOT/config/fedora.cfg"; then
        to_switch+=( "fedora" )
    else
        echo Failed to update fedora mirror, skipping...
    fi
fi

################################################################################
# Switch repos
################################################################################
if [[ ${#to_switch[@]} != 0 ]]; then
    if ! $SCRIPTROOT/switch-repos "$MIRRORROOT" ${to_switch[@]}; then
        echo Failed to switch mirrors ${to_switch[@]}, aborting
        exit 5
    fi
fi

################################################################################
# Sync fg -> bg
################################################################################
for repo in ${to_switch[@]}; do
    rsync --quiet -a --delete --delete-after \
        "$MIRRORROOT/$repo/${repo}_fg"/* "$MIRRORROOT/$repo/${repo}_bg"
done
