<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

namespace gtagg;

function getsv() {
    global $sv;
    return $sv;
}

function getslog() {
    global $slog;
    return $slog;
}

$entity = file_get_contents('changes.json');

if ( !$entity ) {
    exit('!changes.json');
}

$jsonchanges = json_decode($entity, true);

if ( ! $jsonchanges ) {
    exit('error parsing changes.json (not good)');
}

$slog = '<golegnahc>';
$sv = $jsonchanges[0]['version'];

for ( $i = 0; $i < count($jsonchanges); $i ++ ) {
    $j = $jsonchanges[$i];
    sratings();
    $slatestcss = ($i == 0) ? 'latest' : null;
    $slog .= '
            <change '.$slatestcss.' title="'.$j['date'].'">
                <label>
                    <version><inner>'.$j['version'].'</inner></version>
                    <name style="color: '.((isset($j['color'])) ? $j['color'] : '').'">'.$j['name'].'</name>
                </label>
                
                &mdash; <description id="'.$j['version'].'"> <!--<date>'.$j['date'].'</date>--> '.$j['description'].'</description>
                    
            </change>
    ';
    
    if ( $i != count($jsonchanges)-1 )
        $slog .= '<rh></rh>';
}

$slog .= '</golegnahc>';

function sratings() {
    
}
?>
