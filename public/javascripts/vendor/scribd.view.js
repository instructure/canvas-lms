/**

On Thu, Jan 27, 2011 at 4:50 PM, Jared Friedman <[redacted]> wrote:
> Hi JT,
> Very exciting for us that you're using our product in such a significant
> way!  We're very happy to have Instructure as a user.
> As for view.js, that's a great point about it not having a license.  From
> our perspective, please feel free to bundle, include, sell, modify, minify,
> or turn into a word soup any part of the file that we wrote.  I can't speak
> for the portions of the file that are adapted from Adobe's source code, but
> it is my understanding that Adobe has effectively granted permission for
> their use.
> Best of luck with Canvas.
> Jared
> Jared Friedman | CTO and Cofounder | Scribd, Inc. | [redacted] | We're
> hiring great engineers!
>
>
> On Thu, Jan 27, 2011 at 10:03 AM, JT Olds <[redacted]> wrote:
>>
>> Hello,
>>
>> As you may know, Instructure's LMS product Canvas makes heavy use of
>> Scribd. Thanks for your service!
>>
>> We are prepping to launch an open source product that integrates with
>> Scribd and we would love to bundle the Scribd Javascript API file as
>> well (http://www.scribd.com/javascripts/view.js). However, there is no
>> license provided with the file, and in fact, there is both copyright
>> information ascribed to Scribd, and Adobe (for Flash version
>> detection), inside the file.
>>
>> As the copyright holder of the majority of the file, would you
>> consider releasing a Scribd Javascript API file under a GPL-compatible
>> open source license? This could be MIT, BSD, LGPL, etc.
>>
>> Because we want to provide the best user experience for both ours and
>> Scribd's potential customers, we want to make sure our Javascript
>> loads as fast as possible by bundling it with our minified Javascript
>> packages, but we are unable to do so as we don't own the copyright.
>>
>> Thanks!
>>
>> -JT
>> Instructure, Inc.

*/

//this file appears to be written so that does not require prototype, fyi - tom
define([
  'INST' /* INST */,
  'i18n!scribd' 
], function(INST, I18n) {

if(typeof scribd == "undefined") {

	var scribd = new Object();
	
	/* ------------------------
		  Scribd Document
	-------------------------- */
	
	scribd.Document = function() {
	
		
		//Private vars
		this.__params = [ ];			// document attributes
		this.__callQueue = [ ];			// stores premature method calls for later replay, technically a stack (FILO)
		this.__listenerLookup = { };			// lookup[ eventType:String ] -> [ callback1:Function, callback2:Function ... ]
		
		if (arguments.length == 2) {
			// This option is included for backwards compatibility only!
			this.document_id = arguments[0];
			this.access_key = arguments[1];
			return this;
		}

		if (scribd.Document.caller != scribd.Document.getDoc
				&& scribd.Document.caller != scribd.Document.getDocFromUrl
				&& scribd.Document.caller != scribd.Document.getDocFromUrlForExtension
		                && scribd.Document.caller != undefined ) {
			throw new Error("There is no public constructor for scribd.Document.");
		}
	}
	
	scribd.Document.getDoc = function(document_id, access_key) {
		scribd_doc = new scribd.Document();
		scribd_doc.document_id = document_id;
		scribd_doc.access_key = access_key;
		return scribd_doc;
	}
	
	scribd.Document.getDocFromUrl = function(url, publisher_id) {
		scribd_doc = new scribd.Document();
		scribd_doc.url = url;
		scribd_doc.publisher_id = publisher_id;
		return scribd_doc;
	}
	
	scribd.Document.getDocFromUrlForExtension = function(url, extension_id) {
		scribd_doc = new scribd.Document();
		scribd_doc.url = url;
		scribd_doc.extension_id = extension_id;
		scribd_doc.addParam("should_redirect", true);
		return scribd_doc;
	}
		
	
	
	scribd.Document.prototype = {
		/* ---------------
		
		Private Methods
		
		Note: Routed events are those which get routed through a globally defined method: window._scribd_event_handler_embedName()
		We define this method to allow message passing between iPaper and this particular scribd.Document instance. Only used
		for browsers which don't adhere to the DOM 2 event specification (IE).
		
		Workflow:
			1) Assign window._scribd_event_handler_embedName = this.__handleEvent, in this.write()
			2) Add any event listeners to this.__listenerLookup
			3) iPaper calls window._scribd_event_handler_embedName to trigger events, which get routed back through to this.__handleEvent
			4) Iterate through __listenerLookup, firing the appropriate callbacks
		
		----------------- */
		
		__handleEvent: function( eventType ){
			var listeners = this.__listenerLookup[eventType] || [];
			
			for (var i=0; i<listeners.length; i++)
			{
				listeners[i]();
			}
		},
		
		__addRoutedListener: function( eventType, callback ){
      
			if ( this.__listenerExists(eventType, callback) )
				return;
        
			if (this.__listenerLookup[ eventType ]){
				this.__listenerLookup[ eventType ].push(callback);
			} else {
				this.__listenerLookup[ eventType ] = new Array( callback );
			}
		},
		
		__removeRoutedListener: function( eventType, callback ){
			var listeners = this.__listenerLookup[ eventType ];
			for (var i=0; i<listeners.length; i++ ){
				if( listeners[i] == callback ){
					listeners.splice(i, 1);
				}
			}
		},
		
		__listenerExists: function( eventType, callback ){
			var listeners = this.__listenerLookup[ eventType ] || [];
			for ( var i=0; i<listeners.length; i++ ){
				if (listeners[i] == callback) return true;
			}
			return false;
		},
		
		
		/* ---------------
			Public Methods
		---------------- */
		
		addEventListener: function( eventType, callback, optBubble ){
			if (this.api){
				if (window.addEventListener){
					this.api.parentNode.addEventListener( eventType, callback, false );
				} else {
					this.__addRoutedListener( eventType, callback );
				}
			} else {
				this.__callQueue.push(["addEventListener", eventType, callback, false]);
			}
		},
		
		removeEventListener: function( eventType, callback ){
			if (this.api){
				if (window.addEventListener){
					this.api.removeEventListener( eventType, callback, false );
				} else {
					this.__removeRoutedListener( eventType, callback );
				}
			} else {
				this.__callQueue.push(["removeEventListener", eventType, callback]);
			}
		},
		
		getElement : function () {
			return document.getElementsByName( this.__embedName )[0]
		},
		
		addParam : function(name, value) {
			this.__params[name] = value;
		},

		grantAccess : function(user_identifier, secure_session_id, signature) {
			this.__params["user_identifier"] = user_identifier;
			this.__params["secure_session_id"] = secure_session_id;
			this.__params["signature"] = signature;
		},
		
		write : function(elementId) {
			var element = document.getElementById(elementId);
			quickswitch = (this.__params["quickswitch"] == true);

			if (quickswitch) {			
				// create container at body level to avoid calling innerHTML on an element with an inline ancestor
				var container = document.createElement('div');
				container.style.width = "100%";
				container.style.height = "100%";
				document.body.appendChild(container);
			}

			var auto_width = element.offsetWidth;
			var view_mode = '';
			var flashVars = '';
			if (this.__params["width"] && this.__params["width"] != "parent") {
				auto_width = this.__params["width"];
			}
			if (this.__params["mode"]){
				view_mode = this.__params['mode'];
				flashVars += '&viewMode=' + escape(this.__params['mode']);
			}

			if (this.__params["height"] != "parent") {
				var auto_height = Math.round(auto_width * 11.0 / 8.5)
				if (view_mode == 'slideshow')
				{
					auto_height = 35 + Math.round(auto_width * 3.0 / 4.0);
				}

				// Get height of page
				var page_height = window.innerHeight != null
						? window.innerHeight
						: document.documentElement && document.documentElement.clientHeight
								? document.documentElement.clientHeight
								: document.body != null
										? document.body.clientHeight
										: 0;
				
				page_height -= 25; // some breathing room
				
				// Bound the height
				if (auto_height < 200) {
					auto_height = 200;
				}
				if (auto_height > page_height) {
					auto_height = page_height;
				}
				
				var embedHeight = auto_height + "px";
			} else {
				var embedHeight = "100%";
			}
			
			var embedWidth = "100%";
			var embedName = elementId + '_embed' + Math.round(Math.random() * 9e9);
			this.__embedName = embedName;
			var srcString = "ScribdViewer";
			
			// This defaults to true so we only need to handle explicit false cases
			if (this.__params["auto_size"] != true){
				flashVars += '&auto_size=false';
			}
			
			if (this.__params["height"] && this.__params["height"] != "parent"){
				embedHeight = this.__params["height"] + "px";
			}
			if (this.__params["width"] && this.__params["width"] != "parent"){
				embedWidth = this.__params["width"] + "px";
			}
			
			// Params
			if (this.__params["swf_name"]){
				srcString = this.__params["swf_name"];
			}
			
			if (this.__params["disable_related_docs"]){
				flashVars += '&disable_related_docs=' + this.__params["disable_related_docs"];
			}
			if (this.__params["page"]){
				flashVars += '&page=' + this.__params["page"];
			}
			if (this.__params["extension"]){
				flashVars += '&extension=' + this.__params["extension"];
			}
			if (this.__params["title"]){
				flashVars += '&title=' + escape(this.__params["title"]);
			}
			if (this.__params["my_user_id"]){
				flashVars += '&my_user_id=' + this.__params["my_user_id"];
			}
			if (this.__params["api_url"]){
				flashVars += '&api_url=' + this.__params["api_url"];
			}
			if (this.__params["doctype"]){
				flashVars += '&doctype=' + this.__params["doctype"];
			}
			if (this.__params["current_user_id"]){
				flashVars += '&current_user_id=' + this.__params["current_user_id"];
			}
			if (this.__params["search_query"]){
				flashVars += '&search_query=' + escape(this.__params["search_query"]);
			}
			if (this.__params["search_keywords"]){
				flashVars += '&search_keywords=' + escape(this.__params["search_keywords"]);
			}
			if (this.__params["transferCookie"]==true){
				flashVars += '&cookie=' + escape(document.cookie);
			}
			if (this.__params["should_redirect"]){
				flashVars += '&should_redirect=' + this.__params["should_redirect"];
			}
			if (this.__params["secret_password"]){
				flashVars += '&secret_password=' + this.__params["secret_password"];
			}
			if (this.__params["public"] == true){
				flashVars += '&privacy=0';
      		}
      		else {
        		flashVars += '&privacy=1';
			}
			
			if (this.__params["user_identifier"]) {
		        flashVars += '&user_identifier=' + escape(this.__params["user_identifier"]);
			}
			if (this.__params["secure_session_id"]) {
		        flashVars += '&secure_session_id=' + escape(this.__params["secure_session_id"]);
			}
			if (this.__params["signature"]) {
		        flashVars += '&signature=' + this.__params["signature"];
			}
			if (this.__params["docinfo"]) {
				//need to use encodeURIComponent for '+' and '/' in base64 encoding
				flashVars += '&docinfo=' + encodeURIComponent(this.__params["docinfo"]);
			}
			if (this.__params["useIntegratedUi"]) {
				flashVars += '&useIntegratedUi=' + this.__params["useIntegratedUi"];
			}


					
			// Document Attributes
			if (this.document_id){
				flashVars += '&document_id=' + this.document_id;
			}
			if (this.access_key){
				flashVars += '&access_key=' + this.access_key;
			}
			if (this.extension_id){
				flashVars += '&extension_id=' + this.extension_id;
			}
			if (this.url){
				flashVars += '&url=' + escape(this.url);
			}
			if (this.publisher_id){
				flashVars += '&publisher_id=' + escape(this.publisher_id);
			}
			
			var srcPath = "http://d1.scribdassets.com/";
			var protocol = "http://";
			
			if (this.__params["use_ssl"] == true) {
				srcPath = "https://s3.amazonaws.com/documents.scribd.com/";
				flashVars += "&use_ssl=true"; 
				protocol = 'https://';
			}
			
			if (this.__params["src_path"]) {
        			srcPath = this.__params["src_path"];
			}
			if (this.__params["hide_sample_banner"]){
				flashVars += '&hide_sample_banner=' + this.__params["hide_sample_banner"];
			}
			
			if (this.__params["disable_resume_reading"] == true){
				flashVars += '&disable_resume_reading=true';
			}
			
			if (this.__params["hide_full_screen_button"] == true){
				flashVars += '&hide_full_screen_button=true';
			}
			
			if (this.__params["hide_disabled_buttons"] == true){
				flashVars += '&hide_disabled_buttons=true';
			}
			
			if (this.__params["full_screen_type"]){
				flashVars += '&full_screen_type=' + this.__params["full_screen_type"];
			}

			if (this.__params["custom_logo_image_url"]) {
				flashVars += '&custom_logo_image_url=' + escape(this.__params["custom_logo_image_url"]);
			}

			if (this.__params["custom_logo_click_url"]) {
				flashVars += '&custom_logo_click_url=' + escape(this.__params["custom_logo_click_url"]);
			}

			var embedString = Mod_AC_FL_RunContent(
					'codebase', protocol + 'download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0',
					'width', embedWidth, 
					'height', embedHeight, 
					'flashvars', flashVars, 
					'src', srcPath + srcString,
					'quality', 'high', 
					'pluginspage', protocol + 'www.macromedia.com/go/getflashplayer', 
					'align', 'middle', 
					'play', 'true', 
					'loop', 'true', 
					'scale','showall', 
					'wmode', 'opaque', 
					'devicefont', 'false', 
					'id',embedName, 
					'bgcolor', '#ffffff', 
					'name', embedName, 
					'menu','true', 
					'allowFullScreen', 'true', 
					'allowScriptAccess','always', 
					'movie', srcPath + srcString,
					'salign','');
					
      var flash_ok = DetectFlashVer(9,0,0);
      if (!flash_ok) {
        // INSTRUCTURE: Make it a span with display: block instead of a div 
        //   to prevent evil and sadness on browsers that actually care about 
        //   such things
        embedString = '<span style="display:block;font-size:16px;width:300px;border:1px solid #dddddd;padding:3px">' + I18n.t('upgrade_flash', 'Hello, you have an old version of Adobe Flash Player. To use iPaper (and lots of other stuff on the web) you need to %{link_tag}get the latest Flash player%{end_link}.', {link_tag: '<a href="http://www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash">', end_link: '</a>'}) + '  </span>';
      }
			
			
			if(quickswitch) {
				
				/* For QuickSwitch, we avoid calling innerHTML on an element that isn't 
				directly attached to the body. This avoids the IE issue where calling 
				innerHTML on a block element that has in its ancestry an inline element 
				will throw an exception */
				
				// set container innerHTML, which is a direct child of body
				container.innerHTML = embedString;
			
				// delete all child nodes of element
				if (element.hasChildNodes()) {
					while (element.childNodes.length >= 1) {
						element.removeChild(element.firstChild);
					}
				}
				
				element.appendChild(container);
			}
			else
			{
				element.innerHTML = embedString;
			}
			
			var __this = this;
			
			// Event router for IE (which doesn't properly support custom events)
			window[ "_scribd_event_handler_" + embedName ] = function(eventType){ __this.__handleEvent(eventType) };
			
			//
			// setupJsApi -- attach event listeners
			//
			var onSetupJsApi = function(e)
			{ 
			  var e = e || {};		// In the case of IE, there will be no Event so we return an empty object
				var target = e.srcElement || document.getElementsByName(embedName)[0];
				
				if (target.getAttribute('name') == embedName)
				{
					__this.api = target;
          // Grab the next call on the queue, check to see if it's actionable, if not push onto a stack which will replace __callQueue
					var i, method, callParams, rejectedCalls = [];
					
					for (var i=0; i<__this.__callQueue.length; i++)
					{
					  callParams = __this.__callQueue[i];
					  if (callParams[0] == "addEventListener") {  // Execute all listener calls
					    method = callParams.shift();
              __this[method].apply( __this, callParams );
					  } else {
					    rejectedCalls.push( callParams ); // Send back to __callQueue
					  }
					}
					__this.__callQueue = rejectedCalls; // end callQueue
				}
			}
			
			//
			// iPaperReady -- pump call queue
			//
			
			var oniPaperReady = function(e)
			{
				var e = e || {};		// In the case of IE, there will be no Event so we return an empty object
				var target = e.srcElement || document.getElementsByName(embedName)[0];
				
				if (target.getAttribute('name') == embedName) {
				  
					if (__this.onReady){
						__this.onReady();
					}
					
					// Grab the next call on the queue, check to see if it's actionable, if not push onto a stack which will replace __callQueue (rejectedCalls)
					var i, method, callParams, rejectedCalls = [];
					for (i=0; i<__this.__callQueue.length; i++) {
					  callParams = __this.__callQueue.pop();
					  if (callParams[0] != "addEventListener") {  // Execute all non-listener calls
					    method = callParams.shift();
					    if (typeof method != "function") alert(typeof method)
					    __this[ method ].apply( __this, callParams );
					  } else {
					    rejectedCalls.push( callParams ); // Send back to __callQueue
					  }
					}
					__this.__callQueue = rejectedCalls;
					
					// TODO: implement this properly - redispatch initial mouse over event in case browser missed it (firefox, webkit)
					
          // if (__this.initialMouseOver && target.dispatchEvent)
          // {
          //  var evt = target.ownerDocument.createEvent('MouseEvents');
          //  evt.initMouseEvent('mouseover', true, true,
          //      target.ownerDocument.defaultView, 1, 0, 0, 0, 0, false,
          //      false, false, false, 0, null);  
          //  target.dispatchEvent(evt);
          // }
				}
			}
			
			
			if (window.addEventListener){
				window.addEventListener('iPaperReady', oniPaperReady, true);
				window.addEventListener('setupJsApi', onSetupJsApi, true)
			} else {
				// No DOM 2 Support
				this.__addRoutedListener('iPaperReady', oniPaperReady);
				this.__addRoutedListener('setupJsApi', onSetupJsApi);
			}
            
			// initial mouse over notification (for firefox and chrome)
      // this.initialMouseOver = false;
      // 
      // if (window.addEventListener){
      //  element.addEventListener('mouseover', function() { __this.initialMouseOver = true; }, false);
      //  element.addEventListener('mouseout', function() { __this.initialMouseOver = false; }, false);
      // }
		}
	}







	/* ------------------------
		AC_RunActiveContent
	
		Modified to return the embed string, rather than use document.write - modified functions prefixed with 'Mod_'
		Implied consent for use: http://www.adobe.com/devnet/activecontent/articles/devletter.html
	
	-------------------------- */

	// v1.7
	// Flash Player Version Detection
	// Detect Client Browser type
	// Copyright 2005-2007 Adobe Systems Incorporated.  All rights reserved.
	var isIE  = (navigator.appVersion.indexOf("MSIE") != -1) ? true : false;
	var isWin = (navigator.appVersion.toLowerCase().indexOf("win") != -1) ? true : false;

	var isOpera = (navigator.userAgent.indexOf("Opera") != -1) ? true : false;

	function ControlVersion()
	{
		var version;
		var axo;
		var e;

		// NOTE : new ActiveXObject(strFoo) throws an exception if strFoo isn't in the registry

		try {
			// version will be set for 7.X or greater players
			axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");
			version = axo.GetVariable("$version");
		} catch (e) {
		}

		if (!version)
		{
			try {
				// version will be set for 6.X players only
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");
			
				// installed player is some revision of 6.0
				// GetVariable("$version") crashes for versions 6.0.22 through 6.0.29,
				// so we have to be careful. 
			
				// default to the first public version
				version = "WIN 6,0,21,0";

				// throws if AllowScripAccess does not exist (introduced in 6.0r47)		
				axo.AllowScriptAccess = "always";

				// safe to call for 6.0r47 or greater
				version = axo.GetVariable("$version");

			} catch (e) {
			}
		}

		if (!version)
		{
			try {
				// version will be set for 4.X or 5.X player
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.3");
				version = axo.GetVariable("$version");
			} catch (e) {
			}
		}

		if (!version)
		{
			try {
				// version will be set for 3.X player
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.3");
				version = "WIN 3,0,18,0";
			} catch (e) {
			}
		}

		if (!version)
		{
			try {
				// version will be set for 2.X player
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash");
				version = "WIN 2,0,0,11";
			} catch (e) {
				version = -1;
			}
		}
	
		return version;
	}

	// JavaScript helper required to detect Flash Player PlugIn version information
	function GetSwfVer(){
		// NS/Opera version >= 3 check for Flash plugin in plugin array
		var flashVer = -1;
	
		if (navigator.plugins != null && navigator.plugins.length > 0) {
			if (navigator.plugins["Shockwave Flash 2.0"] || navigator.plugins["Shockwave Flash"]) {
				var swVer2 = navigator.plugins["Shockwave Flash 2.0"] ? " 2.0" : "";
				var flashDescription = navigator.plugins["Shockwave Flash" + swVer2].description;
				var descArray = flashDescription.split(" ");
				var tempArrayMajor = descArray[2].split(".");			
				var versionMajor = tempArrayMajor[0];
				var versionMinor = tempArrayMajor[1];
				var versionRevision = descArray[3];
				if (versionRevision == "") {
					versionRevision = descArray[4];
				}
				if (versionRevision[0] == "d") {
					versionRevision = versionRevision.substring(1);
				} else if (versionRevision[0] == "r") {
					versionRevision = versionRevision.substring(1);
					if (versionRevision.indexOf("d") > 0) {
						versionRevision = versionRevision.substring(0, versionRevision.indexOf("d"));
					}
				}
				var flashVer = versionMajor + "." + versionMinor + "." + versionRevision;
			}
		}
		// MSN/WebTV 2.6 supports Flash 4
		else if (navigator.userAgent.toLowerCase().indexOf("webtv/2.6") != -1) flashVer = 4;
		// WebTV 2.5 supports Flash 3
		else if (navigator.userAgent.toLowerCase().indexOf("webtv/2.5") != -1) flashVer = 3;
		// older WebTV supports Flash 2
		else if (navigator.userAgent.toLowerCase().indexOf("webtv") != -1) flashVer = 2;
		else if ( isIE && isWin && !isOpera ) {
			flashVer = ControlVersion();
		}	
		return flashVer;
	}

	// When called with reqMajorVer, reqMinorVer, reqRevision returns true if that version or greater is available
	function DetectFlashVer(reqMajorVer, reqMinorVer, reqRevision)
	{
		versionStr = GetSwfVer();
		if (versionStr == -1 ) {
			return false;
		} else if (versionStr != 0) {
			if(isIE && isWin && !isOpera) {
				// Given "WIN 2,0,0,11"
				tempArray         = versionStr.split(" "); 	// ["WIN", "2,0,0,11"]
				tempString        = tempArray[1];			// "2,0,0,11"
				versionArray      = tempString.split(",");	// ['2', '0', '0', '11']
			} else {
				versionArray      = versionStr.split(".");
			}
			var versionMajor      = versionArray[0];
			var versionMinor      = versionArray[1];
			var versionRevision   = versionArray[2];

	        	// is the major.revision >= requested major.revision AND the minor version >= requested minor
			if (versionMajor > parseFloat(reqMajorVer)) {
				return true;
			} else if (versionMajor == parseFloat(reqMajorVer)) {
				if (versionMinor > parseFloat(reqMinorVer))
					return true;
				else if (versionMinor == parseFloat(reqMinorVer)) {
					if (versionRevision >= parseFloat(reqRevision))
						return true;
				}
			}
			return false;
		}
	}

	function AC_AddExtension(src, ext)
	{
	  if (src.indexOf('?') != -1)
	    return src.replace(/\?/, ext+'?'); 
	  else
	    return src + ext;
	}

	function Mod_AC_Generateobj(objAttrs, params, embedAttrs) 
	{ 
	  var str = '';
	  if (isIE && isWin && !isOpera)
	  {
	    str += '<object ';
	    for (var i in objAttrs)
	    {
	      str += i + '="' + objAttrs[i] + '" ';
	    }
	    str += '>';
	    for (var i in params)
	    {
	      str += '<param name="' + i + '" value="' + params[i] + '" /> ';
	    }
	    str += '</object>';
	  }
	  else
	  {
	    str += '<embed ';
	    for (var i in embedAttrs)
	    {
	      str += i + '="' + embedAttrs[i] + '" ';
	    }
	    str += '> </embed>';
	  }

	  return str;
	}

	function Mod_AC_FL_RunContent(){
	  var ret = AC_GetArgs( arguments, ".swf", "movie", "clsid:d27cdb6e-ae6d-11cf-96b8-444553540000", "application/x-shockwave-flash" );
  
	  return Mod_AC_Generateobj(ret.objAttrs, ret.params, ret.embedAttrs);
	}

	function Mod_AC_SW_RunContent(){
	  var ret = 
	    AC_GetArgs
	    (  arguments, ".dcr", "src", "clsid:166B1BCA-3F9C-11CF-8075-444553540000"
	     , null
	    );
	  return Mod_AC_Generateobj(ret.objAttrs, ret.params, ret.embedAttrs);
	}

	function AC_GetArgs(args, ext, srcParamName, classid, mimeType){
	  var ret = new Object();
	  ret.embedAttrs = new Object();
	  ret.params = new Object();
	  ret.objAttrs = new Object();
	  for (var i=0; i < args.length; i=i+2){
	    var currArg = args[i].toLowerCase();    

	    switch (currArg){	
	      case "classid":
	        break;
	      case "pluginspage":
	        ret.embedAttrs[args[i]] = args[i+1];
	        break;
	      case "src":
	      case "movie":	
	        args[i+1] = AC_AddExtension(args[i+1], ext);
	        ret.embedAttrs["src"] = args[i+1];
	        ret.params[srcParamName] = args[i+1];
	        break;
	      case "onafterupdate":
	      case "onbeforeupdate":
	      case "onblur":
	      case "oncellchange":
	      case "onclick":
	      case "ondblclick":
	      case "ondrag":
	      case "ondragend":
	      case "ondragenter":
	      case "ondragleave":
	      case "ondragover":
	      case "ondrop":
	      case "onfinish":
	      case "onfocus":
	      case "onhelp":
	      case "onmousedown":
	      case "onmouseup":
	      case "onmouseover":
	      case "onmousemove":
	      case "onmouseout":
	      case "onkeypress":
	      case "onkeydown":
	      case "onkeyup":
	      case "onload":
	      case "onlosecapture":
	      case "onpropertychange":
	      case "onreadystatechange":
	      case "onrowsdelete":
	      case "onrowenter":
	      case "onrowexit":
	      case "onrowsinserted":
	      case "onstart":
	      case "onscroll":
	      case "onbeforeeditfocus":
	      case "onactivate":
	      case "onbeforedeactivate":
	      case "ondeactivate":
	      case "type":
	      case "codebase":
	      case "id":
	        ret.objAttrs[args[i]] = args[i+1];
	        break;
	      case "width":
	      case "height":
	      case "align":
	      case "vspace": 
	      case "hspace":
	      case "class":
	      case "title":
	      case "accesskey":
	      case "name":
	      case "tabindex":
	        ret.embedAttrs[args[i]] = ret.objAttrs[args[i]] = args[i+1];
	        break;
	      default:
	        ret.embedAttrs[args[i]] = ret.params[args[i]] = args[i+1];
	    }
	  }
	  ret.objAttrs["classid"] = classid;
	  if (mimeType) ret.embedAttrs["type"] = mimeType;
	  return ret;
	}

	// call callback function if defined 
	// this is used so we make sure view.js is loaded before calling 
	// other code that depends on it
	if(typeof scribd_view_callback != "undefined") {
		scribd_view_callback();
	}
}

return scribd;
});

/* ------------------------
     (c) Scribd 2008
------------------------- */
