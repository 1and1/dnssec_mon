[ "$INCLUDED_ITODNS_SRVTYPES" == "$RUNTOKEN" ] && return
INCLUDED_ITODNS_SRVTYPES="$RUNTOKEN"

INCLUDE "logging"
INCLUDE "prereqs"
INCLUDE "assert"

DEBUG "Loading ${BASH_SOURCE[0]}"

declare -g -A AUTH_PREFIX
declare -g -A POP_LOCATIONS
declare -g -A AUTH_PREFIX
declare -g SRVTYPES


SRVTYPES_INIT() {
	AUTH_PREFIX['pop']="pop"
	AUTH_PREFIX['nspa']="com"
	DC_LOCATIONS['eu']="de_kae_bs de_rhr_bap"

	POP_LOCATIONS['us']="us_dal_bry us_mkc_ws us_nyc_tlx"
	POP_LOCATIONS['eu']="de_fra_act de_fra_fra3 es_mad_mad2 fr_crb_bv nl_ams_nkf"

	DC_VIEWS="${!DC_LOCATIONS[*]}"
	POP_VIEWS="${!POP_LOCATIONS[*]}"
}

GET_LOCATIONS() {
	DEBUG "$*"
	VIEWS="$*"
	if [[ -z $VIEWS ]]
		then
			VIEWS="$DC_VIEWS"
			for V_ in $POP_VIEWS
				do
					if STR_CONTAINS "$V_" "$VIEWS"
						then
							true
						else
							VIEWS="$VIEWS $V_"
						fi
				done
		fi
	DEBUG "VIEWS:$VIEWS"
	RET=""
	for V_ in $VIEWS
		do
			DEBUG "Adding View >$V_<"
			DC_L="${DC_LOCATIONS[$V_]}"
			POP_L="${POP_LOCATIONS[$V_]}"
			RET="$RET $DC_L $POP_L"
		done
	DEBUG ": $RET"
	echo "$RET"
}

VERIFY_SRVTYPES() {
	true #
}

PREREQ_REGISTER SRVTYPES_INIT VERIFY_SRVTYPES
