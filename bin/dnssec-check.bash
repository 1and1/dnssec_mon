#!/bin/bash
#

[ -r "/opt/bashlib/lib/init.bash" ] && . "/opt/bashlib/lib/init.bash"
if [ "$INCLUDED_INIT" != "$RUNTOKEN" ]
    then
        echo "Failed to load libraries"
        exit 1
    fi

INCLUDE "prereqs"
INCLUDE "config"
INCLUDE "assert"
INCLUDE "time"

MYPATH="$(dirname "${BASH_SOURCE[0]}")"
ITODNS_LIBS="$MYPATH/../lib"
MODULES_DIR="$ITODNS_LIBS/modules"

CONFIG_TRY_LOAD "$MYPATH/../itodns.conf" /etc/itodns.conf ~/.itodns.conf

LIBDIR_ADD "$ITODNS_LIBS"


#PREREQ_REGISTER CHECK_CONFIG

TIMESTAMP="$(GET_TIMESTAMP)"

INCLUDE "converters"
INCLUDE "locations"
INCLUDE "server_types"
INCLUDE "dnssec"

CONFIG_TRY_LOAD "$MYPATH/../itodns.conf" /etc/itodns.conf ~/.itodns.conf

CHECK_PREREQS


#CHECKDOMAINS "mail.com" "ui-r.com" "caramail.com" "oneandone.net" "gmx.com" "gmx.net" "gmx.de" "gmx.at" "gmx.ch"

#VERIFY_SEC NS ui-r.com || ERR "could not validate"
#VERIFY_SEC TXT ui-r.com || ERR "could not validate"

#BASHLIB_DEBUG=True
(
for RT in txt a aaaa soa ns
	do
		for Z in gmx.{com,net,de,at,ch} web.de mail.com ui-r.com
			do
				DIG +dnssec $RT $Z @$DNSSEC_RECURSOR
			done
	done
) | PARSE_RRSIGS_STREAM

LOG "Done"
