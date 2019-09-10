#!/bin/bash

EasyRSADir="/etc/openvpn/easy-rsa"
KeysBaseDir="$EasyRSADir/keys"

# Expiry date:
# 1 - look the expiration date in the cert
# 0 - look the modification date of the cert file for the expiration date
CRT_BASED_LIST=1

DEFAULT_EXP_DAY=365

# before the key expiration
BEFORE_NOTICE_DAY=30
# after the key expiration (yes, really, with minus)
AFTER_NOTICE_DAY=-10

# check the expiry date of the cert file
function cert_check {
   for kf in $( find $KeysBaseDir -iname "*crt" )
   do
     EndDate=$( date "+%s" -d "$( openssl x509 -in $kf -text | grep -i "not after" | cut -f2- -d':' )" )
     Today=$( date "+%s" -d "now" )
     let "DayLeft = ( $EndDate - $Today ) / 86400"
	 # the let command returns 0 if the key is already expired (divide by zero or with negative number or something similar)
	 [ $DayLeft -le $BEFORE_NOTICE_DAY ] && [ $DayLeft -ge $AFTER_NOTICE_DAY ] && echo "$( [ $DayLeft ] && { echo "$DayLeft day(s) left"; } || { echo "Unknown age"; } ) "$( [ -f $kf ] && { basename $kf; } )
   done

   exit 0
}

# check the modification date of the vpn file
function file_check {
	# read key expire from the var file
	if [ -e $EasyRSADir/vars ]
	then
	  expday=$( grep -i KEY_EXPIRE $EasyRSADir/vars | cut -f2 -d'=' )
	else
	  expday=$DEFAULT_EXP_DAY
	  echo "using default expire value"
	fi
	# calculate limit days
	if [ ! -z $expday ]
	then
	  let "minday = $expday - $BEFORE_NOTICE_DAY"
	  let "maxday = $expday + $AFTER_NOTICE_DAY"
	fi

	for day in $(seq $minday $maxday)
	do
	  for kf in $( find $KeysBaseDir -iname "*ovpn" -ctime $day )
	  do
		let "dayleft = $expday - $day"
		echo "$( [ $dayleft ] && { echo "$dayleft day(s) left"; } || { echo "$day day(s) old key"; } ) "$( [ -f $kf ] && { basename $kf; } )
	  done
	done

	exit 0
}

if [ $CRT_BASED_LIST -eq 1 ]
then
  cert_check
else
  file_check
fi

exit 0
