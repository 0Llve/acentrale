#!/bin/bash
if [ ! $# -eq 3 ]; then
	echo "Usage: $0 <name> <url> <json>"
        exit 1
fi

stream_name=$1
stream_url=$2
relaisjson=$3
file_base=/tmp/relais-$stream_name
dejavu="/root/dejavu/dejavu.py -c /root/dejavu/dejavu.cnf"

echo "listening $stream_name at $stream_url..."

stream_exists () {
	exists=$(curl -s -m 1 -D - -o /dev/null $stream_url | grep 'Content-Type: audio'>/dev/null)
	[ $? -eq 0 ] && is_online=1 || is_online=0
( flock -x -w 10 200 || exit 1
	cat $relaisjson |jq '(.[] | select(.name == "'$stream_name'")) |= ( .online='$is_online' | .failed=1 | .updated='$(date +'%s')')' > $file_base-json && cp $file_base-json $relaisjson
) 200>/var/lock/.relayingstuff
	return $exists
	}
while (true)
do
	rm -- $file_base*.wav 2>/dev/null
	ffmpeg -i $stream_url -flags +global_header -f segment -segment_time 10 -reset_timestamps 1 $file_base%d.wav 2>&1 | while read segment
do
	echo $segment | grep Opening >/dev/null|| continue
	if [ -f "$file" ]
	then
		i=$((i+1))
		[ $i -gt 10 ] && cumul=0 && i=1
		[ $i -lt 4 ] && {
		recognize=$(python $dejavu --recognize file "$file")
		echo $recognize | grep -v '^{' >/dev/null && r=0
		r=$(echo $recognize |jq '.confidence' 2>/dev/null)
		r=$((r+0))
		cumul=$((cumul+r))
		moy=$((cumul/i))
		[ $moy -gt 100 ] && is_relaying=1 || is_relaying=0
		[ $i -eq 3 ] && 
		( flock -x -w 2 200 || { exit 1; }
			# echo "updating $stream_name"
			cat $relaisjson |jq '(.[] | select(.name == "'$stream_name'")) |= (.online=1 | .failed=0 | .relaying='$is_relaying' | .lastscore='$r' | .updated='$(date +'%s')')' > $file_base-json && cp $file_base-json $relaisjson
		) 200>/var/lock/.relayingstuff
		}
		rm -- "$file"
		[ `ls -- $file_base*.wav |wc -l` -gt 20 ] && echo "CA DEBORDE" && exit
	fi
	file=`echo $segment | cut -d"'" -f2`
done
# ( stream_exists) && echo "problème avec $stream_name !"
sleep 1
while (! stream_exists )
	do 
		sleep 1
		echo -n "."
	done
done
