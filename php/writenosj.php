<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$whitelist = Array(
    '::1',
    '127.0.0.1',
    /*pet*/ '83.163.43.200',
    /*jac*/ '37.251.94.189',
    /* hr boss */ '212.10.249.187',
    /*hannas*/ 'not yet');

$access = in_array($_SERVER["REMOTE_ADDR"], $whitelist);

echo '
    <h2>permission <u>' . ((!!$access) ? 'Granted' : 'Denied') . '</u>!</h2>
    your ip '.$_SERVER["REMOTE_ADDR"].' is '. ((!!$access) ? '' : '*not*') . ' whitelisted<br />
    ~ have fun mapping ~<br />
    <br />
	<hr>
	';


if ( $access ) {
    
    if ( isset($_POST['served']) ) {
		$post = $_POST['served'];
        $max = ini_get('post_max_size');
        $maxb = $max * 1024 * 1024;
        
        echo "<br/>post_max_size: " . ini_get('post_max_size') . ' (' . $maxb .' bytes)';
        echo "<br/>\$_POST input size: " . strlen($post) . ' bytes';
        //echo '<br />going to write to nosj.json...';
        
        flush();

        $data = '{"mapName": "Downtown or w/e", "visuals": ' . $post . '}';
        $code = file_put_contents('../sons/nosj.json', $data);
        echo '<br /><br />bytes written: ' . $code;
		
		//include('chunk.php');		
		
    }
    else echo 'Error: No POST-data. I\'m going to need POST-data.';
}

echo '<hr><a href="../?paly&dev#ed">return to game</a>'
?>
