<?php
	// Simply set a cookie so we can demonstrate that it appears in IE when it was set in FireFox
	sleep(1);
	
	$datetime = date("M j, Y g:i:s.u");
	setcookie("FlashCookie", $datetime, time() + 1800);
	print($datetime);
?>