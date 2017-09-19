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

import $ from 'jquery'
import 'jquery.cookie'

  // monkey patch jquery's JSON parsing so we can have all of our ajax responses return with
  // 'while(1);' prepended to them to protect against a CSRF attack vector.
  var _parseJSON = $.parseJSON;
  $.parseJSON = function() {

    if (arguments[0]) {
      try {
        var newData = arguments[0].replace(/^while\(1\);/, '');
        arguments[0] = newData;
      } catch (err) {
        // data was not a string or something, just pass along to the real parseJSON
        // and let it handle errors.
      }
    }
    return _parseJSON.apply($, arguments);
  };
  $.ajaxSettings.converters["text json"] = $.parseJSON;

  // this is a patch so you can set the "method" atribute on rails' REST-ful forms.
  $.attrHooks.method = $.extend($.attrHooks.method, {
    set: function( elem, value ) {
      var orginalVal = value;
      value = value.toUpperCase() === 'GET' ? 'GET' : 'POST';
      if ( value === 'POST' ) {
        var $input = $(elem).find("input[name='_method']");
        if ( !$input.length ) {
          $input = $("<input type='hidden' name='_method'/>").prependTo(elem);
        }
        $input.val(orginalVal);
      }
      elem.setAttribute('method', value);
      return value;
    }
  });

  $.fn.originalScrollTop = $.fn.scrollTop;
  $.fn.scrollTop = function() {
    if(this.selector == "html,body" && arguments.length === 0) {
      console.error("$('html,body').scrollTop() is not cross-browser compatible... use $.windowScrollTop() instead");
    }
    return $.fn.originalScrollTop.apply(this, arguments);
  };
  $.windowScrollTop = function() {
    // $.browser.safari is true for chrome.
    // with chrome 61, we want the documentElement.scrollTop, so the
    // original code (now the else block) always returns 0.
    // if chrome > 60, force it to return documentElement.scrollTop
    const chromeVer = window.navigator.userAgent.match(/Chrome\/(\d+)/)
    if (chromeVer && parseInt(chromeVer[1], 10) > 60) {
      return $("html").scrollTop()
    } else {
      return ($.browser.safari ? $("body") : $("html")).scrollTop();
    }
  };

  // indicate we want stringified IDs for JSON responses
  $.ajaxPrefilter("json", function( options, originalOptions, jqXHR ) {
    if (options.accepts.json)
      options.accepts.json = options.accepts.json + ', application/json+canvas-string-ids';
    else
      options.accepts.json = 'application/json+canvas-string-ids';
  });

  // see: https://github.com/rails/jquery-ujs/blob/master/src/rails.js#L80
  var CSRFProtection =  function(xhr) {
    var csrfToken = $.cookie('_csrf_token');
    if (csrfToken) xhr.setRequestHeader('X-CSRF-Token', csrfToken);
  }

  $.ajaxPrefilter(function( options, originalOptions, jqXHR ) {
    if ( !options.crossDomain ) CSRFProtection(jqXHR);

    // sends timing info of XHRs to google analytics so we can track ajax speed.
    // (ONLY for ajax requests that took longer than a second)
    var urlWithoutPageViewParam = options.url;
    var start = new Date().getTime();
    jqXHR.done(function(data, textStatus, jqXHR){
      var duration = new Date().getTime() - start;
      if (duration > 1000) {
        var label = '{"requestingPage": "' + window.location + '," "status": "' + textStatus + '", "X-Request-Context-Id" : "' + jqXHR.getResponseHeader('X-Request-Context-Id') + '", "X-Runtime": ' + jqXHR.getResponseHeader('X-Runtime') + '}';
        $.trackEvent('XHRs', urlWithoutPageViewParam, label, duration );
      }
    });
  });

export default $;
