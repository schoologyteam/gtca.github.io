<?php
/*
$db_type = '';
$db_host = '';
$db_name = '';
$db_username = '';
$db_password = '';
$db_prefix = '';
$p_connect = false;

$base_url = 'http://forum.ak.fm';

$link = mysqli_connect($db_host, $db_username, $db_password, $db_name);

$res = mysqli_query($link, '
		SELECT
			posts.id as post_id, posts.poster, posts.poster_id, posts.message, posts.posted,
				topics.subject, topics.id as topic_id, topics.forum_id,
					forums.id, forums.forum_name
		FROM posts
		INNER JOIN topics ON posts.topic_id=topics.id
		LEFT JOIN forums ON topics.forum_id=forums.id
		WHERE forums.id = 18
		ORDER BY posts.id DESC LIMIT 1');

// im excluding the forum ids 14 and 15, because they are internal affairs and area 51
// this actually works as expected -> if the latest post is in either of these restricted forums
// it takes the last more recent post that wasn't in either of these forums :)


if ( $res ) {
	$row = mysqli_fetch_assoc($res);

	$chars = 20;
	
	$msg = $row['message'];
	
	//echo $msg;
	*/
	//$msg = preg_replace("/\[quote.+?\].+?\[\/quote\]\s*/i", "", $msg); // this removes [quote] tags entirely
	/*
	$original = $msg;
	$msg = mb_strimwidth($msg, 0, $chars, "...");
	
	$str = '
			<a id="lastpost_link" href="http://forum.ak.fm/post/'.$row['post_id'].'/#p'.$row['post_id'].'">[ Last GTA2.0 post ]:</a>
			
			<a id="lastpost_poster" href="http://forum.ak.fm/user/'.$row['poster_id'].'/">'.$row['poster'].'</a>
			wrote <om:message>'.$msg.'</om:message>
			in topic <a id="lastpost_forum"  href="http://forum.ak.fm/topic/'.$row['topic_id'].'/">'.$row['subject'].'</a>
			in forum <a id="lastpost_forum" href="http://forum.ak.fm/forum/'.$row['forum_id'].'/">'.$row['forum_name'].'</a>
			';
	echo $str;
} else echo 'Can\'t get last post';*/

// for localhost
echo '
	<a id="lastpost_link" href="http://forum.ak.fm/post/18/#p18">[ Last GTA2.0 post ]</a>
	<a id="lastpost_poster" href="http://forum.ak.fm/user/18/">Steer Lat</a>
	wrote <om:message>Helo</om:message>
	in topic <a id="lastpost_forum" href="http://forum.ak.fm/topic/27/">Test topic</a>
	';
?>