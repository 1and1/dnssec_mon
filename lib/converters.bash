[ "$INCLUDED_ITODNS_CONVERTERS" == "$RUNTOKEN" ] && return
INCLUDED_ITODNS_CONVERTERS="$RUNTOKEN"

INCLUDE "logging"
INCLUDE "prereqs"

DEBUG "Loading ${BASH_SOURCE[0]}"

CONV_2-() {
	tr '_' '-' || FAIL
}

CONV_2.() {
	tr '_' '.' || FAIL
}

CONV-2_() {
	tr '-' '_' || FAIL
}

CONV-2.() {
	tr '-' '.' || FAIL
}

CONV.2-() {
	tr '.' '-' || FAIL
}

CONV.2_() {
	tr '.' '_' || FAIL
}


