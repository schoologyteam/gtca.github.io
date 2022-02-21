<?php

/**
 * @file ./php/chunk.php
 * @deprecated
 * We don't use server-side chunks any more.
 */

// file is inline-included in writenosj.php

echo "<br/><br/>Chunks pass...";

// post format:
//

$de = json_decode( $post );

print_r($de);

$count = 0;

foreach( $de as $c => $b ) {
	$file = '../play/chunks/'.$c.'.json';
	file_put_contents($file, json_encode($b));
	$count ++;
}

echo "<br/>Wrote to $count chunks";

echo "<br/>Done.";

?>