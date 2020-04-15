#!/bin/bash
if [ ! $# -eq 1 ]; then
        echo "Usage: $0 <stream_name>"
        exit 1
fi
stream_name=$1
relaisjson=relais-$stream_name.json
[ ! -f $relaisjson ] && cp relais.json $relaisjson

rm /var/lock/.relayingstuff
relais=$(cat $relaisjson)
echo $relais |jq -c '.[]'|while read json
do
	sleep 1
	( bash ecoute-relais.sh "$(echo $json | jq -r '.name')" "$(echo $json | jq -r '.url')" "$relaisjson" & )
done
