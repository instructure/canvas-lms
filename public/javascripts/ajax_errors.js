/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

var iTest;
INST.errorURL = '/record_js_error';
INST.errorCount = 0;
INST.log_error = function(params) {
  params = params || {};
  var username = "";
  try {
    username = $("#identity .user_name").text();
  } catch(e) { }
  var txt = "?";
  params.url = params.url || location.href;
  params.platform = params.platform || navigator.platform;
  params.action = params.action || location.href;
  params.user_name = username;
  for(var idx in params) {
    txt = txt + 'error[' + idx + "]=" + escape(params[idx]) + "&";
  }
  INST.errorCount += 1;
  $("body").append("<img style='position: absolute; left: -1000px; top: 0;' src='" + INST.errorURL + txt.substring(0, 2000) + "' />");
}
window.onerror = function (msg, url, line) {
  var ignoredErrors = ["webkitSafeEl"];
  for(var idx in ignoredErrors) {
    if(ignoredErrors[idx] && msg && msg.match && msg.match(ignoredErrors[idx])) {
      return true;
    }
  }
  // we're going to ignore errors generated from javascript that isn't served from canvas.
  // this prevents a whole ton of errors about not being able to load google
  // analytics because of firewall rules, etc.
  if (!url.match(window.location.hostname)) {
    return true;
  }

  INST.log_error({ message: msg, line: line, url: url });
  if(INST.environment == "production") {
    return true;
  }
  if(iTest) {
    iTest.ok(false, 'unexpected error: ' + msg);
  }
};

// puts the little red box when something bad happens in ajax.
$(document).ready(function() {
  $("#instructure_ajax_error_result").defaultAjaxError(function(event, request, settings, error, debugOnly) {
    var status = "0";
    var text = "No text";
    var json_data = {};
    try {
      status = request.status;
      text = request.responseText;
      json_data = JSON.parse(text);
    } catch(e) {}
    $.ajaxJSON(location.protocol + '//' + location.host + "/simple_response.json?rnd=" + Math.round(Math.random() * 9999999), 'GET', {}, function() {
      if(json_data && json_data.status == 'AUT') {
        ajaxErrorFlash("There was a problem with your request, possibly due to a long period of inactivity.  Please reload the page and try again.", request);
      } else {
        ajaxErrorFlash("Oops! The last request didn't work out.", request);
      }
    }, function() {
      ajaxErrorFlash("Connection to " + location.host + " was lost.  Please make sure you're connected to the Internet and try again.", request);
    }, {skipDefaultError: true});
    var $obj = $(this);
    var ajaxErrorFlash = function(message, xhr) {
      var i = $obj[0];
      if(!i) { return; }
      var d = i.contentDocument || 
              (i.contentWindow && i.contentWindow.document) || 
              window.frames[$obj.attr('id')].document;
      var $body = $(d).find("body");
      $body.html("<h1>Ajax Error: " + status + "<\/h1>");
      $body.append(text);
      $("#instructure_ajax_error_box").hide();
      var pre = "";
      if(debugOnly) {
        message = message + "<br\/><span style='font-size: 0.7em;'>(Development Only)<\/span>";
      }
      if(debugOnly || INST.environment != "production") {
        message += "<br\/><a href='#' class='last_error_details_link'>details...<\/a>";
      }
      $.flashError(message);
    };
    window.ajaxErrorFlash = ajaxErrorFlash;
    var data = $.ajaxJSON.findRequest(request);
    data = data || {};
    if(data.data) {
      data.params = "";
      for(var name in data.data) {
        data.params += "&" + name + "=" + data.data[name];
      }
    }
    var username = "";
    try {
      username = $("#identity .user_name").text();
    } catch(e) { }
    if(INST.ajaxErrorURL) {
      var txt=  "&Msg="        + escape(text) +
                "&StatusCode=" + escape(status) +
                "&URL="        + escape(data.url || "unknown") +
                "&Page="       + escape(location.href) +
                "&Method="     + escape(data.submit_type || "unknown") +
                "&UserName="   + escape(username) + 
                "&Platform="   + escape(navigator.platform) + 
                "&UserAgent="  + escape(navigator.userAgent) +
                "&Params="     + escape(data.params || "unknown");
      $("body").append("<img style='position: absolute; left: -1000px; top: 0;' src='" + INST.ajaxErrorURL + txt.substring(0, 2000) + "' />");
    }
  });
  $(".last_error_details_link").live('click', function(event) {
    event.preventDefault();
    event.stopPropagation();
    $("#instructure_ajax_error_box").show();
  });
  $(".close_instructure_ajax_error_box_link").click(function(event) {
    event.preventDefault();
    $("#instructure_ajax_error_box").hide();
  });
  
  $("#flash_notice_message,#flash_error_message").each(function(){
    var $this = $(this);
    if($this.css('display') != 'none') {
      var time = $("#flash_notice_message").hasClass('long_show') ? 30000 : 7000;
      $("#flash_notice_message").removeClass('long_show')
      $this.delay(time).hide('drop', { direction: "up" }, 2000, function() {
        $this.empty().hide();
      });
    }
    $this.click(function() {
      $this.stop(true, true).hide('drop', { direction: "up" }, 'fast', function() {
        $this.empty().hide();
      });
    });
  });
  
});
