check_file()
{   
    checksum_file=$1
    root=$2
    file_to_check=$3


    debug_job_start "Checking checksum of file '$root/$file_to_check'"
    file_records=`grep "$file_to_check" "$checksum_file" | sort -u`
    IFS='
'

    [[ -z "$file_records" ]] && echo -n "checksums not found..." \
        && debug_job_skip && return 0

    for file_record in $file_records; do
        expected_checksum_type=`echo $file_record | awk '{print $1}'`
        expected_checksum=`echo $file_record | awk '{print $2}'`


    	shopt -s nocasematch
        if [[ $expected_checksum_type == "MD5" ]]; then
            echo -n "MD5..."
            actual_checksum=`md5sum "$root/$file_to_check" | head -c 32`
        elif [[ $expected_checksum_type == "SHA1" ]] || [[ $expected_checksum_type == "SHA" ]]; then
            echo -n "SHA1..."
            actual_checksum=`sha1sum "$root/$file_to_check" | head -c 40`
        elif [[ $expected_checksum_type == "SHA256" ]]; then
            echo -n "SHA256..."
            actual_checksum=`sha256sum "$root/$file_to_check" | head -c 64`
        fi
    	shopt -u nocasematch

        [[ "$expected_checksum" != "$actual_checksum" ]] && debug_job_err && return 1
    done
    debug_job_ok
    return 0
}
