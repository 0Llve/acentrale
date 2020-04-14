index_uid=pads
curl -X DELETE 'http://127.0.0.1:7700/indexes/'$index_uid
curl -X POST 'http://127.0.0.1:7700/indexes' --data '{"uid" : "'$index_uid'","primaryKey":"id"}'
curl -X POST 'http://127.0.0.1:7700/indexes/'$index_uid'/settings' --data '{"distinctAttribute" : "padID"}'
php get_pads_json.php > /tmp/pads.json
curl -X POST 'http://127.0.0.1:7700/indexes/'$index_uid'/documents' --data @/tmp/pads.json
