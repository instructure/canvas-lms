<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head>
<title>SWFUpload Demos - Cookie Bug Demo</title>
<link href="../css/default.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="../swfupload/swfupload.js"></script>
<script type="text/javascript" src="js/swfupload.queue.js"></script>
<script type="text/javascript" src="js/fileprogress.js"></script>
<script type="text/javascript" src="js/handlers.js"></script>
<script type="text/javascript">
	var swfu;
	var isIE = false;

	window.onload = function() {
		var settings = {
			flash_url : "../swfupload/swfupload.swf",
			upload_url: "upload.php",
			file_size_limit : "1 MB",

			// Button Settings
			button_image_url : "XPButtonUploadText_61x22.png",
			button_placeholder_id : "spanButtonPlaceholder",
			button_width: 61,
			button_height: 22,

			file_dialog_complete_handler : fileDialogComplete,
			upload_success_handler : uploadSuccess
		};

		swfu = new SWFUpload(settings);
		
		if (isIE) {
			window.setInterval(getCookie, 100);
		} else {
			document.getElementById("divSWFUpload").style.display = "block";
		}
	 };
	 
	var last_cookie_value = "";
	function getCookie() {
		var cookie_value = readCookie("FlashCookie");
		if (cookie_value && last_cookie_value && cookie_value !== last_cookie_value) {
			var p = document.createElement("p");
			p.innerHTML = "FlashCookie cookie changed to " + unescape(cookie_value.replace(/[+]/g, " "));
			document.getElementById("divCookieValues").appendChild(p);
		}

		last_cookie_value = cookie_value;
	}
	
	// http://www.quirksmode.org/js/cookies.html
	function readCookie(name) {
		var nameEQ = name + "=";
		var ca = document.cookie.split(';');
		for(var i=0;i < ca.length;i++) {
			var c = ca[i];
			while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
		}
		return null;
	}
	 
</script>
</head>
<body>
<div id="header">
	<h1 id="logo"><a href="../">SWFUpload</a></h1>
	<div id="version">v2.2.0</div>
</div>

<div id="content">

	<h2>Cookie Bug Demo</h2>
	<form id="form1" action="index.php" method="post" enctype="multipart/form-data">
		<p>This page demonstrates the Flash Cookie Bug.  Open this demo similtaneously in IE and in
			another non-IE based browser (i.e., FireFox, Opera, Safari, etc).  Upload several small files
			in the non-IE browser.  Watch as the cookie values magically appear in IE.</p>
		<div id="divSWFUpload" style="display: none;">
			<p> Upload several files in this browser.  The upload script will set a cookie when each file is
				uploaded.  The cookies values will appear below and, due to the Flash Cookie Bug, will also appear
				in IE. </p>
			<p>
				<span id="spanButtonPlaceholder"></span>
			</p>
			<p id="divStatus">0 Files Uploaded</p>
		</div>
		<!--[if IE]>
		
			<p>Open this demo in another browser and upload some files.  You will see the values of the "FlashCookie"
			appear here as they are changed in the other browser.</p>
		
		<script type="text/javascript">
			isIE = true;
		</script>
		<![endif]-->
		<div id="divCookieValues"></div>
	</form>
</div>
</body>
</html>
