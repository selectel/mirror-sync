#!/bin/bash
# Generic message display and job-contol

DEBUG=${DEBUG:-"no"}
QUIET=${QUIET:-"no"}

# If no LOG_FILE set, discard log output
LOG_FILE=${LOG_FILE:-"/dev/null"} 

################################################################################
# Magic FD manipulations
################################################################################
# Log file wrapper function, reads stdin line by line and timestamps each line,
# also filters terminal colors
_log()
{
    while IFS='' read -r line; do
        echo "$(date) $line" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" >> "$LOG_FILE"
    done
}

# Set FD 5 -- main output FD
# Split it's output out helper '_log' function and stdout
# If QUIET is set - suppress console output
if [[ "$QUIET" = "yes" ]]; then
    exec 5> >(tee -a >(_log) > /dev/null)
else
    exec 5> >(tee -a >(_log))
fi

# Supress child's outputs if DEBUG set to 'no', append to main FD otherwise
if [[ "$DEBUG" = "no" ]]; then
    exec 1>/dev/null
    exec 2>/dev/null
else
    exec 1>&5
    exec 2>&5
fi

# FD 3 -- Pretty messages FD
# Prettyfied messages for user sent here
# By default send it's output to main FD
exec 3>&5

################################################################################
# Simple messaging functions
################################################################################
msgs_errors=()

msg()
{
    echo " * $*" 1>&3
}
debug()
{
    [[ "$DEBUG" = "yes" ]] && msg "DEBUG: $*"
}
info()
{
    msg "INFO: $*"
}
error()
{
    msg "ERROR: $*"
    msgs_errors+=( "$*" )
}
fatal()
{
    msg "FATAL: $1"
    ([ ! -z $2 ] && exit $2) || exit 1
}


################################################################################
# Job control functions
################################################################################
msgs_jobname=""

job_start()
{
    msgs_jobname="$1"
    echo -ne "$msgs_jobname..." 1>&3
    #logger -t "$TAG" "$msgs_jobname"
}
job_ok()
{
    echo -e "\e[0;32mOK\e[0m" 1>&3
    #logger -t "$TAG" "$msgs_jobname... OK !"
}
job_err()
{
    echo -e "\e[0;31mFAIL!\e[0m" 1>&3
    #logger -t "$TAG" "$msgs_jobname... FAILED !"
    errors="${errors}$msgs_jobname have failed\n"
}
job_skip()
{
    echo -e "\e[0;33mSKIPPED!!\e[0m" 1>&3
    #logger -t "$TAG" "$msgs_jobname... SKIPPED !"
}
debug_job_start()
{
    [[ "$DEBUG" = "yes" ]] && job_start "$*"
}
debug_job_ok()
{
    [[ "$DEBUG" = "yes" ]] && job_ok
}
debug_job_err()
{
    [[ "$DEBUG" = "yes" ]] && job_err
}
debug_job_skip()
{
    [[ "$DEBUG" = "yes" ]] && job_skip
}
