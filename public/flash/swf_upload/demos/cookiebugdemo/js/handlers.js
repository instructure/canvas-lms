/* **********************
   Event Handlers
   These are my custom event handlers to make my
   web application behave the way I went when SWFUpload
   completes different tasks.  These aren't part of the SWFUpload
   package.  They are part of my application.  Without these none
   of the actions SWFUpload makes will show up in my application.
   ********************** */
function fileDialogComplete(numFilesSelected, numFilesQueued) {
	this.startUpload();
}

function uploadSuccess(file, serverData) {
	try {
		document.getElementById("divStatus").innerHTML = this.getStats().successful_uploads + " files uploaded";
		
		var p = document.createElement("p");
		p.innerHTML = "FlashCookie set to " + serverData;
		document.getElementById("divCookieValues").appendChild(p);
	} catch (ex) {

	}
}
