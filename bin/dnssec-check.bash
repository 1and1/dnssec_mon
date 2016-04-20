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


TIMESTAMP="$(GET_TIMESTAMP)"


TEST_ZONES=""
TEST_TYPES="SOA"

CONFIG_TRY_LOAD "$MYPATH/../itodns.conf" /etc/itodns.conf ~/.itodns.conf
CHECK_PREREQS

ACTION="check"
RRSIG_GRACE_DAYS="0"
NEXTTOKEN="ZONE"
while [[ -n "$1" ]]
	do
		ARG_="$1"
		shift
		case "$ARG_" in
			-d)
				BASHLIB_DEBUG=TRUE
				;;
			-t)
				DEBUG "RecordTypes following"
				NEXTTOKEN="TYPE"
				;;
			-T)
				DEBUG "Loading Typelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_TYPES="$(cat $1)"
				shift
				;;
			-T+)
				DEBUG "Loading Typelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_TYPES="$TEST_TYPES $(cat $1)"
				shift
				;;
			-z)
				DEBUG "Zones following"
				NEXTTOKEN="ZONE"
				;;
			-Z)
				DEBUG "Loading Zonelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_ZONES="$(cat $1)"
				shift
				;;
			-Z+)
				DEBUG "Loading additional Zonelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_ZONES="$TEST_ZONES $(cat $1)"
				shift
				;;
			-s)
				DEBUG "Setting Server $1"
				DNSSEC_RECURSOR="$1"
				shift
				;;
			-m)
				DEBUG "Generating machine-readable output"
				ACTION="parse"
				;;
			-g)
				DEBUG "Defining Gracetime $1 days"
				RRSIG_GRACE_DAYS="$1"
				shift
				;;
			*)
				DEBUG "NoArgMatch $ARG_"
				case "$NEXTTOKEN" in
					'ZONE')
						DEBUG "Adding Zone to check: '$ARG_'"
						TEST_ZONES="$TEST_ZONES $ARG_"
						;;
					'TYPE')
						DEBUG "Adding Type to check: '$ARG_'"
						TEST_TYPES="$TEST_TYPES $ARG_"
						;;
					*)
						FAIL "Can't evaluate for '$NEXTTOKEN'"
						;;
				esac
				;;
		esac
	done

INCLUDE "dnssec"
CHECK_PREREQS


DEBUG "Would test Zones '$TEST_ZONES' for '$TEST_TYPES'"
ASSERT_NOTEMPTY "$TEST_ZONES" || FAIL 2 "need to specify zones to test"
ASSERT_NOTEMPTY "$TEST_TYPES"  || FAIL 2 "no RecordTypes to test"


ASSERT_NOTEMPTY "$ACTION" || FAIL 3 "Unspecified Action: WTF!"
case "$ACTION" in
	check)
		DEBUG "Checking Zones human-readable"
			(
			for RT in $TEST_TYPES
				do
					for Z in $TEST_ZONES
						do
							VERIFY_SEC "$RT" "$Z"
						done
				done
			)
		;;
	parse)
		DEBUG "Checking Zones machine-readable"
			(
			for RT in $TEST_TYPES
				do
					for Z in $TEST_ZONES
						do
							DIG +dnssec "$RT" "$Z" "@$DNSSEC_RECURSOR"
						done
				done
			) | PARSE_RRSIGS_STREAM
		;;
	*)
		FAIL 3 "Unknown Action $ACTION"
		;;
esac

exit

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
