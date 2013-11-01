Mirror-sync
===========

Script set for partial rpm/deb repositories mirroring with sanity check.

# Description

WARNING: This script set is not designed to be used on 'live' repositories
(ones that available to clients during synchronization). It violates
common synchronization order(packages first, metadata later) to provide
partial mirroring capability. It means that repositories will be
inconsistent during the update. Please use those scripts in conjunction
with snapshots, on inactive repos or something like that.

Only rsync mirrors are supported.

There are currently three mirroring scripts, all of them take path to
config file as a first argument.
* **rpm-mirror** - script for mirroring RPM repositories
* **deb-mirror** - script for mirroring DEB repositories
* **arch-mirror** - script for mirroring Archlinux repositories

You can see some config examples at the config/ directory.

# Installation

Clone this repo to preferable location, for example /opt/mirror-sync:
 
    cd /opt
    git clone https://github.com/selectel/mirror-sync.git mirror-sync
 
Create user for running mirroring scripts:

    adduser --no-create-home --home /opt/mirror-sync mirror
    
Create repository storage, for example at /srv/www/mirror and give 
ownership to mirror user:

    mkdir -p /srv/www/mirror/{debian,centos}
    chown -R mirror:mirror /srv/www/mirror
    
Optionally create log directory:
    
    mkdir -p /var/log/mirror-sync
    chown -R mirror:mirror /var/log/mirror-sync
    
Create/edit configuration files for required repositories:

    vim /opt/mirror-sync/config/centos.cfg
    vim /opt/mirror-sync/config/debian.cfg
    
Now you can start synchronization of desired repository like that:

    /opt/mirror-sync/rpm-mirror /opt/mirror-sync/config/centos.cfg
    
or:

    /opt/mirror-sync/deb-mirror /opt/mirror-sync/config/debian.cfg
    
