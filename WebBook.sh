#!/usr/bin/env bash

#FILE="$HOME/.local/share/bookmarks.bmk"
FILE="./bookmarks_sample.bmk"
WEBOOK_MODE_VAR="NOARGOMG"
WEBOOK_MODE_VAR_TYPE=""
WEBOOK_MODE_VAR_DEF="NOARGOMG"
FF() {
	#printf "Running chromium $@\n"
	chromium $@ &
	disown
}

roof() {
	RofiOut=$(echo "$@" | rofi -dmenu)
	if [ "$RofiOut" != "" ]; then
		echo $RofiOut
	fi

}

commentclean() {
	sed '/^#.*/d' /dev/stdin | sed 's/#.*//g'
}

filterSection() {
	sed "/| $1/,/|/!d" $FILE | commentclean | sed '2,$!d' | sed '$d'
}

filterFunction() {
	sed "/DEF $1/,/END/!d" $FILE | sed '2,$!d' | sed '$d' | sed 's/^[[:space:]]*//'
}

JUMPROTO() {
	#printf "Inside Jump Proto\n"
	#printf "|\tJumping to $1\n"
	Sec=$(filterSection $1)
	setmodevar $1
	#printf "|\tNew Section \n $Sec\n"
	roof_inp="$(echo "$Sec" | awk -F'::' '{print $1}')"
	#printf "|\tSelection list ==\n$(echo "$Sec" | awk -F'::' '{print $1}')\n"
	sel=$(roof "$roof_inp")
	#printf "|\t\nSelected  == $sel\n"
	if [ "$sel" != "" ]; then
		#printf "|\t|\tSelection String == $(echo "$Sec" | grep "^$sel *::" | sed 's/.*:://')\n"
		OpDecode "$(echo "$Sec" | grep "$sel *::" | sed 's/.*:://')" "$sel"
	fi
}

CUSTOM() {
	#printf "Inside Custom Function\n"
	if grep -q "SUB $1" $FILE; then
		#printf "|\tFound Subsitutuion $1\n$(grep "SUB $1" $FILE | commentclean)\n"
		link=$(sed -n "s/SUB $1//p" $FILE | commentclean | sed "s,{},$2,g")
		FF $link
	else
		fallback_func
	fi
}

fallback_func() {
	roof "Function\nNot\nDefined"
	main
}

setmodevar() {
	#printf "Inside Setting mode var\n"
	LINE=$(sed -n "s/| $1.*\[\(.*\)\].*/\1/p" $FILE)
	#printf "|\tLINE == $LINE\n"
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
	#printf "|\tMODE VARS => $WEBOOK_MODE_VAR $WEBOOK_MODE_VAR_TYPE\n"
}

moderunner() {
	#printf "Entered Mode runner\n"
	#printf "|\tMode Runner Arg $@\n"
	if [ $WEBOOK_MODE_VAR != $WEBOOK_MODE_VAR_DEF ]; then
		case $WEBOOK_MODE_VAR_TYPE in
			"") ;;
			SUB)
				link=$(sed -n "s/SUB $WEBOOK_MODE_VAR//p" $FILE | sed "s,{},$@,g")
				#printf "|\t|\tlink $link \n"
				FF "$link"
				;;
			EXE)
				$WEBOOK_MODE_VAR $1
				;;
		esac
	fi

}

OpDecode() {
	#printf "Inside OpDecode\n"
	#printf "|\tOpDecode \$1 == $1, \$2 == $2\n"
	if [ "$1" == "" ]; then
		moderunner "$2"
	else
		OP=$(echo "$1" | awk -F' ' '{print $1}')
		ARG=$(echo "$1" | awk -F' ' '{print $2}')
		#printf "|\tOpDecode[OP == $OP],[ARG == $ARG]\n"
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
