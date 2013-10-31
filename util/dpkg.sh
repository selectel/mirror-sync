#!/bin/bash

# Guess filename based on POSSIBLE_COMPRESSIONS variable
# It will cycle through filenames (myname myname.gz myname.bz2 myname.xz etc...)
# and return first match that exists in the filesystem
# $1 -- base filename
guess_filename()
{
    local to_return=""
    local file="$1"

    #debug "Guessing filename for $file"
    if [[ ! -f "$file" ]]; then
        for ext in ${POSSIBLE_COMPRESSIONS[@]}; do
            if [[ -f "$file.$ext" ]]; then
                #debug "Got match $file.$ext"
                to_return="$file.$ext"
                break
            fi
        done
    else
        to_return="$file"
    fi
    echo "$to_return"
}

# Determines if file is compressed, and uncompresses into stdout
# $1 -- file too cat
# $2=false -- Try to guess filename 
read_file()
{
    local file="$1"
    local try_to_guess="${2:-'false'}"
    if [[ ! -f "$file" ]]; then 
        if [[ "$try_to_guess" = "false" ]]; then
            return
        else
            file=`guess_filename "$file"`
            [[ -f "$file" ]] || return
        fi
    fi

    case `file "$file"` in
        *gzip*)
            # We got a GZip
            zcat "$file"
            return;;
        *bzip2*)
            # We got a BZip2
            bzcat "$file"
            return;;
        *XZ*)
            # We got a XZ
            xzcat "$file"
            return;;
        *text*)
            # Must be a plain text
            cat "$file"
            return;;
    esac
}

# Gets distro components from Release file
# $1 -- path to Release file
# $2 -- user component list
get_dist_components()
{
    local dist_components=( `read_file "$1"| egrep "^Components: "| cut -d' ' -f'2-'` )
    local user_components=${2:-""}
    local to_return=""

    if [[ -z "$user_components" ]]; then
        echo "$dist_components"
    elif [[ -z $dist_components ]]; then
        echo "$user_components"
    else
        for ucomp in $user_components; do
            if contains "$ucomp" "${dist_components[@]}"; then
                to_return="${to_return} $ucomp"
            fi
        done
    fi
    echo $to_return
}

# Gets distro arches from Release file
# $1 -- path to Release file
# $2 -- user arch list
get_dist_architectures()
{
    local dist_arches=( `read_file "$1"| egrep "^Architectures: "| cut -d' ' -f'2-'` )
    local user_arches=( $* )
    local to_return=""
    # Filter out arches that not listed in 'ARCHs' global variable 
    for arch in ${user_arches[@]}; do
        if contains "$arch" "${dist_arches[@]}"; then
            to_return="${to_return} $arch"
        fi

        # Special case architecture that is not included in Release arches list
        if [[ "$arch" = "all" ]]; then
            to_return="${to_return} $arch"
        fi
    done
    echo $to_return
}

# Checks dist file validity
# $1 -- Full path to release file
# $2 -- Relative path to target file from the repository root
pkg_file_valid()
{
    local release="$1"
    local pkg="$2"

    # Check if release file has an md5sum section, if not then just return OK
    if ! egrep -i '^MD5Sum:\s*$' $release &> /dev/null; then
        debug "Release file '$release' doesn't contain MD5 info"
        return 0
    fi

    # Get distro basedir
    local dist_base=`dirname "$release"`
    local pkg_path="$dist_base/$pkg"


    local pkg_line=`cat "$release" | egrep -i "^ [0-9a-f]{32}\s+[0-9]+\s+$pkg\s*$"`

    # Check if we found files md5 string. if not return all ok
    # TODO: make option to raise error on missing md5sum
    if [[ -z "$pkg_line" ]]; then
        error "Can't find md5sum for '$pkg' in '$release', skipping"
        return 0
    fi

    # Get line with MD5SUM for current package
    local expected_md5sum=`echo "$pkg_line" | awk '{print $1}'`
    local expected_size=`echo "$pkg_line" | awk '{print $2}'`

    # Check file validity if it's not found just empty vars
    local size=`stat -c%s "$pkg_path"`
    local md5sum=`md5sum "$pkg_path"| awk '{print $1}'`

    if  [[ -e $pkg_path ]] && \
        [[ $size = $expected_size ]] && \
        [[ $md5sum =  $expected_md5sum ]]; then
        debug "File '$pkg' checked by '$release' is OK"
        return 0
    fi
    error "File '$pkg_path' checked by '$release' is BAD"
    debug "File details:"
    debug "size = $size, expected $expected_size"
    debug "md5sum = $md5sum, expected $expected_md5sum"
    return 1
}

# DEPRECATED
parse_pkg_file()
{
    local file="$1"
    local to_return=()

    local line
    declare -A entry

    read_file "$file" | \
    while read line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        param=${line%%:*}
        entry[$param]=#${line#*: }
        #    #echo "${entry[md5sum]} ${entry[size]} ${entry[filename]}"
        #    entry=()
    done
}
