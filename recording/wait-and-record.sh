#!/bin/bash

silence_tolerance=10
stream_url="http://<your stream url>"

stream_name=$(basename $stream_url .mp3)

pigefile_base=/var/www/html/records/$stream_name
pidfile=/var/run/recording-$stream_name.pid

start_recording () {
	nohup ffmpeg -i $stream_url -c copy $pigefile_base-$(date +"%Y%m%d-%H%M%S").mp3 & echo $! > $pidfile
}

silence_detector () {
	ffmpeg -i $stream_url -af silencedetect=n=-50dB:d=$silence_tolerance -f null - 2>&1 
}

stream_exists () {
	curl -s -m 1 -D - -o /dev/null $stream_url | grep 'Content-Type: audio'
}
while (true)
do
	start_recording
	silence_detector | while read silentline
do 
	echo $silentline | grep silence_end && (
		echo "STARTING RECORD $stream_url";
		start_recording
	        ) 
	echo $silentline | grep silence_start && (
		echo "STOPING RECORD";
		if [ -f $pidfile ] 
		then
			kill `cat $pidfile`
			rm $pidfile
		fi
		) 
done
sleep 1
while (! stream_exists )
	do 
		sleep 1
		echo -n "."
	done
done

exit
