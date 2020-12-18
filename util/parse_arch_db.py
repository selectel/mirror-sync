#!/usr/bin/python3
# This script parses contents of given archlinux DB files, and creates rsync
# command line to synchronize mirror

import os
import sys

import tarfile

# STEPS
# 1) Determine compression of file
# 2) Open Tar
# 3) Walk dirs in tar

# Regex to parse 
cur_root = os.path.dirname(os.path.realpath(sys.argv[0]))
    
for pkgfile in sys.argv[1:]:
    if pkgfile.endswith(".gz"):
        file = tarfile.open(name=pkgfile, mode="r:gz")
    elif pkgfile.endswith(".bz2"):
        file = tarfile.open(name=pkgfile, mode="r:bz2")
    else:
        file = tarfile.open(name=pkgfile, mode="r:")

    repo_root = os.path.dirname(os.path.realpath(pkgfile))

    # Walk all dirs
    for pkg in file:
        if pkg.isdir():
            descpath = os.path.join(pkg.name, "desc")
            descmember = file.getmember(descpath)
            desc = file.extractfile(descmember).readlines()

            filename = ""
            has_sig = False
            md5sum = ""
            for i in range(0, len(desc)):
                d = desc[i].decode('utf-8')
                if d.startswith('%FILENAME%'):
                    filename = os.path.realpath(os.path.join(repo_root,
                                                             desc[i+1].decode('utf-8').strip("\n")))
                if d.startswith('%MD5SUM%'):
                    md5sum = desc[i+1].decode('utf-8').strip("\n")
                if d.startswith('%PGPSIG%'):
                    has_sig = True

            if filename:
                sys.stdout.write(filename + "\n")
                sys.stderr.write("MD5 " + md5sum + " " + filename + "\n")
                if has_sig:
                    sys.stdout.write(filename + ".sig\n")
