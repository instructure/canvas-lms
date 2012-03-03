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
/*jshint evil:true*/

define([
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit, defaultAjaxError */
], function($) {

  $.originalGetJSON = $.getJSON;
  $.getJSON = function(url, data, callback) {
    var xhr = $.originalGetJSON(url, data, callback);
    $.ajaxJSON.storeRequest(xhr, url, 'GET', data);
    return xhr;
  };
  var assert_option = function(data, arg) {
    if(!data[arg]) {
      throw arg + " option is required";
    }
  };
  $.ajaxJSONPreparedFiles = function(options) {
    assert_option(options, 'context_code');
    var list = [];
    var $this = this;
    var pre_list = options.files || options.file_elements || [];
    for(var idx = 0; idx < pre_list.length; idx++) {
      var item = pre_list[idx];
      item.name = (item.value || item.name).split(/(\/|\\)/).pop();
      list.push(item);
    }
    var attachments = [];
    var ready = function() {
      var data = options.data;
      if(options.handle_files) {
        var result = attachments;
        if(options.single_file) {
          result = attachments[0];
        }
        data = options.handle_files.call(this, result, data);
      }
      if(options.url && options.success && data !== false) {
        $.ajaxJSON(options.url, options.method, data, options.success, options.error);
      }
    };
    var uploadFile = function(parameters, file) {
      $.ajaxJSON(options.uploadDataUrl || "/files/pending", 'POST', parameters, function(data) {
        try {
        if(data && data.upload_url) {
          var post_params = data.upload_params;
          var old_name = $(file).attr('name');
          $(file).attr('name', data.file_param);
          $.ajaxJSONFiles(data.upload_url, 'POST', post_params, $(file), function(data) {
            attachments.push(data);
            $(file).attr('name', old_name);
            next.call($this);
          }, function(data) {
            $(file).attr('name', old_name);
            (options.upload_error || options.error).call($this, data);
          }, {onlyGivenParameters: data.remote_url});
        } else {
          (options.upload_error || options.error).call($this, data);
        }
        } catch(e) {
          var ex = e;
        }
      }, function() { 
        return (options.upload_error || options.error).apply(this, arguments);
      });
    };
    var next = function() {
      var item = list.shift();
      if(item) {
        uploadFile.call($this, $.extend({
          'attachment[folder_id]': options.folder_id,
          'attachment[intent]': options.intent,
          'attachment[asset_string]': options.asset_string,
          'attachment[filename]': item.name,
          'attachment[context_code]': options.context_code
        }, options.formData || {}), item);
      } else {
        ready.call($this);
      }
    };
    next.call($this);
  };
  $.ajaxJSONFiles = function(url, submit_type, formData, files, success, error, options) {
    var $newForm = $(document.createElement("form"));
    $newForm.attr('action', url).attr('method', submit_type);
    if(!formData.authenticity_token) {
      formData.authenticity_token = $("#ajax_authenticity_token").text();
    }
    var fileNames = {};
    files.each(function() {
      fileNames[$(this).attr('name')] = true;
    });
    for(var idx in formData) {
      if(!fileNames[idx]) {
        var $input = $(document.createElement('input'));
        $input.attr('type', 'hidden').attr('name', idx).attr('value', formData[idx]);
        $newForm.append($input);
      }
    }
    files.each(function() {
      var $newFile = $(this).clone(true);
      $(this).after($newFile);
      $newForm.append($(this));
      $(this).removeAttr('id');
    });
    $("body").append($newForm.hide());
    $newForm.formSubmit({
      fileUpload: true,
      success: success,
      onlyGivenParameters: options ? options.onlyGivenParameters : false,
      error: error
    });
    (function() {
      $newForm.submit();
    }).call($newForm);
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
      if(!data.authenticity_token) {
        data.authenticity_token = $("#ajax_authenticity_token").text();
      }
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
          data = eval("("  + xhr.responseText + ")");
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
      success: function(data) {
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
      error: function() {
        ajaxError.apply(this, arguments);
      },
      data: data
    };
    if(options && options.timeout) {
      params.timeout = options.timeout;
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
  
});
