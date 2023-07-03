#!/bin/bash

WARN_MODE=
WARN_MODE="$WARN_MODE -w all"
#WARN_MODE="$WARN_MODE -w none"
WARN_MODE="$WARN_MODE -w param"
WARN_MODE="$WARN_MODE -w Escape"
WARN_MODE="$WARN_MODE -w pedantic"
WARN_MODE="$WARN_MODE -w Next"
#WARN_MODE="$WARN_MODE -w funcptr"
#WARN_MODE="$WARN_MODE -w constness"
WARN_MODE="$WARN_MODE -w suffix"
#WARN_MODE="$WARN_MODE -w Error"
WARN_MODE="$WARN_MODE -w upcast"

fbc $WARN_MODE -exx -x test/finger2023 @finger2023.lst
if [[ "$?" == "0" ]] ; then
	if [[ "$1" == "install" ]] ; then
		sudo cp test/finger2023 /usr/bin/finger2023
		sudo chown root:root /usr/bin/finger2023
		sudo chmod 755 /usr/bin/finger2023
	fi
fi
