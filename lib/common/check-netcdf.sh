#!/bin/bash

#############################
# NETCDF CHECKING FUNCTIONS #
#############################

export NETCDF_CHECKER=/usr/local/bin/netcdf-checker

# a wrapper to run the netcdf checker
# $1 - file
# "$@" - netcdf check arguments
netcdf_checker() {
    local file=$1; shift
    local tmp_checker_output=`mktemp`
    local tmp_checker_errors=`mktemp`
    export UDUNITS2_XML_PATH="$DATA_SERVICES_DIR/lib/udunits2/udunits2.xml"
    $NETCDF_CHECKER $file "$@" > $tmp_checker_output 2> $tmp_checker_errors
    local -i retval=$?

    if [ $retval -ne 0 ]; then
        # log to specific log file and not the main log file
        local log_file=`get_log_file $LOG_DIR $file`
        cat $tmp_checker_errors $tmp_checker_output >> $log_file
        if [ $retval == 2 ]; then
            log_error "WARNING! Exceptions occurred while running checker (details in log)."
        fi
        log_error "File did not pass all compliance checks, verbose log saved at '$log_file'"
    fi
    rm -f $tmp_checker_output $tmp_checker_errors

    return $retval
}
export -f netcdf_checker

# dumps the netcdf checker report for a given file to stdout
# $1 - file
get_netcdf_checker_report() {
    local file=$1; shift
    local log_file=`get_log_file $LOG_DIR $file`
    cat $log_file
}
export -f get_netcdf_checker_report

# checks a netcdf file
# $1 - netcdf file to check
check_netcdf() {
    local file=$1; shift
    ncdump -h $file >& /dev/null
}
export -f check_netcdf

# checks a netcdf file for CF compliance
# $1 - netcdf file to check
check_netcdf_cf() {
    local file=$1; shift
    netcdf_checker $file --test=cf
}
export -f check_netcdf_cf

# checks a netcdf file for IMOS compliance
# $1 - netcdf file to check
check_netcdf_imos() {
    local file=$1; shift
    netcdf_checker $file --test=imos
}
export -f check_netcdf_imos

# checks a netcdf file for an IMOS facility compliance
# $1 - netcdf file to check
# $2 - facility specific plugin
check_netcdf_facility() {
    local file=$1; shift
    local facility=$1; shift
    netcdf_checker $file --test=$facility
}
export -f check_netcdf_facility

