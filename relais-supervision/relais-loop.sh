#!/bin/bash
relaisjson=relais.json
rm /var/lock/.relayingstuff
relais=$(cat $relaisjson)
echo $relais |jq -c '.[]'|while read json
do
	sleep 1
	( bash ecoute-relais.sh "$(echo $json | jq -r '.name')" "$(echo $json | jq -r '.url')" "$relaisjson" & )
done
