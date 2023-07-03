#!/bin/bash

fbc -w pedantic -exx -x test/finger2023 @finger2023.lst
if [[ "$?" == "0" ]] ; then
	if [[ "$1" == "install" ]] ; then
		sudo cp test/finger2023 /usr/bin/finger2023
		sudo chown root:root /usr/bin/finger2023
		sudo chmod 755 /usr/bin/finger2023
	fi
fi
