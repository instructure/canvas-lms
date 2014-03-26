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
define([
  'i18n!media_comments',
  'underscore',
  'vendor/jquery.ba-tinypubsub',
  'jquery' /* $ */,
  'str/htmlEscape',
  'compiled/media_comments/js_uploader',
  'compiled/jquery/mediaComment' /* $.fn.mediaComment */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* /\$\.h/, /\$\.fileSize/ */,
  'jquery.instructure_misc_plugins' /* .dim, /\.log\(/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(I18n, _, pubsub, $, htmlEscape, JsUploader) {


  $.mediaComment = function(command, arg1, arg2) {
    var $container = $("<div/>")
    $("body").append($container.hide());
    $.fn.mediaComment.apply($container, arguments);
  }

  var domainRootAccountId;
  $.mediaComment.partnerData = function(params) {
    var hash = {
      context_code: $.mediaComment.contextCode(),
      root_account_id: domainRootAccountId || (domainRootAccountId = Number($("#domain_root_account_id").text())),
      context_source: ENV.CONTEXT_ACTION_SOURCE
    }
    if(ENV.SIS_SOURCE_ID){
      hash['sis_source_id'] = ENV.SIS_SOURCE_ID
    }
    if(ENV.SIS_USER_ID){
      hash['sis_user_id'] = ENV.SIS_USER_ID
    }
    return JSON.stringify(hash);
  }

  $.mediaComment.contextCode = function() {
    // if we can't figure out which context we are in assume that it is the current logged in user
    return ENV.context_asset_string || ('user_' + ENV.current_user_id);
  }

  function addEntry(entry){
    var contextCode = $.mediaComment.contextCode(),
        mediaType = { 2: 'image', 5: 'audio' }[entry.mediaType] || 'video';

    if (contextCode) {
      $.ajaxJSON("/media_objects", "POST", {
        id: entry.entryId,
        type: mediaType,
        context_code: contextCode,
        title: entry.title,
        user_entered_title: entry.userTitle
      }, function(data) {
        pubsub.publish('media_object_created', data);
      }, $.noop);
    }
    pubsub.publish('media_comment_created', {id: entry.entryId, mediaType: mediaType});
  }

  var addedEntryIds = {};
  $.mediaComment.entryAdded = function(entryId, entryType, title, userTitle) {
    if (!entryId || addedEntryIds[entryId]) return;
    addedEntryIds[entryId] = true;
    var entry = {
      mediaType: entryType,
      entryId: entryId,
      title: title,
      userTitle: userTitle
    };
    addEntry(entry);
  };

  // **********************************************************************
  // audio delegate for flash
  // **********************************************************************
  $.mediaComment.audio_delegate = {
    readyHandler: function() {
      try {
        $("#audio_upload")[0].setMediaType('audio');
      } catch (e) {
        $.mediaComment.upload_delegate.setupErrorHandler();
      }
    },
    selectHandler: function() {
      $.mediaComment.upload_delegate.selectHandler('audio');
    },
    singleUploadCompleteHandler: function(entries) {
      $.mediaComment.upload_delegate.singleUploadCompleteHandler('audio', entries);
    },
    allUploadsCompleteHandler: function() {
      $.mediaComment.upload_delegate.allUploadsCompleteHandler('audio');
    },
    entriesAddedHandler: function(entries) {
      $.mediaComment.upload_delegate.entriesAddedHandler('audio', entries);
    },
    progressHandler: function(info) {
      $.mediaComment.upload_delegate.progressHandler('audio', info[0], info[1], info[2]);
    },
    uploadErrorHandler: function() {
      $.mediaComment.upload_delegate.uploadErrorHandler('audio');
    }
  };

  // **********************************************************************
  // video delegate for flash
  // **********************************************************************
  $.mediaComment.video_delegate = {
    readyWatcher: null,
    expectReady: function() {
      // In IE, if cross-domain permissions aren't set up correctly, Flash silently stops interacting with JS.
      if ($.mediaComment.video_delegate.readyWatcher) {return;}
      $.mediaComment.video_delegate.readyWatcher = setTimeout($.mediaComment.upload_delegate.setupErrorHandler, 2000);
    },
    readyHandler: function() {
      try {
        $("#video_upload")[0].setMediaType('video');
      } catch (e) {
        $.mediaComment.upload_delegate.setupErrorHandler();
      }
      clearTimeout($.mediaComment.video_delegate.readyWatcher);
      $.mediaComment.video_delegate.readyWatcher = true;
    },
    selectHandler: function() {
      $.mediaComment.upload_delegate.selectHandler('video');
    },
    singleUploadCompleteHandler: function(entries) {
      $.mediaComment.upload_delegate.singleUploadCompleteHandler('video', entries);
    },
    allUploadsCompleteHandler: function() {
      $.mediaComment.upload_delegate.allUploadsCompleteHandler('video');
    },
    entriesAddedHandler: function(entries) {
      $.mediaComment.upload_delegate.entriesAddedHandler('video', entries);
    },
    progressHandler: function(info) {
      $.mediaComment.upload_delegate.progressHandler('video', info[0], info[1], info[2]);
    },
    uploadErrorHandler: function() {
      $.mediaComment.upload_delegate.uploadErrorHandler('video');
    }
  };

  // **********************************************************************
  // uploader flash delegate
  // **********************************************************************
  $.mediaComment.upload_delegate = {
    currentType: 'audio',
    submit: function() {
      var type = $.mediaComment.upload_delegate.currentType;
      var files = $("#" + type + "_upload")[0].getFiles();
      if(files.length > 1) {
        $("#" + type + "_upload")[0].removeFiles(0, files.length - 2);
      }
      files = $("#" + type + "_upload")[0].getFiles();
      if(files.length == 0) {
        return;
      }
      $("#media_upload_progress").css('visibility', 'visible').progressbar({value: 1});
      $("#media_upload_submit").attr('disabled', true).text(I18n.t('messages.submitting', "Submitting Media File..."));
      $("#" + type + "_upload")[0].upload();
    },
    selectHandler: function(type) {
      $.mediaComment.upload_delegate.currentType = type;
      try {
        var files = $("#" + type + "_upload")[0].getFiles();
      } catch (e) {
        $.mediaComment.upload_delegate.setupErrorHandler();
        return;
      }
      if(files.length > 1) {
        $("#" + type + "_upload")[0].removeFiles(0, files.length - 2);
      }
      var file = $("#" + type + "_upload")[0].getFiles()[0];
      $("#media_upload_settings .icon").attr('src', '/images/file-' + type + '.png');
      $("#media_upload_submit").show();
      $("#media_upload_submit").attr('disabled', file ? false : true)
      $("#media_upload_settings").css('visibility', file ? 'visible' : 'hidden');
      $("#media_upload_title").val(file.title);
      $("#media_upload_display_title").text(file.title);
      $("#media_upload_file_size").text($.fileSize(file.bytesTotal));


      $("#media_upload_feedback_text").html("");
      $("#media_upload_feedback").css('visibility', 'hidden');
      if (file.bytesTotal > INST.kalturaSettings.max_file_size_bytes) {
        $("#media_upload_feedback_text").html(I18n.t('errors.file_too_large', "*This file is too large.* The maximum size is %{size}MB.", { size: INST.kalturaSettings.max_file_size_bytes / 1048576, wrapper: '<b>$1</b>' }));
        $("#media_upload_feedback").css('visibility', 'visible');
        $("#media_upload_submit").hide();
        return;
      }

      // Currently there is a known problem with the
      // KUpload widget, where unless you submit the uploaded
      // file as part of the select callback, the flash widget
      // has some sort of access control problem.  When this is
      // fixed we can uncomment this line and remove the one
      // after it.
      // $("#media_upload_title").focus().select();
      $("#media_upload_submit").click();
    },
    singleUploadCompleteHandler: function(type, entries) {
      $("#media_upload_progress").progressbar('option', 'value', 100);
    },
    allUploadsCompleteHandler: function(type) {
      $("#media_upload_progress").progressbar('option', 'value', 100);
      $("#" + type + "_upload")[0].addEntries();
    },
    entriesAddedHandler: function(type, entries) {
      $("#media_upload_progress").progressbar('option', 'value', 100);
      var entry = entries[0];
      $("#media_upload_submit").text(I18n.t('messages.submitted', "Submitted Media File!"));
      setTimeout(function() {
        $("#media_comment_dialog").dialog('close');
      }, 1500);
      if(type == 'audio') {
        entry.entryType = 5;
      } else if(type == 'video') {
        entry.entryType = 1;
      }
      $.mediaComment.entryAdded(entry.entryId, entry.entryType, entry.title);
    },
    progressHandler: function(type, loaded_bytes, total_bytes, entry) {
      var pct = 100.0 * loaded_bytes / total_bytes;
      $("#media_upload_progress").progressbar('option', 'value', pct);
    },
    uploadErrorHandler: function(type) {
      var error = $("#" + type + "_upload")[0].getError();
      $("#media_upload_errors").text(I18n.t('errors.upload_failed', "Upload failed with error:") + " " + error);
      $("#media_upload_progress").hide();
    },
    setupErrorHandler: function() {
      $("#media_upload_feedback_text").html(I18n.t('errors.media_comment_installation_broken', "Media comment uploading has not been set up properly. Please contact your administrator."));
      $("#media_upload_feedback").css('visibility', 'visible');
      $('#audio_upload_holder').css('visibility', 'hidden');
      $('#video_upload_holder').css('visibility', 'hidden');
    }
  };

  var reset_selectors = false;
  var lastInit = null;
  $.mediaComment.init = function(mediaType, opts) {
    lastInit = lastInit || new Date();
    mediaType = mediaType || "any";
    opts = opts || {};
    var user_name = $.trim($("#identity .user_name").text() || "");
    if(user_name) {
      user_name = user_name + ": " + (new Date()).toString("ddd MMM d, yyyy");
    }
    var defaultTitle = opts.defaultTitle || user_name || I18n.t('titles.media_contribution', "Media Contribution");
    var mediaCommentReady = function() {
      var ks, uid;
      if (INST.kalturaSettings.js_kaltura_uploader) {
        ks = jsUploader.getKs()
        uid = jsUploader.getUid();
      } else {
        ks = $dialog.data('ks');
        uid = $dialog.data('uid') || "ANONYMOUS"
      }
      $("#video_record_title,#audio_record_title").val(defaultTitle);
      $dialog.dialog({
        title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
        width: 560,
        height: 475,
        modal: true
      });
      $dialog.dialog('option', 'close', function() {
        $("#audio_record").before("<div id='audio_record'/>").remove();
        $("#video_record").before("<div id='video_record'/>").remove();
        if(opts && opts.close && $.isFunction(opts.close)) {
          opts.close.call($dialog);
        }
      });
      $("#audio_record").before("<div id='audio_record'/>").remove();
      $("#video_record").before("<div id='video_record'/>").remove();


      if(mediaType == "video") {
        $("#video_record_option").click();
        $("#media_record_option_holder").hide();
        $("#audio_upload_holder").hide();
        $("#video_upload_holder").show();
      } else if(mediaType == "audio") {
        $("#audio_record_option").click();
        $("#media_record_option_holder").hide();
        $("#audio_upload_holder").show();
        $("#video_upload_holder").hide();
      } else {
        $("#video_record_option").click();
        $("#audio_upload_holder").show();
        $("#video_upload_holder").show();
      }
      // re-set the state on everything.  Basically just clear the uploader
      // files list, remove the uploader progress bar and re-set the submit button.
      // Re-set the recorders, too?  I guess probably, yeah, if you can.
      $(document).triggerHandler('reset_media_comment_forms');

      var temporaryName = $.trim($("#identity .user_name").text()) + " " + (new Date()).toISOString();
      // **********************************************************************
      // Flash audio video record (and upload)
      // **********************************************************************
      setTimeout(function() {
        var recordVars = {
          host:location.protocol + "//" + INST.kalturaSettings.domain,
          rtmpHost:"rtmp://" + (INST.kalturaSettings.rtmp_domain || INST.kalturaSettings.domain),
          kshowId:"-1",
          pid:INST.kalturaSettings.partner_id,
          subpid:INST.kalturaSettings.subpartner_id,
          uid: uid,
          ks:ks,
          themeUrl:"/media_record/skin.swf",
          localeUrl:"/media_record/locale.xml",
          thumbOffset:"1",
          licenseType:"CC-0.1",
          showUi:"true",
          useCamera:"0",
          maxFileSize: INST.kalturaSettings.max_file_size_bytes / 1048576,
          maxUploads: 1,
          partnerData: $.mediaComment.partnerData(),
          partner_data: $.mediaComment.partnerData(),
          entryName:temporaryName
        };

        var params = {
          "align": "middle",
          "quality": "high",
          "bgcolor": "#ffffff",
          "name": "KRecordAudio",
          "allowScriptAccess":"sameDomain",
          "type": "application/x-shockwave-flash",
          "pluginspage": "http://www.adobe.com/go/getflashplayer",
          "wmode": "opaque"
        };
        $("#audio_record").text(I18n.t('messages.flash_required_record_audio', "Flash required for recording audio."));
        if (INST.kalturaSettings.use_alt_record_widget) {
          swfobject.embedSWF("/media_record/KRecord_alt.swf", "audio_record", "400", "300", "9.0.0", false, recordVars, params);
        } else {
          swfobject.embedSWF("/media_record/KRecord.swf", "audio_record", "400", "300", "9.0.0", false, recordVars, params);
        }

        var params = $.extend({}, params, {name: 'KRecordVideo'});
        var recordVars = $.extend({}, recordVars, {useCamera: '1'});
        $("#video_record").html("Flash required for recording video.");
        if (INST.kalturaSettings.use_alt_record_widget) {
          swfobject.embedSWF("/media_record/KRecord_alt.swf", "video_record", "400", "300", "9.0.0", false, recordVars, params);
        } else {
          swfobject.embedSWF("/media_record/KRecord.swf", "video_record", "400", "300", "9.0.0", false, recordVars, params);
        }

        // give the dialog time to initialize or the recorder will
        // render funky in ie
      }, INST.browser.ie ? 500 : 10);

      // **********************************************************************
      // Flash uploaders
      // **********************************************************************
      var flashVars = {
        host:location.protocol + "//" + INST.kalturaSettings.domain,
        partnerId:INST.kalturaSettings.partner_id,
        subPId:INST.kalturaSettings.subpartner_id,
        uid: uid,
        entryId: "-1",
        ks:ks,
        thumbOffset:"1",
        licenseType:"CC-0.1",
        maxFileSize: INST.kalturaSettings.max_file_size_bytes / 1048576,
        maxUploads: 1,
        partnerData: $.mediaComment.partnerData(),
        partner_data: $.mediaComment.partnerData(),
        uiConfId: INST.kalturaSettings.upload_ui_conf,
        jsDelegate: "$.mediaComment.audio_delegate"
      };

      var params = {
        "align": "middle",
        "quality": "high",
        "bgcolor": "#ffffff",
        "name": "KUpload",
        "allowScriptAccess":"always",
        "type": "application/x-shockwave-flash",
        "pluginspage": "http://www.adobe.com/go/getflashplayer",
        "wmode": "transparent"
      }
      $("#audio_upload").text(I18n.t('messages.flash_required_upload_audio', "Flash required for uploading audio."));
      var width = "180";
      var height = "50";
      swfobject.embedSWF("//" + INST.kalturaSettings.domain + "/kupload/ui_conf_id/" + INST.kalturaSettings.upload_ui_conf, "audio_upload", width, height, "9.0.0", false, flashVars, params);

        flashVars = $.extend({}, flashVars, {jsDelegate: '$.mediaComment.video_delegate'});
        $("#video_upload").text(I18n.t('messages.flash_required_upload_video', "Flash required for uploading video."));
        var width = "180";
        var height = "50";
        swfobject.embedSWF("//" + INST.kalturaSettings.domain + "/kupload/ui_conf_id/" + INST.kalturaSettings.upload_ui_conf, "video_upload", width, height, "9.0.0", false, flashVars, params);

          // **********************************************************************
          // Audio meters for audio and video recording
          // **********************************************************************
          var $audio_record_holder, $audio_record, $audio_record_meter;
          var audio_record_counter, current_audio_level, audio_has_volume;
          var $video_record_holder, $video_record, $video_record_meter;
          var video_record_counter, current_video_level, video_has_volume = false;
          reset_selectors = true;
          setInterval(function() {
            if(reset_selectors) {
              $audio_record_holder = $("#audio_record_holder");
              $audio_record = $("#audio_record");
              $audio_record_meter = $("#audio_record_meter");
              audio_record_counter = 0;
              current_audio_level = 0;
              $video_record_holder = $("#video_record_holder");
              $video_record = $("#video_record");
              $video_record_meter = $("#video_record_meter");
              video_record_counter = 0;
              current_video_level = 0;
              reset_selectors = false;
            }
            audio_record_counter++;
            video_record_counter++;
            var audio_level = null, video_level = null;
            if($audio_record && $audio_record[0] && $audio_record[0].getMicophoneActivityLevel && $audio_record.parent().length) {
              audio_level = $audio_record[0].getMicophoneActivityLevel();
            } else {
              $audio_record = $("#audio_record");
            }
            if($video_record && $video_record[0] && $video_record[0].getMicophoneActivityLevel && $video_record.parent().length) {
              video_level = $video_record[0].getMicophoneActivityLevel();
            } else {
              $video_record = $("#video_record");
            }
            if(audio_level != null) {
              audio_level = Math.max(audio_level, current_audio_level);
              if(audio_level > -1 && !$audio_record_holder.hasClass('with_volume')) {
                $audio_record_meter.css('display', 'none');
                $("#audio_record_holder").addClass('with_volume').animate({'width': 420}, function() {
                  $audio_record_meter.css('display', '');
                });
              }
              if(audio_record_counter > 4) {
                current_audio_level = 0;
                audio_record_counter = 0;
                var band = (audio_level - (audio_level % 10)) / 10;
                $audio_record_meter.attr('class', 'volume_meter band_' + band);
              } else {
                current_audio_level = audio_level;
              }
            }
            if(video_level != null) {
              video_level = Math.max(video_level, current_video_level);
              if(video_level > -1 && !$video_record_holder.hasClass('with_volume')) {
                $video_record_meter.css('display', 'none');
                $("#video_record_holder").addClass('with_volume').animate({'width': 420}, function() {
                  $video_record_meter.css('display', '');
                });
              }
              if(video_record_counter > 4) {
                current_video_level = 0;
                video_record_counter = 0;
                var band = (video_level - (video_level % 10)) / 10;
                $video_record_meter.attr('class', 'volume_meter band_' + band);
              } else {
                current_video_level = video_level;
              }
            }
          }, 20);
    } // END mediaCommentReady function

    // Do JS uploader is appropriate
    if (INST.kalturaSettings.js_kaltura_uploader) {
      jsUploader = new JsUploader(mediaType, opts);
      jsUploader.onReady = mediaCommentReady
      jsUploader.addEntry = addEntry
    }

    var now = new Date();
    if((now - lastInit) > 300000) {
      $("#media_comment_dialog").dialog('close').remove();
    }
    lastInit = now;

    var $dialog = $("#media_comment_dialog");
    if($dialog.length == 0 && !INST.kalturaSettings.js_kaltura_uploader) {
      var $div = $("<div/>").attr('id', 'media_comment_dialog');
      $div.text(I18n.t('messages.loading', "Loading..."));
      $div.dialog({
        title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
        resizable: false,
        width: 470,
        height: 300,
        modal: true
      });

      // **********************************************************************
      // load kaltura_session
      // **********************************************************************
      $.ajaxJSON('/api/v1/services/kaltura_session', 'POST', {}, function(data) {
        $div.data('ks', data.ks);
        $div.data('uid', data.uid);
      }, function(data) {
        if(data.logged_in == false) {
          $div.data('ks-error', I18n.t('errors.must_be_logged_in', "You must be logged in to record media."));
        } else {
          $div.data('ks-error', I18n.t('errors.load_failed', "Media Comment Application failed to load.  Please try again."));
        }
      });
      // **********************************************************************
      // Load dialog html
      // **********************************************************************
      $.get("/partials/_media_comments.html", function(html) {
        var checkForKS = function() {
          if($div.data('ks')) {
            $div.html(html);
            $div.find("#media_record_tabs").tabs({activate: $.mediaComment.video_delegate.expectReady});
            mediaCommentReady();
          } else if($div.data('ks-error')) {
            $div.html($div.data('ks-error'));
          } else {
            setTimeout(checkForKS, 500);
          }
        }
        checkForKS();
        $dialog = $("#media_comment_dialog");
      });
      $dialog = $div;
    } else if (!INST.kalturaSettings.js_kaltura_uploader) {
      // only call mediaCommentReady if we are not doing js uploader
      mediaCommentReady();
    }
  } // End of init function
  $(document).ready(function() {
    $(document).bind('reset_media_comment_forms', function() {
      $("#audio_record_holder_message,#video_record_holder_message").removeClass('saving')
        .find(".recorder_message").html("Saving Recording...<img src='/images/media-saving.gif'/>");
      $("#audio_record_holder").stop(true, true).clearQueue().css('width', '').removeClass('with_volume');
      $("#video_record_holder").stop(true, true).clearQueue().css('width', '').removeClass('with_volume');
      $("#media_upload_submit").text(I18n.t('buttons.submit', "Submit Media File")).attr('disabled', true);
      $("#media_upload_settings").css('visibility', 'hidden');
      $("#media_upload_progress").css('visibility', 'hidden').progressbar().progressbar('option', 'value', 1);
      $("#media_upload_title").val("");
      var files = $("#audio_upload")[0] && $("#audio_upload")[0].getFiles && $("#audio_upload")[0].getFiles();
      if(files && $("#audio_upload")[0].removeFiles && files.length > 0) {
        $("#audio_upload")[0].removeFiles(0, files.length - 1);
      }
      files = $("#video_upload")[0] && $("#video_upload")[0].getFiles && $("#video_upload")[0].getFiles();
      if(files && $("#video_upload")[0].removeFiles && files.length > 0) {
        $("#video_upload")[0].removeFiles(0, files.length - 1);
      }
   });
    $("#media_upload_submit").live('click', function(event) {
      $.mediaComment.upload_delegate.submit();
    });
    $("#video_record_option,#audio_record_option").live('click', function(event) {
      event.preventDefault();
      $("#video_record_option,#audio_record_option").removeClass('selected_option');
      $(this).addClass('selected_option');
      $("#audio_record_holder").stop(true, true).clearQueue().css('width', '').removeClass('with_volume');
      $("#video_record_holder").stop(true, true).clearQueue().css('width', '').removeClass('with_volume');
      if($(this).attr('id') == 'audio_record_option') {
        $("#video_record_holder_holder").hide();
        $("#audio_record_holder_holder").show();
      } else {
        $("#video_record_holder_holder").show();
        $("#audio_record_holder_holder").hide();
      }
    });
  });
  $(document).bind('media_recording_error', function() {
    $("#audio_record_holder_message,#video_record_holder_message").find(".recorder_message").html(
            htmlEscape(I18n.t('errors.save_failed', "Saving appears to have failed.  Please close this popup to try again.")) +
            "<div style='font-size: 0.8em; margin-top: 20px;'>" +
            htmlEscape(I18n.t('errors.persistent_problem', "If this problem keeps happening, you may want to try recording your media locally and then uploading the saved file instead.")) +
            "</div>");
  });


  window.mediaCommentCallback = function(results) {
    _.each(results, addEntry);
    $("#media_comment_create_dialog").empty().dialog('close');
  }

  window.beforeAddEntry = function() {
    var attemptId = Math.random();
    $.mediaComment.lastAddAttemptId = attemptId;
    setTimeout(function() {
      if($.mediaComment.lastAddAttemptId == attemptId) {
        $(document).triggerHandler('media_recording_error');
      }
    }, 30000);
    $("#audio_record_holder_message,#video_record_holder_message").addClass('saving');
  }
  window.addEntryFail = function() {
    $(document).triggerHandler('media_recording_error');
  }
  window.addEntryFailed = function() {
    $(document).triggerHandler('media_recording_error');
  }
  window.addEntryComplete = function(entries) {
    $.mediaComment.lastAddAttemptId = null;
    $("#audio_record_holder_message,#video_record_holder_message").removeClass('saving');
    try {
      var userTitle = null;
      if(!$.isArray(entries)) {
        entries = [entries];
      }
      for(var idx = 0; idx < entries.length; idx++) {
        var entry = entries[idx];
        if($("#media_record_tabs").tabs('option', 'selected') == 0) {
          userTitle = $("#video_record_title,#audio_record_title").filter(":visible:first").val();
        } else if($("#media_record_tabs").tabs('option', 'selected') == 1) {
        }
        if(entry.entryType == 1 && $("#audio_record_option").hasClass('selected_option')) {
          entry.entryType = 5;
        }
        $.mediaComment.entryAdded(entry.entryId, entry.entryType, entry.entryName, userTitle);
        $("#media_comment_dialog").dialog('close');
      }
    } catch(e) {
      console.log(e);
      alert(I18n.t('errors.save_failed_try_again', "Entry failed to save.  Please try again."));
    }
  }
});

// Debugging methods for kaltura record widget. If These exist they'll be called.
//function deviceDetected(){
//    console.log('detected');
//}
//
//function connected(){
//    console.log('connected');
//}
//function workingMicFound(){
//    console.log('mic found');
//}
//
//function noMicsFound(){
//    console.log('no mics found');
//}
