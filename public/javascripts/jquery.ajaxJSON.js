/**
 * Copyright (C) 2011 - 2012 Instructure, Inc.
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
/*jshint evil:true*/

define([
  'INST' /* INST */,
  'jquery' /* $ */,
  'compiled/behaviors/authenticity_token'
], function(INST, $, authenticity_token) {

  var _getJSON = $.getJSON;
  $.getJSON = function(url, data, callback) {
    var xhr = _getJSON.apply($, arguments);
    $.ajaxJSON.storeRequest(xhr, url, 'GET', data);
    return xhr;
  };
  // Wrapper for default $.ajax behavior.  On error will call
  // the default error method if no error method is provided.
  $.ajaxJSON = function(url, submit_type, data, success, error, options) {
    data = data || {};
    if(!url && error) {
      error(null, null, "URL required for requests", null);
      return;
    }
    url = url || ".";
    if(submit_type != "GET") {
      data._method = submit_type;
      submit_type = "POST";
      data.authenticity_token = authenticity_token();
    }
    if($("#page_view_id").length > 0 && !data.page_view_id && (!options || !options.skipPageViewLog)) {
      data.page_view_id = $("#page_view_id").text();
    }
    var ajaxError = function(xhr, textStatus, errorThrown) {
      var data = xhr;
      if(xhr.responseText) {
        var text = xhr.responseText.replace(/(<([^>]+)>)/ig,"");
        data = { message: text };
        try {
          data = $.parseJSON(xhr.responseText);
        } catch(e) { }
      }
      if(options && options.skipDefaultError) {
        $.ajaxJSON.ignoredXHRs.push(xhr);
      }
      if(error && $.isFunction(error)) {
        error(data, xhr, textStatus, errorThrown);
      } else {
        $.ajaxJSON.unhandledXHRs.push(xhr);
      }
    };
    var params = {
      url: url,
      dataType: "json",
      type: submit_type,
      success: function(data, textStatus, xhr) {
        data = data || {};
        var page_view_id = null;
        if(xhr && xhr.getResponseHeader && (page_view_id = xhr.getResponseHeader("X-Canvas-Page-View-Id"))) {
          setTimeout(function() {
            $(document).triggerHandler('page_view_id_received', page_view_id);
          }, 50);
        }
        if(!data.length && data.errors) {
          ajaxError(data.errors, null, "");
          if(!options || !options.skipDefaultError) {
            $.fn.defaultAjaxError.func.call($.fn.defaultAjaxError.object, null, data, "0", data.errors);
          } else {
            $.ajaxJSON.ignoredXHRs.push(xhr);
          }
        } else if(success && $.isFunction(success)) {
          success(data, xhr);
        }
      },
      error: function(xhr) {
        ajaxError.apply(this, arguments);
      },
      complete: function(xhr) {
      },
      data: data
    };
    if(options && options.timeout) {
      params.timeout = options.timeout;
    }
    if(options && options.contentType) {
      params.contentType = options.contentType;
    }

    var xhr = $.ajax(params);
    $.ajaxJSON.storeRequest(xhr, url, submit_type, data);
    return xhr;
  };
  $.ajaxJSON.unhandledXHRs = [];
  $.ajaxJSON.ignoredXHRs = [];
  $.ajaxJSON.passedRequests = [];
  $.ajaxJSON.storeRequest = function(xhr, url, submit_type, data) {
    $.ajaxJSON.passedRequests.push({
      xhr: xhr,
      url: url,
      submit_type: submit_type,
      data: data
    });
  };
  $.ajaxJSON.findRequest = function(xhr) {
    var requests = $.ajaxJSON.passedRequests;
    for(var idx in requests) {
      if(requests[idx] && requests[idx].xhr == xhr) {
        return requests[idx];
      }
    }
    return null;
  };

  $.ajaxJSON.isUnauthenticated = function(xhr) {
    if (xhr.status != 401) {
      return false;
    }

    var json_data = {};
    try {
      json_data = $.parseJSON(text);
    } catch(e) {}

    return json_data.status == 'unauthenticated';
  };

  // Defines a default error for all ajax requests.  Will always be called
  // in the development environment, and as a last-ditch error catching
  // otherwise.  See "ajax_errors.js"
  $.fn.defaultAjaxError = function(func) {
    $.fn.defaultAjaxError.object = this;
    $.fn.defaultAjaxError.func = function(event, request, settings, error) {
      var inProduction = (INST.environment == "production");
      var unhandled = ($.inArray(request, $.ajaxJSON.unhandledXHRs) != -1);
      var ignore = ($.inArray(request, $.ajaxJSON.ignoredXHRs) != -1);
      if((!inProduction || unhandled || $.ajaxJSON.isUnauthenitcated(request)) && !ignore) {
        $.ajaxJSON.unhandledXHRs = $.grep($.ajaxJSON.unhandledXHRs, function(xhr, i) {
          return xhr != request;
        });
        var debugOnly = false;
        if(!unhandled) {
          debugOnly = true;
        }
        func.call(this, event, request, settings, error, debugOnly);
      }
    };
    this.ajaxError($.fn.defaultAjaxError.func);
  };
});
