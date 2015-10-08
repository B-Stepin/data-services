#!/bin/bash

DEFAULT_BACKUP_RECIPIENT=sys.admin@emii.org.au

# returns non zero if file does not match regex filter
# $1 - regex to match with
# $2 - file to validate
regex_filter() {
    local regex="$1"; shift
    local file=`basename $1`; shift
    echo $file | grep -E $regex -q
}

# trigger netcdf checker for file
# $1 - file
# "$@" - suites (checkers) to trigger
trigger_checkers() {
    local file=$1; shift
    local backup_recipient=$1; shift
    check_netcdf $file || \
        file_error_and_report_to_uploader $file $backup_recipient \
        "Not a NetCDF file"

    local check_suite
    for check_suite in "$@"; do
        local checker_function="check_netcdf_${check_suite}"
        $checker_function $file || \
            file_error_and_report_to_uploader $file $backup_recipient \
            "NetCDF file does not comply with '${check_suite}' check"
    done
}

# sets environment, literally runs 'export name="value"'
# $1 - environment variable pair (name=value)
set_enrivonment() {
    local env_pair=$1; shift
    eval export $env_pair
}

# prints usage and exit
usage() {
    echo "Usage: $0 [OPTIONS]... FILE"
    echo "Performs generic checks against a file, then pushes it to production."
    echo "
Options:
  -r, --regex                Regular expresions to filter by.
  -e, --exec                 Execution for path evaluation.
  -c, --checks               NetCDF Checker checks to perform on file.
  -E, --env                  Environment variables to set (name=value).
  -b, --email                Backup email recipient."
    exit 3
}

# main
# $1 - file to handle
main() {
    local tmp_getops
    tmp_getops=`getopt -o hr:e:c:E:b: --long help,regex:,exec:,checks:,env:,email: -- "$@"`
    [ $? != 0 ] && usage

    eval set -- "$tmp_getops"
    local regex path_evaluation_executable checks backup_recipient

    # parse the options
    while true ; do
        case "$1" in
            -h|--help) usage;;
            -r|--regex) regex="$2"; shift 2;;
            -e|--exec) path_evaluation_executable="$2"; shift 2;;
            -c|--checks) checks="$2"; shift 2;;
            -E|--env) set_enrivonment "$2"; shift 2;;
            -b|--email) backup_recipient="$2"; shift 2;;
            --) shift; break;;
            *) usage;;
        esac
    done

    local file=$1; shift

    [ x"$path_evaluation_executable" = x ] && usage
    [ x"$backup_recipient" = x ] && backup_recipient=$DEFAULT_BACKUP_RECIPIENT

    if [ x"$regex" != x ]; then
        regex_filter "$regex" $file || file_error $file "Did not pass regex filter '$regex'"
    fi

    local path_hierarchy
    path_hierarchy=`$DATA_SERVICES_DIR/$path_evaluation_executable $file`
    if [ $? -ne 0 ] || [ x"$path_hierarchy" = x ]; then
        file_error $file "Could not evaluate path for '$file' using '$path_evaluation_executable'"
    fi

    trigger_checkers $file $backup_recipient $checks

    s3_move_to_production $file IMOS/$path_hierarchy
    move_to_production_force $file $OPENDAP_DIR/1 IMOS/opendap/$path_hierarchy
}

main "$@"