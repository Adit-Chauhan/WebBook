#!/usr/bin/env bash

FILE="$HOME/.config/bookmarks.conf"

FF() {
	#printf "Running firefox $@\n"
	firefox $@ &
	disown
}

roof() {
	RofiOut=$(echo "$@" | rofi -dmenu)
	if [ "$RofiOut" == "" ]; then
		echo "Quitting"
		exit 1
	else
		echo $RofiOut
	fi

}

rofied() {
	#printf "\n\nIn Rofied\n"
	#printf $(echo "$@" | awk -F'::' '{print $1}')
	#printf "\n"
	RofiOut=$(echo "$@" | awk -F'::' '{print $1}' | rofi -dmenu)
	if [ "$RofiOut" == "" ]; then
		echo "Quitting"
		kill -9 $$
		exit 1
	else
		echo $RofiOut
	fi
}

filterSection() {
	sed "/| $1/,/|/!d" $FILE | sed '2,$!d' | sed '$d'
}

filterFunction() {
	sed "/DEF $1/,/END/!d" $FILE | sed '2,$!d' | sed '$d' | sed 's/^[[:space:]]*//'
}

JUMPROTO() {
	#printf "\n\nJumpProto Jump to $1"
	Sec=$(filterSection $1)
	#printf "\nNew Section \n$Sec\n"
	#printf "Selection \n$(echo "$Sec" | awk -F'::' '{print $1}')\n"
	roof_inp="$(echo "$Sec" | awk -F'::' '{print $1}')"
	sel=$(roof "$roof_inp")
	#printf "\nSelected \n$sel"
	OpDecode $(echo "$Sec" | grep "$sel" | sed 's/.*:://')
}

CUSTOM() {
	if grep -q "SUB $1" $FILE; then
		#printf "Found Subsitutuion $1\n$(grep "SUB $1" $FILE)\n"
		link=$(sed -n "s/SUB $1//p" $FILE | sed "s,{},$2,g")
		FF $link
	else
		rofied "Function\nNot\nDefined"
		main
	fi
}

OpDecode() {
	OP=$(echo "$@" | awk -F' ' '{print $1}')
	ARG=$(echo "$@" | awk -F' ' '{print $2}')
	#printf "\n OpDecode\nOP $OP\nARG $ARG\n"

	case $OP in
		"") ;;
		\;*) ;;
		\"*)
			Temp=$(echo $OP | sed 's/"//g')
			FF $Temp
			;;
		RUN)
			FF $ARG
			;;
		JUMP)
			JUMPROTO $ARG
			;;
		*)
			CUSTOM $OP $ARG
			;;
	esac
}

main() {
	JUMPROTO Home
}

main
