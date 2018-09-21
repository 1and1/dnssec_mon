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

HELP() {
	cat <<EOT
$0 [OPTS] <ZONES>
Options:
    -d           enable Debugging
    -m           enable machine-parsable output
    -w           warn-mode - only show warnings and only show seconds
    -c <file>    specify additional configfile to read
    -s <server>  select Server for DNS-Requests
    -g <days>    specify the number of grace days to warn
                 before expiration

    -t {types}   specify that recordtypes are following
    -z {zones}   specify that a list of zones are following

    -T <file>    read the list of types from file
    -Z <file>    read the list of zones from file
    if -T or -Z is suffixed by a "+" sign, the contents of the
    file will be added to the existing lists.

EOT
}

MYPATH="$(dirname "${BASH_SOURCE[0]}")"
DNSSEC_LIBS="$MYPATH/../lib"
MODULES_DIR="$DNSSEC_LIBS/modules"
LIBDIR_ADD "$DNSSEC_LIBS"

TIMESTAMP="$(GET_TIMESTAMP)"

TEST_ZONES=""
TEST_TYPES="SOA"
DNSSEC_RECURSOR="rec01.svc.1u1.it"

CONFIG_TRY_LOAD "$MYPATH/../dnssec_mon.conf" /etc/dnssec_mon.conf ~/.dnssec_mon.conf
CHECK_PREREQS

MAIN(){
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
			LOG "Done"
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
		warn)
			DEBUG "Checking Zones for warnings"
				(
				for RT in $TEST_TYPES
					do
						for Z in $TEST_ZONES
							do
								DIG +dnssec "$RT" "$Z" "@$DNSSEC_RECURSOR"
							done
					done
				) | PARSE_RRSIGS_STREAM | GENERATE_WARNING
			;;
		*)
			FAIL 3 "Unknown Action $ACTION"
			;;
	esac
}

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
			'-?')
				HELP
				exit 0
				;;
			-c)
				DEBUG "Loading additional config $1"
				CONFIG_LOAD "$1" || FAIL 7 "Could not load $1"
				shift
				;;
			-t)
				DEBUG "RecordTypes following"
				NEXTTOKEN="TYPE"
				;;
			-T)
				DEBUG "Loading Typelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_TYPES="$(cat "$1")"
				shift
				;;
			-T+)
				DEBUG "Loading Typelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_TYPES="$TEST_TYPES $(cat "$1")"
				shift
				;;
			-z)
				DEBUG "Zones following"
				NEXTTOKEN="ZONE"
				;;
			-Z)
				DEBUG "Loading Zonelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_ZONES="$(cat "$1")"
				shift
				;;
			-Z+)
				DEBUG "Loading additional Zonelist from file $1"
				[[ -r "$1" ]] || ERROR "File $1 not readable"
				TEST_ZONES="$TEST_ZONES $(cat "$1")"
				shift
				;;
			-s)
				DEBUG "Setting Server $1"
				DNSSEC_RECURSOR="$1"
				shift
				;;
			-h)
				DEBUG "Generating human-readable output"
				ACTION="check"
				;;
			-m)
				DEBUG "Generating machine-readable output"
				ACTION="parse"
				;;
			-w)
				DEBUG "Generating warning-only output"
				ACTION="warn"
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

MAIN $*