<?php
	session_start();
	
	sleep(5);
	
	$upload_good = false;
	if (!isset($_FILES["Filedata"])) {
		$upload_good = "Not recieved, probably exceeded POST_MAX_SIZE";
	}
	else if (!is_uploaded_file($_FILES["Filedata"]["tmp_name"])) {
		$upload_good = "Upload is not a file. PHP didn't like it.";
	} 
	else if ($_FILES["Filedata"]["error"] != 0) {
		$upload_good = "Upload error no. " + $_FILES["Filedata"]["error"];
	} else {
		$upload_good = "The upload was good";
	}
?>
<p>Upload Page</p>

<p>The server slept for 5 seconds so you can test the assume_success_timeout setting.</p>

<p>Here is the list of cookies that the agent sent:</p>
<ul>
	<?php
		foreach ($_COOKIE as $name => $value) {
			echo "<li>";
			echo htmlspecialchars($name) . "=" . htmlspecialchars($value);
			echo "</li>\n";
		}
	?>
</ul>
<p>Here is the list of query values:</p>
<ul>
	<?php
		foreach ($_GET as $name => $value) {
			echo "<li>";
			echo htmlspecialchars($name) . "=" . htmlspecialchars($value);
			echo "</li>\n";
		}
	?>
</ul>
<p>Here is the list of post values:</p>
<ul>
	<?php
		foreach ($_POST as $name => $value) {
			echo "<li>";
			echo htmlspecialchars($name) . "=" . htmlspecialchars($value);
			echo "</li>\n";
		}
	?>
</ul>
<p>Here is the list of the files uploaded:</p>
<ul>
	<?php
		foreach ($_FILES as $name => $value) {
			echo "<li>";
			echo htmlspecialchars($name) . "=" . htmlspecialchars($value["name"]);
			echo "</li>\n";
		}
	?>
</ul>
<p>Filedata upload status: <?php echo $upload_good; ?>.</p>

<p>Here is the current session id:</p>
<p><?php echo htmlspecialchars(session_id()); ?></p>
<p>Compare this to the session id displayed near the top of the Features Demo page. The Flash Player plug-in does not send the correct cookies in some browsers.</p>
<p>Here are some special characters:</p>
<p>Unicode: ☺☻♂♂♠♣♥♦</p>
<p>"\r\n\u0040\x40\004</p>
<p>The above line should say: quote backslash r backslash n backslash u 0 0 4 0 backslash x 4 0 backslash 0 0 4</p>
<p>If you see any @ signs the escaping didn't work right.</p>
<?php
	if (isset($_POST["please_return"]) && is_numeric($_POST["please_return"])) {
		$status_code = $_POST["please_return"];
		echo "Return HTTP Status Code $status_code as requested";
		header("HTTP/1.1 $status_code Custom Status Code");
	}
?>