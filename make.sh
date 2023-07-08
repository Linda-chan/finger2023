#!/bin/bash

# Собираем интересные предупреждения :}
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

# Создаём выходной каталог...
if [[ ! -d "output" ]]; then
	mkdir "output"
fi

# Запускаем компилятор...
fbc $WARN_MODE -exx -x "output/finger2023" @finger2023.lst

# Если всё прошло хорошо, проверяем, не было ли параметра 
# "--update"...
if [[ "$?" == "0" ]] ; then
	if [[ "$1" == "--update" ]] ; then
		sudo cp "output/finger2023" "/usr/bin/finger2023"
		sudo chown root:root "/usr/bin/finger2023"
		sudo chmod 644 "/usr/bin/finger2023"
	fi
fi
