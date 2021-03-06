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
	GRACE_DAYS="${RRSIG_GRACE_DAYS}000000"

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
					VERIFY_VALID_RANGE "$SIG_FROM" "$SIG_UNTIL" "$GRACE_DAYS"
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

###
##
#  VERIFY_RRSIGS
#
##
###
PARSE_RRSIGS_STREAM() {
	DEBUG "$@"
	CURRDATE="$(GET_DATETIMESTR)"
	RET_=0;

	echo "SIG_TYPE;RECORD;Q_TYPE;WARN;SIG_TYPE;SIG_ALG;SIG_NLAB;SIG_TTL;SIG_FROM;SIG_TIME_ACTIVE_SECS;SIG_TIME_ACTIVE_HR;SIG_UNTIL;SIG_TIME_LEFT_SECS;SIG_TIME_LEFT_HR;SIG_KEYID;SIG_OWNER;SIG_SIGNATURE"

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
			WARN=""
			if [[ "$Q_TYPE" = "NSEC3" ]]
				then
					echo ";$RECORD;$Q_TYPE;;;;;;;;;;;;;;$SIG_TYPE $SIG_ALG $SIG_NLAB $SIG_TTL $SIG_UNTIL $SIG_FROM $SIG_KEYID $SIG_OWNER $SIG_SIGNATURE $_REST"
				else
					SIG_TIME_LEFT="$(DIFF_DATETIMESTR "$SIG_UNTIL" "$CURRDATE" )"
					SIG_TIME_LEFT_HR="$( CONV_SEC2TIME $SIG_TIME_LEFT )"
					SIG_TIME_ACTIVE="$(DIFF_DATETIMESTR "$CURRDATE" "$SIG_FROM" )"
					SIG_TIME_ACTIVE_HR="$(CONV_SEC2TIME $SIG_TIME_ACTIVE )"
					DEBUG "$((RRSIG_GRACE_DAYS * 24 * 3600)) > $SIG_TIME_LEFT ?"
					[[ "$((RRSIG_GRACE_DAYS * 24 * 3600))" -gt "$SIG_TIME_LEFT" ]] && WARN="GRACE"
					[[ "0" -gt "$SIG_TIME_LEFT" ]] && WARN="ERROR"
					echo "$SIG_TYPE;$RECORD;$Q_TYPE;$WARN;$SIG_TYPE;$SIG_ALG;$SIG_NLAB;$SIG_TTL;$SIG_FROM;$SIG_TIME_ACTIVE;$SIG_TIME_ACTIVE_HR;$SIG_UNTIL;$SIG_TIME_LEFT;$SIG_TIME_LEFT_HR;$SIG_KEYID;$SIG_OWNER;$SIG_SIGNATURE $_REST"
				fi
		done < <(cat | grep RRSIG )
}

GENERATE_WARNING() {
	while IFS=';' read SIG_TYPE RECORD Q_TYPE WARN SIG_TYPE SIG_ALG SIG_NLAB SIG_TTL SIG_FROM SIG_TIME_ACTIVE_SECS SIG_TIME_ACTIVE_HR SIG_UNTIL SIG_TIME_LEFT_SECS SIG_TIME_LEFT_HR Other_
		do
#			echo $WARN
			case "$WARN" in
				GRACE)
					echo "WARN: $Q_TYPE for $SIG_TYPE $RECORD will be invalid in $SIG_TIME_LEFT_HR (${SIG_TIME_LEFT_SECS}s)";
					;;
				ERROR)
					echo "ERROR: $Q_TYPE for $SIG_TYPE $RECORD will is invalid for $SIG_TIME_LEFT_HR (${SIG_TIME_LEFT_SECS}s)";
					;;
				*)
					true
					;;
			esac
		done
}


VERIFY_VALID_RANGE() {
	DEBUG "$@"
	ASSERT_NOTEMPTY "$2" || FAIl 9
	ASSERT_ISINTEGER "$1" || FAIL 9
	ASSERT_ISINTEGER "$2" || FAIL 9
	ASSERT_LT "$1" "$2"  || FAIL 9

	PREGRACE="$3"
	[[ -n "$PREGRACE" ]] || PREGRACE="5000000"
	ASSERT_ISINTEGER "$PREGRACE" || FAIL 9

	VALID="0"
	CURRDATE="$(date -u +%Y%m%d%H%M%S)"
	GRACE_DATE="$(( CURRDATE + PREGRACE))"

	DEBUG "PREGRACE = $PREGRACE -> $GRACE_DATE"


	if [[ "$1" -gt "$CURRDATE" ]]
		then
			TIME_="$(DIFF_DATETIMESTR "$1" "$CURRDATE")"
			ERR_MSG "ERROR: Inceptiondate not yet reached: $(CONV_SEC2TIME $TIME_) to go"
			VALID="1"
		fi
	if [[ "$2" -le "$CURRDATE" ]]
		then
			TIME_="$(DIFF_DATETIMESTR "$CURRDATE" "$2")"
			ERR_MSG "ERROR: Expirationdate reached: $(CONV_SEC2TIME $TIME_)"
			VALID="2"
	elif [[ "$2" -le "$(( CURRDATE + PREGRACE))" ]]
		then
			TIME_="$(DIFF_DATETIMESTR "$CURRDATE" "$2")"
			ERR_MSG "WARN: Expirationdate nearly reached: $(CONV_SEC2TIME $TIME_) left "
			VALID="3"
		fi
	return "$VALID"
}

DNSSEC_INIT() {
	DEBUG "$@"
	ASSERT_NOTEMPTY "$DNSSEC_RECURSOR" &&
	ASSERT_ISINTEGER "$RRSIG_GRACE_DAYS"
}


PREREQ_REGISTER DNSSEC_INIT

