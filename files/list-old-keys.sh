#!/bin/bash

EasyRSADir="/etc/openvpn/easy-rsa"
KeysBaseDir="$EasyRSADir/keys"

# read key expire from the var file
if [ -e $EasyRSADir/vars ]
then
  expday=$( grep -i KEY_EXPIRE $EasyRSADir/vars | cut -f2 -d'=' )
else
  expday=365
  echo "using default expire value"
fi
# calculate limit days
if [ ! -z $expday ]
then
  let "minday = $expday - 10"
  let "maxday = $expday + 10"
fi

for day in $(seq $minday $maxday)
do
  echo "--- $day days old keys ---"
  find $KeysBaseDir -iname "*ovpn" -ctime $day
  echo ""
done

