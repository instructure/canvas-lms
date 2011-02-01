var FeaturesDemoHandlers = {
	swfUploadLoaded : function () {
		FeaturesDemo.start(this);  // This refers to the SWFObject because SWFUpload calls this with .apply(this).
	},
	fileDialogStart : function () {
		try {
			FeaturesDemo.selEventsQueue.options[FeaturesDemo.selEventsQueue.options.length] = new Option("File Dialog Start", "");
		} catch (ex) {
			this.debug(ex);
		}
	},

	fileQueued : function (file) {
		try {
			var queueString = file.id + ":  0%:" + file.name;
			FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.options.length] = new Option(queueString, file.id);
			FeaturesDemo.selEventsQueue.options[FeaturesDemo.selEventsQueue.options.length] = new Option("File Queued: " + file.id, "");
		} catch (ex) {
			this.debug(ex);
		}
	},

	fileQueueError : function (file, errorCode, message) {
		try {
			var errorName = "";
			switch (errorCode) {
			case SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED:
				errorName = "QUEUE LIMIT EXCEEDED";
				break;
			case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
				errorName = "FILE EXCEEDS SIZE LIMIT";
				break;
			case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
				errorName = "ZERO BYTE FILE";
				break;
			case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
				errorName = "INVALID FILE TYPE";
				break;
			default:
				errorName = "UNKNOWN";
				break;
			}

			var errorString = errorName + ":File ID: " + (typeof(file) === "object" && file !== null ? file.id : "na") + ":" + message;
			FeaturesDemo.selEventsQueue.options[FeaturesDemo.selEventsQueue.options.length] = new Option("File Queue Error: " + errorString, "");

		} catch (ex) {
			this.debug(ex);
		}
	},
	
	fileDialogComplete : function (numFilesSelected, numFilesQueued) {
		try {
			FeaturesDemo.selEventsQueue.options[FeaturesDemo.selEventsQueue.options.length] = new Option("File Dialog Complete: " + numFilesSelected + ", " + numFilesQueued, "");
		} catch (ex) {
			this.debug(ex);
		}
	},
	
	uploadStart : function (file) {
		try {
			FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option("File Start: " + file.id, "");
		} catch (ex) {
			this.debug(ex);
		}

		return true;
	},

	uploadProgress : function (file, bytesLoaded, totalBytes) {

		try {
			var percent = Math.ceil((bytesLoaded / file.size) * 100);
			if (percent < 10) {
				percent = "  " + percent;
			} else if (percent < 100) {
				percent = " " + percent;
			}

			FeaturesDemo.selQueue.value = file.id;
			var queueString = file.id + ":" + percent + "%:" + file.name;
			FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = queueString;


			FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option("Upload Progress: " + bytesLoaded, "");
		} catch (ex) {
			this.debug(ex);
		}
	},

	uploadSuccess : function (file, serverData, receivedResponse) {
		try {
			var queueString = file.id + ":Done:" + file.name;
			FeaturesDemo.selQueue.value = file.id;
			FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = queueString;

			FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option("Upload Success: " + file.id, "");

			if (receivedResponse) {
				FeaturesDemo.divServerData.innerHTML = typeof(serverData) === "undefined" ? "" : serverData; //.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/\t/g, "    ").replace(/  /g, " &nbsp;");
			} else {
				FeaturesDemo.divServerData.innerHTML = "assume_success_timeout setting timed out before a response was received from the server";
			}
		} catch (ex) {
			this.debug(ex);
		}
	},

	uploadError : function (file, errorCode, message) {
		FeaturesDemo.divServerData.innerHTML = "";
		try {
			var errorName = "";
			switch (errorCode) {
			case SWFUpload.UPLOAD_ERROR.HTTP_ERROR:
				FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = file.id + ":HTTP:" + file.name;
				errorName = "HTTP ERROR";
				break;
			case SWFUpload.UPLOAD_ERROR.MISSING_UPLOAD_URL:
				errorName = "MISSING UPLOAD URL";
				break;
			case SWFUpload.UPLOAD_ERROR.IO_ERROR:
				FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = file.id + ":IO  :" + file.name;
				errorName = "IO ERROR";
				break;
			case SWFUpload.UPLOAD_ERROR.SECURITY_ERROR:
				FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = file.id + ":SEC :" + file.name;
				errorName = "SECURITY ERROR";
				break;
			case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
				errorName = "UPLOAD LIMIT EXCEEDED";
				break;
			case SWFUpload.UPLOAD_ERROR.UPLOAD_FAILED:
				errorName = "UPLOAD FAILED";
				break;
			case SWFUpload.UPLOAD_ERROR.SPECIFIED_FILE_ID_NOT_FOUND:
				errorName = "SPECIFIED FILE ID NOT FOUND";
				break;
			case SWFUpload.UPLOAD_ERROR.FILE_VALIDATION_FAILED:
				errorName = "FILE VALIDATION FAILED";
				break;
			case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
				errorName = "FILE CANCELLED";
				
				FeaturesDemo.selQueue.value = file.id;
				FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = file.id + ":----:" + file.name;

				FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option("File Cancelled " + file.id, "");
				break;
			case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
				errorName = "FILE STOPPED";
				
				FeaturesDemo.selQueue.value = file.id;
				FeaturesDemo.selQueue.options[FeaturesDemo.selQueue.selectedIndex].text = file.id + ":  0%:" + file.name;

				FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option("File Stopped " + file.id, "");
				break;
			default:
				errorName = "UNKNOWN";
				break;
			}

			var errorString = errorName + ":File ID: " + (typeof(file) === "object" && file !== null ? file.id : "na") + ":" + message;
			FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option(errorString, "");

		} catch (ex) {
			this.debug(ex);
		}
	},
	
	uploadComplete : function (file) {
		try {
			FeaturesDemo.selEventsFile.options[FeaturesDemo.selEventsFile.options.length] = new Option("Upload Complete: " + file.id, "");
		} catch (ex) {
			this.debug(ex);
		}
	},
	
	// This custom debug method sends all debug messages to the Firebug console.  If debug is enabled it then sends the debug messages
	// to the built in debug console.  Only JavaScript message are sent to the Firebug console when debug is disabled (SWFUpload won't send the messages
	// when debug is disabled).
	debug : function (message) {
		try {
			if (window.console && typeof(window.console.error) === "function" && typeof(window.console.log) === "function") {
				if (typeof(message) === "object" && typeof(message.name) === "string" && typeof(message.message) === "string") {
					window.console.error(message);
				} else {
					window.console.log(message);
				}
			}
		} catch (ex) {
		}
		try {
			if (this.settings.debug) {
				this.debugMessage(message);
			}
		} catch (ex1) {
		}
	}
};
