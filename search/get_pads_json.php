<?php
$index_uid = "pads";
$pads_api_url='https://<etherpad-lite-server>/api/1.2.13/';
$pads_apikey='<etherpad-lite api key>';
$pads_list_url=$pads_api_url.'listAllPads?apikey='.$pads_apikey;
$pads_list_json = json_decode(file_get_contents($pads_list_url));
$pads_list = $pads_list_json->data->padIDs;

function txt2parafs($txt) {
	$lines = explode("\n",$txt);
	$newparaf=true;
	$parafs = array();
	foreach ($lines as $linenb=>$line) {
		if(preg_match("/^[\s_-]?$/",$line)) {
			$newparaf=true;
			continue;
		}
		if($newparaf) {
			$debut_paraf_linenb = $linenb;
			$parafs[$debut_paraf_linenb]=$line;
		}
		else {
			$parafs[$debut_paraf_linenb].="\n".$line;
		}
		$newparaf=false;
	}
	return $parafs;
}

$docs=array();
foreach($pads_list as $pad) {
	if(preg_match('/^private_/',$pad))continue;

	$pad_lastedited_url=$pads_api_url.'getLastEdited?padID='.$pad.'&apikey='.$pads_apikey;
	$pad_lastedited_json=json_decode(file_get_contents($pad_lastedited_url));
	$pad_lastedited=$pad_lastedited_json->data->lastEdited;
//	if ($pad_lastedited < (time()-(60*60))*1000) continue;
	
	$pad_text_url=$pads_api_url.'getText?padID='.$pad.'&apikey='.$pads_apikey;
	$pad_text_json=json_decode(file_get_contents($pad_text_url));
	$pad_text=$pad_text_json->data->text;
	$pad_parafs = txt2parafs($pad_text);
//	$pad_parafs=preg_split("/\n[\s_-]?\n/",$pad_text);
	
	foreach($pad_parafs as $parid=>$paraf) {
		$docs[]=array('id'=>md5($pad.'-'.$parid),'txt'=>$paraf,'line_nb'=>$parid,'padID'=>$pad, 'last_edited'=>$pad_lastedited);
	}
	echo "\n";
}
echo json_encode($docs);
?>
