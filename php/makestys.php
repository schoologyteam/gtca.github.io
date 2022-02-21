<?php
/*
crawls all folders in play/sty
and produced play/stys.json
which is used by lightbox.js
*/
$ignores = Array('.', '..', 'nontile', 'wil', 'ste', 'bil');
$blacklist = array('.', '..');
$categories = Array();
$r = '../play/sty/';
$root = opendir( $r );
while (( $e = readdir($root) ) !== false) {
	$path = $r . $e;
	
	if ( is_dir( $path ) && ! in_array($e, $ignores) ) {
	
		$types = Array();
		
		$categories[$e] = Array();
		
		//echo 'folder: ' . $path . ' <br />';
		
		if ( $folder = opendir($path) ) {
			$count = 0;
			while ( false !== ($f = readdir($folder)) ) {
				$path = $r . $e . '/' . $f;
				//echo $path . '<br />';
				if ( is_dir( $path ) && ! in_array($f, $blacklist) ) {
					//echo 'type: ' . $f . ' <br />';
					if ( $type = opendir($path) ) {
						$categories[$e][$f] = Array();
						$count = 0;
						while ( false !== ($t = readdir($type)) ) {
							$path = $r . $e . '/' . $f . '/' . $t;
							if ( is_file( $path ) && ! in_array($t, $blacklist) ) {
								$categories[$e][$f][] = $t;
							}
						}
					}
					
				}
			}
		}
		
		closedir($folder);
		
	}
		
}
//print_r($folders);
echo json_encode($categories);
?>