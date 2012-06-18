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
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* /\$\.h/, /\$\.fileSize/ */,
  'jquery.instructure_misc_plugins' /* .dim, /\.log\(/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(I18n, $, htmlEscape) {

  (function($, INST){
    var yourVersion = null;
    try {
      yourVersion = swfobject.getFlashPlayerVersion().major + "." + swfobject.getFlashPlayerVersion().minor;
      yourVersion = " (you have " + yourVersion + " installed)";
    } catch(e) {
    }
    var flashRequiredMessage = "<div>" + htmlEscape(I18n.t('messages.flash_required', "This video requires Flash version 9 or higher (you have %{version} installed).", { version: yourVersion })) +
            "<br/><a target='_blank' href='http://get.adobe.com/flashplayer/'>" + htmlEscape(I18n.t('links.upgrade_flash', "Click here to upgrade")) +"</a></div>";
    $.fn.mediaComment = function(command, arg1, arg2, arg3, arg4) {
      var id = arg1, mediaType = arg2, downloadUrl = arg3;
      if(!INST.kalturaSettings) { console.log('Kaltura has not been enabled for this account'); return; }
      if(command == 'create') {
        mediaType = arg1;
        var callback = arg2;
        var cancel_callback = arg3;
        var defaultTitle = arg4;
        $("#media_recorder_container").removeAttr('id').addClass('old_recorder_container');
        this.attr('id', 'media_recorder_container').removeClass('old_recorder_container');
        $(document).unbind('media_comment_created');
        var $comment = this;
        $(document).bind('media_comment_created', function(event, data) {
          callback.call($comment, data.id, data.mediaType);
        });
        $.mediaComment.init(mediaType, {
          modal: false,
          close: function() {
            if(cancel_callback && $.isFunction(cancel_callback)) {
              cancel_callback.call($comment);
            }
          },
          defaultTitle: defaultTitle
        });
      } else if(command == 'show_inline') {
        var $div = $("<span/>");
        if(mediaType != 'video' && mediaType != 'audio') {
          if($(this).hasClass('audio_playback')) {
            mediaType = 'audio';
          } else {
            mediaType = 'video';
          }
        }
        $div.attr('id', 'media_comment_holder_' + Math.round(Math.random() * 10000));
        var $holder = $(this);
        if($(this).parent(".instructure_file_link_holder").length > 0) {
          $holder = $(this).parent(".instructure_file_link_holder");
        }
        var showInline = function(id) {
          $holder.append($div);
          var width = $holder.width();
          var flashVars = {};
          var params = {
            allowScriptAccess: 'always',
            allowNetworking: 'all',
            allowFullScreen: true,
            bgcolor: "#000000",
            wmode: 'opaque'
          };
          var url = "/media_objects/" + id + "/redirect";
          var width = Math.min($holder.closest("div,p,table").width() || 550, 550);
          var height = width / 550 * 448;
          if(mediaType == 'audio') {
            height = 125;
            width = Math.min(width, 350);
          }
          swfobject.embedSWF(url, $div.attr('id'), width.toString(), height.toString(), "9.0.0", false, flashVars, params);
        }
        if(id == 'maybe') {
          var detailsUrl = downloadUrl.replace(/\/download.*/, "");
          $holder.text("Loading...");
          $.ajaxJSON(detailsUrl, 'GET', {}, function(data) {
            if(data.attachment && data.attachment.media_entry_id && data.attachment.media_entry_id != 'maybe') {
              $holder.text("");
              showInline(data.attachment.media_entry_id);
            } else {
              $holder.text(I18n.t('messages.file_failed_to_load', "This media file failed to load"));
            }
          }, function() {
            $holder.text(I18n.t('messages.file_failed_to_load', "This media file failed to load"));
          });
        } else {
          showInline(id);
        }
      } else if(command == 'show') {
        var flashVars = {},
            params = {
              allowScriptAccess: 'always',
              allowNetworking: 'all',
              allowFullScreen: true,
              bgcolor: "#000000",
              wmode: 'opaque'
            },
            url = "/media_objects/" + id + "/redirect",
            $dialog = $("#media_comment_player_dialog");

        if (!$dialog.length) {
          $dialog = $("<div id='media_comment_player_dialog'/>").appendTo('body');
        }

        $dialog
          .dialog({
            title: I18n.t('titles.play_comment', "Play Media Comment"),
            width: 575,
            height: 493,
            modal: true,
            draggable: false
          })
          .empty()
          .css({padding: 0, overflow: 'hidden'})//get rid of scrollbars and whitespace, have to do oveflow:hidden because the swf <object> is display:inline not display:block
          .append($('<div id="media_comment_play" />').html(flashRequiredMessage));

        swfobject.embedSWF(url, 'media_comment_play', "100%", "100%", "9.0.0", false, flashVars, params);
      }
      return this;
    };

    var thumbnailsQueued = [];
    var thumbnailing = false;
    var nextThumbnail = function() {
      thumbnailing = true;
      var iterations = Math.min(thumbnailsQueued.length, 30),
          thumbnail;
      for (var idx = 0; idx < iterations; idx++) {
        if (thumbnail = thumbnailsQueued.shift()) {
          thumbnail.elem.createMediaCommentThumbnail(thumbnail);
        }
      }
      if (thumbnailsQueued.length > 0) {
        setTimeout(nextThumbnail, 500);
      } else {
        thumbnailing = false;
      }
    };

    $.fn.mediaCommentThumbnail = function(size, keepOriginalText) {
      $(this).each(function() {
        thumbnailsQueued.push({size: size, elem: $(this), keepOriginalText: keepOriginalText});
      });
      if(!thumbnailing) {
        thumbnailing = true;
        setTimeout(nextThumbnail, 500);
      }
      return this;
    }
    $.fn.createMediaCommentThumbnail = function(opts) {
      if(!INST.kalturaSettings) { console.log('Kaltura has not been enabled for this account'); return; }
      var size = opts.size || 'normal';
      var only_show_icon = opts.only_show_icon;
      var keep_original_text = opts.keepOriginalText;
      var dimensions = $.fn.mediaCommentThumbnail.sizes[size] || $.fn.mediaCommentThumbnail.sizes['normal'];
      this.each(function() {
        var id = $.trim($(this).find(".media_comment_id:first").text());
        if(!id && $(this).attr('id') && $(this).attr('id').match(/^media_comment_/)) {
          id = $(this).attr('id').substring(14);
        }
        id = id || $.trim($(this).parent().find(".media_comment_id:first").text());
        if(id) {
          var url = "http://" + INST.kalturaSettings.resource_domain;
          if(location.protocol === 'https:') {
            url = "https://" + (INST.kalturaSettings.secure_resource_domain || INST.kalturaSettings.domain);
          }
          url = url + "/p/" + INST.kalturaSettings.partner_id + "/thumbnail/entry_id/";
          url = url + id;
          url = url + "/width/" + dimensions.width + "/height/" + dimensions.height + "/bgcolor/000000/type/2/vid_sec/5";
          var $img = $("<img/>");
          $img.addClass('media_comment_thumbnail');
          $img.addClass('media_comment_thumbnail-' + size);
          if(only_show_icon) {
            $img.attr('src', '/images/media_comment.png');
          } else {
            $img.attr('src', '/images/blank.png');
            $(this).addClass('no-hover').addClass('no-underline');
            $img.hover(function() {
              $img.attr('src', '/images/play_overlay.png');
            }, function() {
              $img.attr('src', '/images/blank.png');
            });
          }
          $img.css('backgroundImage', 'url(' + url + ')');
          $img.attr('title', I18n.t('titles.click_to_view', 'Click to View'));
          var $a = $(this);
          if(!keep_original_text) {
            $(this).empty();
          } else {
            var $a = $(this).clone().empty().removeClass('instructure_file_link');
            if($(this).parent(".instructure_file_link_holder").length > 0) {
              $(this).parent(".instructure_file_link_holder").append($a);
            } else {
              $(this).after($a);
            }
          }
          $a.addClass('instructure_inline_media_comment');
          $a.append($img).css({
            backgroundImage: '',
            padding: 0
          });
          $(this).append("<span class='media_comment_id' style='display: none;'>" + id + "</span>");
        }
      });
      return this;
    };
    $.fn.mediaCommentThumbnail.sizes = {
      normal: {width: 140, height: 100},
      small: {width: 70, height: 50}
    };
    $.mediaComment = function(command, arg1, arg2) {
      var $container = $("<div/>")
      $("body").append($container.hide());
      $.fn.mediaComment.apply($container, arguments);
    }
    $.mediaComment.partnerData = function(params) {
      params = params || {};
      params.context_code = $.mediaComment.contextCode();
      params.root_account_id = parseInt($("#domain_root_account_id").text(), 10) || 0;
      return JSON.stringify(params);
    }
    $.mediaComment.contextCode = function() {
      var code = "";
      try {
        code = $.trim($("#current_context_code").text()) || $.trim("user_" + $("#identity .user_id").text());
      } catch(e) { }
      return code;
    }

    var addedEntryIds = {};
    $.mediaComment.entryAdded = function(entryId, entryType, title, userTitle) {
      if(!entryId || addedEntryIds[entryId]) { return; }
      addedEntryIds[entryId] = true;
      var entry = {
        mediaType: entryType,
        entryId: entryId,
        title: title,
        userTitle: userTitle
      }
      var context_code = $.mediaComment.contextCode();
      if(entry.mediaType == 1 || entry.mediaType == 2 || entry.mediaType == 5 || true) {
        var mediaType = 'video';
        if(entry.mediaType == 2) {
          mediaType = 'image';
        } else if(entry.mediaType == 5) {
          mediaType = 'audio';
        }
        if(context_code) {
          $.ajaxJSON("/media_objects", "POST", {
              id: entry.entryId,
              type: mediaType,
              context_code: context_code,
              title: entry.title,
              user_entered_title: entry.userTitle
          }, function(data) {
            $(document).triggerHandler('media_object_created', data);
          }, function(data) {});
        }
        $(document).triggerHandler('media_comment_created', {id: entry.entryId, mediaType: mediaType});
      }
    };
    $.mediaComment.audio_delegate = {
      readyHandler: function() {
        $("#audio_upload")[0].setMediaType('audio');
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
    $.mediaComment.video_delegate = {
      readyHandler: function() {
        $("#video_upload")[0].setMediaType('video');
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
    }
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
        var files = $("#" + type + "_upload")[0].getFiles();
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
      }
    }
    var reset_selectors = false;
    var lastInit = null;
    $.mediaComment.init = function(media_type, opts) {
      lastInit = lastInit || new Date();
      media_type = media_type || "any";
      opts = opts || {};
      var user_name = $.trim($("#identity .user_name").text() || "");
      if(user_name) {
        user_name = user_name + ": " + (new Date()).toString("ddd MMM d, yyyy");
      }
      var defaultTitle = opts.defaultTitle || user_name || I18n.t('titles.media_contribution', "Media Contribution");
      var mediaCommentReady = function() {
        $("#video_record_title,#audio_record_title").val(defaultTitle);
        $dialog.dialog({
          title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
          width: 560,
          height: 460,
          modal: false
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

        var ks = $dialog.data('ks');

        if(media_type == "video") {
          $("#video_record_option").click();
          $("#media_record_option_holder").hide();
          $("#audio_upload_holder").hide();
          $("#video_upload_holder").show();
        } else if(media_type == "audio") {
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
        setTimeout(function() {
          var recordVars = {
            host:location.protocol + "//" + INST.kalturaSettings.domain,
            rtmpHost:"rtmp://" + (INST.kalturaSettings.rtmp_domain || INST.kalturaSettings.domain),
            kshowId:"-1",
            pid:INST.kalturaSettings.partner_id,
            subpid:INST.kalturaSettings.subpartner_id,
            uid:$dialog.data('uid') || "ANONYMOUS",
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
          }
          var params = {
            "align": "middle",
            "quality": "high",
            "bgcolor": "#ffffff",
            "name": "KRecordAudio",
            "allowScriptAccess":"sameDomain",
            "type": "application/x-shockwave-flash",
            "pluginspage": "http://www.adobe.com/go/getflashplayer",
            "wmode": "opaque"
          }
          $("#audio_record").text(I18n.t('messages.flash_required_record_audio', "Flash required for recording audio."))
          swfobject.embedSWF("/media_record/KRecord.swf", "audio_record", "400", "300", "9.0.0", false, recordVars, params);

          var params = $.extend({}, params, {name: 'KRecordVideo'});
          var recordVars = $.extend({}, recordVars, {useCamera: '1'});
          $("#video_record").html("Flash required for recording video.")
          swfobject.embedSWF("/media_record/KRecord.swf", "video_record", "400", "300", "9.0.0", false, recordVars, params);
          // give the dialog time to initialize or the recorder will
          // render funky in ie
        }, INST.browser.ie ? 500 : 10);

        var flashVars = {
          host:location.protocol + "//" + INST.kalturaSettings.domain,
          partnerId:INST.kalturaSettings.partner_id,
          subPId:INST.kalturaSettings.subpartner_id,
          uid:$dialog.data('uid') || "ANONYMOUS",
          entryId: "-1",
          ks:ks,
          thumbOffset:"1",
          licenseType:"CC-0.1",
          maxFileSize: INST.kalturaSettings.max_file_size_bytes / 1048576,
          maxUploads: 1,
          uiConfId: INST.kalturaSettings.upload_ui_conf,
          jsDelegate: "$.mediaComment.audio_delegate"
        }
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
        swfobject.embedSWF("//" + INST.kalturaSettings.domain + "/kupload/ui_conf_id/" + INST.kalturaSettings.upload_ui_conf, "audio_upload", width, height, "9.0.0", false, flashVars, params)

        flashVars = $.extend({}, flashVars, {jsDelegate: '$.mediaComment.video_delegate'});
        $("#video_upload").text(I18n.t('messages.flash_required_upload_video', "Flash required for uploading video."));
        var width = "180";
        var height = "50";
        swfobject.embedSWF("//" + INST.kalturaSettings.domain + "/kupload/ui_conf_id/" + INST.kalturaSettings.upload_ui_conf, "video_upload", width, height, "9.0.0", false, flashVars, params)


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
      }
      var now = new Date();
      if((now - lastInit) > 300000) {
        $("#media_comment_dialog").dialog('close').remove();
      }
      lastInit = now;

      var $dialog = $("#media_comment_dialog");
      if($dialog.length == 0) {
        var $div = $("<div/>").attr('id', 'media_comment_dialog');
        $div.text(I18n.t('messages.loading', "Loading..."));
        $div.dialog({
          title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
          resizable: false,
          width: 470,
          height: 300,
          modal: false
        });
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
        $.get("/partials/_media_comments.html", function(html) {
          var checkForKS = function() {
            if($div.data('ks')) {
              $div.html(html);
              $div.find("#media_record_tabs").tabs({
                select: function() {
                  $(document).triggerHandler('reset_media_comment_forms');
                }
              });
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
      } else {
        mediaCommentReady();
      }
    }
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
  })($, INST);

  window.mediaCommentCallback = function(results) {
    var context_code = $.trim($("#current_context_code").text()) || $.trim("user_" + $("#identity .user_id").text());
    for(var idx in results) {
      var entry = results[idx];
      if(entry.mediaType == 1 || entry.mediaType == 2 || entry.mediaType == 5 || true) {
        var mediaType = 'video';
        if(entry.mediaType == 2) {
          mediaType = 'image';
        } else if(entry.mediaType == 5) {
          mediaType = 'audio';
        }
        if(context_code) {
          $.ajaxJSON("/media_objects", "POST", {
              id: entry.entryId,
              type: mediaType,
              context_code: context_code,
              title: entry.name
          }, function(data) {
            $(document).triggerHandler('media_object_created', data);
          }, function(data) {});
        }
        $(document).triggerHandler('media_comment_created', {id: entry.entryId, mediaType: mediaType});
      }
    }
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
