#!/usr/bin/python3
# This script parses contents of given 'Package' files, and creates rsync
# command line to synchronize mirror

import re
import sys

# Regex to parse 
regex = re.compile("^(?P<param>[a-z0-9]+): (?P<value>.*)$", re.IGNORECASE)

for pkgfile in sys.argv[1:]:
    if pkgfile.endswith(".gz"):
        import gzip

        file = gzip.open(pkgfile)
    elif pkgfile.endswith(".bz2"):
        import bz2

        file = bz2.BZ2File(pkgfile)
    else:
        file = open(pkgfile)

    # Current package 
    pkg = {}

    for line in file:
        # If we have a blank line - it's means that we're on package separator
        # Print the information about current package and clear current package info
        if line == "\n":
            sys.stdout.write(f"{pkg['filename']}\n")
            if "md5sum" in pkg:
                sys.stderr.write(f"MD5 {pkg['md5sum']} {pkg['filename']}\n")
            pkg = {}

        m = regex.match(line)
        if m:
            pkg[m.group("param").lower()] = m.group("value")
