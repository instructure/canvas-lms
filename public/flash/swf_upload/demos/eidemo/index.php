<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head>
<title>SWFUpload Demos - External Interface Demo</title>
<link href="../css/default.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="../swfupload/swfupload.js"></script>
<script type="text/javascript" src="js/fileprogress.js"></script>
<script type="text/javascript" src="js/handlers.js"></script>
<script type="text/javascript">
		var swfu;

		window.onload = function() {
			var settings = {
				flash_url : "../swfupload/swfupload.swf",
				upload_url: "upload.php",
				post_params: {"PHPSESSID" : "<?php echo session_id(); ?>"},
				file_size_limit : "100 MB",
				file_types : "*.*",
				file_types_description : "All Files",
				file_upload_limit : 100,
				file_queue_limit : 0,
				custom_settings : {
					progressTarget : "fsUploadProgress",
					cancelButtonId : "btnCancel"
				},
				debug: true,

				// Button settings
				button_image_url: "images/TestImageNoText_65x29.png",
				button_width: "65",
				button_height: "29",
				button_placeholder_id: "spanButtonPlaceHolder",
				button_text: '<span class="theFont">Hello</span>',
				button_text_style: ".theFont { font-size: 16; }",
				button_text_left_padding: 12,
				button_text_top_padding: 3,
				
				// The event handler functions are defined in handlers.js
				file_queued_handler : fileQueued,
				file_queue_error_handler : fileQueueError,
				upload_start_handler : uploadStart,
				upload_progress_handler : uploadProgress,
				upload_error_handler : uploadError,
				upload_success_handler : uploadSuccess
			};

			swfu = new SWFUpload(settings);
	     };
	</script>
</head>
<body>
<div id="header">
	<h1 id="logo"><a href="../">SWFUpload</a></h1>
	<div id="version">v2.2.0</div>
</div>

<div id="content">
	<h2>External Interface Demo</h2>
	<form id="form1" action="index.php" method="post" enctype="multipart/form-data">
		<p> This page tests rebuilding the External Interface after some kind of display change.  This demo isn't meant for building upon. Rather it
		helps test whether a particular browser is suffering from this bug.</p>

		<div class="fieldset flash" id="fsUploadProgress">
			<span class="legend">Upload Queue</span>
		</div>
		<div id="divStatus">0 Files Uploaded</div>
		<div id="divMovieContainer">
			<span id="spanButtonPlaceHolder"></span>
			<input type="button" value="Start Upload" onclick="swfu.startUpload();" style="margin-left: 2px; font-size: 8pt; height: 29px;" />
		</div>
		<div>
			<input type="button" value="'Display None' Movie" onclick='swfu.getMovieElement().style.display = "none";' />
			<input type="button" value="'Display Block' Movie" onclick='swfu.getMovieElement().style.display = "";' />
			<input type="button" value="Hide Movie" onclick='swfu.getMovieElement().style.visibility = "hidden";' />
			<input type="button" value="Show Movie" onclick='swfu.getMovieElement().style.visibility = "";' />
			<input type="button" value="'Display None' Movie Parent" onclick='document.getElementById("divMovieContainer").style.display = "none";' />
			<input type="button" value="'Display Block' Movie Parent" onclick='document.getElementById("divMovieContainer").style.display = "";' />
			<input type="button" value="Hide Movie Parent" onclick='document.getElementById("divMovieContainer").style.visibility = "hidden";' />
			<input type="button" value="Show Movie Parent" onclick='document.getElementById("divMovieContainer").style.visibility = "";' />
			<input type="button" value="Manipulate the DOM" onclick='var bob = swfu.getMovieElement(); var cont = document.getElementById("divMovieContainer"); cont.removeChild(bob); cont.insertBefore(bob, cont.firstChild)' />
		</div>

	</form>
</div>
</body>
</html>
