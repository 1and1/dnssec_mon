[ "$INCLUDED_ITODNS_DIG" == "$RUNTOKEN" ] && return
INCLUDED_ITODNS_DIG="$RUNTOKEN"

INCLUDE "logging"
INCLUDE "prereqs"
INCLUDE "assert"
INCLUDE "local"

DEBUG "Loading ${BASH_SOURCE[0]}"

declare -g DIG_PATH


DIG() {
	DEBUG "$@"
	EXEC "$DIG_PATH $* 2>&1"
}


FIND_DIG_PATH() {
	DEBUG "$@"
	DP="$(which dig)"
	[[ "$?"  -eq 0 ]] || ERR "Can't find dig"
	echo "$DP"
}

MOD_DIG_INIT() {
	DEBUG "$@"
	[[ -n "$DIG_PATH" ]] || DIG_PATH="$(FIND_DIG_PATH)"

	ASSERT_EXEC "$DIG_PATH" || return 1
	EXEC "$DIG_PATH localhost >/dev/null"  || return 1
}



PREREQ_REGISTER MOD_DIG_INIT

