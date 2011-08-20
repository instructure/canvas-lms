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

//create a global object "INST" that we will have be Instructure's namespace.
if (typeof(window.INST) == "undefined") {
  window.INST = {}; //this is our "namespace"
}

I18n.scoped('instructure', function(I18n) {
  // ============================================================================================
  // = Try to figure out what browser they are using and set INST.broswer.theirbrowser to true  =
  // = and add a css class to the body for that browser                                       =
  // ============================================================================================
  
  INST.browser = {};
  $.each([7,8,9], function() {
    if ($('html').hasClass('ie'+this)) {
      INST.browser['ie'+this] = INST.browser.ie = true;
    }  
  });
  if (window.devicePixelRatio) {
    INST.browser.webkit = true;
    //from: http://www.byond.com/members/?command=view_post&post=53727
    INST.browser[(escape(navigator.javaEnabled.toString()) == 'function%20javaEnabled%28%29%20%7B%20%5Bnative%20code%5D%20%7D') ? 'chrome' : 'safari'] = true;
  }
  //this is just using jquery's browser sniffing result of if its firefox, it should probably use feature detection
  INST.browser.ff = $.browser.mozilla;
  // now we have some degree of knowing which of the common browsers it is, on dom ready, give the body those classes
  // so for example, if you were on IE6 the body would have the classes "ie" AND "ie6"
  $(function(){
    $.each(INST.browser, function(k,v){
      if (v) {
        $('body').addClass(k);
      }
    });
  });

  
  // this function is to prevent you from doing all kinds of expesive operations on a 
  // jquery object that doesn't actually have any elements in it
  // it is similar and inspired by http://www.slideshare.net/paul.irish/perfcompression (slide #42)
  // to use it do something like:
  // $("a .bunch #of .nodes").ifExists(function(orignalQuery){
  //   //  'this' points to the original jquery object (in this case, $("a .bunch #of .nodes") );
  //   // orignalQuery is the same as 'this';
  //   this.slideUp().dialog().show(); 
  // });
  $.fn.ifExists = function(func){
    this.length && func.call(this, this);
    return this;
  };
  
  
  // Generate a unique integer id (unique within the entire window).
  // Useful for temporary DOM ids.
  // if you pass it a prefix (because all dom ids have to have a alphabetic prefix) it will 
  // make sure that there is no other element on the page with that id.
  var idCounter = 10001;
  $.uniqueId = function(prefix){
    do {
      var id = (prefix || '') + idCounter++;
    } while (prefix && $('#' + id).length);
    return id;
  };
  
  // Return the first value which passes a truth test
  $.detect = function(collection, callback) {
    var result;
    $.each(collection, function(index, value) {
      if (callback.call(value, index, collection)) {
        result = value;
        return false; // we found it, break the $.each() loop iteration by returning false
      }
    });
    return result;
  };
  
  
  // this is just pulled from jquery 1.6 because jquery 1.5 could not do .map on an object
  $.map = function (elems, callback, arg) {
    var value, key, ret = [],
        i = 0,
        length = elems.length,


        // jquery objects are treated as arrays
        isArray = elems instanceof jQuery || length !== undefined && typeof length === "number" && ((length > 0 && elems[0] && elems[length - 1]) || length === 0 || jQuery.isArray(elems));

    // Go through the array, translating each of the items to their
    if (isArray) {
      for (; i < length; i++) {
        value = callback(elems[i], i, arg);

        if (value != null) {
          ret[ret.length] = value;
        }
      }

      // Go through every key on the object,
    } else {
      for (key in elems) {
        value = callback(elems[key], key, arg);

        if (value != null) {
          ret[ret.length] = value;
        }
      }
    }

    // Flatten any nested arrays
    return ret.concat.apply([], ret);
  }

  // Intercepts the default form submission process.  Uses the form tag's
  // current action and method attributes to know where to submit to.
  // NOTE: because IE only allows form methods to be "POST" or "GET",
  // we can't set the form to "PUT" or "DELETE" as cleanly as we'd like.
  // I'm following the Rails convention, and adding a _method input
  // if one doesn't already exist, and then setting that input's value
  // to the method type.  formSubmit checks this value first, then
  // the checks form.data('method') and finally the form's method
  // attribute.
  // Options:
  //    validation options -- formSubmit calls validateForm before
  //      submitting, so you can pass in validation options to
  //      formSubmit and it will validate first.
  //    noSubmit: Option to call everything normally until the actual request,
  //      then just calls success with the processed data
  //    processData: formSubmit by default just calls $.fn.getFormData.
  //      if you need additional data in the form submission, add
  //      it here and return the new object.
  //    beforeSubmit: called right before the request is sent.  Useful
  //      for hiding forms, adding ajax loader icons, etc.
  //    success: called on success
  //    error: Called on error.  The response from the server will also
  //      be used to populate error boxes on form elements.  If the form
  //      no longer exists and no error method is provided, the default
  //      error method for Instructure is called... actually
  //      it will always be called when you're in development environment.
  //    fileUpload: Either a boolean or a function.  If it is true or
  //      returns true, then it's assumed this is a file upload request
  //      and we use the iframe trick to submit the form.
  $.fn.formSubmit = function(options) {
    this.submit(function(event) {
      var $form = $(this); //this is to handle if bind to a template element, then it gets cloned the original this would not be the same as the this inside of here.
      if($form.data('submitting')) { return; }
      $form.data('trigger_event', event);
      $form.hideErrors();
      var error = false;
      var result = $form.validateForm(options);
      if(!result) {
        return false;
      }
      // retrieve form data
      var formData = $form.getFormData(options);
      if(options.processData && $.isFunction(options.processData)) {
        var newData = null;
        try {
          newData = options.processData.call($form, formData);
        } catch(e) { error = e; }
        if(newData === false) {
          return false;
        } else if(newData) {
          formData = newData;
        }
      }
      var method = $form.data('method') || $form.find("input[name='_method']").val() || $form.attr('method'),
          formId = $form.attr('id'),
          action = $form.attr('action'),
          submitParam = null;
      if($.isFunction(options.beforeSubmit)) {
        submitParam = null;
        try {
          submitParam = options.beforeSubmit.call($form, formData);
        } catch(e) { error = e; }
        if(submitParam === false) {
          return false;
        }
      }
      var doUploadFile = options.fileUpload;
      if($.isFunction(options.fileUpload)) {
        try {
          doUploadFile = options.fileUpload.call($form, formData);
        } catch(e) { error = e; }
      }
      if(doUploadFile && options.fileUploadOptions) {
        $.extend(options, options.fileUploadOptions);
      }
      if($form.attr('action')) {
        action = $form.attr('action');
      }
      if(error && !options.preventDegradeToFormSubmit) {
        if(INST && INST.environment == 'development') {
          $.flashError('formSubmit error, trying to gracefully degrade. See console for details');
        }
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      if(options.noSubmit) {
        if($.isFunction(options.success)) {
          options.success.call($form, formData, submitParam);
        }
      } else if(doUploadFile && options.preparedFileUpload && options.context_code) {
        $.ajaxJSONPreparedFiles.call(this, {
          handle_files: (options.upload_only ? options.success : options.handle_files),
          single_file: options.singleFile,
          context_code: $.isFunction(options.context_code) ? (options.context_code.call($form)) : options.context_code,
          asset_string: options.asset_string,
          intent: options.intent,
          folder_id: $.isFunction(options.folder_id) ? (options.folder_id.call($form)) : options.folder_id,
          file_elements: $form.find("input[type='file']"),
          url: (options.upload_only ? null : action),
          uploadDataUrl: options.uploadDataUrl,
          formData: options.postFormData ? formData : null,
          success: options.success,
          error: options.error
        });
      } else if(doUploadFile && $.handlesHTML5Files && $form.hasClass('handlingHTML5Files')) {
        var args = $.extend({}, formData);
        $form.find("input[type='file']").each(function() {
          var $input = $(this),
              file_list = $input.data('file_list');
          if(file_list && (file_list instanceof FileList)) {
            args[$input.attr('name')] = file_list;
          }
        });
        $.toMultipartForm(args, function(params) {
          $.sendFormAsBinary({
            url: action,
            body: params.body,
            content_type: params.content_type,
            method: method,
            success: function(data) {
              if(options.success && $.isFunction(options.success)) {
                options.success.call($form, data, submitParam);
              }
            },
            error: function(data, request) {
              // error function
              var $formObj = $form,
                  needValidForm = true;
              
              if(options.error && $.isFunction(options.error)) {
                data = data || {};
                var $obj = options.error.call($form, data.errors || data, submitParam);
                if($obj) {
                  $formObj = $obj;
                }
                needValidForm = false;
              } else {
                needValidForm = true;
              }
              if($formObj.parents("html").get(0) == $("html").get(0) && options.formErrors !== false) {
                $formObj.formErrors(data);
              } else if(needValidForm) {
                $.ajaxJSON.unhandledXHRs.push(request);
              }
            }
          });
        });
      } else if(doUploadFile) {
        var id            = $.uniqueId(formId + "_"),
            $frame        = $("<div style='display: none;' id='box_" + id + "'><form id='form_" + id + "'></form><iframe id='frame_" + id + "' name='frame_" + id + "' src='about:blank' onload='$(\"#frame_" + id + "\").triggerHandler(\"form_response_loaded\");'></iframe>")
                                .appendTo("body").find("#frame_" + id),
            $frameForm    = $(this),
            formMethod    = method,
            priorTarget   = $frameForm.attr('target'),
            priorEnctype  = $frameForm.attr('ENCTYPE'),
            request       = new $.fakeXHR(0, ""),
            $originalForm = $form;

        $frameForm.attr({
          'method' : method,
          'action' : action,
          'ENCTYPE' : 'multipart/form-data',
          'encoding' : 'multipart/form-data',
          'target' :"frame_" + id
        });
        if(options.onlyGivenParameters) {
          $frameForm.find("input[name='_method']").remove();
          $frameForm.find("input[name='authenticity_token']").remove();
        }

        $.ajaxJSON.storeRequest(request, action, method, formData);
        
        $frame.bind('form_response_loaded', function() {
          var $form = $originalForm,
              i = $frame[0],
              doc,
              exception;
          if (i.contentDocument) {
            doc = i.contentDocument;
          } else if (i.contentWindow) {
            doc = i.contentWindow.document;
          } else {
            doc = window.frames[id].document;
          }
          var text = "";
          var href = null;
          var exception = null;
          try {
            if(doc.location.href == "about:blank") {
              return;
            }
            text = $(doc).text();
            var data = JSON.parse(text);
            if(options.success && $.isFunction(options.success) && data && !data.errors) {
              options.success.call($form, data, submitParam);
            }
          } catch(e) {
            data = {};
            exception = e;
          }
          if(exception || data.errors) {
            var $formObj = $form,
                needValidForm = true;
            
            request.responseText = text;
            if(options.error && $.isFunction(options.error)) {
              var $obj = options.error.call($form, (data.errors || text), submitParam);
              if($obj) {
                $formObj = $obj;
              }
              needValidForm = false;
            } else if($.fn.formSubmit.defaultAjaxErrorObject && $.isFunction($.fn.formSubmit.defaultAjaxErrorFunction)) {
              needValidForm = true;
            }
            if($formObj.parents("html").get(0) == $("html").get(0) && options.formErrors !== false) {
              $formObj.formErrors(data.errrors || data);
            } else if(needValidForm) {
              $.ajaxJSON.unhandledXHRs.push(request);
            }
            $.fn.defaultAjaxError.func.call($.fn.defaultAjaxError.object, null, request, "0", exception);
          }
          setTimeout(function() {
            $form.attr({
              'ENCTYPE': priorEnctype,
              'encoding': priorEnctype,
              'target':  priorTarget
            });
            $("#box_" + id).remove();
          }, 5000);
        });
        $frameForm.data('submitting', true).submit().data('submitting', false);
      } else {
        $.ajaxJSON(action, method, formData, function(data) {
          // success function
          if($.isFunction(options.success)) {
            options.success.call($form, data, submitParam);
          }
        }, function(data, request, status, error) {
          // error function
          data = data || {};
          var $formObj = $form,
              needValidForm = true;
          if($.isFunction(options.error)) {
            var $obj = options.error.call($form, data.errors || data, submitParam);
            if($obj) {
              $formObj = $obj;
            }
            needValidForm = false;
          } else {
            needValidForm = true;
          }
          if($formObj.parents("html").get(0) == $("html").get(0) && options.formErrors !== false) {
            $formObj.formErrors(data);
          } else if(needValidForm) {
            $.ajaxJSON.unhandledXHRs.push(request);
          }
        });
      }
    });
    return this;
  };
  
  $.handlesHTML5Files = !!(window.File && window.FileReader && window.FileList && XMLHttpRequest && (new XMLHttpRequest()).sendAsBinary);
  if($.handlesHTML5Files) {
    $("input[type='file']").live('change', function(event) {
      var file_list = this.files;
      if(file_list) {
        $(this).data('file_list', file_list);
        $(this).parents("form").addClass('handlingHTML5Files');
      }
    });
  }
  $.ajaxFileUpload = function(options) {
    if(!options.data.authenticity_token) {
      options.data.authenticity_token = $("#ajax_authenticity_token").text();
    }
    $.toMultipartForm(options.data, function(params) {
      $.sendFormAsBinary({
        url: options.url,
        body: params.body,
        content_type: params.content_type,
        method: options.method,
        success: function(data) {
          if(options.success && $.isFunction(options.success)) {
            options.success.call(this, data);
          }
        },
        progress: function(data) {
          if(options.progress && $.isFunction(options.progress)) {
            options.progress.call(this, data);
          }
        },
        error: function(data, request) {
          // error function
          if(options.error && $.isFunction(options.error)) {
            data = data || {};
            var $obj = options.error.call(this, data.errors || data);
          } else {
            $.ajaxJSON.unhandledXHRs.push(request);
          }
        }
      }, options.binary === false);
    });
  };

  $.httpSuccess = function(r) {
    try {
      return !r.status && location.protocol == "file:" ||
        ( r.status >= 200 && r.status < 300 ) || r.status == 304 ||
        jQuery.browser.safari && r.status == undefined;
    } catch(e){}

    return false;
  };

  $.sendFormAsBinary = function(options, not_binary) {
    var body = options.body;
    var url = options.url;
    var method = options.method;
    var xhr = new XMLHttpRequest();
    if(xhr.upload) {
      xhr.upload.addEventListener('progress', function(event) {
        if(options.progress && $.isFunction(options.progress)) {
          options.progress.call(this, event); 
        }
      }, false);
      xhr.upload.addEventListener('error', function(event) {
        if(options.error && $.isFunction(options.error)) {
          options.error.call(this, "uploading error", xhr, event);
        }
      }, false);
      xhr.upload.addEventListener('abort', function(event) {
        if(options.error && $.isFunction(options.error)) {
          options.error.call(this, "aborted by the user", xhr, event);
        }
      }, false);
      xhr.onreadystatechange = function(event) {
        if(xhr.readyState == 4) {
          var json = null;
          try {
            json = JSON.parse(xhr.responseText);
          } catch(e) { }
          if($.httpSuccess(xhr)) {
            if(json && !json.errors) {
              if(options.success && $.isFunction(options.success)) {
                options.success.call(this, json, xhr, event);
              }
            } else {
              if(options.error && $.isFunction(options.error)) {
                options.error.call(this, json || xhr.responseText, xhr, event);
              }
            }
          } else {
            if(options.error && $.isFunction(options.error)) {
              options.error.call(this, json || xhr.responseText, xhr, event);
            }
          }
        }
      };
    }
    xhr.open(method, url);
    xhr.overrideMimeType(options.content_type || "multipart/form-data");
    xhr.setRequestHeader('Content-Type', options.content_type || "multipart/form-data");
    xhr.setRequestHeader('Content-Length', body.length);
    xhr.setRequestHeader('Accept', 'application/json, text/javascript, */*');
    xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    if(not_binary) {
      xhr.send(body);
    } else {
      if(!xhr.sendAsBinary) {
        console.log('xhr.sendAsBinary not supported');
      }
      xhr.sendAsBinary(body);
    }
  };
  
  $.fileData = function(file_object) {
    return {
      name: file_object.name || file_object.fileName,
      size: file_object.size || file_object.fileSize,
      type: file_object.type,
      forced_type: file_object.type || "application/octet-stream"
    };
  };
    
  $.toMultipartForm = function(params, callback) {
    var boundary = "-----AaB03x" + $.uniqueId(),
        result = {content_type: "multipart/form-data; boundary=" + boundary},
        body = "--" + boundary + "\r\n",
        paramsList = [];
    
    for(var idx in params) {
      paramsList.push([idx, params[idx]]);
    }
    function sanitizeQuotedString(text) {
      return text.replace(/\"/g, "");
    }
    function finished() {
      result.body = body.substring(0, body.length - 2) + '--';
      callback(result);
    };
    function nextParam() {
      if(paramsList.length === 0) {
        finished();
        return;
      }
      var param = paramsList.shift(),
          name = param[0],
          value = param[1];
      
      if(window.FileList && (value instanceof FileList)) {
        value = value[0];
      }
      if(window.FileList && (value instanceof FileList)) {
        var innerBoundary = "-----BbC04y" + $.uniqueId(),
            fileList = [];
        body += "Content-Disposition: form-data; name=\"" + sanitizeQuotedString(name) + "\r\n" +
                "Content-Type: multipart/mixed; boundary=" + innerBoundary + "\r\n\r\n";
        for(var jdx in value) {
          fileList.push(value);
        }
        function finishedFiles() {
          body += "--" + innerBoundary + "--\r\n" +
                  "--" + boundary + "\r\n";
          nextParam();
        }
        function nextFile() {
          if(fileList.length === 0) {
            finishedFiles();
            return;
          }
          var file = fileList.shift(),
              fileData = $.fileData(file),
              reader = new FileReader();
          
          reader.onloadend = function() {
            body += "--" + innerBoundary + "\r\n" +
                    "Content-Disposition: file; filename=\"" + sanitizeQuotedString(fileData.name) + "\"\r\n" +
                    "Content-Type: " + fileData.forced_type + "\r\n" +
                    "Content-Transfer-Encoding: binary\r\n" +
                    "\r\n" +
                    reader.result;
            nextFile();
          };
          reader.readAsBinaryString(file);
        }
        nextFile();
      } else if(window.File && (value instanceof File)) {
        var fileData = $.fileData(value),
            reader = new FileReader();
        reader.onloadend = function() {
          body += "Content-Disposition: file; name=\"" + sanitizeQuotedString(name) + "\"; filename=\"" + fileData.name + "\"\r\n" +
                  "Content-Type: " + fileData.forced_type + "\r\n" +
                  "Content-Transfer-Encoding: binary\r\n" + 
                  "\r\n" + 
                  reader.result + 
                  "\r\n--" + boundary + "\r\n";
          nextParam();
        };
        reader.readAsBinaryString(value);
      } else if(value && value.fake_file) {
        body += "Content-Disposition: file; name=\"" + sanitizeQuotedString(name) + "\"; filename=\"" + value.name + "\"\r\n" + 
                "Content-Type: " + value.content_type + "\r\n" + 
                "Content-Transfer-Encoding: binary\r\n" + 
                "\r\n" + 
                value.content + 
                "\r\n--" + boundary + "\r\n";
        nextParam();
      } else {
        body += "Content-Disposition: form-data; name=\"" + sanitizeQuotedString(name) + "\"\r\n" + 
                "\r\n" + 
                (value || "").toString() + "\r\n" + 
                "--" + boundary + "\r\n";
        nextParam();
      }
    };
    nextParam();
  };
  
  // Used to make a fake XHR request, useful if there's errors on an
  // asynchronous request generated using the iframe trick.
  $.fakeXHR = function(status_code, text) {
    this.status = status_code;
    this.responseText = text;
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
      if((!inProduction || unhandled) && !ignore) {
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
  
  // Fills the selected form object with the collected data values.
  // Handles select boxes, check boxes and radios as well.
  //  object_name: Name of the object form form elements.  So if
  //    I provide the data {good: true, bad: false} and
  //    options.object_name == "assignment", then it will fill
  //    form elements "good" and "assignment[good]" with true
  //    and "bad" and "assignment[bad]" with false.
  //  call_change: Specifies whether to trigger the onchange event
  //    for form elements that are set.
  $.fn.fillFormData = function(data, opts) {
    if(this.length) {
      data = data || [];
      var options = $.extend({}, $.fn.fillFormData.defaults, opts);

      if(options.object_name) {
        data = $._addObjectName(data, options.object_name, true);
      }
      this.find(":input").each(function() {
        var $obj = $(this);
        var name = $obj.attr('name');
        var inputType = $obj.attr('type');
        if(name in data) {
          if(name) {
            if(inputType == "hidden" && $obj.next("input:checkbox").attr('name') == name) {
              // do nothing
            } else if(inputType != "checkbox" && inputType != "radio") {
              var val = data[name];
              if(typeof(val) == 'undefined' || val === null) { val = ""; }
              $obj.val(val.toString());
            } else {
              if($obj.val() == data[name]) {
                $obj.attr('checked', true);
              } else {
                $obj.attr('checked', false);
              }
            }
            if($obj && $obj.change && options.call_change) {
              $obj.change();
            }
          }
        }
      });
    }
    return this;
  };
  $.fn.fillFormData.defaults = {object_name: null, call_change: true};
  // Pulls out the selected and entered values on a given form.
  //    object_name: see fillFormData above.  If object_name == "assignment"
  //      and the form has an element named "assignment[good]" then
  //      the result will include both "assignment[good]" and "good"
  //    values: specify the set of values to retrieve (if they exist)
  //      by default retrieves all it can find.
  $.fn.getFormData = function(options) {
    var options = $.extend({}, $.fn.getFormData.defaults, options),
        result = {},
        $form = this;
    $form.find(":input").not(":button").each(function() {
      var $input = $(this),
          inputType = $(this).attr('type');
      if((inputType == "radio" || inputType == 'checkbox') && !$input.attr('checked')) { return; }
      var val = $input.val();
      if($input.hasClass('suggestion_title') && $input.attr('title') == val) {
        val = "";
      } else if($input.hasClass('datetime_field_enabled') && $input.parent().children(".datetime_suggest").text()) {
        if($input.parent().children('.datetime_suggest').hasClass('invalid_datetime')) {
          val = $input.parent().children('.datetime_suggest').text();
        } else {
          val = $input.parent().children('.datetime_suggest').text();
        }
      }
      try {
        if($input.data('rich_text')) {
          val = $input.editorBox('get_code', false);
        }
      } catch(e) {}
      var attr = $input.attr('name');
      var multiValue = attr.match(/\[\]$/)
      if(inputType == 'hidden' && !multiValue) {
        if($form.find("[name='" + attr + "']").filter("textarea,:radio:checked,:checkbox:checked,:text,:password,select,:hidden")[0] != $input[0]) {
          return;
        }
      }
      if(attr && attr !== "" && (inputType == "checkbox" || typeof(result[attr]) == "undefined" || multiValue)) {
        if(!options.values || $.inArray(attr, options.values) != -1) {
          if(multiValue) {
            result[attr] = result[attr] || [];
            result[attr].push(val);
          } else {
            result[attr] = val;
          }
        }
      }
      var lastAttr = attr;
    });
    if(options.object_name) {
      result = $._stripObjectName(result, options.object_name, true);
    }
    return result;
  };
  $.fn.getFormData.defaults = {object_name: null};
  $.replaceOneTag = function(text, name, value) {
    if(!text) { return text; }
    name = (name || "").toString();
    value = (value || "").toString().replace(/\s/g, "+");
    var itemExpression = new RegExp("(%7B|{){2}[\\s|%20|\+]*" + name + "[\\s|%20|\+]*(%7D|}){2}", 'g');
    return text.replace(itemExpression, value);
  };
  // backwards compatible with only one tag
  $.replaceTags = function(text, mapping_or_name, maybe_value) {
    if (typeof mapping_or_name == 'object') {
      for (var name in mapping_or_name) {
        text = $.replaceOneTag(text, name, mapping_or_name[name])
      }
      return text;
    } else {
      return $.replaceOneTag(text, mapping_or_name, maybe_value)
    }
  }
  
  $.encodeToHex = function(str) {
    var hex = "";
    var e = str.length;
    var c = 0;
    var h;
    for (var i = 0; i < str.length; i++) {
      part = str.charCodeAt(i).toString(16);
      while (part.length < 2) {
        part = "0" + part;
      }
      hex += part;
    }
    return hex;
  };
  $.decodeFromHex = function(str) {
    var r='';
    var i = 0;
    while(i < str.length){
      r += unescape('%'+str.substring(i,i+2));
      i += 2;
    }
    return r;
  };
  
  $.htmlEscape = function(str) {
    return str && str.htmlSafe ?
      str.toString() :
      $.htmlEscape.element.text(str).html();
  }
  $.htmlEscape.element = $('<div/>');
  // escape all string values (not keys) in an object
  $.htmlEscapeValues = function(obj) {
    var k,v;
    for (k in obj) {
      v = obj[k];
      if (typeof v === "string") {
        obj[k] = $.htmlEscape(v);
      }
    }
  }
  $.h = $.htmlEscape;

  // useful for i18n, e.g. t('key', 'pick one: %{select}', {select: $.raw('<select><option>...')})
  // note that raw returns a String object, so you may want to call toString
  // if you're using it elsewhere
  $.raw = function(str) {
    str = new String(str);
    str.htmlSafe = true;
    return str;
  }
  
  // Fills the selected object(s) with data values as specified.  Plaintext values should be specified in the
  //  data: data used to fill template.
  //  id: set the id attribute of the template object
  //  textValues: a list of strings, which values should be plaintext
  //  htmlValues: a list of strings, which values should be html
  //  hrefValues: List of string.  Searches for all anchor tags in the template
  //    and globally replaces "{{ value }}" with data[value].  Useful for adding
  //    new elements asynchronously, when you don't know what their URL will be
  //    until they're created.
  $.fn.fillTemplateData = function(options) {
    if(this.length && options) {
      if (options.iterator) {
        this.find("*").andSelf().each(function(){
          var $el = $(this);
          $.each(["name", "id", "class"], function(i, attr){
            if ( $el.attr(attr) ) {
              $el.attr(attr, $el.attr(attr).replace(/-iterator-/, options.iterator));
            }
          });
        });
      }
      if(options.id) {
        this.attr('id', options.id);
      }
      var contentChange = false;
      if(options.data) {
        for(var item in options.data) {
          if(options.except && $.inArray(item, options.except) != -1) {
            continue;
          }
          if (options.dataValues && $.inArray(item, options.dataValues) != -1) {
            this.data(item, options.data[item].toString());
          }
          var $found_all = this.find("." + item);
          var avoid = options.avoid || "";
          $found_all.each(function() {
            var $found = $(this);
            if($found.length > 0 && $found.closest(avoid).length === 0) {
              if(typeof(options.data[item]) == "undefined" || options.data[item] === null) {
                options.data[item] = "";
              }
              if(options.htmlValues && $.inArray(item, options.htmlValues) != -1) {
                $found.html(options.data[item].toString());
                if($found.hasClass('user_content')) {
                  contentChange = true;
                  $found.removeClass('enhanced');
                  $found.data('unenhanced_content_html', options.data[item].toString());
                }
              } else if ($found[0].tagName.toUpperCase() == "INPUT") {
                $found.val(options.data[item]);
              } else {
                try {
                  var str = options.data[item].toString();
                  $found.html($.htmlEscape(str));
                } catch(e) { }
              }
            }
          });
        }
      }
      if(options.hrefValues && options.data) {
        this.find("a,span[rel]").each(function() {
          var $obj = $(this), 
              oldHref, oldRel, oldName;
          for(var i in options.hrefValues) {
            var name = options.hrefValues[i];
            if(oldHref = $obj.attr('href')) {
              var newHref = $.replaceTags(oldHref, name, encodeURIComponent(options.data[name]));
              var orig = $obj.text() == $obj.html() ? $obj.text() : null;
              if(oldHref != newHref) {
                $obj.attr('href', newHref);
                if(orig) {
                  $obj.text(orig);
                }
              }
            }
            if(oldRel = $obj.attr('rel')) {
              $obj.attr('rel', $.replaceTags(oldRel, name, options.data[name]));
            }
            if(oldName = $obj.attr('name')) {
              $obj.attr('name', $.replaceTags(oldName, name, options.data[name]));
            }
          }
        });
      }
      if(contentChange) {
        $(document).triggerHandler('user_content_change');
      }
    
    }
    return this;
  };
  
  $.fn.fillTemplateData.defaults = {htmlValues: null, hrefValues: null};
  // Reverse version of fillTemplateData.  Lets you pull out the string versions of values held in divs, spans, etc.
  // Based on the usage of class names within an object to specify an object's sub-parts.
  $.fn.getTemplateData = function(options) {
    if(!this.length || !options) {
      return {};
    }
    var result = {}, item, val;
    if(options.textValues) {
      for(item in options.textValues) {
        var $item = this.find("." + options.textValues[item].replace(/\[/g, '\\[').replace(/\]/g, '\\]') + ":first");
        val = $.trim($item.text());
        if($item.html() == "&nbsp;") { val = ""; }
        if(val.length == 1 && val.charCodeAt(0) == 160) {
          val = "";
        }
        result[options.textValues[item]] = val;
      }
    }
    if(options.dataValues) {
      for(item in options.dataValues) {
        var val = this.data(options.dataValues[item]);
        if(val) {
          result[options.dataValues[item]] = val;
        }
      }
    }
    if(options.htmlValues) {
      for(item in options.htmlValues) {
        var $elem = this.find("." + options.htmlValues[item].replace(/\[/g, '\\[').replace(/\]/g, '\\]') + ":first");
        val = null;
        if($elem.hasClass('user_content') && $elem.data('unenhanced_content_html')) {
          val = $elem.data('unenhanced_content_html');
        } else {
          val = $.trim($elem.html());
        }
        result[options.htmlValues[item]] = val;
      }
    }
    return result;
  };
  $.fn.getTemplateValue = function(value, options) {
    var opts = $.extend({}, options, {textValues: [value]});
    return this.getTemplateData(opts)[value];
  };
  // Used internally to prepend object_name to data key names
  // Supports nested names, e.g.
  //      assignment[id] => discussion_topic[assignment][id]
  $._addObjectName = function(data, object_name, include_original) {
    if(!data) { return data; }
    var new_result = {};
    if(data instanceof Array) {
      new_result = [];
    }
    var original_name,
        new_name,
        first_bracket;
        
    for(var i in data) {
      if(data instanceof Array) {
        original_name = data[i];
      } else {
        original_name = i;
      }

      first_bracket = original_name.indexOf('[');
      if (first_bracket >= 0) {
        new_name = object_name + "[" + original_name.substring(0, first_bracket) + "]" + original_name.substring(first_bracket);
      } else {
        new_name = object_name + "[" + original_name + "]";
      }
      if(typeof(original_name) == "string" && original_name.indexOf("=") === 0) {
        new_name = original_name.substring(1);
        original_name = new_name;
      }

      if(data instanceof Array) {
        new_result.push(new_name);
        if(include_original) {
          new_result.push(original_name);
        }
      } else {
        new_result[new_name] = data[i];
        if(include_original) {
          new_result[original_name] = data[i];
        }
      }
    }
    return new_result;
  };
  // Used internally to strip object_name from data key names
  // Supports nested names, e.g.
  //      discussion_topic[assignment][id] => assignment[id]
  $._stripObjectName = function(data, object_name, include_original) {
    var new_result = {};
    var short_name;
    if(data instanceof Array) {
      new_result = [];
    }
    for(var i in data) {
      var original_name, found;
      if(data instanceof Array) {
        original_name = data[i];
      } else {
        original_name = i;
      }

      if(found = (original_name.indexOf(object_name + "[") === 0)) {
        short_name = original_name.replace(object_name + "[", "");
        closing = short_name.indexOf("]");
        short_name = short_name.substring(0, closing) + short_name.substring(closing + 1);
        if(data instanceof Array) {
          new_result.push(short_name);
        } else {
          new_result[short_name] = data[i];
        }
      }

      if (!found || include_original) {
        if(data instanceof Array) {
          new_result.push(data[i]);
        } else {
          new_result[i] = data[i];
        }
      }
    }
    return new_result;
  };
  
  // Validated the selected form.  Pops up little error messages
  // next to form elements that have errors.
  //  object_name: specify to make error checking easier.  If object_name == "assignment"
  //    and required included "good", then "assignment[good]" is required. Only
  //    useful if all validations use the given object_name
  //  required: a list of strings, elements that are required
  //  dates: list of strings, elements that must be blank or a valid date
  //  times: list of strings, elements that must be blank or a valid time
  //  numbers: list of strings, elements that must be blank or a valid number
  //  property_validations: hash, where key names are form element names
  //    and key values are functions to call on the given data.  The function
  //    should return true if valid, false otherwise.
  $.fn.validateForm = function(options) {
    if (this.length === 0) {
      return false;
    }
    var options = $.extend({}, $.fn.validateForm.defaults, options),
        $form = this,
        errors = {},
        data = options.data || $form.getFormData(options);

    if (options.object_name) {
      options.required = $._addObjectName(options.required, options.object_name);
      options.date_fields = $._addObjectName(options.date_fields, options.object_name);
      options.dates = $._addObjectName(options.dates, options.object_name);
      options.times = $._addObjectName(options.times, options.object_name);
      options.numbers = $._addObjectName(options.numbers, options.object_name);
      options.property_validations = $._addObjectName(options.property_validations, options.object_name);
    }
    if (options.required) {
      $.each(options.required, function(i, name) {
        if (!data[name]) {
          if (!errors[name]) { 
            errors[name] = []; 
          }
          errors[name].push(I18n.t('errors.field_is_required', "This field is required"));
        }
      });
    }
    if(options.date_fields) {
      $.each(options.date_fields, function(i, name) {
        var $item = $form.find("input[name='" + name + "']").filter(".datetime_field_enabled");
        if($item.length && $item.parent().children(".datetime_suggest").hasClass('invalid_datetime')) {
          if (!errors[name]) { 
            errors[name] = []; 
          }
          errors[name].push(I18n.t('errors.invalid_datetime', "Invalid date/time value"));
        }
      });
    }
    if (options.numbers) {
      $.each(options.numbers, function(i, name){
        var val = parseFloat(data[name]);
        if(isNaN(val)) {
          if(!errors[name]) { 
            errors[name] = []; 
          }
          errors[name].push(I18n.t('errors.invalid_number', "This should be a number."));
        }
      });
    }
    if(options.property_validations) {
      $.each(options.property_validations, function(name, validation) {
        if($.isFunction(validation)) {
          var result = validation.call($form, data[name], data);
          if(result) {
            if(typeof(result) != "string") {
              result = I18n.t('errors.invalid_entry_for_field', "Invalid entry: %{field}", {field: name});
            }
            if(!errors[name]) { errors[name] = []; }
            errors[name].push(result);
          }
        }
      });
    }
    var hasErrors = false;
    for(var err in errors) {
      hasErrors = true;
      break;
    }
    if(hasErrors) {
      $form.formErrors(errors);
      return false;
    }
    return true;
  };
  $.fn.validateForm.defaults = {object_name: null, required: null, dates: null, times: null};
  // Takes in an errors object and creates little pop-up message boxes over
  // each errored form field displaying the error text.  Still needs some
  // css lovin'.
  $.fn.formErrors = function(data_errors) {
    if(this.length === 0) {
      return;
    }
    var $form = this;
    var errors = {};
    if(data_errors && data_errors['errors']) {
      data_errors = data_errors['errors'];
    }
    if(typeof(data_errors) == 'string') { 
      data_errors = {base: data_errors}; 
    }
    $.each(data_errors, function(i, val) {
      if(typeof(val) == "string") {
        var newval = [];
        newval.push(val);
        val = newval;
      } else if(typeof(i) == "number" && val.length == 2 && typeof(val[1]) == "string") {
        newval = [];
        newval.push(val[1]);
        i = val[0];
        val = newval;
      } else {
        try {
          newval = [];
          for(var idx in val) {
            if(typeof(val[idx]) == "object" && val[idx].message) {
              newval.push(val[idx].message.toString());
            } else {
              newval.push(val[idx].toString());
            }
          }
          val = newval;
        } catch(e) {
          val = val.toString();
        }
      }
      if($form.find(":input[name='" + i + "'],:input[name*='[" + i + "]']").length > 0) {
        $.each(val, function(idx, msg) {
          if(!msg.match(i)) {
          }
          if(!errors[i]) {
            errors[i] = msg;
          } else {
            errors[i] += "<br/>" + msg;
          }
        });
      } else {
        $.each(val, function(idx, msg) {
          if(!errors.general) {
            errors.general = msg;
          } else {
            errors.general += "<br/>" + msg;
          }
        });
      }
    });
    var hasErrors = false;
    var highestTop = 0;
    var currentTop = $(document).scrollTop();
    $.each(errors, function(name, msg) {
      var $obj = $form.find(":input[name='" + name + "'],:input[name*='[" + name + "]']").filter(":first");
      if(!$obj || $obj.length === 0 || name == "general") {
        $obj = $form;
      }
      if($obj[0].tagName == 'TEXTAREA' && $obj.next('.mceEditor').length) {
        $obj = $obj.next().find(".mceIframeContainer");
      }
      hasErrors = true;
      var offset = $obj.errorBox(msg).offset();
      if(offset.top > highestTop) {
        highestTop = offset.top;
      }
    });
    if(hasErrors) {
      $('html,body').scrollTo({top: highestTop, left:0});
    }
    return this;
  };
  $.fn.zIndex = function() {
    var $obj = this;
    while($obj.length > 0 && $obj.closest("html").length > 0) {
      var zIndex = parseInt($obj.css('zIndex'), 10);
      if(zIndex && !isNaN(zIndex)) {
        return zIndex;
      } else {
        $obj = $obj.parent();
      }
    }
    return 1;
  };
  // Pops up a small box containing the given message.  The box is connected to the given form element, and will
  // go away when the element is selected.
  $.fn.errorBox = function(message, scroll) {
    if(this.length) {
      var $obj = this,
          $oldBox = $obj.data('associated_error_box');
      if($oldBox) {
        $oldBox.remove();
      }
      var $template = $("#error_box_template");
      if(!$template.length) {
        $template = $("<div id='error_box_template' class='error_box errorBox' style=''>" + 
                          "<div class='error_text' style=''></div>" +
                          "<img src='/images/error_bottom.png' class='error_bottom'/>" + 
                        "</div>").appendTo("body");
      }
      var $box = $template.clone(true).attr('id', '').css('zIndex', $obj.zIndex() + 1).appendTo("body");
      $box.find(".error_text").html(message);
      var offset = $obj.offset();
      var height = $box.outerHeight();
      var objLeftIndent = Math.round($obj.outerWidth() / 5);
      if($obj[0].tagName == "FORM") {
        objLeftIndent = Math.min(objLeftIndent, 50);
      }
      $box.hide().css({
        top: offset.top - height + 2,
        left: offset.left + objLeftIndent
      }).fadeIn('fast');
      
      $obj.data({
        associated_error_box :$box,
        associated_error_object: $obj
      }).focus(function() {
        $box.fadeOut('slow', function() {
          $box.remove();
        });
      });
        
      $box.click(function() {
        $(this).fadeOut('fast', function() {
          $(this).remove();
        });
      });
      $.fn.errorBox.errorBoxes.push($obj);
      if(!$.fn.errorBox.isBeingAdjusted) {
        $.moveErrorBoxes();
      }
      if(scroll) {
        $("html,body").scrollTo($box);
      }
      return $box;
    }
  };
  $.fn.errorBox.errorBoxes = [];
  $.moveErrorBoxes = function() {
    if(!$.fn.errorBox.isBeingAdjusted) {
      $.fn.errorBox.isBeingAdjusted = true;
      setInterval($.moveErrorBoxes, 500);
    }
    var list = [];
    var prevList = $.fn.errorBox.errorBoxes;
    $(".error_box:visible").each(function() {
      var $box = $(this);
      if(!$box.data('associated_error_object') || $box.data('associated_error_object').filter(":visible").length === 0) {
        $box.hide();
      }
    });
    for(var idx in prevList) {
      var $obj = prevList[idx].filter(":visible:first");
      if($obj.data('associated_error_box')) {
        list.push($obj);
        var $box = $obj.data('associated_error_box');
        if($obj.filter(":visible").length === 0) {
          $box.hide();
        } else {
          var offset = $obj.offset();
          var height = $box.outerHeight();
          var objLeftIndent = Math.round($obj.outerWidth() / 5);
          if($obj[0].tagName == "FORM") {
            objLeftIndent = Math.min(objLeftIndent, 50);
          }
          $box.css({
            top: offset.top - height + 2,
            left: offset.left + objLeftIndent
          }).show();
        }
      }
    }
    $.fn.errorBox.errorBoxes = list;
  };
  // Hides all error boxes for the given form element and its input elements.
  $.fn.hideErrors = function(options) {
    if(this.length) {
      var $oldBox = this.data('associated_error_box');
      if($oldBox) {
        $oldBox.remove();
        this.data('associated_error_box', null);
      }
      this.find(":input").each(function() {
        var $obj = $(this),
            $oldBox = $obj.data('associated_error_box');
        if($oldBox) {
          $oldBox.remove();
          $obj.data('associated_error_box', null);
        }
      });
    }
    return this;
  };
  
  // Shows a gray-colored text suggestion for the form object when it is
  // blank, i.e. a date field would show DD-MM-YYYY until the user clicks on it.
  // I may phase this out or rewrite it, I'm undecided.  It's not
  // being used very much yet.
  $.fn.formSuggestion = function() {
    return this.each(function() {
      var $this = $(this);
      $this.focus(function(event) {
        var $this = $(this),
            title = $this.attr('title');
        $this.addClass('suggestionFocus');
        if(!title || title === "") { return; }
        if($this.val() == title) {
          $this.select();
        }
        $this.removeClass("form_text_hint");
      }).blur(function(event) {
        var $this = $(this),
            title = $this.attr('title');
        $this.removeClass('suggestionFocus');
        if(!title || title === "") { return; }
        if($this.val() === "") {
          $this.val(title);
        }
        if($this.val() == title) {
          $this.addClass("form_text_hint");
        }
      })
      // Workaround a strage bug where the input would be selected then immediately unselected 
      // every other time you clicked on the input with its defaultValue being shown
      .mouseup(false)
      .change(function(event) {
        var $this = $(this),
            title;
        if ( !$this.hasClass('suggestionFocus') && ( title = $(this).attr('title') ) ) {
          $this.removeClass('suggestionFocus');
          if ($this.val() === "") {
            $this.val(title);
          }
          $this.toggleClass("form_text_hint", $this.val() == title);
        }
      }).addClass('suggestion_title');
      
      var title = $this.attr('title'),
          val   = $this.val();
      if ( title && ( val === "" || val == title) ) {
        $this.addClass("form_text_hint").val(title);
      }
    });
  };
  $.fn.formSuggestion.suggestions = [];
  
  $.windowScrollTop = function() {
    return ($.browser.safari ? $("body") : $("html")).scrollTop();
  };
  $.fn.originalScrollTop = $.fn.scrollTop;
  $.fn.scrollTop = function() {
    if(this.selector == "html,body" && arguments.length === 0) {
      console.error("$('html,body').scrollTop() is not cross-browser compatible... use $.windowScrollTop() instead");
    }
    return $.fn.originalScrollTop.apply(this, arguments);
  };

  // Scrolls the supplied object until its visible. Call from
  // ("html,body") to scroll the window.
  $.fn.scrollToVisible = function(obj) {
    var options = {};
    var $obj = $(obj);
    
    var outerOffset = $("body").offset();
    this.each(function() {
      try {
        outerOffset = $(this).offset();
        return false;
      } catch(e) {}
    });
    if ($obj.length === 0) { return; }
    var innerOffset   = $obj.offset(),
        width         = $obj.outerWidth(),
        height        = $obj.outerHeight(),
        top           = innerOffset.top - outerOffset.top,
        bottom        = top + height,
        left          = innerOffset.left - outerOffset.left,
        right         = left + width,
        currentTop    = (this.selector == "html,body" ? $.windowScrollTop() : this.scrollTop()),
        currentLeft   = this.scrollLeft(),
        currentHeight = this.outerHeight(),
        currentWidth  = this.outerWidth();
    
    if (this[0].tagName == "HTML" || this[0].tagName == "BODY") {
      currentHeight = $(window).height();
      if($("#wizard_box:visible").length > 0) {
        currentHeight -= $("#wizard_box:visible").height();
      }
      currentWidth = $(window).width();
      top -= currentTop;
      left -= currentLeft;
      bottom -= currentTop;
      right -= currentLeft;
    }
    if (top < 0 || (currentHeight < height && bottom > currentHeight)) {
      options.scrollTop = top + currentTop;
    } else if (bottom > currentHeight) {
      options.scrollTop = bottom + currentTop - currentHeight + 20;
    }
    if (left < 0) {
      options.scrollLeft = left + currentLeft;
    } else if (right > currentWidth) {
      options.scrollLeft = right + currentLeft - currentWidth + 20;
    }
    if (options.scrollTop == 1) { options.scrollTop = 0; }
    if (options.scrollLeft == 1) { options.scrollLeft = 0; }
    
    this.scrollTop(options.scrollTop);
    this.scrollLeft(options.scrollLeft);
    
    return this;
  };
  
  // Simple dropdown list.  Takes the list of attributes specified in "options" and displays them
  // in a menu anchored to the selected element.
  $.fn.dropdownList = function(options) {
    if (this.length) {
      var $div = $("#instructure_dropdown_list");
      if (options == "hide" || options == "remove" || $div.data('current_dropdown_initiator') == this[0]) {
        $div.remove().data('current_dropdown_initiator', null);
        return;
      }
      var options = $.extend({}, $.fn.dropdownList.defaults, options),
          $list = $div.children("div.list");
      if (!$list.length) {
        $div = $("<div id='instructure_dropdown_list'><div class='list ui-widget-content'></div></div>").appendTo("body");
        $(document).mousedown(function(event) {
          if ($div.data('current_dropdown_initiator') && !$(event.target).closest("#instructure_dropdown_list").length) {
            $div.hide().data('current_dropdown_initiator', null);
          }
        }).mouseup(function(event) {
          if ($div.data('current_dropdown_initiator') && !$(event.target).closest("#instructure_dropdown_list").length) {
            $div.hide();
            setTimeout(function() {
              $div.data('current_dropdown_initiator', null);
            }, 100);
          }
        }).add(this).add($div).keydown(function(event) {
          if ($div.data('current_dropdown_initiator')) {
            var $current = $div.find(".ui-state-hover,.ui-state-active");
            if (event.keyCode == 38) { // up
              if ($current.length && $current.prev().length) {
                $current.removeClass('ui-state-hover ui-state-active').addClass('minimal')
                  .prev().addClass('ui-state-hover').removeClass('minimal')
                  .find('span').focus();
              } else {
                $item.focus();
              }
              return false;
            } else if (event.keyCode == 40) { // down
              if (!$current.length) {
                $div.find(".option:first")
                  .addClass('ui-state-hover').removeClass('minimal')
                  .find('span').focus();
              } else if ($current.next().length) {
                $current.removeClass('ui-state-hover ui-state-active').addClass('minimal')
                  .next().addClass('ui-state-hover').removeClass('minimal')
                  .find('span').focus();
              }
              return false;
            } else if (event.keyCode == 13 && $current.length) {
              $current.click();
              return false;
            } else {
              $div.hide().data('current_dropdown_initiator', null);
            }
          }
        });
        $div.find(".option").removeClass('ui-state-hover ui-state-active').addClass('minimal');
        $div.click(function(event) {
          $div.hide().data('current_dropdown_initiator', null);
        });
        $list = $div.children("div.list");
      }
      $div.data('current_dropdown_initiator', this[0]);
      if (options.width) { 
        $div.width(options.width); 
      }
      if (options.height) { 
        $div.find(".list").css('maxHeight', options.height); 
      }
      $list.empty();
      $.each(options.options, function(optionName, callback){
        var $option = $("<div class='option minimal' style='cursor: pointer; padding: 2px 5px; overflow: hidden; white-space: nowrap;'>" +
                        "  <span tabindex='-1'>" + optionName.replace(/_/g, " ") + "</span>" +
                        "</div>").appendTo($list);

        if($.isFunction(callback)) {
          function unhoverOtherOptions(){
            $option.parent().find("div.option").removeClass('ui-state-hover ui-state-active').addClass('minimal');
          }
          $option.addClass('ui-state-default').bind({
            mouseenter: function() {
              unhoverOtherOptions();
              $option.addClass('ui-state-hover').removeClass('minimal');
            },
            mouseleave: unhoverOtherOptions,
            mousedown: function(event) {
              event.preventDefault();
              unhoverOtherOptions();
              $option.addClass('ui-state-active').removeClass('minimal');
            },
            mouseup: unhoverOtherOptions,
            click: callback
          });
        } else {
          $option.addClass('ui-state-disabled').bind({
            mousedown: function(event) {
              event.preventDefault();
            }
          });
        }
      });
      var offset = this.offset(),
          height = this.outerHeight(),
          width = this.outerWidth();
      
      $div.css({
        whiteSpace : "nowrap",
        position : 'absolute',
        top : offset.top + height, 
        left : offset.left + 5, 
        right : ''
      }).hide().show();
      
      //this is a fix so that if the dropdown ends up being off the page then move it back in so that it is on the page.
      if ($div.offset().left + $div.width() > $(window).width()) {
        $div.css({'left' : '','right' : 0});
      }
    }
    return this;
  };
  $.fn.dropdownList.defaults = {height: 250, width: "auto"};
  
  $.parseDateTime = function(date, time) {
    var date = $.datepicker.parseDate('mm/dd/yy', date);
    if(time) {
      var times = time.split(":");
      var hr = parseInt(times[0], 10);
      if(hr == 12) { hr = 0; }
      if(time.match(/pm/i)) {
        hr += 12;
      }
      var min = 0;
      if(times[1]) {
        min = times[1].replace(/(am|pm)/gi, "");
      }
      date.setHours(hr);
      date.setMinutes(min);
    } else {
      date.setHours(0);
      date.setMinutes(0);
    }
    date.date = date;
    return date;
  };
  
  $.formatDateTime = function(date, options) {
    var head = "", tail = "";
    if(date) {
      date.date = date.date || date;
    }
    if(options.object_name) {
      head += options.object_name + "[";
      tail = "]" + tail;
    }
    if(options.property_name) {
      head += options.property_name;
    }
    var result = {};
    if(date && !isNaN(date.date.getFullYear())) {
      result[head + "(1i)" + tail] = date.getFullYear();
      result[head + "(2i)" + tail] = (date.getMonth() + 1);
      result[head + "(3i)" + tail] = date.getDate();
      result[head + "(4i)" + tail] = date.getHours();
      result[head + "(5i)" + tail] = date.getMinutes();
    } else {
      result[head + "(1i)" + tail] = "";
      result[head + "(2i)" + tail] = "";
      result[head + "(3i)" + tail] = "";
      result[head + "(4i)" + tail] = "";
      result[head + "(5i)" + tail] = "";
    }
    return result;
  };  
  
  $.parseFromISO = function(iso, datetime_type) {
    var user_offset = parseInt($("#time_zone_offset").text(), 10) / -60;
    var today = new Date();
    datetime_type = datetime_type || 'event';
    try {
      var result = {};
      if(!iso) {
        return $.parseFromISO.defaults;
      }
      var year = iso.substring(0, 4);
      var month = iso.substring(5, 7);
      var day = iso.substring(8, 10);
      var date_offset = parseInt(iso.substring(19), 10) || 0;
      result.date = new Date(year, month - 1, day);
      if(result.date.getTimezoneOffset() != today.getTimezoneOffset()) {
        user_offset = user_offset - ((result.date.getTimezoneOffset() - today.getTimezoneOffset()) / 60);
      }
      var hour_shift = user_offset - date_offset;
      // NOTE: This value is a literal parsing of the date
      // passed in and may technically be incorrect if there
      // is shifting due to time zones.
      // result.date = $.datepicker.parseDate("yy-mm-dd", iso.substring(0, 10));
      result.date_sortable = iso.substring(0, 10);
      result.date_string = month + "/" + day + "/" + year;
      result.date_formatted = $.dateString(result.date);
      var hour_string = iso.substring(11, 13);
      var minute_string = iso.substring(14, 16);
      var second_string = iso.substring(17, 19);
      var hours = (parseInt(hour_string, 10)) * 1000.0 * 3600;
      if(hour_shift && !isNaN(hour_shift)) {
        hours = hours + (hour_shift * 1000.0 * 3600);
      }
      var minutes = parseInt(minute_string, 10) * 1000.0 * 60;
      var seconds = parseInt(second_string, 10) * 1000.0;
      var time_timestamp = (hours + minutes + seconds) || 0;
      var date_timestamp = (Date.UTC(year, month - 1, day)) || 0;
      result.time_timestamp = time_timestamp / 1000;
      result.date_timestamp = date_timestamp / 1000;
      var tz_offset = result.date.getTimezoneOffset() * 60000;
      var time = new Date(date_timestamp + time_timestamp + tz_offset);
      var ampm = "am";
      hours = time.getHours();
      if(hours > 12) {
        hours -= 12;
        ampm = "pm";
      } else if(hours == 12) {
        ampm = "pm";
      } else if(hours === 0) {
        hours = 12;
      }
      var time_formatted = hours;
      var time_tail = ":";
      if(time.getMinutes() < 10) {
        time_tail += "0";
      }
      time_tail += time.getMinutes();
      if(time.getMinutes() !== 0) {
        time_formatted += time_tail;
      }
      var by_at = datetime_type == 'due_date' ? 'by' : 'at';
      var time_for_date_formatted = ' ' + by_at + ' ' + time_formatted + ampm;
      result.show_time = true;
      var sortable_hour = time.getHours();
      if(sortable_hour < 10) {
        sortable_hour = "0" + sortable_hour;
      }
      result.time_sortable = sortable_hour + time_tail;
      time_formatted += ampm;
      result.time_formatted = time_formatted;
      result.time_string = hours + time_tail + ampm;
      result.time = time;
      result.datetime = time;
      result.date_formatted = $.dateString(result.datetime);
      result.datetime_formatted = result.date_formatted + time_for_date_formatted;
      result.timestamp = (time_timestamp + date_timestamp) / 1000;
      result.minute_timestamp = result.timestamp - (result.timestamp % 60);
      return result;
    } catch(e) {
      return $.parseFromISO.defaults;
    }
  };
  $.parseFromISO.ref_date = new Date();
  $.parseFromISO.offset = $.parseFromISO.ref_date.getTimezoneOffset() * 60000;
  $.parseFromISO.defaults = {
      date: new Date($.parseFromISO.offset),
      date_sortable: "0000-00-00",
      date_string: "",
      date_formatted: "",
      time_timestamp: 0,
      date_timestamp: 0,
      timestamp: 0,
      time: new Date($.parseFromISO.offset),
      time_formatted: "",
      time_string: ""
  };
  var today = new Date();
  $.thisYear = function(date) {
    return date && (date.getFullYear() == today.getFullYear());
  };
  $.dateString = function(date) {
    return (date && (date.toString($.thisYear(date) ? 'MMM d' : 'MMM d, yyyy'))) || "";
  };
  $.timeString = function(date) {
    return (date && date.toString('h:mmtt').toLowerCase()) || "";
  };
  $.friendlyDatetime = function(datetime, perspective) {
    if (perspective == null) {
      perspective = 'past';
    }
    var today = Date.today();
    if (Date.equals(datetime.clone().clearTime(), today)) {
      return I18n.l('#time.formats.tiny', datetime);
    } else {
      return $.friendlyDate(datetime, perspective);
    }
  };
  $.friendlyDate = function(datetime, perspective) {
    if (perspective == null) {
      perspective = 'past';
    }
    var today = Date.today();
    var date = datetime.clone().clearTime();
    if (Date.equals(date, today)) {
      return I18n.t('#date.days.today', 'Today');
    } else if (Date.equals(date, today.add(-1).days())) {
      return I18n.t('#date.days.yesterday', 'Yesterday');
    } else if (Date.equals(date, today.add(1).days())) {
      return I18n.t('#date.days.tomorrow', 'Tomorrow');
    } else if (perspective == 'past' && date < today && date >= today.add(-6).days()) {
      return I18n.l('#date.formats.weekday', date);
    } else if (perspective == 'future' && date < today.add(7).days() && date >= today) {
      return I18n.l('#date.formats.weekday', date);
    }
    return I18n.l('#date.formats.medium', date);
  };
  $.fn.parseFromISO = $.parseFromISO;

  // Returns the width of the browser's scroll bars.
  $.fn.scrollbarWidth = function() {
      var $div = $('<div style="width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;"><div style="height:100px;"></div>').appendTo(this),
          $innerDiv = $div.find('div');
      // Append our div, do our calculation and then remove it
      var w1 = $innerDiv.innerWidth();
      $div.css('overflow-y', 'scroll');
      var w2 = $innerDiv.innerWidth();
      $div.remove();
      return (w1 - w2);
  };

  // Shows an ajax-loading image on the given object.
  $.fn.loadingImg = function(options) {
    if(!this || this.length === 0) {
      return this;
    }
    var $obj = this.filter(":first");
    var list;
    if(options == "hide" || options == "remove") {
      $obj.children(".loading_image").remove();
      list = $obj.data('loading_images') || [];
      for(var idx in list) {
        if(list[idx]) {
          list[idx].remove();
        }
      }
      $obj.data('loading_images', null);
      return this;
    } else if(options == "remove_once") {
      $obj.children(".loading_image").remove();
      list = $obj.data('loading_images') || [];
      var img = list.pop();
      if(img) { img.remove(); }
      $obj.data('loading_images', list);
      return this;
    } else if (options == "register_image" && arguments.length == 3) {
      $.fn.loadingImg.image_files[arguments[1]] = arguments[2];
    }
    options = $.extend({}, $.fn.loadingImg.defaults, options);
    var image = $.fn.loadingImg.image_files['normal'];
    if(options.image_size && $.fn.loadingImg.image_files[options.image_size]) {
      image = $.fn.loadingImg.image_files[options.image_size];
    }
    if(options.paddingTop) {
      options.vertical = options.paddingTop;
    }
    var paddingTop = 0;
    if(options.vertical) {
      if(options.vertical == "top") {
      } else if(options.vertical == "bottom") {
        paddingTop = $obj.outerHeight();
      } else if(options.vertical == "middle")  {
        paddingTop = ($obj.outerHeight() / 2) - (image.height / 2);
      } else {
        paddingTop = parseInt(options.vertical, 10);
        if(isNaN(paddingTop)) {
          paddingTop = 0;
        }
      }
    }
    var paddingLeft = 0;
    if(options.horizontal) {
      if(options.horizontal == "left") {
      } else if(options.horizontal == "right") {
        paddingLeft = $obj.outerWidth() - image.width;
      } else if(options.horizontal == "middle")  {
        paddingLeft = ($obj.outerWidth() / 2) - (image.width / 2);
      } else {
        paddingLeft = parseInt(options.horizontal, 10);
        if(isNaN(paddingLeft)) {
          paddingLeft = 0;
        }
      }
    }
    var zIndex = $obj.zIndex() + 1;
    var $imageHolder = $(document.createElement('div')).addClass('loading_image_holder');
    var $image = $(document.createElement('img')).attr('src', image.url);
    $imageHolder.append($image);
    list = $obj.data('loading_images') || [];
    list.push($imageHolder);
    $obj.data('loading_images', list);

    if(!$obj.css('position') || $obj.css('position') == "static") {
      var offset = $obj.offset();
      var top = offset.top, left = offset.left;
      if(options.vertical) {
        top += paddingTop;
      }
      if(options.horizontal) {
        left += paddingLeft;
      }
      $imageHolder.css({
        zIndex: zIndex,
        position: "absolute",
        top: top,
        left: left
      });
      $("body").append($imageHolder);
    } else {
      $imageHolder.css({
        zIndex: zIndex,
        position: "absolute",
        top: paddingTop,
        left: paddingLeft
      });
      $obj.append($imageHolder);
    }
    return $(this);
  };
  $.fn.loadingImg.defaults = {paddingTop: 0, image_size: 'normal', vertical: 0, horizontal: 0};
  $.fn.loadingImg.image_files = {
    normal: {url: '/images/ajax-loader.gif', width: 32, height: 32},
    small: {url: '/images/ajax-loader-small.gif', width: 16, height: 16}
  };
  $.fn.loadingImage = $.fn.loadingImg;
  // Simple animation for dimming an element's opacity
  $.fn.dim = function(speed) {
    return this.animate({opacity: 0.4}, speed);
  };
  $.fn.undim = function(speed) {
    return this.animate({opacity: 1.0}, speed);
  };
  // Helper for deleting objects from the DOM and db.
  //  url: URL to pass DELETE message.  If none provided,
  //    behaves as if the request were a success.  Useful for testing.
  //  message: Confirmation message
  //  cancelled: Function to handle cancel.
  //  confirmed: Functiont to handle confirm, before submit.
  //  success: What to do on success.  If none provided, fades
  //    out the element and removes it from the DOM.
  //  error: Error.
  $.fn.confirmDelete = function(options) {
    var options = $.extend({}, $.fn.confirmDelete.defaults, options);
    var $object = this;
    var result = true;
    options.noMessage = options.noMessage || options.no_message;
    if(options.message && !options.noMessage) {
      if(!$.skipConfirmations) {
        result = confirm(options.message);
      }
    }
    if(!result) {
      if(options.cancelled && $.isFunction(options.cancelled)) {
        options.cancelled.call($object);
      }
      return;
    }
    if(!options.confirmed) {
      options.confirmed = function() {
        $object.dim();
      };
    }
    options.confirmed.call($object);
    if(options.url) {
      if(!options.success) {
        options.success = function(data) {
          $object.fadeOut('slow', function() {
            $object.remove();
          });
        };
      }
      var data = {};
      if(options.token) {
        data.authenticity_token = options.token;
      }
      if(!data.authenticity_token) {
        data.authenticity_token = $("#ajax_authenticity_token").text();
      }
      $.ajaxJSON(options.url, "DELETE", data, function(data) {
        options.success.call($object, data);
      }, function(data, request, status, error) {
        if(options.error && $.isFunction(options.error)) {
          options.error.call($object, data, request, status, error);
        } else {
          $.ajaxJSON.unhandledXHRs.push(request);
        }
      });
    } else {
      if(!options.success) {
        options.success = function() {
          $object.fadeOut('slow', function() {
            $object.remove();
          });
        };
      }
      options.success.call($object);
    }
  };
  $.fn.confirmDelete.defaults = {
    message: I18n.t('confirms.default_delete_thing', "Are you sure you want to delete this?")
  };
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
  }
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
      if(options.url && options.success && data != false) {
        $.ajaxJSON(options.url, options.method, data, options.success, options.error);
      }
    }
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
          debugger;
          ex;
        }
      }, function() { 
        return (options.upload_error || options.error).apply(this, arguments);
      });
    }
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
    }
    next.call($this);
  }
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
        $.ajaxJSON.inFlighRequests -= 1;
        data = data || {};
        var page_view_id = null;
        if(xhr && xhr.getResponseHeader && (page_view_id = xhr.getResponseHeader("X-Canvas-Page-View-Id"))) {
          setTimeout(function() {
            $(document).triggerHandler('page_view_id_recieved', page_view_id);
          }, 50);
        }
        if(!data.length && data['errors']) {
          ajaxError(data['errors'], null, "");
          if(!options || !options.skipDefaultError) {
            $.fn.defaultAjaxError.func.call($.fn.defaultAjaxError.object, null, data, "0", data['errors']);
          } else {
            $.ajaxJSON.ignoredXHRs.push(xhr);
          }
        } else if(success && $.isFunction(success)) {
          success(data);
        }
      },
      error: function() {
        $.ajaxJSON.inFlighRequests -= 1;
        ajaxError.apply(this, arguments);
      },
      data: data
    };
    if(options && options.timeout) {
      params['timeout'] = options.timeout;
    }
    $.ajaxJSON.inFlighRequests += 1;
    var xhr = $.ajax(params);
    $.ajaxJSON.storeRequest(xhr, url, submit_type, data);
    return xhr;
  };
  $.ajaxJSON.inFlighRequests = 0;
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
  var already_listening_for_close_link_clicks = false;
  $._flashBox = function(type, content, timeout) {
    if(!already_listening_for_close_link_clicks) {
      already_listening_for_close_link_clicks = true;
      $("#flash_message_holder .close-link").live('click', function(event) {
        event.preventDefault();
      });
    }
    $("#flash_" + type + "_message")
      .stop(true, true)
      .empty().append("<a href='' class='close-link'>#</a>")
      .append(content)
      .hide()
      .css('opacity', 1)
      .show('drop', { direction: "up" })
      .slideDown('normal')
      .delay(timeout || 7000)
      .hide('drop', { direction: "up" }, 2000, function() {
        $(this).empty().hide();
      });
  };
  
  // Pops up a small notification box at the top of the screen.
  $.flashMessage = function(content, timeout) {
    $._flashBox("notice", content, timeout);
  };
  // Pops up a small error box at the top of the screen.
  $.flashError = function(content, timeout) {
    $._flashBox("error", content, timeout);
  };
  // Watches the given element's location.href for any changes
  // to the fragment ("#...") and calls the provided function
  // when there are any.
  // $(document).fragmentChange(function(event, hash) { alert(hash); });
  $.fn.fragmentChange = function(fn) {
    if(fn && fn !== true) {
      var query = (window.location.search || "").replace(/^\?/, "").split("&");
      var idx;
      // The URL can hard-code a hash regardless of what's
      // actually shown in the hash by specifying a query
      // parameter, hash=some_hash
      var query_hash = null;
      for(idx in query) {
        var item = query[idx];
        if(item && item.indexOf("hash=") === 0) {
          query_hash = "#" + item.substring(5);
        }
      }
      this.bind('document_fragment_change', fn);
      var $doc = this;
      var found = false;
      // Can only be used on the root document,
      // will not work on an iframe, for example.
      for(idx in $._checkFragments.fragmentList) {
        var obj = $._checkFragments.fragmentList[idx];
        if(obj.doc[0] == $doc[0]) {
          found = true;
        }
      }
      if(!found) {
        $._checkFragments.fragmentList.push({
          doc: $doc,
          fragment: ""
        });
      }
      $(window).bind('hashchange', $._checkFragments);
      setTimeout(function() {
        if(query_hash && query_hash.length > 0) {
          $doc.triggerHandler('document_fragment_change', query_hash);
        } else if($doc && $doc[0] && $doc[0].location && $doc[0].location.hash.length > 0) {
          $doc.triggerHandler('document_fragment_change', $doc[0].location.hash);
        }
      }, 500);
    } else {
      this.triggerHandler('document_fragment_change', this[0].location.hash);
    }
    return this;
  };
  $._checkFragments = function() {
    var list = $._checkFragments.fragmentList;
    for(var idx in list) {
      var obj = list[idx];
      var $doc = obj.doc;
      if($doc[0].location.hash != obj.fragment) {
        $doc.triggerHandler('document_fragment_change', $doc[0].location.hash);
        obj.fragment = $doc[0].location.hash;
        $._checkFragments.fragmentList[idx] = obj;
      }
    }
  };
  $._checkFragments.fragmentList = [];
  // Triggers a click only if the anchor tag isn't disabled.
  $.fn.clickLink = function() {
    var $obj = this.eq(0);
    if(!$obj.hasClass('disabled_link')) {
      $obj.click();
    }
  };
  // jQuery supposedly has this built-in, but I haven't
  // had much success with it.
  $.fn.showIf = function(bool) {
    if ($.isFunction(bool)) {
      bool = bool.call(this);
    }
    if(bool) {
      this.show();
    } else {
      this.hide();
    }
    return this;
  };

  var scrollSideBarIsBound = false;
  $.scrollSidebar = function(){
    if(!scrollSideBarIsBound){
      var $right_side = $("#right-side"),
          $body = $('body'),
          $main = $('#main'),
          $not_right_side = $("#not_right_side"),
          $window = $(window),
          headerHeight = $right_side.offset().top,
          rightSideMarginBottom = $("#right-side-wrapper").height() - $right_side.outerHeight();
          
      function onScroll(){
        var windowScrollTop = $window.scrollTop(),
            windowScrollIsBelowHeader = (windowScrollTop > headerHeight);
        if (windowScrollIsBelowHeader) {
          var notRightSideHeight = $not_right_side.height(),
              rightSideHeight = $right_side.height(),
              notRightSideIsTallerThanRightSide = notRightSideHeight > rightSideHeight,
              rightSideBottomIsBelowMainBottom = ( headerHeight + $main.height() - windowScrollTop ) <= ( rightSideHeight + rightSideMarginBottom );
        }
        $body
          .toggleClass('with-scrolling-right-side',     windowScrollIsBelowHeader && notRightSideIsTallerThanRightSide && !rightSideBottomIsBelowMainBottom)
          .toggleClass('with-sidebar-pinned-to-bottom', windowScrollIsBelowHeader && notRightSideIsTallerThanRightSide &&  rightSideBottomIsBelowMainBottom);
      }
      onScroll();
      $window.scroll(onScroll);
      setInterval(onScroll, 1000);
      scrollSideBarIsBound = true;
    }
  };
  
  // Catches specified key events and calls the provided function
  // when they occur.  Can use text or key codes, passed in as a
  // space-separated string.
  $.fn.keycodes = function(options, fn) {
    /* Based loosely on Tzury Bar Yochay's js-hotkeys:
    (c) Copyrights 2007 - 2008

    Original idea by by Binny V A, http://www.openjs.com/scripts/events/keyboard_shortcuts/

    jQuery Plugin by Tzury Bar Yochay
    tzury.by@gmail.com
    http://evalinux.wordpress.com
    http://facebook.com/profile.php?id=513676303

    Project's sites:
    http://code.google.com/p/js-hotkeys/
    http://github.com/tzuryby/hotkeys/tree/master

    License: same as jQuery license. */
    var specialKeys = { 27: 'esc', 9: 'tab', 32:'space', 13: 'return', 8:'backspace', 145: 'scroll',
        20: 'capslock', 144: 'numlock', 19:'pause', 45:'insert', 36:'home', 46:'del',
        35:'end', 33: 'pageup', 34:'pagedown', 37:'left', 38:'up', 39:'right',40:'down',
        112:'f1',113:'f2', 114:'f3', 115:'f4', 116:'f5', 117:'f6', 118:'f7', 119:'f8',
        120:'f9', 121:'f10', 122:'f11', 123:'f12', 191:'/' };
    if ($.browser.mozilla){
        specialKeys = $.extend(specialKeys, { 96: '0', 97:'1', 98: '2', 99:
            '3', 100: '4', 101: '5', 102: '6', 103: '7', 104: '8', 105: '9' });
    }
    if(typeof(options) == "string") {
      options = {keyCodes: options};
    }
    if(this.filter(":input,object,embed").length > 0) {
      options.ignore = "";
    }
    var options = $.extend({}, $.fn.keycodes.defaults, options);

    var keyCodes = [];
    var originalCodes = [];
    var codes = options.keyCodes.split(" ");
    $.each(codes, function(i, code) {
      originalCodes.push(code);
      code = code.split("+").sort().join("+").toLowerCase();
      keyCodes.push(code);
    });
    this.bind('keydown', function(event, originalEvent) {
      event = (originalEvent && originalEvent.keyCode) ? originalEvent : event;
      if(options.ignore && $(event.target).is(options.ignore)) { return; }
      var code = [];
      if(event.shiftKey) { code.push("Shift"); }
      if(event.ctrlKey) { code.push("Ctrl"); }
      if(event.metaKey) { code.push("Meta"); }
      if(event.altKey) { code.push("Alt"); }
      var key = specialKeys[event.keyCode];
      key = key || String.fromCharCode(event.keyCode);
      code.push(key);
      code = code.sort().join("+").toLowerCase();
      event.keyMatches = function(checkCode) {
        checkCode = checkCode.split("+").sort().join("+").toLowerCase();
        return checkCode == code;
      };
      var idx = $.inArray(code, keyCodes);
      var picker = $(document).data('last_datepicker');
      if(picker && picker[0] == this && event.keyCode == 27) {
        event.preventDefault();
        return false;
      }

      if(idx != -1) {
        event.keyString = originalCodes[idx];
        fn.call(this, event);
      }
    });
    return this;
  };
  $.fn.keycodes.defaults = {ignore: ":input,object,embed", keyCodes: ""};
  $.datepicker.oldParseDate = $.datepicker.parseDate;
  $.datepicker.parseDate = function(format, value, settings) {
    return Date.parse((value || "").toString().replace(/ (at|by)/, "")) || $.datepicker.oldParseDate(format, value, settings);
  };
  $.datepicker._generateDatepickerHTML = $.datepicker._generateHTML;
  $.datepicker._generateHTML = function(inst) {
    var html = $.datepicker._generateDatepickerHTML(inst);
    if(inst.settings.timePicker) {
      var hr = inst.input.data('time-hour') || "";
      hr = hr.replace(/'/g, "");
      var min = inst.input.data('time-minute') || "";
      min = min.replace(/'/g, "");
      var ampm = inst.input.data('time-ampm') || "";
      var selectedAM = (ampm == "am") ? "selected" : "";
      var selectedPM = (ampm == "pm") ? "selected" : "";
      html += "<div class='datepicker-time'><label for='ui-datepicker-time-hour'>" + $.h(I18n.beforeLabel('datepicker.time', "Time")) + "</label> <input id='ui-datepicker-time-hour' type='text' value='" + hr + "' title='hr' class='ui-datepicker-time-hour' style='width: 20px;'/>:<input type='text' value='" + min + "' title='min' class='ui-datepicker-time-minute' style='width: 20px;'/> <select class='ui-datepicker-time-ampm' title='" + $.h(I18n.t('datepicker.titles.am_pm', "am/pm")) + "'><option value=''>&nbsp;</option><option value='am' " + selectedAM + ">" + $.h(I18n.t('#time.am', "am")) + "</option><option value='pm' " + selectedPM + ">" + $.h(I18n.t('#time.pm', "pm")) + "</option></select>&nbsp;&nbsp;&nbsp;<button type='button' class='button small-button ui-datepicker-ok'>" + $.h(I18n.t('#buttons.done', "Done")) + "</button></div>";
    }
    return html;
  };
  $.fn.realDatepicker = $.fn.datepicker;
  var _originalSelectDay = $.datepicker._selectDay;
  $.datepicker._selectDay = function(id, month, year, td) {
    var target = $(id);
    if ($(td).hasClass(this._unselectableClass) || this._isDisabledDatepicker(target[0])) {
      return;
    }
    var inst = this._getInst(target[0]);
    if(inst.settings.timePicker && !$.datepicker.okClicked && !inst._keyEvent) {
      var origVal = inst.inline;
      inst.inline = true;
      $.data(target, 'datepicker', inst);
      _originalSelectDay.call(this, id, month, year, td);
      inst.inline = origVal;
      $.data(target, 'datepicker', inst);
    } else {
      _originalSelectDay.call(this, id, month, year, td);
    }
  };
  $.fn.datepicker = function(options) {
    options = $.extend({}, options);
    options.prevOnSelect = options.onSelect;
    options.onSelect = function(text, picker) {
      if(options.prevOnSelect) {
        options.prevOnSelect.call(this, text, picker);
      }
      var $div = picker.dpDiv;
      var hr = $div.find(".ui-datepicker-time-hour").val() || $(this).data('time-hour');
      var min = $div.find(".ui-datepicker-time-minute").val() || $(this).data('time-minute');
      var ampm = $div.find(".ui-datepicker-time-ampm").val() || $(this).data('time-ampm');
      if(hr) {
        min = min || "00";
        ampm = ampm || "pm";
        var time = hr + ":" + min + " " + ampm;
        text += " " + time;
      }
      picker.input.val(text).change();
    };
    if(!$.fn.datepicker.timepicker_initialized) {
      $(document).delegate('.ui-datepicker-ok', 'click', function(event) {
        var cur = $.datepicker._curInst;
        var inst = cur;
        var sel = $('td.' + $.datepicker._dayOverClass +
          ', td.' + $.datepicker._currentClass, inst.dpDiv);
        if (sel[0]) {
          $.datepicker.okClicked = true;
          $.datepicker._selectDay(cur.input[0], inst.selectedMonth, inst.selectedYear, sel[0]);
          $.datepicker.okClicked = false;
        } else {
          $.datepicker._hideDatepicker(null, $.datepicker._get(inst, 'duration'));
        }
      });
      $(document).delegate(".ui-datepicker-time-hour", 'change keypress focus blur', function(event) {
        var cur = $.datepicker._curInst;
        if(cur) {
          var val = $(this).val();
          $(this).val(val);
          cur.input.data('time-hour', val);
        }
      }).delegate(".ui-datepicker-time-minute", 'change keypress focus blur', function(event) {
        var cur = $.datepicker._curInst;
        if(cur) {
          var val = $(this).val();
          $(this).val(val);
          cur.input.data('time-minute', val);
        }
      }).delegate(".ui-datepicker-time-ampm", 'change keypress focus blur', function(event) {
        var cur = $.datepicker._curInst;
        if(cur) {
          var val = $(this).val();
          $(this).val(val);
          cur.input.data('time-ampm', val);
        }
      });
      $(document).delegate(".ui-datepicker-time-hour,.ui-datepicker-time-minute,.ui-datepicker-time-ampm", 'mousedown', function(event) {
        $(this).focus();
      });
      $(document).delegate(".ui-datepicker-time-hour,.ui-datepicker-time-minute,.ui-datepicker-time-ampm", 'change keypress focus blur', function(event) {
        if(event.keyCode && event.keyCode == 13) {
          var cur = $.datepicker._curInst;
          var inst = cur;
          var sel = $('td.' + $.datepicker._dayOverClass +
            ', td.' + $.datepicker._currentClass, inst.dpDiv);
          if (sel[0]) {
            $.datepicker.okClicked = true;
            $.datepicker._selectDay(cur.input[0], inst.selectedMonth, inst.selectedYear, sel[0]);
            $.datepicker.okClicked = false;
          } else {
            $.datepicker._hideDatepicker(null, $.datepicker._get(inst, 'duration'));
          }
        } else if(event.keyCode && event.keyCode == 27) {
          $.datepicker._hideDatepicker(null, '');
        }
      });
      $.fn.datepicker.timepicker_initialized = true;
    }
    this.realDatepicker(options);
    $(document).data('last_datepicker', this);
  };
  $.fn.date_field = function(options) {
    options = $.extend({}, options);
    options.dateOnly = true;
    this.datetime_field(options);
    return this;
  };
  $.fn.time_field = function(options) {
    options = $.extend({}, options);
    options.timeOnly = true;
    this.datetime_field(options);
    return this;
  };
  $.fn.datetime_field = function(options) {
    options = $.extend({}, options);
    this.each(function() {
      var $field = $(this);
      // if($field.hasClass('datetime_field_enabled')) { return; }
      // $field.addClass('datetime_field_enabled');
      if(!options.timeOnly) {
        $field.datepicker({
          timePicker: (!options.dateOnly),
          constrainInput: false,
          dateFormat: 'M d, yy',
          showOn: 'button',
          buttonImage: '/images/datepicker.gif?1234',
          buttonImageOnly: true
        });
      }
      var $after = $(this);
      $field.addClass('datetime_field_enabled');
      if($field.next(".ui-datepicker-trigger").length > 0) { $after = $field.next(); }
      var $div = $(document.createElement('div')).addClass('datetime_suggest');
      $after.after($div);
      $div = $after.next();
      $field.bind("change focus blur keyup", function() {
        var val = $(this).val();
        if(options.timeOnly && val && parseInt(val, 10) == val) {
          if(val < 8) {
            val += "pm";
          } else {
            val += "am";
          }
        }
        var d = Date.parse((val || "").toString().replace(/ (at|by)/, ""));
        var parse_error_message = I18n.t('errors.not_a_date', "That's not a date!"); 
        var text = parse_error_message;
        if(!$(this).val()) { text = ""; }
        if(d) {
          $(this).data('date', d);
          if(!options.timeOnly && !options.dateOnly && (d.getHours() || d.getMinutes() || options.alwaysShowTime)) {
            text = d.toString('ddd MMM d, yyyy h:mmtt');
            $(this).data('time-hour', d.toString('h'))
              .data('time-minute', d.toString('mm'))
              .data('time-ampm', d.toString('tt').toLowerCase());
          } else if(!options.timeOnly) {
            text = d.toString('ddd MMM d, yyyy');
          } else {
            text = d.toString('h:mmtt').toLowerCase();
          }
        }
        var $suggest = $(this).parent().children('.datetime_suggest');
        if($suggest) {
          $suggest.toggleClass('invalid_datetime', text == parse_error_message);
          $suggest.text(text);
        }
      }).triggerHandler('change');
    });
    return this;
  };
  $.datetime = {};
  $.datetime.shortFormat = "MMM d, yyyy";
  $.datetime.defaultFormat = "MMM d, yyyy h:mmtt";
  $.datetime.sortableFormat = "yyyy-MM-ddTHH:mm:ss";
  $.datetime.clean = function(text) {
    var date = Date.parse((text || "").toString("yyyy-MM-ddTHH:mm:ss").replace(/ (at|by)/, "")) || text;
    var result = "";
    if(date) {
      if(date.getHours() || date.getMinutes()) {
        result = date.toString($.datetime.defaultFormat);
      } else {
        result = date.toString($.datetime.shortFormat);
      }
    }
    return result;
  };
  $.datetime.process = function(text) {
    var date = text;
    if(typeof(text) == "string") {
      date = Date.parse((text || "").toString().replace(/ (at|by)/, ""));
    }
    var result = "";
    if(date) {
      result = date.toString($.datetime.sortableFormat);
    }
    return result;
  };
    /* Based loosely on:
    jQuery ui.timepickr - 0.6.5
    http://code.google.com/p/jquery-utils/

    (c) Maxime Haineault <haineault@gmail.com>
    http://haineault.com

    MIT License (http://www.opensource.org/licenses/mit-license.php */
  $.fn.timepicker = function() {
    var $picker = $("#time_picker");
    if($picker.length === 0) {
      $picker = $._initializeTimepicker();
    }
    this.each(function() {
      $(this).focus(function() {
        var offset = $(this).offset();
        var height = $(this).outerHeight();
        var width = $(this).outerWidth();
        var $picker = $("#time_picker");
        $picker.css({
          left: -1000,
          height: 'auto',
          width: 'auto'
        }).show();
        var pickerOffset = $picker.offset();
        var pickerHeight = $picker.outerHeight();
        var pickerWidth = $picker.outerWidth();
        $picker.css({
          top: offset.top + height,
          left: offset.left
        }).end();
        $("#time_picker .time_slot").removeClass('ui-state-highlight').removeClass('ui-state-active');
        $picker.data('attached_to', $(this)[0]);
        var windowHeight = $(window).height();
        var windowWidth = $(window).width();
        var scrollTop = $.windowScrollTop();
        if((offset.top + height - scrollTop + pickerHeight) > windowHeight) {
          $picker.css({
            top: offset.top - pickerHeight
          });
        }
        if(offset.left + pickerWidth > windowWidth) {
          $picker.css({
            left: offset.left + width - pickerWidth
          });
        }
        $("#time_picker").hide().slideDown();
      }).blur(function() {
        if($("#time_picker").data('attached_to') == $(this)[0]) {
          $("#time_picker").data('attached_to', null);
          $("#time_picker").hide()
            .find(".time_slot.ui-state-highlight").removeClass('ui-state-highlight');
        }
      }).keycodes("esc return", function(event) {
        $(this).triggerHandler('blur');
      }).keycodes("ctrl+up ctrl+right ctrl+left ctrl+down", function(event) {
        if($("#time_picker").data('attached_to') != $(this)[0]) {
          return;
        }
        event.preventDefault();
        var $current = $("#time_picker .time_slot.ui-state-highlight:first");
        var time = $($("#time_picker").data('attached_to')).val();
        var hr = 12;
        var min = "00";
        var ampm = "pm";
        var idx;
        if(time && time.length >= 7) {
          hr = time.substring(0, 2);
          min = time.substring(3, 5);
          ampm = time.substring(5, 7);
        }
        if($current.length === 0) {
          idx = parseInt(time, 10) - 1;
          if(isNaN(idx)) { idx = 0; }
          $("#time_picker .time_slot").eq(idx).triggerHandler('mouseover');
          return;
        }
        if(event.keyString == "ctrl+up") {
          var $parent = $current.parent(".widget_group");
          idx = $parent.children(".time_slot").index($current);
          if($parent.hasClass('ampm_group')) {
            idx = min / 15;
          } else if($parent.hasClass('minute_group')) {
            idx = parseInt(hr, 10) - 1;
          }
          $parent.prev(".widget_group").find(".time_slot").eq(idx).triggerHandler('mouseover');
        } else if(event.keyString == "ctrl+right") {
          $current.next(".time_slot").triggerHandler('mouseover');
        } else if(event.keyString == "ctrl+left") {
          $current.prev(".time_slot").triggerHandler('mouseover');
        } else if(event.keyString == "ctrl+down") {
          $parent = $current.parent(".widget_group");
          idx = $parent.children(".time_slot").index($current);
          var $list = $parent.next(".widget_group").find(".time_slot");
          idx = Math.min(idx, $list.length - 1);
          if($parent.hasClass('hour_group')) {
            idx = min / 15;
          } else if($parent.hasClass('minute_group')) {
            idx = (ampm == "am") ? 0 : 1;
          }
          $list.eq(idx).triggerHandler('mouseover');
        }
      });
    });
    return this;
  };
  $._initializeTimepicker = function() {
    var $picker = $(document.createElement('div'));
    $picker.attr('id', 'time_picker').css({
      position: "absolute",
      display: "none"
    });
    var pickerHtml = "<div class='widget_group hour_group'>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>01</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>02</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>03</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>04</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>05</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>06</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>07</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>08</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>09</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>10</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>11</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>12</div>";
    pickerHtml += "<div class='clear'></div>";
    pickerHtml += "</div>";
    pickerHtml += "<div class='widget_group minute_group'>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>00</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>15</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>30</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>45</div>";
    pickerHtml += "<div class='clear'></div>";
    pickerHtml += "</div>";
    pickerHtml += "<div class='widget_group ampm_group'>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>" + $.h(I18n.t('#time.am', "am")) + "</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>" + $.h(I18n.t('#time.pm', "pm")) + "</div>";
    pickerHtml += "<div class='clear'></div>";
    pickerHtml += "</div>";
    $picker.html(pickerHtml);
    $("body").append($picker);
    $picker.find(".time_slot").mouseover(function() {
      $picker.find(".time_slot.ui-state-highlight").removeClass('ui-state-highlight');
      $(this).addClass('ui-state-highlight');
      var $field = $($picker.data('attached_to') || "none");
      var time = $field.val();
      var hr = 12;
      var min = "00";
      var ampm = "pm";
      if(time && time.length >= 7) {
        hr = time.substring(0, 2);
        min = time.substring(3, 5);
        ampm = time.substring(5, 7);
      }
      var val = $(this).text();
      if(val > 0 && val <= 12) {
        hr = val;
      } else if(val == "am" || val == "pm") {
        ampm = val;
      } else {
        min = val;
      }
      $field.val(hr + ":" + min + ampm);
    }).mouseout(function() {
      $(this).removeClass('ui-state-highlight');
    }).mousedown(function(event) {
      event.preventDefault();
      $(this).triggerHandler('mouseover');
      $(this).removeClass('ui-state-highlight').addClass('ui-state-active');
    }).mouseup(function() {
      $(this).removeClass('ui-state-active');
    }).click(function(event) {
      event.preventDefault();
      $(this).triggerHandler('mouseover');
      if($picker.data('attached_to')) {
        $($picker.data('attached_to')).focus();
      }
      $picker.stop().hide().data('attached_to', null);
    });
    return $picker;
  };
  
  // This is a patch that so that if you disable an element, that it also gives it the class disabled.  
  // that way you can add css classes for our friend IE6. so rather than using selector:disabled, you can do selector.disabled.
  // I patch the $.attr method, not the $.fn.attr method because both $.fn.attr and $.fn.removeAttr use $.attr. 
  // which means that it will get run trough this both when you disable AND remove the 'disabled' attribute on an element.
  $.attrBeforeHandlingDisabled = $.attr;
  $.attr = function( elem, name, value, pass ){
    if(typeof(name) === "string" && name.toLowerCase() === 'disabled' && value !== undefined) {
      $(elem)[(value ? "add" : "remove") + "Class"]('disabled');
    }
    return $.attrBeforeHandlingDisabled.apply(this, arguments);
  };
  
  // this is a patch so you can set the "method" atribute on rails' REST-ful forms.
  $.attrBeforeHandlingFormMethod = $.attr;
  $.attr = function( elem, name, value, pass ) {
    // if it's an html node and if we are trying to set the 'method' attribute
    if ( elem && value && typeof(name) === "string" && name.toLowerCase() == 'method') {
      var orginalVal = value;
      value = value.toUpperCase() === 'GET' ? 'GET' : 'POST';
      if ( value === 'POST' ) {
        var $input = $(elem).find("input[name='_method']");
        if ( !$input.length ) {
          $input = $("<input type='hidden' name='_method'/>").prependTo(elem);
        }
        $input.val(orginalVal);
      }
    }
    // can't do .apply because we need to pas the NEW 'value' that we set above, not the one in 'arguments'
    return $.attrBeforeHandlingFormMethod.call( this, elem, name, value, pass );
  };
  
  $.fn.indicate = function(options) {
    options = options || {};
    var $indicator;
    if(options == "remove") {
      $indicator = this.data('indicator');
      if($indicator) {
        $indicator.remove();
      }
      return;
    }
    $(".indicator_box").remove();
    var offset = this.offset();
    if(options && options.offset) {
      offset = options.offset;
    }
    var width = this.width();
    var height = this.height();
    var zIndex = (options.container || this).zIndex();
    $indicator = $(document.createElement('div'));
    $indicator.css({
      width: width + 6,
      height: height + 6,
      top: offset.top - 3,
      left: offset.left - 3,
      zIndex: zIndex + 1,
      position: 'absolute',
      display: 'block',
      "-moz-border-radius": 5,
      opacity: 0.8,
      border: "2px solid #870",
      backgroundColor: "#fd0"
    });
    $indicator.addClass('indicator_box');
    $indicator.mouseover(function() {
      $(this).stop().fadeOut('fast', function() {
        $(this).remove();
      });
    });
    if(this.data('indicator')) {
      this.indicate('remove');
    }
    this.data('indicator', $indicator);
    $("body").append($indicator);
    if(options && options.singleFlash) {
      $indicator.hide().fadeIn().animate({opacity: 0.8}, 500).fadeOut('slow', function() {
        $(this).remove();
      });
    } else {
      $indicator.hide().fadeIn().animate({opacity: 0.8}, 500).fadeOut('slow').fadeIn('slow').animate({opacity: 0.8}, 2500).fadeOut('slow', function() {
        $(this).remove();
      });
    }
    if(options && options.scroll) {
      $("html,body").scrollToVisible($indicator);
    }
  };
  
  $.keys = function(object){
    var results = [];
    for (var property in object)
      results.push(property);
    return results;
  };
  
  $.fn.hasScrollbar = function(){
    return this.length && (this[0].clientHeight < this[0].scrollHeight);
  };
  
  $.fn.log = function (msg) {
    console.log("%s: %o", msg, this);
    return this;
  };
  
  $.fn.chevronCrumbs = function(options) {
    return this.each(function() {
      $(this).show()
        .addClass("chevron-crumbs")
        .children().not("#hide-scratch")
          .addClass('chevron-crumb')
          .append('<span class="chevron-outer"><span class="chevron-inner"></span></span>')
          .filter(".active").prev().addClass("before-active");
    });
  };
  
  $.underscore = function(string) {
    return (string || "").replace(/([A-Z])/g, "_$1").replace(/^_/, "").toLowerCase();
  };
  $.titleize = function(string) {
    var res = (string || "").replace(/([A-Z])/g, " $1").replace(/_/g, " ").replace(/\s+/, " ").replace(/^\s/, "");
    return $.map(res.split(/\s/), function(word) { return (word[0] || "").toUpperCase() + word.substring(1); }).join(" ");
  };
  $.pluralize = function(string) {
    return (string || "") + "s";
  };
  $.pluralize_with_count = function(count, string) {
    return "" + count + " " + (count == 1 ? string : $.pluralize(string));
  }
  
  $.parseUserAgentString = function(userAgent) {
    userAgent = (userAgent || "").toLowerCase();
    var data = {
      version: (userAgent.match( /.+(?:me|ox|it|ra|ie|er)[\/: ]([\d.]+)/ ) || [0,null])[1],
      chrome: /chrome/.test( userAgent ),
      safari: /webkit/.test( userAgent ),
      opera: /opera/.test( userAgent ),
      msie: /msie/.test( userAgent ) && !(/opera/.test( userAgent )),
      firefox: /firefox/.test( userAgent),
      mozilla: /mozilla/.test( userAgent ) && !(/(compatible|webkit)/.test( userAgent )),
      speedgrader: /speedgrader/.test( userAgent )
    };
    var browser = null;
    if(data.chrome) {
      browser = "Chrome";
    } else if(data.safari) {
      browser = "Safari";
    } else if(data.opera) {
      browser = "Opera";
    } else if(data.msie) {
      browser = "Internet Explorer";
    } else if(data.firefox) {
      browser = "Firefox";
    } else if(data.mozilla) {
      browser = "Mozilla";
    } else if(data.speedgrader) {
      browser = "SpeedGrader for iPad";
    }
    if (!browser) {
      browser = I18n.t('browsers.unrecognized', "Unrecognized Browser");
    } else if(data.version) {
      data.version = data.version.split(/\./).slice(0,2).join(".");
      browser = browser + " " + data.version;
    }
    return browser;
  };
  
  $.fileSize = function(bytes) {
    var factor = 1024;
    if(bytes < factor) {
      return parseInt(bytes, 10) + " bytes";
    } else if(bytes < factor * factor) {
      return parseInt(bytes / factor, 10) + "KB";
    } else {
      return (Math.round(10.0 * bytes / factor / factor) / 10.0) + "MB";
    }
  };
  
  $.uniq = function(array) {
    var result = [];
    var hash = {};
    for(var idx in array) {
      if(!hash[array[idx]]) {
        hash[array[idx]] = true;
        result.push(array[idx]);
      }
    }
    return result;
   };

  $.getUserServices = function(service_types, success, error) {
    if(!$.isArray(service_types)) { service_types = [service_types]; }
    var url = "/services?service_types=" + service_types.join(",");
    $.ajaxJSON(url, 'GET', {}, function(data) {
      if(success) { success(data); }
    }, function(data) {
      if(error) { error(data); }
    });
  };
  
  var lastLookup; //used to keep track of diigo requests
  $.findLinkForService = function(service_type, callback) {
    var $dialog = $("#instructure_bookmark_search");
    if( !$dialog.length ) {
      $dialog = $("<div id='instructure_bookmark_search'/>");
      $dialog.append("<form id='bookmark_search_form' style='margin-bottom: 5px;'>" +
                       "<img src='/images/blank.png'/>&nbsp;&nbsp;" +
                       "<input type='text' class='query' style='width: 230px;'/>" +
                       "<button class='button search_button' type='submit'>" +
                       $.h(I18n.t('buttons.search', "Search")) + "</button></form>");
      $dialog.append("<div class='results' style='max-height: 200px; overflow: auto;'/>");
      $dialog.find("form").submit(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var now = new Date();
        if(service_type == 'diigo' && lastLookup && now - lastLookup < 15000) {
          // let the user know we have to take things slow because of Diigo
          setTimeout(function() {
            $dialog.find("form").submit();
          }, 15000 - (now - lastLookup));
          $dialog.find(".results").empty()
            .append($.h(I18n.t('status.diigo_search_throttling', "Diigo limits users to one search every ten seconds.  Please wait...")));
          return;
        }
        $dialog.find(".results").empty().append($.h(I18n.t('status.searching', "Searching...")));
        lastLookup = new Date();
        var query = $dialog.find(".query").val();
        var url = $.replaceTags($dialog.data('reference_url'), 'query', query);
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $dialog.find(".results").empty();
          if( !data.length ) {
            $dialog.find(".results").append($.h(I18n.t('no_results_found', "No Results Found")));
          }
          for(var idx in data) {
            data[idx].short_title = data[idx].title;
            if(data[idx].title == data[idx].description) {
              data[idx].short_title = $.truncateText(data[idx].description, 30);
            }
            $("<div class='bookmark'/>")
              .appendTo($dialog.find(".results"))
              .append($('<a class="bookmark_link" style="font-weight: bold;"/>').attr({
                  href: data[idx].url,
                  title: data[idx].title
                }).text(data[idx].short_title)
              )
              .append($("<div style='margin: 5px 10px; font-size: 0.8em;'/>").text(data[idx].description || I18n.t('no_description', "No description")));
          }
        }, function() {
          $dialog.find(".results").empty()
            .append($.h(I18n.t('errors.search_failed', "Search failed, please try again.")));
        });
      });
      $dialog.delegate('.bookmark_link', 'click', function(event) {
        event.preventDefault();
        var url = $(this).attr('href');
        var title = $(this).attr('title') || $(this).text();
        $dialog.dialog('close');
        callback({
          url: url,
          title: title
        });
      });
    }
    $dialog.find(".search_button").text(service_type == 'delicious' ? I18n.t('buttons.search_by_tag', "Search by Tag") : I18n.t('buttons.search', "Search"));
    $dialog.find("form img").attr('src', '/images/' + service_type + '_small_icon.png');
    var url = "/search/bookmarks?q=%7B%7B+query+%7D%7D&service_type=%7B%7B+service_type+%7D%7D";
    url = $.replaceTags(url, 'service_type', service_type);
    $dialog.data('reference_url', url);
    $dialog.find(".results").empty().end()
      .find(".query").val("");
    $dialog.dialog('close').dialog({
      autoOpen: false,
      title: I18n.t('titles.bookmark_search', "Bookmark Search: %{service_name}", {service_name: $.titleize(service_type)}),
      open: function() {
        $dialog.find("input:visible:first").focus().select();
      },
      width: 400
    }).dialog('open');
  };
  
  $.findImageForService = function(service_type, callback) {
    var $dialog = $("#instructure_image_search");
    $dialog.find("button").attr('disabled', false);
    if( !$dialog.length ) {
      $dialog = $("<div id='instructure_image_search'/>")
                  .append("<form id='image_search_form' style='margin-bottom: 5px;'>" +
                            "<img src='/images/flickr_creative_commons_small_icon.png'/>&nbsp;&nbsp;" + 
                            "<input type='text' class='query' style='width: 250px;' title='" +
                            $.h(I18n.t('tooltips.enter_search_terms', "enter search terms")) + "'/>" + 
                            "<button class='button' type='submit'>" +
                            $.h(I18n.t('buttons.search', "Search")) + "</button></form>")
                  .append("<div class='results' style='max-height: 240px; overflow: auto;'/>");
      
      $dialog.find("form .query").formSuggestion();
      $dialog.find("form").submit(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var now = new Date();
        $dialog.find("button").attr('disabled', true);
        $dialog.find(".results").empty().append(I18n.t('status.searching', "Searching..."));
        $dialog.bind('search_results', function(event, data) {
          $dialog.find("button").attr('disabled', false);
          if(data && data.photos && data.photos.photo) {
            $dialog.find(".results").empty();
            for(var idx in data.photos.photo) {
              var photo = data.photos.photo[idx],
                  image_url = "http://farm" + photo.farm + ".static.flickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_s.jpg",
                  big_image_url = "http://farm" + photo.farm + ".static.flickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + ".jpg",
                  source_url = "http://www.flickr.com/photos/" + photo.owner + "/" + photo.id;
                  
              $dialog.find(".results").append(
                $('<div class="image" style="float: left; padding: 2px; cursor: pointer;"/>')
                .append($('<img/>', {
                  data: {
                    source: source_url,
                    big_image_url: big_image_url
                  },
                  'class': "image_link",
                  src: image_url,
                  title: "embed " + (photo.title || ""),
                  alt: photo.title || ""  
                }))
              );
            }
          } else {
            $dialog.find(".results").empty().append($.h(I18n.t('errors.search_failed', "Search failed, please try again.")));
          }
        });
        var query = encodeURIComponent($dialog.find(".query").val());
        // this request will be handled by window.jsonFlickerApi()
        $.getScript("http://www.flickr.com/services/rest/?method=flickr.photos.search&format=json&api_key=734839aadcaa224c4e043eaf74391e50&per_page=25&license=1,2,3,4,5,6&sort=relevance&text=" + query);
      });
      $dialog.delegate('.image_link', 'click', function(event) {
        event.preventDefault();
        $dialog.dialog('close');
        callback({
          image_url: $(this).data('big_image_url') || $(this).attr('src'),
          link_url: $(this).data('source'),
          title: $(this).attr('alt')
        });
      });
    }
    $dialog.find("form img").attr('src', '/images/' + service_type + '_small_icon.png');
    var url = $("#editor_tabs .bookmark_search_url").attr('href');
    url = $.replaceTags(url, 'service_type', service_type);
    $dialog
      .data('reference_url', url)
      .find(".results").empty().end()
      .find(".query").val("").end()
      .dialog('close')
      .dialog({
        autoOpen: false,
        title: I18n.t('titles.image_search', "Image Search: %{service_name}", {service_name: $.titleize(service_type)}),
        width: 440,
        open: function() {
          $dialog.find("input:visible:first").focus().select();
        },
        height: 320
      })
      .dialog('open');
  };
  
  $.truncateText = function(string, max) {
    max = max || 30;
    if ( !string ) { 
      return ""; 
    } else {
      var split  = (string || "").split(/\s/),
          result = "",
          done   = false;
          
      for(var idx in split) {
        var val = split[idx];
        if ( done ) {
          // do nothing
        } else if( val && result.length < max) {
          if(result.length > 0) {
            result += " ";
          }
          result += val;
        } else {
          done = true;
          result += "...";
        }
      }
      return result;
    }
  };
  
  function getTld(hostname){
    hostname = (hostname || "").split(":")[0];
    var parts = hostname.split("."),
        length = parts.length;
    return ( length > 1  ? 
      [ parts[length - 2] , parts[length - 1] ] : 
      parts 
    ).join("");
  }
  var locationTld = getTld(window.location.hostname);
  
  $.expr[':'].external = function(element){
    var href = $(element).attr('href');
    //if a browser doesnt support <a>.hostname then just dont mark anything as external, better to not get false positives.
    return !!(href && href.length && !href.match(/^(mailto\:|javascript\:)/) && element.hostname && getTld(element.hostname) != locationTld);
  };
  
  INST.youTubeRegEx = /^https?:\/\/(www\.youtube\.com\/watch.*v(=|\/)|youtu\.be\/)([^&#]*)/;
  $.youTubeID = function(path) {
    var match = path.match(INST.youTubeRegEx);
    if(match && match[match.length - 1]) {
      return match[match.length - 1];
    }
    return null;
  };
  
  window.equella = {
    ready: function(data) {
      $(document).triggerHandler('equella_ready', data);
    },
    cancel: function() {
      $(document).triggerHandler('equella_cancel');
    }
  };
  $(document).bind('equella_ready', function(event, data) {
    $("#equella_dialog").triggerHandler('equella_ready', data);
  }).bind('equella_cancel', function() {
    $("#equella_dialog").dialog('close');
  });
  
  var storage_user_id;
  function getUser() {
    if ( !storage_user_id ) {
      storage_user_id = $.trim($("#identity .user_id").text());
    }
    return storage_user_id;
  };
  
  $.store.userGet = function(key) {
    return $.store.get("_" + getUser() + "_" + key);
  };
  
  $.store.userSet = function(key, value) {
    return $.store.set("_" + getUser() + "_" + key, value);
  };
  
  $.store.userRemove = function(key, value) {
    return $.store.remove("_" + getUser() + "_" + key, value);
  };
  
  window.jsonFlickrApi = function(data) {
    $("#instructure_image_search").triggerHandler('search_results', data);
  };

  // return query string parameter
  // $.queryParam("name") => qs value or null
  $.queryParam = function(name) {
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regex = new RegExp("[\\?&]"+name+"=([^&#]*)");
    var results = regex.exec(window.location.search);
    if(results == null)
      return results;
    else
      return decodeURIComponent(results[1].replace(/\+/g, " "));
  };
  
  // tells you how many keys are in an object, 
  // so: $.size({})  === 0  and $.size({foo: "bar"}) === 1
  $.size = function(object) {
    var keyCount = 0;
    $.each(object,function(){ keyCount++; });
    return keyCount;
  };
  
  $.capitalize = function(string) {
    return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase();
  };
  
  // first element in array is if scribd can handle it, second is if google can.
  var previewableMimeTypes = {
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template":   [1, 1],
      "application/vnd.oasis.opendocument.spreadsheet":                            [1, 1],
      "application/vnd.sun.xml.writer":                                            [1, 1],
      "application/excel":                                                         [1, 1],
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":         [1, 1],
      "text/rtf":                                                                  [1, false],
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template":      [1, 1],
      "application/vnd.sun.xml.impress":                                           [1, 1],
      "application/vnd.sun.xml.calc":                                              [1, 1],
      "application/vnd.ms-excel":                                                  [1, 1],
      "application/msword":                                                        [1, 1],
      "application/mspowerpoint":                                                  [1, 1],
      "application/rtf":                                                           [1, 1],
      "application/vnd.oasis.opendocument.presentation":                           [1, 1],
      "application/vnd.oasis.opendocument.text":                                   [1, 1],
      "application/vnd.openxmlformats-officedocument.presentationml.template":     [1, 1],
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow":    [1, 1],
      "text/plain":                                                                [1, 1],
      "application/vnd.openxmlformats-officedocument.presentationml.presentation": [1, 1],
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document":   [1, 1],
      "application/postscript":                                                    [1, 1],
      "application/pdf":                                                           [1, 1],
      "application/vnd.ms-powerpoint":                                             [1, 1]

  };
  
  $.filePreviewsEnabled = function(){
    return !(INST.disableScribdPreviews && INST.disableGooglePreviews);
  }
  
  // check to see if a file of a certan mimeType is previewable inline in the browser by either scribd or googleDocs
  // ex: $.isPreviewable("application/mspowerpoint")  -> true
  //     $.isPreviewable("application/rtf", 'google') -> false
  $.isPreviewable = function(mimeType, service){
    return $.filePreviewsEnabled() && previewableMimeTypes[mimeType] && (
      !service ||
      (!INST['disable' + $.capitalize(service) + 'Previews'] && previewableMimeTypes[mimeType][{scribd: 0, google: 1}[service]])
    );
  };
  
  $.fn.loadDocPreview = function(options) {
    // if it is a scribd doc and flash is available
    var flashVersion = swfobject.getFlashPlayerVersion(),
        hasGoodEnoughFlash = flashVersion && flashVersion.major > 9;
    
    return this.each(function(){
      var $this = $(this),
          opts = $.extend({
            height: '400px'
          }, $this.data(), options);
          
      function tellAppIViewedThisInline(){
        // if I have a url to ping back to the app that I viewed this file inline, ping it.
        if (opts.attachment_view_inline_ping_url) {
          $.ajaxJSON(opts.attachment_view_inline_ping_url, 'POST', {}, function() { }, function() { });
        }
      }
      
      // if doc is scribdable, and the browser can show it.
      if (!INST.disableScribdPreviews && opts.scribd_doc_id && opts.scribd_access_key && hasGoodEnoughFlash && scribd) {
        var scribdDoc = scribd.Document.getDoc( opts.scribd_doc_id, opts.scribd_access_key ),
            id = $this.attr('id'),
            // see http://www.scribd.com/developers/api?method_name=Javascript+API for an explaination of these options
            scribdParams = $.extend({ 
              'jsapi_version': 1, 
              'disable_related_docs': true, //Disables the related documents tab in List Mode.
              'auto_size' : false, //When false, this parameter forces Scribd Reader to use the provided width and height rather than using a width multiplier of 85/110.
              'height' : opts.height,
              'use_ssl' : 'https:' == document.location.protocol
            }, opts.scribdParams);

        if (!id) {
          id = $.uniqueId("scribd_preview_");
          $this.attr('id', id);
        }
        $.each(scribdParams, function(key, value){
          scribdDoc.addParam(key, value);
        });
        if ($.isFunction(opts.ready)) {
          scribdDoc.addEventListener('iPaperReady', opts.ready);
        }
        scribdDoc.write( id );
        tellAppIViewedThisInline();
      } else if (!INST.disableGooglePreviews && (!opts.mimeType || $.isPreviewable(opts.mimeType, 'google')) && opts.attachment_id || opts.public_url){ 
        // else if it's something google docs preview can handle and we can get a public url to this document.
        function loadGooglePreview(){
          // this handles both ssl and plain http.
          var googleDocPreviewUrl = '//docs.google.com/viewer?' + $.param({
            embedded: true,
            url: opts.public_url
          });
          $('<iframe src="' + googleDocPreviewUrl + '" height="' + opts.height  + '" width="100%" />')
            .appendTo($this)
            .load(function(){
              tellAppIViewedThisInline();
              if ($.isFunction(opts.ready)) {
                opts.ready();
              }
            });
        }
        if (opts.public_url) { 
          loadGooglePreview()
        } else if (opts.attachment_id) {
          var url = '/files/'+opts.attachment_id+'/public_url.json';
          if (opts.submission_id) {
            url += '?' + $.param({ submission_id: opts.submission_id });
          }
          $this.loadingImage();
          $.ajaxJSON(url, 'GET', {}, function(data){
            $this.loadingImage('remove');
            if (data && data.public_url) {
              $.extend(opts, data);
              loadGooglePreview();
            }
          });
        }
      } else {
        // else fall back with a message that the document can't be viewed inline
        $this.html('<p>' + $.h(I18n.t('errors.cannot_view_document_inline', 'This document cannot be viewed inline, you might not have permission to view it or it might have been deleted.')) + '</p>');
      }
    });
  };
  
  // this is used if you want to fill the browser window with something inside #content but you want to also leave the footer and header on the page.
  $.fn.fillWindowWithMe = function(options){
    var opts               = $.extend({minHeight: 400}, options),
        $this              = $(this),
        $wrapper_container = $('#wrapper-container'),
        $main              = $('#main'),
        $not_right_side    = $('#not_right_side'),
        $window            = $(window),
        $toResize          = $(this).add(opts.alsoResize);

    function fillWindowWithThisElement(){
      $toResize.height(0);
      var spaceLeftForThis = $window.height() 
                             - ($wrapper_container.offset().top + $wrapper_container.height())
                             + ($main.height() - $not_right_side.height()),
          newHeight = Math.max(400, spaceLeftForThis);
                               
      $toResize.height(newHeight);
      if ($.isFunction(opts.onResize)) {
        opts.onResize.call($this, newHeight);
      }
    }
    fillWindowWithThisElement();
    $window
      .unbind('resize.fillWindowWithMe')
      .bind('resize.fillWindowWithMe', fillWindowWithThisElement);
    return this;
  };

  $.regexEscape = function(string) {
    return string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  }

  $.fn.autoGrowInput = function(o) {

    o = $.extend({
        maxWidth: 1000,
        minWidth: 0,
        comfortZone: 70
    }, o);

    this.filter('input:text').each(function(){

      var minWidth = o.minWidth || $(this).width(),
        val = '',
        input = $(this),
        testSubject = $('<tester/>').css({
          position: 'absolute',
          top: -9999,
          left: -9999,
          width: 'auto',
          fontSize: input.css('fontSize'),
          fontFamily: input.css('fontFamily'),
          fontWeight: input.css('fontWeight'),
          letterSpacing: input.css('letterSpacing'),
          whiteSpace: 'nowrap'
        }),
        check = function() {

          setTimeout(function() {
            if (val === (val = input.val())) {return;}

            // Enter new content into testSubject
            var escaped = val.replace(/&/g, '&amp;').replace(/\s/g,'&nbsp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            testSubject.html(escaped);

            // Calculate new width + whether to change
            var testerWidth = testSubject.width(),
              newWidth = (testerWidth + o.comfortZone) >= minWidth ? testerWidth + o.comfortZone : minWidth,
              currentWidth = input.width(),
              isValidWidthChange = (newWidth < currentWidth && newWidth >= minWidth)
                                   || (newWidth > minWidth && newWidth < o.maxWidth);

            // Animate width
            if (isValidWidthChange) {
              input.width(newWidth);
            }
          });

        };

      testSubject.insertAfter(input);

      $(this).bind('keyup keydown blur update change', check);

    });

    return this;

  };
});
