#!/usr/bin/env bash

FILE="$HOME/.config/bookmarks.conf"
WEBOOK_MODE_VAR="NOARGOMG"
WEBOOK_MODE_VAR_TYPE=""
WEBOOK_MODE_VAR_DEF="NOARGOMG"
FF() {
	printf "Running firefox $@\n"
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
	printf "\n\nIn Rofied\n"
	printf $(echo "$@" | awk -F'::' '{print $1}')
	printf "\n"
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
	printf "\n\nJumpProto Jump to $1\n"
	Sec=$(filterSection $1)
	setmodevar $1
	printf "\nNew Section \n$Sec\n"
	printf "Selection \n$(echo "$Sec" | awk -F'::' '{print $1}')\n"
	roof_inp="$(echo "$Sec" | awk -F'::' '{print $1}')"
	sel=$(roof "$roof_inp")
	printf "\nSelected \n$sel"
	if [ "$sel" != "" ]; then
		OpDecode "$(echo "$Sec" | grep "$sel" | sed 's/.*:://')" "$sel"
	fi
}

CUSTOM() {
	if grep -q "SUB $1" $FILE; then
		printf "Found Subsitutuion $1\n$(grep "SUB $1" $FILE)\n"
		link=$(sed -n "s/SUB $1//p" $FILE | sed "s,{},$2,g")
		FF $link
	else
		fallback_func
	fi
}

fallback_func() {
	rofied "Function\nNot\nDefined"
	main
}

setmodevar() {
	printf "setting mode var\n"
	LINE=$(sed -n "s/| $1.*\[\(.*\)\].*/\1/p" $FILE)
	printf "Line $LINE\n"
	if [ "$LINE" != "" ]; then
		if grep -q "SUB $LINE" $FILE; then
			WEBOOK_MODE_VAR_TYPE="SUB"
			WEBOOK_MODE_VAR=$LINE
		elif grep -q "EXE $LINE" $FILE; then
			WEBOOK_MODE_VAR_TYPE="EXE"
			WEBOOK_MODE_VAR=$(sed -n "s/EXE $LINE \(.*\)/\1/p" $FILE)
		fi
	else
		WEBOOK_MODE_VAR=$WEBOOK_MODE_VAR_DEF
	fi
	printf "MODE VARS $WEBOOK_MODE_VAR $WEBOOK_MODE_VAR_TYPE\n"
}

moderunner() {
	printf "Entered Mode runner\n"
	printf "Mode Runner Arg $@\n"
	if [ $WEBOOK_MODE_VAR != $WEBOOK_MODE_VAR_DEF ]; then
		case $WEBOOK_MODE_VAR_TYPE in
			"") ;;
			SUB)
				link=$(sed -n "s/SUB $WEBOOK_MODE_VAR//p" $FILE | sed "s,{},$@,g")
				printf "Mode runner link $link \n"
				FF "$link"
				;;
			EXE)
				$WEBOOK_MODE_VAR $1
				;;
		esac
	fi

}

OpDecode() {
	printf "\nOpDecode \$1 == $1, \$2 == $2\n"
	if [ "$1" == "" ]; then
		moderunner "$2"
	else
		OP=$(echo "$1" | awk -F' ' '{print $1}')
		ARG=$(echo "$1" | awk -F' ' '{print $2}')
		printf "\n OpDecode\nOP $OP\nARG $ARG\n"
		case $OP in
			"") ;;
			\;*) ;;
			\"*)
				FF $(echo $OP | sed 's/"//g')
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
	fi
}

main() {
	JUMPROTO Home
}

main
