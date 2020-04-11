#!/bin/bash

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

source "/bin/bash_entry" || exit $?
tkl_include "__init__.sh" || exit $?

function configure()
{
  # no local logging if nested call
  (( ! IMPL_MODE && ! NEST_LVL )) && {
    export IMPL_MODE=1
    exec 3>&1 4>&2
    tkl_push_trap 'exec 2>&4 1>&3' EXIT

    [[ ! -e "$CONFIGURE_DIR/.log" ]] && mkdir "$CONFIGURE_DIR/.log"

    # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
    #

    # RANDOM instead of milliseconds
    case $BASH_VERSION in
      # < 4.2
      [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
        LOG_FILE_NAME_SUFFIX=$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))
        ;;
      # >= 4.2
      *)
        printf -v LOG_FILE_NAME_SUFFIX "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
        ;;
    esac

    # stdout+stderr redirection into the same log file with handles restore
    {
    {
    {
      configure "$@" 2>&1 1>&8
    } | tee -a "$CONFIGURE_DIR/.log/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME}.log" 1>&9
    } 8>&1 | tee -a "$CONFIGURE_DIR/.log/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME}.log"
    } 9>&2

    exit $?
  }

  # always calls as an external process without an inprocess call optimization
  tkl_call "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/configure.xsh" "$@"
  tkl_set_error $?

  exit $tkl__last_error
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  configure "$@"
fi

fi
