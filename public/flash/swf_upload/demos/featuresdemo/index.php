<?php session_start(); ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head>
<title>SWFUpload Demos - Features Demo</title>
<link href="../css/default.css" rel="stylesheet" type="text/css" />
<link href="css/featuresdemo.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="../swfupload/swfupload.js"></script>
<script type="text/javascript" src="js/featuresdemo.js"></script>
<script type="text/javascript" src="js/handlers.js"></script>
<script type="text/javascript">
		var suo;
		window.onload = function() {
			// Check to see if SWFUpload is available
			if (typeof(SWFUpload) === "undefined") {
				return;
			}

			// Instantiate a SWFUpload Instance
			suo = new SWFUpload({
				// Backend Settings
				upload_url: "upload.php?get_name=get_value",
				assume_success_timeout: 10,

				post_params: { "post_name1": "post_value1", "post_name2": "post_value2" }, 	// Here are some POST values to send. These can be changed dynamically
				file_post_name: "Filedata",	// This is the "name" of the file item that the server-side script will receive. Setting this doesn't work in the Linux Flash Player
				requeue_on_error: false,
				http_success : [123, 444],

				// File Upload Settings
				file_size_limit : "100 MB",
				file_types : "*.*",
				file_types_description : "All Files",
				file_upload_limit : "10",

				button_image_url : "images/button_270x22.png",
				button_width : 270,
				button_height : 22,
				button_action : SWFUpload.BUTTON_ACTION.SELECT_FILES,
				button_placeholder_id : "spanButtonPlaceholder",
				button_text : '<span class="btnText">Select Files...</span>',
				button_text_style : ".btnText { font-size: 10; font-weight: bold; font-family: MS Shell Dlg; }",
				button_text_top_padding : 3,
				button_text_left_padding : 100,
				
				// Event Handler Settings
				swfupload_loaded_handler : FeaturesDemoHandlers.swfUploadLoaded,
				file_dialog_start_handler : FeaturesDemoHandlers.fileDialogStart,
				file_queued_handler : FeaturesDemoHandlers.fileQueued,
				file_queue_error_handler : FeaturesDemoHandlers.fileQueueError,
				file_dialog_complete_handler : FeaturesDemoHandlers.fileDialogComplete,
				upload_start_handler : FeaturesDemoHandlers.uploadStart,
				upload_progress_handler : FeaturesDemoHandlers.uploadProgress,
				upload_error_handler : FeaturesDemoHandlers.uploadError,
				upload_success_handler : FeaturesDemoHandlers.uploadSuccess,
				
				upload_complete_handler : FeaturesDemoHandlers.uploadComplete,
				debug_handler : FeaturesDemoHandlers.debug,
				
				// Flash Settings
				flash_url : "../swfupload/swfupload.swf",	// Relative to this file

				// Debug Settings
				debug: true		// For the purposes of this demo I wan't debug info shown
			});

	     };
	</script>
</head>
<body>
<div id="header">
	<h1 id="logo"><a href="../">SWFUpload</a></h1>
	<div id="version">v2.2.0</div>
</div>
<div id="content">
	<h2>Features Demo</h2>
	<form>
		The Features Demo allows you to experiment with all the features and settings that SWFUpload v2.0 offers.<br />
		<br />
		You can change all the settings except 'upload_url'.<br />
		<br />
		<strong>Your PHP Session ID is <?php echo session_id(); ?>.</strong> This is provided so you can see the Flash Player Cookie
		bug in action.  Compare this Session ID to the Session ID and Cookies displayed in the Server Data section
		after an upload is complete (SWFUpload FP9 only).<br />
		<br />
		SWFUpload has <span id="spanLoadStatus" style="font-weight: bold;">not loaded</span><br />
		<table class="layout">
			<tr>
				<td style="width: 316px;">
					<div class="fieldset">
						<span class="legend">Queue</span>
						<div>
							<select id="selQueue" size="15" style="width: 270px;">
							</select>
						</div>
						<div>
							<table class="btn">
								<tr>
									<td colspan="3"><span id="spanButtonPlaceholder"></span></td>
								</tr>
							</table>
						</div>
						<div>
							<table class="btn">
								<tr>
									<td class="btn-left"></td>
									<td class="btn-center"><button id="btnStartSelectedFile" type="button" class="action">Start Selected File</button></td>
									<td class="btn-right"></td>
								</tr>
							</table>
						</div>
						<div>
							<table class="btn">
								<tr>
									<td class="btn-left"></td>
									<td class="btn-center"><button id="btnStopUpload" type="button" class="action">Stop Upload</button></td>
									<td class="btn-right"></td>
								</tr>
							</table>
						</div>
						<div>
							<table class="btn">
								<tr>
									<td class="btn-left"></td>
									<td class="btn-center"><button id="btnCancelSelectedFile" type="button" class="action">Cancel Selected File</button></td>
									<td class="btn-right"></td>
								</tr>
							</table>
						</div>
						<div>
							<table class="btn">
								<tr>
									<td class="btn-left"></td>
									<td class="btn-center"><button id="btnCancelSelectedFileNoEvent" type="button" class="action">Cancel Selected File (no event)</button></td>
									<td class="btn-right"></td>
								</tr>
							</table>
						</div>
					</div>
					<div class="fieldset" id="fsStaticSettings">
					<span class="legend">Static Settings</span>
					<div>
						<div class="checkbox">
							<input id="cbPreventSWFCaching" type="checkbox" />
							<label for="cbPreventSWFCaching">prevent_swf_caching</label>
						</div>
						<table class="btn">
							<tr>
								<td class="btn-left"></td>
								<td class="btn-center"><button id="btnReloadSWFUpload" type="button">Reload SWFUpload</button></td>
								<td class="btn-right"></td>
							</tr>
						</table>
					</div>
					</div>
				</td>
				<td style="width: 316px;">
					<div class="fieldset">
					<span class="legend">Post Params</span>
					<div>
						<label for="txtAddFileParamName"><strong>File Post Param</strong> (Select a file first)</label>
						<div style="margin-left: 10px; margin-bottom: 10px;">
							<table>
								<tr>
									<td></td>
									<td><strong>Name</strong></td>
									<td><strong>Value</strong></td>
									<td></td>
								</tr>
								<tr>
									<td style="vertical-align: middle; text-align: right;">Add:</td>
									<td><input id="txtAddFileParamName" type="text" class="textbox" style="width: 100px;" />
									</td>
									<td><input id="txtAddFileParamValue" type="text" class="textbox" style="width: 100px;" />
									</td>
									<td><button id="btnAddFileParam" type="button"></button></td>
								</tr>
								<tr>
									<td style="vertical-align: middle;">Remove:</td>
									<td><input id="txtRemoveFileParamName" type="text" class="textbox" style="width: 100px;" /></td>
									<td><button id="btnRemoveFileParam" type="button"></button></td>
									<td></td>
								</tr>
							</table>
						</div>
					</div>
					<label for="txtAddParamName" style="font-weight: bolder;">Global Post Params</label>
					<div style="margin-left: 10px;">
						<div>
							<select id="selParams" size="5">
							</select>
							<button id="btnRemoveParam" type="button"></button>
						</div>
						<table>
							<tr>
								<td></td>
								<td><strong>Name</strong></td>
								<td><strong>Value</strong></td>
								<td></td>
							</tr>
							<tr>
								<td style="vertical-align: middle;">Add:</td>
								<td><input id="txtAddParamName" type="text" class="textbox" />
								</td>
								<td><input id="txtAddParamValue" type="text" class="textbox" />
								</td>
								<td><button id="btnAddParam" type="button"></button></td>
							</tr>
						</table>
					</div>
					</div>
					<div class="fieldset">
					<span class="legend">Instance Information</span>
					<div>
						<label for="txtMovieName">movieName</label>
						<input id="txtMovieName" type="text" class="textbox" />
					</div>
					<div>
						<label for="txtFlashHTML">Flash HTML</label>
						<textarea id="txtFlashHTML" wrap="soft" style="height: 100px;"></textarea>
					</div>
					</div>
				</td>
				<td style="width: 316px;"><div class="fieldset">
					<span class="legend">Dynamic Settings</span>
					<div id="divDynamicSettingForm">
						<table>
							<tr>
								<td>
									<div>
										<label for="txtUploadTarget">upload_url</label>
										<input id="txtUploadTarget" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtHTTPSuccess">http_success</label>
										<input id="txtHTTPSuccess" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtAssumeSuccessTimeout">assume_success_timeout</label>
										<input id="txtAssumeSuccessTimeout" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtFilePostName">file_post_name</label>
										<input id="txtFilePostName" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtFileTypes">file_types</label>
										<input id="txtFileTypes" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtFileTypesDescription">file_types_description</label>
										<input id="txtFileTypesDescription" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtFileSizeLimit">file_size_limit</label>
										<input id="txtFileSizeLimit" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtFileUploadLimit">file_upload_limit</label>
										<input id="txtFileUploadLimit" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtFileQueueLimit">file_queue_limit</label>
										<input id="txtFileQueueLimit" type="text" class="textbox" />
									</div>
									<div class="checkbox">
										<input id="cbUseQueryString" type="checkbox" />
										<label for="cbUseQueryString">use_query_string</label>
									</div>
									<div class="checkbox">
										<input id="cbRequeueOnError" type="checkbox" />
										<label for="cbRequeueOnError">requeue_on_error</label>
									</div>
									<div class="checkbox">
										<input id="cbDebug" type="checkbox" />
										<label for="cbDebug">debug</label>
									</div>
								</td>
								<td>
									<div class="checkbox">
										<label>button_action</label>
										<div style="margin-left: 10px;">
										<input id="rbButtonActionSelectFile" type="radio" name="button_action" /> <label for="rbButtonActionSelectFile" style="display: inline;">Select File</label><br />
										<input id="rbButtonActionSelectFiles" type="radio" name="button_action" /> <label for="rbButtonActionSelectFiles" style="display: inline;">Select Files</label><br />
										<input id="rbButtonActionStartUpload" type="radio" name="button_action" /> <label for="rbButtonActionStartUpload" style="display: inline;">Start Upload</label><br />
										</div>
									</div>
									<div class="checkbox">
										<input id="cbButtonDisabled" type="checkbox" />
										<label for="cbButtonDisabled">button_disabled</label>
									</div>
									<div>
										<label for="txtButtonImageUrl">button_image_url</label>
										<input id="txtButtonImageUrl" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtButtonText">button_text</label>
										<input id="txtButtonText" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtButtonWidth">button_width</label>
										<input id="txtButtonWidth" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtButtonHeight">button_height</label>
										<input id="txtButtonHeight" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtButtonTextStyle">button_text_style</label>
										<input id="txtButtonTextStyle" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtButtonTextLeftPadding">button_text_left_padding</label>
										<input id="txtButtonTextLeftPadding" type="text" class="textbox" />
									</div>
									<div>
										<label for="txtButtonTextTopPadding">button_text_top_padding</label>
										<input id="txtButtonTextTopPadding" type="text" class="textbox" />
									</div>
								</td>
							</tr>
							
						</table>
					</div>
					<div>
						<table class="btn">
							<tr>
								<td class="btn-left"></td>
								<td class="btn-center"><button id="btnUpdateDynamicSettings" type="button">Update Dynamic Settings</button></td>
								<td class="btn-right"></td>
							</tr>
						</table>
					</div>
					</div>
				</td>
			</tr>
			<tr>
				<td colspan="3"><div class="fieldset">
					<span class="legend">Events</span>
					<table style="width: 100%;">
						<tr>
							<td style="width: 50%"><div>
									<label for="selEventsQueue">Queue</label>
									<select id="selEventsQueue" size="10" style="width: 100%;">
									</select>
								</div></td>
							<td style="width: 50%; overflow: hidden;"><div>
									<label for="selEventsFile">File</label>
									<select id="selEventsFile" size="10" style="width: 100%;">
									</select>
								</div></td>
						</tr>
					</table>
					</div>
					<div class="fieldset">
					<span class="legend">Debug</span>
					<div>
						<textarea id="SWFUpload_Console" wrap="off"></textarea>
					</div>
					</div>
					<div class="fieldset">
					<span class="legend">Server Data</span>
					<div id="divServerData"></div>
					</div></td>
			</tr>
		</table>
	</form>
</div>
</body>
</html>
