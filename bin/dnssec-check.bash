#!/bin/bash
#

#BASHLIB_DEBUG="TRUE"

[ -r "/usr/local/lib/bashlib/init.bash" ] && . "/usr/local/lib/bashlib/init.bash"
if [ "$INCLUDED_INIT" != "$RUNTOKEN" ]
    then
        echo "Failed to load libraries"
        exit 1
    fi

[[ "$1" = "-d" ]] && BASHLIB_DEBUG="TRUE"

INCLUDE "prereqs"
INCLUDE "config"
INCLUDE "assert"
INCLUDE "time"

MYPATH="$(dirname $0)"
ITODNS_LIBS="$MYPATH/../lib"
MODULES_DIR="$ITODNS_LIBS/modules"

CONFIG_TRY_LOAD /etc/itodns.conf ~/.itodns.conf

LIBDIR_ADD "$ITODNS_LIBS"


#PREREQ_REGISTER CHECK_CONFIG

TIMESTAMP="$(GET_TIMESTAMP)"

INCLUDE "converters"
INCLUDE "locations"
INCLUDE "server_types"
INCLUDE "dnssec"

CONFIG_TRY_LOAD /etc/itodns.conf ~/.itodns.conf

CHECK_PREREQS

#BASHLIB_DEBUG="TRUE"

CHECKDOMAINS "mail.com" "ui-r.com" "caramail.com" "oneandone.net"

VERIFY_SEC NS ui-r.com || ERR "could not validate"
VERIFY_SEC TXT ui-r.com || ERR "could not validate"
#VERIFY_SEC NSEC3 h69d0ht05fconsv11efmr0b3qrv31903.ui-r.com.

LOG "Done"
