<?php
	if (isset($_POST["PHPSESSID"])) {
		session_id($_POST["PHPSESSID"]);
	}
	session_start();

	// The Demos don't save files


	// In this demo we trigger the uploadError event in SWFUpload by returning a status code other than 200 (which is the default returned by PHP)
	if (!isset($_FILES["Filedata"]) || !is_uploaded_file($_FILES["Filedata"]["tmp_name"]) || $_FILES["Filedata"]["error"] != 0) {
		// Usually we'll only get an invalid upload if our PHP.INI upload sizes are smaller than the size of the file we allowed
		// to be uploaded.
		header("HTTP/1.1 500 File Upload Error");
		if (isset($_FILES["Filedata"])) {
			echo $_FILES["Filedata"]["error"];
		}
		exit(0);
	}
	
?>