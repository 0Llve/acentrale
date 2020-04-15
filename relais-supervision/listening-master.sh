#!/bin/bash
stream_url=http://stream.p-node.org/acentrale320.mp3
stream_name=$(basename $stream_url .mp3)
file_base=/tmp/master-$stream_name
silence_tolerance=10
delayed_relay_tolerance_minutes=2
pidfile=/var/run/fingerprinting-$stream_name.pid

stream_exists () {
	curl -s -m 1 -D - -o /dev/null $stream_url | grep 'Content-Type: audio' >/dev/null
}
silence_detector () {
	ffmpeg -i $stream_url -af silencedetect=n=-50dB:d=$silence_tolerance -f null - 2>&1 
}
start_fingerprinting () {
	(
	sh -c 'echo $$ > '$pidfile'; exec ffmpeg -i '$stream_url' -flags +global_header -f segment -segment_time 6 -reset_timestamps 1 '$file_base'%d.wav 2>&1' | while read segment
	do
		echo $segment | grep Opening >/dev/null || continue
		if [ -f "$file" ]
		then
			python /root/dejavu/dejavu.py -c /root/dejavu/dejavu.cnf --fingerprint "$file" >/dev/null
			rm -- "$file"
			[ `ls -- $file_base*.wav |wc -l` -gt 10 ] && exit
		fi
		file=`echo $segment | cut -d"'" -f2`
		i=$((i+1))
		[ $i -gt 36 ] && (
		echo 'delete f,s from fingerprints f right join songs s on f.song_id=s.song_id where created < (NOW() - INTERVAL '$delayed_relay_tolerance_minutes' MINUTE);' | mysql --login-path=dejavu dejavu
		)
	done
	)&
	bash /root/relais-loop.sh $stream_name
}
while (true)
do
	start_fingerprinting
	silence_detector | while read silentline
	do 
	echo $silentline | grep silence_end >/dev/null && (
	echo "STARTING RECORD $stream_url";
	start_fingerprinting
	) 
	echo $silentline | grep silence_start >/dev/null && (
	echo "STOPING RECORD";
	pkill -f ecoute
	if [ -f $pidfile ] 
	then
		kill $(cat $pidfile)
		rm $pidfile
	fi
	) 
done
sleep 1
while (! stream_exists )
	do 
		sleep 1
		echo -n '.'
	done
done
