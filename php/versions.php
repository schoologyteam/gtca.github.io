<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

namespace gtagg;

define("FILE", "versions.json");

function getv() {
    global $v;
    return $v;
}

function getversions() {
    global $versions;
    return $versions;
}

$entity = file_get_contents(FILE);

if ( !$entity ) {
    exit(FILE);
}

$object = json_decode($entity, true);

if ( ! $object ) {
    exit("error parsing :d");
}

$versions = '<versions>';
$v = $object[0]['version'];

for ( $i = 0; $i < count($object); $i ++ ) {
    $j = $object[$i];
    sratings();
    $slatestcss = ($i == 0) ? 'latest' : null;
    $versions .= '
            <element '.$slatestcss.' title="'.$j['date'].'">
                <label>
                    <version><inner>'.$j['version'].'</inner></version>
                    <name style="color: '.((isset($j['color'])) ? $j['color'] : '').'">'.$j['name'].'</name>
                </label>
                
                &mdash; <description id="'.$j['version'].'"> <!--<date>'.$j['date'].'</date>--> '.$j['description'].'</description>
                    
            </element>
    ';
    
    if ( $i != count($object)-1 )
        $versions .= '<rh></rh>';
}

$versions .= '</versions>';

function sratings() {
    
}
?>
