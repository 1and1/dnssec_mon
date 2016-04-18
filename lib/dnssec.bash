[ "$INCLUDED_ITODNS_DNSSEC" == "$RUNTOKEN" ] && return
INCLUDED_ITODNS_DNSSEC="$RUNTOKEN"

INCLUDE "logging"
INCLUDE "prereqs"
INCLUDE "assert"
INCLUDE "dig"

DEBUG "Loading ${BASH_SOURCE[0]}"

CHECKDOMAINS() {
	DEBUG "$@"
	for DOMAIN
		do
			CHECK_DOMAIN  $DOMAIN || ERR "Domaincheck $DOMAIN failed"
		done
}


CHECK_DOMAIN() {
	DEBUG "$@"
	VERIFY_SEC SOA "$1"
	VERIFY_SEC NS "$1"
	VERIFY_SEC MX "$1"
	VERIFY_SEC TXT "$1"
	VERIFY_SEC A "$1"
}

###
##
#  VERIFY_SEC $TYPE $RECORD
#
#  uses dig for query of record $RECORD of type $TYPE
#
##
###
VERIFY_SEC() {
	DEBUG "$@"
	ASSERT_NOTEMPTY "$2"
	QTYPE="$1"
	QNAME="$2"

	QUERY="$(DIG "+dnssec" "$QTYPE" "$QNAME" "@$DNSSEC_RECURSOR")"
	Q_CONTENT="$(echo "$QUERY" | egrep -v "^;" | egrep -v "^$" )"

	RET_=0;
	LOG "Checking for $QTYPE $QNAME"

	while read 	RECORD \
			TTL \
			_IN \
			Q_TYPE \
			SIG_TYPE \
			SIG_ALG \
			SIG_NLAB \
			SIG_TTL \
			SIG_UNTIL \
			SIG_FROM \
			SIG_KEYID \
			SIG_OWNER \
			SIG_SIGNATURE  \
			_REST
		do
			if [[ "$Q_TYPE" = "NSEC3" ]]
				then
					LOG "Record not found - got NSEC3: $RECORD"
				else
					DEBUG "Record $SIG_TYPE $RECORD from $SIG_OWNER is valid from $SIG_FROM to $SIG_UNTIL - signed with algo $SIG_ALG"
					VERIFY_VALID_RANGE "$SIG_FROM" "$SIG_UNTIL"
					VVR_EC="$?"   #Verif-Valid-Rance-Error-Code
					case "$VVR_EC" in
						0)
							LOG "Signature timerange ($SIG_FROM < $SIG_UNTIL) valid"
							;;
						1)
							LOG "Signature not yet valid"
							return $VVR_EC
							;;
						2)
							LOG "Signature no longer valid"
							return $VVR_EC
							;;
						3)
							LOG "Signature soon invalid"
							;;
						*)
							FAIL "Unexpected Returncode $VVR_EC"
							;;
					esac
				fi
		done < <(echo "$QUERY" | grep RRSIG)
}


VERIFY_VALID_RANGE() {
	DEBUG "$@"
	ASSERT_NOTEMPTY "$2" || FAIl 9
	ASSERT_ISINTEGER "$1" || FAIL 9
	ASSERT_ISINTEGER "$2" || FAIL 9
	ASSERT_LT "$1" "$2"  || FAIL 9

	PREGRACE="$3"
	[[ -n "$PREGRACE" ]] && PREGRACE="5000000"

	VALID="0"
	CURRDATE="$(date -u +%Y%m%d%H%M%S)"
	if [[ "$1" -gt "$CURRDATE" ]]
		then
			ERR "ERROR: Inceptiondate not yet reached: $(( $1 - CURRDATE )) to go"
			VALID="1"
		fi
	if [[ "$2" -le "$CURRDATE" ]]
		then
			ERR "ERROR: Expirationdate reached: $(( CURRDATE - $2))"
			VALID="2"
	elif [[ "$2" -le "$(( CURRDATE - PREGRACE))" ]]
		then
			ERR "WARN: Expirationdate nearly reached: $(( $2 - CURRDATE )) left "
			VALID="3"
		fi
	return "$VALID"
}

DNSSEC_INIT() {
	DEBUG "$@"
	ASSERT_NOTEMPTY "$DNSSEC_RECURSOR"
}


PREREQ_REGISTER DNSSEC_INIT

