var instance = {},
    tinychat,
    TinychatEmbed,
    getWindowSize;

tinychat = function(flashvars, options) {
  return new TinychatEmbed(flashvars, options).initialize()
}

TinychatEmbed = function(flashvars, options) {
  if(typeof flashvars.room != 'string') {
    this.initialize = function() { alert('Developer: please send "room" and "target" variables.'); };
    return this;
  }

  // Set defaults
  this.applicationId = 'tinychat' + flashvars.room;
  this.flashvars = {
    key: 'tinychat',
    target: 'client'
  };

  this.options = {
    baseUrl: '//tinychat.com/embed/',
    bgcolor: '#222'
  };

  // Override defaults w/ given params and options.
  for(var i in flashvars) {
    this.flashvars[i] = flashvars[i];
  }

  for(var i in options) {
    this.options[i] = options[i];
  }

  this.data = {
    inFocus: true,
    interval: {},
    messageCount: 0,
    originalDocumentTitle: document.title,
    privateChatListInFocus: false,
    privateChatSenderName: null,
    publicChatListInFocus: false,
    scripts: [],
    SWAP_TIMEOUT: 2000,
    swapToPrivateChatMessageNotice: true,
    titleSwapTimer: null
  };
}

TinychatEmbed.prototype.load_script = function(url, callback, timeout) {
  var _self  = this,
      script = document.createElement('script');
  if (!timeout) timeout = 3;

  for (var i in this.data.scripts) {
    if (this.data.scripts[i] === url) return callback(true);
  }

  this.data.scripts[this.data.scripts.length] = url;

  script.src = url;

  if (typeof callback == 'function') {
    //http://www.aaronpeters.nl/blog/prevent-double-callback-execution-in-IE9
    if (script.readyState) {
      // IE, incl. IE9
      script.onreadystatechange = function() {
        if (script.readyState === 'loaded' || script.readyState === 'complete') {
          delete script.onreadystatechange;
          window.clearTimeout(_self.data.interval[url]);
          callback(true);
        }
      };
    }
    else {
      // other browsers
      script.onload = function() {
        window.clearTimeout(_self.data.interval[url]);
        callback(true);
      };
    }

    document.getElementsByTagName('head')[0].appendChild(script);
    this.data.interval[url] = window.setTimeout(function() {
      script.onreadystatechange = function(){};
      script.onload             = function(){};
      callback(false);
    }, (timeout * 1000));
  }

  return true;
}

TinychatEmbed.prototype.initialize = function() {
  var _self = this;

  this.load_script('//ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js', function() {
    _self.embedFlash();
    if (typeof _self.callback == 'function') _self.callback();
  });

  return this;
}

TinychatEmbed.prototype.reloadFlash = function() {
  var targetDiv = document.createElement('div');
  targetDiv.id  = this.flashvars.target;
  document.getElementById(this.applicationId).parentNode.appendChild(targetDiv);

  swfobject.removeSWF(this.applicationId);
  this.embedFlash();
}

TinychatEmbed.prototype.embedFlash = function() {
  var majorVersion  = swfobject.getFlashPlayerVersion().major,
      minorVersion  = swfobject.getFlashPlayerVersion().minor,
      appUrl        = this.getApplicationUrl(majorVersion, minorVersion),
      versionString = majorVersion + "." + minorVersion + ".0",
      params,
      attributes;

  instance[this.flashvars.target] = this;

  params = {
    allowfullscreen: 'true',
    allowscriptaccess: 'always',
    bgcolor: this.options.bgcolor,
    quality: 'high',
    wmode: this.flashvars.wmode
  };

  attributes = {
    align: 'middle',
    id: this.applicationId,
    name: this.applicationId
  };

  swfobject.embedSWF(appUrl, this.flashvars.target, "100%", "100%", versionString, false, this.flashvars, params, attributes);
  this.registerListeners();
}

TinychatEmbed.prototype.onFocusHandler = function() {
  if (this.data.publicChatListInFocus)  this.data.messageCount = 0;
  if (this.data.privateChatListInFocus) this.resetPrivateChatMessageNotice();
  this.data.inFocus = true;
  this.updateTitle();
}

TinychatEmbed.prototype.onBlurHandler = function() {
  this.data.inFocus = false;
  this.updateTitle();
}

TinychatEmbed.prototype.registerListeners = function() {
  var _self = this;

  window.onfocus = function() { _self.onFocusHandler(); };
  window.onblur  = function() { _self.onBlurHandler();  };

  if (window.addEventListener) {
    window.addEventListener('message', function(e) {
      _self.oAuthDone(e.data);
    }, false);
  } else if (window.attachEvent) {
    window.attachEvent('onmessage', function(e) {
      _self.oAuthDone(e.data);
    });
  }
}

TinychatEmbed.prototype.getApplicationUrl = function(majorVersion, minorVersion) {
  var swfName;

  if (majorVersion > 10) {
    swfName = 'Tinychat-11.1-1.0.0.0546.swf';
  } else if (majorVersion == 10) {
    if (minorVersion >= 3) {
      swfName = 'Tinychat-10.3-1.0.0.0546.swf';
    } else if (minorVersion == 2) {
      swfName = 'Tinychat-10.2-1.0.0.0546.swf';
    } else {
      swfName = 'Tinychat-10.0-1.0.0.0546.swf';
    }
  }

  // version is for cache busting, not choosing an actual version
  return this.options.baseUrl + swfName + '?version=1.0.0.0546';
}

TinychatEmbed.prototype.openSecurityPanel = function(panel) {
  var url    = this.options.baseUrl + 'SecurityPanelPopup.html?panel=' + panel + '&' + Math.random(),
      iframe = createIframe("SecurityPanel", url, 215, 138);
  this.centerElement(iframe);

  document.body.appendChild(iframe);
}

TinychatEmbed.prototype.closeSecurityPanel = function() {
  var iframe = getSecurityPanel(),
      app;
  document.body.removeChild(iframe);
  app = this.getApplication();
  app.securityPanelClosed();
}

TinychatEmbed.prototype.securityPanelAuthorizationChanged = function(bool) {
  var app = this.getApplication();
  app.securityPanelAuthorizationChanged(bool);
}

TinychatEmbed.prototype.getSecurityPanel = function() {
  return document.getElementById('SecurityPanel');
}

TinychatEmbed.prototype.getApplication = function() {
  return document.getElementById(this.applicationId);
}

TinychatEmbed.prototype.createIframe = function(id, url, width, height) {
  var iframe = document.createElement('iframe');

  iframe.allowTransparency = true;
  iframe.frameBorder       = 0;
  iframe.style.overflow    = 'hidden';
  iframe.style.position    = 'absolute';
  iframe.style.display     = 'block';
  iframe.id                = id;
  iframe.setAttribute('src', url);

  if (width)  iframe.width  = width;
  if (height) iframe.height = height;

  return iframe;
}

TinychatEmbed.prototype.createFloatingDiv = function(id) {
  var div = document.createElement('div');
  if (id) div.id = id;
  document.body.appendChild(div);

  div.style.position = 'fixed';
  div.style.left     = '45%';
  div.style.top      = '45%';
  div.style.zIndex   = 50;
}

TinychatEmbed.prototype.toggleElementVisibility = function(id, visible) {
  var element = document.getElementById(id);

  if (element) {
    if (visible) {
      element.style.display = 'block';
    } else {
      element.style.display = 'none';
    }
  }
}

TinychatEmbed.prototype.centerElement = function(element) {
  var point = getWindowSize();

  element.style.position = 'fixed';
  element.style.left = point.x + 'px';
  element.style.top = point.y + 'px';
}

TinychatEmbed.prototype.clientOAuth = function(site, type, room, cid) {
  var _self = this,
      app = _self.getApplication(),
      url = '//tinychat.com/api/clientoauth?type=' + type + '&site=' + site + '&room=' + room + '&cid=' + cid,
      wid = _self.openPopup(url),
      lastHash = '' + window.location.hash,
      timer, l, json, resp, tc;

  if (!wid || wid === null) return app.oAuthResponse('blocked');

  timer = setInterval(function() {
    if (wid.closed) {
      clearInterval(timer);
      _self.clearHash();
      return app.oAuthResponse('closed');
    }

    // location.hash method
    try {
      l = '' + window.location.hash;

      if ('' + window.location.hash !== lastHash ) {
        json = unescape(window.location.hash.substring(1));

        if (json.indexOf('#') > 0) json = json.substring(0, json.indexOf('#'));
        resp = jQuery.parseJSON(json);
        try {
          app.oAuthResponse(resp.res, resp.type, resp.id, resp.name, resp.pic);
        } catch (x) {
          // fail silently
        }

        clearInterval(timer);
        wid.close();
        return _self.clearHash();
      }
    } catch(x) {
      // fail silently
    }

    // try postmessage method for non tinychat.com embeds
    try {
      l  = '' + window.location;
      tc = l.indexOf('//tinychat.com');

      if (tc !== 0 && wid.postMessage) {
        wid.postMessage(timer, 'http://tinychat.com/closepopup');
      } else {
        // materialize function method
        resp = wid.checkoauth();

        if (resp.done) {
          try {
            app.oAuthResponse(resp.res, resp.type, resp.id, resp.name, resp.pic);
          } catch (x) {
            // fail silently
          }

          clearInterval(timer);
          wid.close();
          return _self.clearHash();
        }
      }
    }  catch(x) {
      // fail silently
    }
  }, 1000);
}

TinychatEmbed.prototype.clearHash = function() {
  var l = '' + window.location;
  window.location = l.indexOf('#') > 0 ? l.substring(0, l.indexOf('#')) + '#' : l + '#';
}

TinychatEmbed.prototype.oAuthDone = function(data) {
  var resp, app;

  try {
    if (data) {
      var resp = data.split(/,/);
      if (resp.length == 5) {
        clearInterval(resp[0]);
        app = this.getApplication();
        app.oAuthResponse('OK', resp[1], resp[2], resp[3], resp[4]);
      }
    }
  } catch (x) {
    // fail silently
  }
}

TinychatEmbed.prototype.openPopup = function(url, width, height) {
  if (!width) width = 785;
  if (!height) height = 450;
  return window.open(url, 'win', 'menubar=no,width=' + width + ',height=' + height+ ',toolbar=no');
}

/** Chat message received indicators **/
TinychatEmbed.prototype.getPublicChatUnreadMessageCount = function() {
  return this.data.messageCount;
}

TinychatEmbed.prototype.increasePublicChatUnreadMessageCount = function() {
  if (!this.data.publicChatListInFocus || !this.data.inFocus) {
    this.data.messageCount++;
    this.updateTitle();
  }
}

TinychatEmbed.prototype.privateMessageReceived = function(senderName) {
  if (!this.data.privateChatListInFocus || !this.data.inFocus) {
    if (this.data.titleSwapTimer) this.resetPrivateChatMessageNotice();
    this.data.privateChatSenderName = senderName;
    this.swapTitleDisplay();
  }
}

TinychatEmbed.prototype.swapTitleDisplay = function() {
  var _this = this;

  if (this.data.swapToPrivateChatMessageNotice) {
    document.title = this.data.privateChatSenderName + ' sent you a message!';
  } else {
    this.updateTitle();
  }

  this.data.swapToPrivateChatMessageNotice = !this.data.swapToPrivateChatMessageNotice;

  // Loop until the timeout is cleared
  this.data.titleSwapTimer = setTimeout(function() { _this.swapTitleDisplay(); }, this.data.SWAP_TIMEOUT);
}

TinychatEmbed.prototype.publicChatListFocusChange = function(bool) {
  this.data.publicChatListInFocus = bool;

  if (bool) {
    this.data.messageCount = 0;
    this.updateTitle();
  }
}

TinychatEmbed.prototype.privateChatListFocusChange = function(bool) {
  this.data.privateChatListInFocus = bool;

  if (bool) {
    this.resetPrivateChatMessageNotice();
    this.updateTitle();
  }
}

TinychatEmbed.prototype.updateTitle = function() {
  if (this.data.messageCount === 0) {
    document.title = this.data.originalDocumentTitle;
  } else if (this.data.messageCount > 99) {
    document.title = this.data.originalDocumentTitle + ' (99+)';
  } else if (this.data.messageCount > 0) {
    document.title = this.data.originalDocumentTitle + ' (' + this.data.messageCount + ')';
  }
}

TinychatEmbed.prototype.resetPrivateChatMessageNotice = function() {
  clearTimeout(this.data.titleSwapTimer);
  this.data.titleSwapTimer = null;
  this.data.privateChatSenderName = null;
  this.data.swapToPrivateChatMessageNotice = true;
}

getWindowSize = function() {
  var width = 0,
      height = 0;

  if (!window.innerWidth) {
    if (document.documentElement.clientWidth !== 0) {
      width = document.documentElement.clientWidth;
      height = document.documentElement.clientHeight;
    } else {
      width = document.body.clientWidth;
      height = document.body.clientHeight;
    }
  } else {
    width = window.innerWidth;
    height = window.innerHeight;
  }

  return { width:width, height:height };
}

