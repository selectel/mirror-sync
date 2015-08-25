#!/bin/bash

# Checks if remote file/dir exists
rsync_file_exists()
{
    /usr/bin/rsync --no-motd --list-only "${UPSTREAM}::${UPSTREAM_DIR}/$1"  &> /dev/null
    return $?
}

# Fetches list of files from remote rsync repo by given mask
# $1 -- file mask
rsync_ls()
{
    local to_return=()
    local mask="$1"

    files=`/usr/bin/rsync --no-motd --list-only \
        --relative --recursive --no-implied-dirs \
        --perms --links --times --hard-links --sparse --safe-links \
        "${UPSTREAM}::${UPSTREAM_DIR}/$mask" | \
        grep -v "^d" |  sed -e "s/->.*//g" | awk '{$1=$2=$3=$4=""}1'`

    for file in $files; do
        to_return+=( "$file" )
    done

    echo "${to_return[@]}"
    return 0
}

# Rsync wrapper function
fetch()
{
    src_path="$1"
    dst_path="$2"
    shift; shift
    opt_args=( $* )

    # Create a dest dir if needed
    dst_dir=`dirname $dst_path`
    [[ -d "$dst_dir" ]] || mkdir -p "$dst_dir"

    debug_job_start "Fetching '$src_path' to '$dst_path' with params '${opt_args[@]}'"
    /usr/bin/rsync --no-motd --perms --links --times --hard-links --sparse --safe-links \
        ${opt_args[@]} \
        "${UPSTREAM}::${UPSTREAM_DIR}/$src_path" "$dst_path"
    local rsync_ec="$?"
    if [[ $rsync_ec = 0 ]]; then
        debug_job_ok
    else
        debug_job_err
    fi
    return $rsync_ec
}

# Fetches all files to specified root
# $1 -- Local root, where all files will be stored by it's relative path
# $* -- Files to fetch
fetch_all()
{
    local root="$1"; shift
    local fetched=()
    local rsync_out=""
    
    # New and fast
    rsync_out=` echo $* | tr ' ' '\n' | \
        rsync --no-motd --relative --out-format='%n' --files-from=- \
        --no-implied-dirs --no-motd \
        --perms --links --times --hard-links --sparse \
        "${UPSTREAM}::${UPSTREAM_DIR}/" "$root" 2> /dev/null`
    for line in $rsync_out; do
        debug "Fetched file $LOCAL_DIR/$line"
        fetched+=( "$LOCAL_DIR/$line" )
    done
    echo ${fetched[@]}

    # Old slow and deprecated
    #local fetched=()
    #for file in $*; do
    #    fetch "$file" "$LOCAL_DIR/$file"
    #    if [[ $? = 0 ]]; then
    #        fetched+=( "$LOCAL_DIR/$file" )
    #    fi
    #done
    #echo ${fetched[@]}
}
