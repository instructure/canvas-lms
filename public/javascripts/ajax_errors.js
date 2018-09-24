/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import INST from './INST'
import I18n from 'i18n!ajax_errors'
import $ from 'jquery'
import htmlEscape from './str/htmlEscape'
import './jquery.ajaxJSON' // ajaxJSON, defaultAjaxError
import 'compiled/jquery.rails_flash_notifications' // flashError
import 'jqueryui/effects/drop'

  INST.errorCount = 0;
  window.onerror = function (msg, url, line, column, errorObj) {
    INST.errorCount += 1;
  };

  // puts the little red box when something bad happens in ajax.
  $(document).ready(function() {
    $("#instructure_ajax_error_result").defaultAjaxError(function(event, request, settings, error, debugOnly) {
      if (error === 'abort') return;
      var status = "0";
      var text = I18n.t('no_text', "No text");
      try {
        status = request.status;
        text = request.responseText;
      } catch(e) {}
      $.ajaxJSON(location.protocol + '//' + location.host + "/simple_response.json?rnd=" + Math.round(Math.random() * 9999999), 'GET', {}, function() {
        if ($.ajaxJSON.isUnauthenticated(request)) {
          var message = htmlEscape(I18n.t('errors.logged_out', "You are not currently logged in, possibly due to a long period of inactivity."))
          message += "<br\/><a href='/login' id='inactivity_login_link' target='_new'>" + htmlEscape(I18n.t('links.login', 'Login')) + "<\/a>";
          $.flashError({ html: message }, 30000)
          $('#inactivity_login_link').focus();
        } else if (status != 409) {
          ajaxErrorFlash(I18n.t('errors.unhandled', "Oops! The last request didn't work out."), request);
        }
      }, function() {
        ajaxErrorFlash(I18n.t('errors.connection_lost', "Connection to %{host} was lost.  Please make sure you're connected to the Internet and try again.", {host: location.host}), request);
      }, {skipDefaultError: true});
      var $obj = $(this);
      var ajaxErrorFlash = function(message, xhr) {
        var i = $obj[0];
        if(!i) { return; }
        var d = i.contentDocument ||
                (i.contentWindow && i.contentWindow.document) ||
                window.frames[$obj.attr('id')].document;
        var $body = $(d).find("body");
        $body.html($("<h1 />").text(I18n.t('error_heading', 'Ajax Error: %{status_code}', {status_code: status})));
        $body.append(htmlEscape(text));
        $("#instructure_ajax_error_box").hide();
        var pre = "";
        message = htmlEscape(message);
        if(debugOnly) {
          message += "<br\/><span style='font-size: 0.7em;'>(Development Only)<\/span>";
        }
        if(debugOnly || INST.environment != "production") {
          message += "<br\/><a href='#' class='last_error_details_link'>" + htmlEscape(I18n.t('links.details', 'details...')) + "<\/a>";
        }
        $.flashError({ html: message });
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
        $("body").append("<img style='position: absolute; left: -1000px; top: 0;' src='" + htmlEscape(INST.ajaxErrorURL + txt.substring(0, 2000)) + "' />");
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

  });
