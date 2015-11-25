#!/bin/bash
#
# The MIT License (MIT)
# 
# Copyright (c) 2015 Olaf Lessenich
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


PATH='/bin:/usr/bin'
umask 177

usage () {
	echo "usage: check-ports "
	echo "         -p # prepare Database"
	echo "         -m <mailaddress> # send output via mail"
}

if [ "$1" = "help" ]; then usage; exit 1; fi

PROG="$0"
AUFRUF="$*"
MAILADD=""
OUT="/tmp/check-ports.$$"

HOST=$(hostname)

getports() {
	lsof -i -n -P | awk '/LISTEN/ { print $1"/"$3"/"$8 }' | sort -u
}

for i; do
	case "$1" in
		-p) PREPARE="P"; ;;
		-m) MAILADD="$MAILADD $2"; shift ;;
		-*) usage; exit 1; ;;
	esac
	[ $# -gt 0 ] && shift
done

[ `whoami` != "root" ] && echo "Please execute as root!" && exit 1

TMP="/tmp/ports-check-1.$$"
REFDIR="${HOME}/check"

# only collect data
if [ "$PREPARE" = "P" ]; then
	REF="${REFDIR}/${HOST}.ports"
	getports > $TMP
	if [ -f "$TMP" ]; then
		[ -f $REF ] && mv $REF $REF.`date '+%d%m%y'`
		mv $TMP $REF
	fi
	exit 0
fi

REF="${REFDIR}/${HOST}.ports"
getports > $TMP
if [ -f "$TMP" ]; then
	diff $TMP $REF > $OUT
	rm $TMP
fi

if [ -s $OUT ]; then
	if [ "$MAILADD" != "" ]; then
		PROG_BASE=`basename $PROG`
		echo "" >> $OUT
		echo "Warning: $HOST LISTEN-Status has changed" >> $OUT
		echo "System has to be checked!">> $OUT
		echo "If the change is legitimate, remember to update the check file." >> $OUT
		CALL=`echo "$AUFRUF" | sed "s/-m $MAILADD//"`
		echo "# $PROG -p" >> $OUT
		echo "------------------------------------------------" >> $OUT
		( echo; echo "$HOST: $PROG $AUFRUF"; echo; cat $OUT; echo ) \
			| mailx -s "$HOST: $PROG_BASE" "$MAILADD"
	else
		# Print to terminal
		echo; echo @$HOST:; echo; cat $OUT
	fi
fi

[ -f $OUT ] && rm $OUT
[ -f $TMP ] && rm $TMP

exit 0
