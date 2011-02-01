// Called instead of the SWFUpload _showUI method
var FeaturesDemo = {
	start: function (swf_upload_instance) {
		FeaturesDemo.SU = swf_upload_instance;

		FeaturesDemo.cacheFields();
		FeaturesDemo.loadAll();

		FeaturesDemo.btnStartSelectedFile.onclick = function () {
			try {
				FeaturesDemo.startSelectedFile();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnStopUpload.onclick = function () {
			try {
				FeaturesDemo.stopUpload();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnCancelSelectedFile.onclick = function () {
			try {
				FeaturesDemo.cancelSelectedFile(true);
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnCancelSelectedFileNoEvent.onclick = function () {
			try {
				FeaturesDemo.cancelSelectedFile(false);
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnAddFileParam.onclick = function () {
			try {
				FeaturesDemo.addFileParam();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnRemoveFileParam.onclick = function () {
			try {
				FeaturesDemo.removeFileParam();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnAddParam.onclick = function () {
			try {
				FeaturesDemo.addParam();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnRemoveParam.onclick = function () {
			try {
				FeaturesDemo.removeParam();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnUpdateDynamicSettings.onclick = function () {
			try {
				FeaturesDemo.updateDynamicSettings();
			} catch (ex) {
			}
			return false;
		};
		FeaturesDemo.btnReloadSWFUpload.onclick = function () {
			try {
				FeaturesDemo.reloadSWFUpload();
			} catch (ex) {
			}
			return false;
		};
		
		document.getElementById("spanLoadStatus").innerHTML = "loaded";
	},
	cacheFields: function () {
		if (FeaturesDemo.is_cached) {
			return;
		}
		
		FeaturesDemo.selQueue = document.getElementById("selQueue");
		FeaturesDemo.btnStartSelectedFile = document.getElementById("btnStartSelectedFile");
		FeaturesDemo.btnStopUpload = document.getElementById("btnStopUpload");
		FeaturesDemo.btnCancelSelectedFile = document.getElementById("btnCancelSelectedFile");
		FeaturesDemo.btnCancelSelectedFileNoEvent = document.getElementById("btnCancelSelectedFileNoEvent");
		FeaturesDemo.txtAddFileParamName = document.getElementById("txtAddFileParamName");
		FeaturesDemo.txtAddFileParamValue = document.getElementById("txtAddFileParamValue");
		FeaturesDemo.btnAddFileParam = document.getElementById("btnAddFileParam");
		FeaturesDemo.txtRemoveFileParamName = document.getElementById("txtRemoveFileParamName");
		FeaturesDemo.btnRemoveFileParam = document.getElementById("btnRemoveFileParam");
		FeaturesDemo.selParams = document.getElementById("selParams");
		FeaturesDemo.btnRemoveParam = document.getElementById("btnRemoveParam");
		FeaturesDemo.txtAddParamName = document.getElementById("txtAddParamName");
		FeaturesDemo.txtAddParamValue = document.getElementById("txtAddParamValue");
		FeaturesDemo.btnAddParam = document.getElementById("btnAddParam");
		FeaturesDemo.txtUploadTarget = document.getElementById("txtUploadTarget");
		FeaturesDemo.txtHTTPSuccess = document.getElementById("txtHTTPSuccess");
		FeaturesDemo.txtAssumeSuccessTimeout = document.getElementById("txtAssumeSuccessTimeout");
		FeaturesDemo.btnUpdateDynamicSettings = document.getElementById("btnUpdateDynamicSettings");
		FeaturesDemo.txtFlashHTML = document.getElementById("txtFlashHTML");
		FeaturesDemo.txtMovieName = document.getElementById("txtMovieName");
		FeaturesDemo.txtFilePostName = document.getElementById("txtFilePostName");
		FeaturesDemo.txtFileTypes = document.getElementById("txtFileTypes");
		FeaturesDemo.txtFileTypesDescription = document.getElementById("txtFileTypesDescription");
		FeaturesDemo.txtFileSizeLimit = document.getElementById("txtFileSizeLimit");
		FeaturesDemo.txtFileUploadLimit = document.getElementById("txtFileUploadLimit");
		FeaturesDemo.txtFileQueueLimit = document.getElementById("txtFileQueueLimit");
		FeaturesDemo.cbUseQueryString = document.getElementById("cbUseQueryString");
		FeaturesDemo.cbRequeueOnError = document.getElementById("cbRequeueOnError");
		FeaturesDemo.cbPreventSWFCaching = document.getElementById("cbPreventSWFCaching");
		FeaturesDemo.cbDebug = document.getElementById("cbDebug");
		FeaturesDemo.btnReloadSWFUpload = document.getElementById("btnReloadSWFUpload");
		FeaturesDemo.selEventsQueue = document.getElementById("selEventsQueue");
		FeaturesDemo.selEventsFile = document.getElementById("selEventsFile");
		FeaturesDemo.SWFUpload_Console = document.getElementById("SWFUpload_Console");
		FeaturesDemo.divServerData = document.getElementById("divServerData");

		FeaturesDemo.rbButtonActionSelectFile = document.getElementById("rbButtonActionSelectFile");
		FeaturesDemo.rbButtonActionSelectFiles = document.getElementById("rbButtonActionSelectFiles");
		FeaturesDemo.rbButtonActionStartUpload = document.getElementById("rbButtonActionStartUpload");
		FeaturesDemo.txtButtonImageUrl = document.getElementById("txtButtonImageUrl");
		FeaturesDemo.txtButtonText = document.getElementById("txtButtonText");
		FeaturesDemo.txtButtonWidth = document.getElementById("txtButtonWidth");
		FeaturesDemo.txtButtonHeight = document.getElementById("txtButtonHeight");
		FeaturesDemo.txtButtonTextStyle = document.getElementById("txtButtonTextStyle");
		FeaturesDemo.txtButtonTextLeftPadding = document.getElementById("txtButtonTextLeftPadding");
		FeaturesDemo.txtButtonTextTopPadding = document.getElementById("txtButtonTextTopPadding");
		FeaturesDemo.cbButtonDisabled = document.getElementById("cbButtonDisabled");
		
		FeaturesDemo.is_cached = true;
	},
	clearAll: function () {
		FeaturesDemo.selQueue.options.length = 0;
		FeaturesDemo.txtAddFileParamName.value = "";
		FeaturesDemo.txtAddFileParamValue.value = "";
		FeaturesDemo.txtRemoveFileParamName.value = "";
		FeaturesDemo.selParams.options.length = 0;
		FeaturesDemo.txtAddParamName.value = "";
		FeaturesDemo.txtAddParamValue.value = "";
		FeaturesDemo.txtUploadTarget.value = "";
		FeaturesDemo.txtFlashHTML.value = "";
		FeaturesDemo.txtMovieName.value = "";
		FeaturesDemo.txtHTTPSuccess.value = "";
		FeaturesDemo.txtAssumeSuccessTimeout.value = "";
		FeaturesDemo.txtFilePostName.value = "";
		FeaturesDemo.txtFileTypes.value = "";
		FeaturesDemo.txtFileTypesDescription.value = "";
		FeaturesDemo.txtFileSizeLimit.value = "";
		FeaturesDemo.txtFileUploadLimit.value = "";
		FeaturesDemo.txtFileQueueLimit.value = "";
		FeaturesDemo.cbUseQueryString.checked = false;
		FeaturesDemo.cbPreventSWFCaching.checked = false;
		FeaturesDemo.cbRequeueOnError.checked = false;
		FeaturesDemo.cbDebug.checked = false;
		FeaturesDemo.selEventsQueue.options.length = 0;
		FeaturesDemo.selEventsFile.options.length = 0;
		FeaturesDemo.SWFUpload_Console.value = "";
		FeaturesDemo.divServerData.innerHTML = "";

		FeaturesDemo.rbButtonActionSelectFile.checked = false;
		FeaturesDemo.rbButtonActionSelectFiles.checked = false;
		FeaturesDemo.rbButtonActionStartUpload.checked = false;
		FeaturesDemo.txtButtonImageUrl.value = "";
		FeaturesDemo.txtButtonText.value = "";
		FeaturesDemo.txtButtonWidth.value = "";
		FeaturesDemo.txtButtonHeight.value = "";
		FeaturesDemo.txtButtonTextStyle.value = "";
		FeaturesDemo.txtButtonTextLeftPadding.value = "";
		FeaturesDemo.txtButtonTextTopPadding.value = "";
		FeaturesDemo.cbButtonDisabled.checked = false;
		
	},
	loadAll: function () {
		var param_obj = FeaturesDemo.SU.settings.post_params;
		var counter = 0;
		for (var key in param_obj) {
			if (param_obj.hasOwnProperty(key)) {
				FeaturesDemo.selParams.options[counter++] = new Option(key, param_obj[key]);
			}
		}

		switch (FeaturesDemo.SU.settings.button_action) {
		case SWFUpload.BUTTON_ACTION.SELECT_FILE:
			FeaturesDemo.rbButtonActionSelectFile.checked = true;
			break;
		case SWFUpload.BUTTON_ACTION.START_UPLOAD:
			FeaturesDemo.rbButtonActionStartUpload.checked = true;
			break;
		case SWFUpload.BUTTON_ACTION.SELECT_FILES:
		default:
			FeaturesDemo.rbButtonActionSelectFiles.checked = true;
			break;
		}
		
		FeaturesDemo.txtUploadTarget.value = FeaturesDemo.SU.settings.upload_url;
		FeaturesDemo.txtFlashHTML.value = FeaturesDemo.SU.getFlashHTML();
		FeaturesDemo.txtMovieName.value = FeaturesDemo.SU.movieName;
		FeaturesDemo.txtHTTPSuccess.value = FeaturesDemo.SU.settings.http_success.join(", ");
		FeaturesDemo.txtAssumeSuccessTimeout.value = FeaturesDemo.SU.settings.assume_success_timeout;
		FeaturesDemo.txtFilePostName.value = FeaturesDemo.SU.settings.file_post_name;
		FeaturesDemo.txtFileTypes.value = FeaturesDemo.SU.settings.file_types;
		FeaturesDemo.txtFileTypesDescription.value = FeaturesDemo.SU.settings.file_types_description;
		FeaturesDemo.txtFileSizeLimit.value = FeaturesDemo.SU.settings.file_size_limit;
		FeaturesDemo.txtFileUploadLimit.value = FeaturesDemo.SU.settings.file_upload_limit;
		FeaturesDemo.txtFileQueueLimit.value = FeaturesDemo.SU.settings.file_queue_limit;
		FeaturesDemo.cbUseQueryString.checked = FeaturesDemo.SU.settings.use_query_string;
		FeaturesDemo.cbRequeueOnError.checked = FeaturesDemo.SU.settings.requeue_on_error;
		FeaturesDemo.cbPreventSWFCaching.checked = FeaturesDemo.SU.settings.prevent_swf_caching;
		FeaturesDemo.cbDebug.checked = FeaturesDemo.SU.settings.debug;
		
		FeaturesDemo.txtButtonImageUrl.value = FeaturesDemo.SU.settings.button_image_url;
		FeaturesDemo.txtButtonText.value = FeaturesDemo.SU.settings.button_text;
		FeaturesDemo.txtButtonWidth.value = FeaturesDemo.SU.settings.button_width;
		FeaturesDemo.txtButtonHeight.value = FeaturesDemo.SU.settings.button_height;
		FeaturesDemo.txtButtonTextStyle.value = FeaturesDemo.SU.settings.button_text_style;
		FeaturesDemo.txtButtonTextLeftPadding.value = FeaturesDemo.SU.settings.button_text_left_padding;
		FeaturesDemo.txtButtonTextTopPadding.value = FeaturesDemo.SU.settings.button_text_top_padding;
		FeaturesDemo.cbButtonDisabled.checked = FeaturesDemo.SU.settings.button_disabled;
	},

	startSelectedFile: function () {
		if (FeaturesDemo.selQueue.options.length === 0) {
			alert("You must queue a file first");
			return;
		}
		if (FeaturesDemo.selQueue.selectedIndex === -1) {
			alert("Please select a file from the queue.");
			return;
		}

		var file_id = FeaturesDemo.selQueue.value;
		FeaturesDemo.SU.startUpload(file_id);
	},
	stopUpload: function () {
		FeaturesDemo.SU.stopUpload();
	},
	cancelSelectedFile: function (triggerEvent) {
		if (FeaturesDemo.selQueue.options.length === 0) {
			alert("You must queue a file first");
			return;
		}
		if (FeaturesDemo.selQueue.selectedIndex === -1) {
			alert("Please select a file from the queue.");
			return;
		}

		var file_id = FeaturesDemo.selQueue.value;
		FeaturesDemo.SU.cancelUpload(file_id, triggerEvent);
	},
	addFileParam: function () {
		if (FeaturesDemo.selQueue.selectedIndex === -1) {
			alert("Please select a file from the queue.");
			return;
		}
		var file_id = FeaturesDemo.selQueue.value;
		var name = FeaturesDemo.txtAddFileParamName.value;
		var value = FeaturesDemo.txtAddFileParamValue.value;

		if (name === "") {
			alert("Please enter a Param name.");
			return;
		}

		if (FeaturesDemo.SU.addFileParam(file_id, name, value)) {
			FeaturesDemo.txtAddFileParamName.value = "";
			FeaturesDemo.txtAddFileParamValue.value = "";
			alert("Param added.");
		} else {
			alert("Param not added.");
		}
	},
	removeFileParam: function () {
		if (FeaturesDemo.selQueue.selectedIndex === -1) {
			alert("Please select a file from the queue.");
			return;
		}
		var file_id = FeaturesDemo.selQueue.value;
		var name = FeaturesDemo.txtRemoveFileParamName.value;

		if (name === "") {
			alert("Please enter a Param name.");
			return;
		}

		if (FeaturesDemo.SU.removeFileParam(file_id, name)) {
			FeaturesDemo.txtRemoveFileParamName.value = "";
			alert("Param removed.");
		} else {
			alert("Param not removed.");
		}
	},
	addParam: function () {
		var name = FeaturesDemo.txtAddParamName.value;
		var value = FeaturesDemo.txtAddParamValue.value;

		if (name === "") {
			alert("Please enter a Param name.");
			return;
		}

		FeaturesDemo.selParams.options[FeaturesDemo.selParams.options.length] = new Option(name, value);
		FeaturesDemo.txtAddParamName.value = "";
		FeaturesDemo.txtAddParamValue.value = "";
	},
	removeParam: function () {
		if (FeaturesDemo.selParams.selectedIndex === -1) {
			alert("Please select a Param.");
			return;
		}

		FeaturesDemo.selParams.options[FeaturesDemo.selParams.selectedIndex] = null;
	},
	updateDynamicSettings: function () {
		// Build the param object
		var params = FeaturesDemo.getParamsObject();
		FeaturesDemo.SU.setPostParams(params);
		FeaturesDemo.SU.setHTTPSuccess(FeaturesDemo.txtHTTPSuccess.value);
		FeaturesDemo.SU.setAssumeSuccessTimeout(FeaturesDemo.txtAssumeSuccessTimeout.value);
		FeaturesDemo.SU.setFileTypes(FeaturesDemo.txtFileTypes.value, FeaturesDemo.txtFileTypesDescription.value);
		FeaturesDemo.SU.setFileSizeLimit(FeaturesDemo.txtFileSizeLimit.value);
		FeaturesDemo.SU.setFileUploadLimit(FeaturesDemo.txtFileUploadLimit.value);
		FeaturesDemo.SU.setFileQueueLimit(FeaturesDemo.txtFileQueueLimit.value);
		FeaturesDemo.SU.setFilePostName(FeaturesDemo.txtFilePostName.value);
		FeaturesDemo.SU.setDebugEnabled(FeaturesDemo.cbDebug.checked);
		FeaturesDemo.SU.setUseQueryString(FeaturesDemo.cbUseQueryString.checked);
		FeaturesDemo.SU.setRequeueOnError(FeaturesDemo.cbRequeueOnError.checked);
		
		FeaturesDemo.SU.setButtonDimensions(FeaturesDemo.txtButtonWidth.value, FeaturesDemo.txtButtonHeight.value);
		FeaturesDemo.SU.setButtonText(FeaturesDemo.txtButtonText.value);
		FeaturesDemo.SU.setButtonTextStyle(FeaturesDemo.txtButtonTextStyle.value);
		FeaturesDemo.SU.setButtonTextPadding(FeaturesDemo.txtButtonTextLeftPadding.value, FeaturesDemo.txtButtonTextTopPadding.value);
		FeaturesDemo.SU.setButtonDisabled(FeaturesDemo.cbButtonDisabled.checked);

		switch (true) {
		case FeaturesDemo.rbButtonActionSelectFiles.checked:
			FeaturesDemo.SU.setButtonAction(SWFUpload.BUTTON_ACTION.SELECT_FILES);
			break;
		case FeaturesDemo.rbButtonActionSelectFile.checked:
			FeaturesDemo.SU.setButtonAction(SWFUpload.BUTTON_ACTION.SELECT_FILE);
			break;
		case FeaturesDemo.rbButtonActionStartUpload.checked:
			FeaturesDemo.SU.setButtonAction(SWFUpload.BUTTON_ACTION.START_UPLOAD);
			break;
		}
		
		// We ignore any changes to the upload_url
		FeaturesDemo.txtUploadTarget.value = FeaturesDemo.SU.settings.upload_url;

		alert("Dynamic Settings updated.");
	},
	getParamsObject: function () {
		var params = {};
		for (var i = 0; i < FeaturesDemo.selParams.options.length; i++) {
			var name = FeaturesDemo.selParams.options[i].text;
			var value = FeaturesDemo.selParams.options[i].value;
			params[name] = value;
		}
		return params;
	},
	reloadSWFUpload: function () {
		try {
			var settings = {
				upload_url : FeaturesDemo.SU.settings.upload_url,
				use_query_string : FeaturesDemo.cbUseQueryString.checked,
				requeue_on_error : FeaturesDemo.cbRequeueOnError.checked,
				http_success : FeaturesDemo.txtHTTPSuccess.value.replace(" ", "").split(","),
				post_params : FeaturesDemo.getParamsObject(),
				file_size_limit : FeaturesDemo.txtFileSizeLimit.value,
				file_post_name : FeaturesDemo.txtFilePostName.value,
				file_types : FeaturesDemo.txtFileTypes.value,
				file_types_description : FeaturesDemo.txtFileTypesDescription.value,
				file_upload_limit : FeaturesDemo.txtFileUploadLimit.value,
				file_queue_limit : FeaturesDemo.txtFileQueueLimit.value,
				swfupload_loaded_handler : FeaturesDemoHandlers.swfUploadLoaded,
				file_queued_handler : FeaturesDemoHandlers.fileQueued,
				file_queue_error_handler : FeaturesDemoHandlers.fileQueueError,
				upload_progress_handler : FeaturesDemoHandlers.uploadProgress,
				upload_error_handler : FeaturesDemoHandlers.uploadError,
				upload_success_handler : FeaturesDemoHandlers.uploadSuccess,
				upload_complete_handler : FeaturesDemoHandlers.uploadComplete,
				debug_handler : FeaturesDemoHandlers.debug,
				flash_url : "../swfupload/swfupload.swf",
				debug : FeaturesDemo.cbDebug.checked,
				prevent_swf_caching : FeaturesDemo.cbPreventSWFCaching.checked,
				button_placeholder_id : "spanButtonPlaceholder",
				button_image_url : FeaturesDemo.txtButtonImageUrl.value,
				button_width : FeaturesDemo.txtButtonWidth.value,
				button_height : FeaturesDemo.txtButtonHeight.value,
				button_text : FeaturesDemo.txtButtonText.value,
				button_text_style : FeaturesDemo.txtButtonTextStyle.value,
				button_text_top_padding : FeaturesDemo.txtButtonTextTopPadding.value,
				button_text_left_padding : FeaturesDemo.txtButtonTextLeftPadding.value,
				button_disabled : FeaturesDemo.cbButtonDisabled.checked
			};

			var movie = FeaturesDemo.SU.getMovieElement();
			
			var placeHolder = document.createElement("span");
			placeHolder.id = "spanButtonPlaceholder";
			movie.parentNode.replaceChild(placeHolder, movie);
			
			FeaturesDemo.SU.destroy();
			
			FeaturesDemo.clearAll();

			FeaturesDemo.SU = new SWFUpload(settings);

		} catch (ex) {
			alert(ex);
		}
	}
};
