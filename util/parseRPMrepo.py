#!/usr/bin/python
# This script parses RPM repos

import os
import sys
import hashlib

from xml.etree.ElementTree import ElementTree
from xml.etree.ElementTree import dump 

XMLREPONS = "{http://linux.duke.edu/metadata/repo}"
XMLPKGNS = "{http://linux.duke.edu/metadata/common}"

def check_file(filepath, checksumtype, checksum):
    filechecksum = ""
    if checksumtype == "sha":
        filechecksum = hashlib.sha1(''.join(open(filepath).readlines())).hexdigest()
    elif checksumtype == "sha256":
        filechecksum = hashlib.sha256(''.join(open(filepath).readlines())).hexdigest()

    if filechecksum == checksum:
        return True
    return False

def parse_repomd(repo):
    filename = os.path.join(repo, "repodata", "repomd.xml")
    toret = {}

    tree = ElementTree()
    tree.parse(open(filename, 'r'))

    for data in tree.findall(XMLREPONS+"data"):
        filetype = data.get('type')
        f_location = data.find(XMLREPONS+"location")
        if f_location is not None:
            filepath = f_location.get('href')
        else: raise TypeError("Bad repomd: Failed to get location of '" + filetype + "'")

        # Check checksum for file
        f_checksum = data.find(XMLREPONS+"checksum")
        if f_checksum is not None:
            checksumtype = f_checksum.get('type')
            checksum = f_checksum.text
        if not check_file(os.path.join(repo, filepath), checksumtype, checksum):
            raise TypeError("Bad repo: Wrong checksum for file '" + os.path.join(repo, filepath) + "', expected '" + checksum + "'")

        # Append file info
        toret[filetype] = filepath
    return toret

for repo in sys.argv[1:]:
    repofiles = parse_repomd(repo)

    # Check primary database
    pkgfile = os.path.join(repo, repofiles["primary"])
    if pkgfile.endswith(".gz"):
        import gzip
        file = gzip.open(pkgfile)
    elif pkgfile.endswith(".bz2"):
        import bz2
        file = bz2.BZ2File(pkgfile)
    else:
        file = open(pkgfile)

    tree = ElementTree()
    tree.parse(file)
    #for i in tree.iter():
    #    print i.tag

    for package in tree.findall(XMLPKGNS+"package"):
        location = package.find(XMLPKGNS+"location").get("href")
        checksum = package.find(XMLPKGNS+"checksum").text
        checksum_type = package.find(XMLPKGNS+"checksum").get("type")
        sys.stdout.write(location+"\n")
        sys.stderr.write(checksum_type+" "+checksum+" "+location+"\n")
            
    #for location in tree.findall(XMLPKGNS+"package/"+XMLPKGNS+"location"):
    #    print("/"+location.get("href"))


