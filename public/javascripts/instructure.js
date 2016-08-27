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
  'compiled/views/KeyboardNavDialog',
  'INST' /* INST */,
  'i18n!instructure',
  'jquery' /* $ */,
  'underscore',
  'timezone',
  'compiled/userSettings',
  'str/htmlEscape',
  'jsx/shared/rce/RichContentEditor',
  'instructure_helper',
  'jqueryui/draggable',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.doc_previews' /* filePreviewsEnabled, loadDocPreview */,
  'jquery.dropdownList' /* dropdownList */,
  'jquery.google-analytics' /* trackEvent */,
  'jquery.instructure_date_and_time' /* datetimeString, dateString, fudgeDateForProfileTimezone */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags, youTubeID */,
  'jquery.instructure_misc_plugins' /* ifExists, .dim, confirmDelete, showIf, fillWindowWithMe */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'compiled/jquery/fixDialogButtons',
  'compiled/jquery/mediaCommentThumbnail',
  'vendor/date' /* Date.parse */,
  'vendor/jquery.ba-tinypubsub' /* /\.publish\(/ */,
  'jqueryui/accordion' /* /\.accordion\(/ */,
  'jqueryui/resizable' /* /\.resizable/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/tabs' /* /\.tabs/ */,
  'compiled/behaviors/trackEvent',
  'compiled/badge_counts',
  'vendor/jquery.placeholder'
], function(KeyboardNavDialog, INST, I18n, $, _, tz, userSettings, htmlEscape, RichContentEditor) {

  RichContentEditor.preloadRemoteModule()

  $.trackEvent('Route', location.pathname.replace(/\/$/, '').replace(/\d+/g, '--') || '/');

  function enhanceUserContent() {
    var $content = $("#content");
    $(".user_content:not(.enhanced):visible").addClass('unenhanced');
    $(".user_content.unenhanced:visible")
      .each(function() {
        var $this = $(this);
        $this.find("img").css('maxWidth', Math.min($content.width(), $this.width()));
        $this.data('unenhanced_content_html', $this.html());
      })
      .find(".enhanceable_content").show()
        .filter(".dialog").each(function(){
          var $dialog = $(this);
          $dialog.hide();
          $dialog.closest(".user_content").find("a[href='#" + $dialog.attr('id') + "']").click(function(event) {
            event.preventDefault();
            $dialog.dialog();
          });
        }).end()
        .filter(".draggable").draggable().end()
        .filter(".resizable").resizable().end()
        .filter(".sortable").sortable().end()
        .filter(".accordion").accordion().end()
        .filter(".tabs").each(function() {
          $(this).tabs();
        }).end()
      .end()
      .find("a:not(.not_external, .external):external").each(function(){
        var externalLink = htmlEscape(I18n.t('titles.external_link', 'Links to an external site.'));
        $(this)
          .not(":has(img)")
          .addClass('external')
          .html('<span>' + $(this).html() + '</span>')
          .attr('target', '_blank')
          .attr('rel', 'noreferrer')
          .append('<span aria-hidden="true" class="ui-icon ui-icon-extlink ui-icon-inline" title="' + $.raw(externalLink) + '"/>')
          .append('<span class="screenreader-only">&nbsp;(' + $.raw(externalLink) + ')</span>');
      }).end()
        .find("a.instructure_file_link").each(function() {
            var $link = $(this),
                $span = $("<span class='instructure_file_link_holder link_holder'/>");
            $link.removeClass('instructure_file_link').before($span).appendTo($span);
            if($link.attr('target') != '_blank') {
          $span.append("<a href='" + htmlEscape($link.attr('href')) + "' target='_blank' title='" + htmlEscape(I18n.t('titles.view_in_new_window', "View in a new window")) +
              "' style='padding-left: 5px;'><img src='/images/popout.png' alt='" + htmlEscape(I18n.t('titles.view_in_new_window', "View in a new window")) + "'/></a>");
        }
      });
    if ($.filePreviewsEnabled()) {
      $("a.instructure_scribd_file").not(".inline_disabled").each(function() {
        var $link = $(this);
        if ( $.trim($link.text()) ) {
          var $span = $("<span class='instructure_scribd_file_holder link_holder'/>"),
                      $scribd_link = $("<a class='scribd_file_preview_link' aria-hidden='true' tabindex='-1' href='" + htmlEscape($link.attr('href')) + "' title='" + htmlEscape(I18n.t('titles.preview_document', "Preview the document")) +
                          "' style='padding-left: 5px;'><img src='/images/preview.png' alt='" + htmlEscape(I18n.t('titles.preview_document', "Preview the document")) + "'/></a>");
                  $link.removeClass('instructure_scribd_file').before($span).appendTo($span);
                  $span.append($scribd_link);
                  if($link.hasClass('auto_open')) {
                      $scribd_link.click();
                  }
              }
          });
      }

    $(".user_content.unenhanced a")
      .find("img.media_comment_thumbnail").each(function() {
        $(this).closest("a").addClass('instructure_inline_media_comment');
      }).end()
      .filter(".instructure_inline_media_comment").removeClass('no-underline').mediaCommentThumbnail('normal').end()
      .filter(".instructure_video_link, .instructure_audio_link").mediaCommentThumbnail('normal', true).end()
      .not(".youtubed").each(function() {
        var $link = $(this),
            href = $link.attr('href'),
            id = $.youTubeID(href || "");
        if($link.hasClass('inline_disabled')) {
        } else if(id) {
          var $after = $('<a href="'+ htmlEscape(href) +'" class="youtubed"><img src="/images/play_overlay.png" class="media_comment_thumbnail" style="background-image: url(//img.youtube.com/vi/' + htmlEscape(id) + '/2.jpg)" alt="' + htmlEscape($link.data('preview-alt')) + '"/></a>')
            .click(function(event) {
              event.preventDefault();
              var $video = $("<span class='youtube_holder' style='display: block;'><iframe src='//www.youtube.com/embed/" + htmlEscape(id) + "?autoplay=1&rel=0&hl=en_US&fs=1' frameborder='0' width='425' height='344'></iframe><br/><a href='#' style='font-size: 0.8em;' class='hide_youtube_embed_link'>" + htmlEscape(I18n.t('links.minimize_youtube_video', "Minimize Video")) + "</a></span>");
              $video.find(".hide_youtube_embed_link").click(function(event) {
                event.preventDefault();
                $video.remove();
                $after.show();
                $.trackEvent('hide_embedded_content', 'hide_you_tube');
              });
              $(this).after($video).hide();
            });
          $.trackEvent('show_embedded_content', 'show_you_tube');
          $link
            .addClass('youtubed')
            .after($after);
        }
      });
    $(".user_content.unenhanced").removeClass('unenhanced').addClass('enhanced');

    setTimeout(function() {
      $(".user_content form.user_content_post_form:not(.submitted)").submit().addClass('submitted');
    }, 10);
  }

  $(function() {

    // handle all of the click events that were triggered before the dom was ready (and thus weren't handled by jquery listeners)
    if (window._earlyClick) {

      // unset the onclick handler we were using to capture the events
      document.removeEventListener('click', _earlyClick);

      if (_earlyClick.clicks) {
        // wait to fire the "click" events till after all of the event hanlders loaded at dom ready are initialized
        setTimeout(function(){
          $.each(_.uniq(_earlyClick.clicks), function() {
            // cant use .triggerHandler because it will not bubble,
            // but we do want to preventDefault, so this is what we have to do
            var event = $.Event('click');
            event.preventDefault();
            $(this).trigger(event);
          });
        }, 1);
      }
    }

    ///////////// START layout related stuff
    // make sure that #main is at least as big as the tallest of #right_side, #content, and #left_side and ALWAYS at least 500px tall
    $('#main:not(.already_sized)').css({"minHeight" : Math.max($("#left_side").height(), parseInt(($('#main').css('minHeight') || "").replace('px', ''), 10))});

    var $menu_items = $(".menu-item"),
        $menu = $("#menu"),
        menuItemHoverTimeoutId;

    // Makes sure that the courses/groups menu is openable by clicking
    $coursesItem = $menu.find('#courses_menu_item .menu-item-title');
    $coursesItem.click(function (e) {
      if (e.metaKey || e.ctrlKey) return;
      e.preventDefault();
      $coursesItem.focus();
    })

    function clearMenuHovers(){
      window.clearTimeout(menuItemHoverTimeoutId);
      // this is explicitly finding every time in case
      // someone has added menu items to the list after init
      $menu.find(".menu-item").removeClass("hover hover-pending");
    }

    function unhoverMenuItem(){
      $menu_items.filter(".hover-pending").removeClass('hover-pending');
      menuItemHoverTimeoutId = window.setTimeout(clearMenuHovers, 400);
    }

    function hoverMenuItem(event){
      var hadClass = $menu_items.filter(".hover").length > 0;
      clearMenuHovers();
      var $elem = $(this);
      $elem.addClass('hover-pending');
      if(hadClass) { $elem.addClass('hover'); }
      setTimeout(function() {
        if($elem.hasClass('hover-pending')) {
          $elem.addClass("hover");
        }
      }, 300);
      $.publish('menu/hovered', $elem);
    }

    $menu
      .delegate('.menu-item', 'mouseenter focusin', hoverMenuItem )
      .delegate('.menu-item', 'mouseleave focusout', unhoverMenuItem );


    // this stuff is for the ipad, it needs a little help getting the drop menus to show up
    $menu_items.live('touchstart', function(){
      // if we are not in an alredy hovering drop-down, drop it down, otherwise do nothing
      // (so that if a link is clicked in one of the li's it gets followed).
      if(!$(this).hasClass('hover')){
        return hoverMenuItem.call(this, event);
      }
    });
    // If I touch anywhere on the screen besides inside a dropdown, make the dropdowns go away.
    $(document).bind('touchstart', function(event){
      if (!$(event.target).closest(".menu-item").length) {
        unhoverMenuItem();
      }
    });



    // this next block of code adds the ellipsis on the breadcrumb if it overflows one line
    var $breadcrumbs = $("#breadcrumbs"),
        $breadcrumbEllipsis,
        addedEllipsisClass = false;
    function resizeBreadcrumb(){
      var maxWidth = 500,
          // we want to make sure that the breadcrumb doesnt wrap multiple lines, the way we are going to check if it is one line
          // is by grabbing the first (which should be the home crumb) and checking to see how high it is, the * 1.5 part is
          // just in case to ever handle any padding or margin.
          hightOfOneBreadcrumb = $breadcrumbs.find('li:visible:first').height() * 1.5;
      $breadcrumbEllipsis = $breadcrumbEllipsis || $breadcrumbs.find('.ellipsible');
      $breadcrumbEllipsis.css('maxWidth', "");
      $breadcrumbEllipsis.ifExists(function(){
        for (var i=0; $breadcrumbs.height() > hightOfOneBreadcrumb && i < 20; i++) { //the i here is just to make sure we don't get into an ifinite loop somehow
          if (!addedEllipsisClass) {
            addedEllipsisClass = true;
            $breadcrumbEllipsis.addClass('ellipsis');
          }
          $breadcrumbEllipsis.css('maxWidth', (maxWidth -= 20));
        }
      });
    }
    resizeBreadcrumb(); //force it to run once right now
    $(window).resize(resizeBreadcrumb);
    // end breadcrumb ellipsis


    //////////////// END layout related stuff

    KeyboardNavDialog.prototype.bindOpenKeys.call({$el: $('#keyboard_navigation')});

    $("#switched_role_type").ifExists(function(){
      var context_class = $(this).attr('class');
      var $img = $("<img/>");
      var switched_roles_message = null;
      switch ($(this).data('role')) {
        case 'TeacherEnrollment':
          switched_roles_message = I18n.t('switched_roles_message.teacher', "You have switched roles temporarily for this course, and are now viewing the course as a teacher.  You can restore your role and permissions from the course home page.");
          break;
        case 'StudentEnrollment':
          switched_roles_message = I18n.t('switched_roles_message.student', "You have switched roles temporarily for this course, and are now viewing the course as a student.  You can restore your role and permissions from the course home page.");
          break;
        case 'TaEnrollment':
          switched_roles_message = I18n.t('switched_roles_message.ta', "You have switched roles temporarily for this course, and are now viewing the course as a TA.  You can restore your role and permissions from the course home page.");
          break;
        case 'ObserverEnrollment':
          switched_roles_message = I18n.t('switched_roles_message.observer', "You have switched roles temporarily for this course, and are now viewing the course as an observer.  You can restore your role and permissions from the course home page.");
          break;
        case 'DesignerEnrollment':
          switched_roles_message = I18n.t('switched_roles_message.designer', "You have switched roles temporarily for this course, and are now viewing the course as a designer.  You can restore your role and permissions from the course home page.");
          break;
        default:
          switched_roles_message = I18n.t('switched_roles_message.student', "You have switched roles temporarily for this course, and are now viewing the course as a student.  You can restore your role and permissions from the course home page.");
      };
      $img.attr('src', '/images/warning.png')
        .attr('title', switched_roles_message)
        .css({
          paddingRight: 2,
          width: 12,
          height: 12
        });
      $("#crumb_" + context_class).find("a").prepend($img);
    });

    $("a.show_quoted_text_link").live('click', function(event) {
      var $text = $(this).parents(".quoted_text_holder").children(".quoted_text");
      if($text.length > 0) {
        event.preventDefault();
        $text.show();
        $(this).hide();
      }
    });

    $("a.equella_content_link").live('click', function(event) {
      event.preventDefault();
      var $dialog = $("#equella_preview_dialog");
      if( !$dialog.length ) {
        $dialog = $("<div/>");
        $dialog.attr('id', 'equella_preview_dialog').hide();
        $dialog.html("<h2/><iframe style='background: url(/images/ajax-loader-medium-444.gif) no-repeat left top; width: 800px; height: 350px; border: 0;' src='about:blank' borderstyle='0'/><div style='text-align: right;'><a href='#' class='original_link external external_link' target='_blank'>" + htmlEscape(I18n.t('links.view_equella_content_in_new_window', "view the content in a new window")) + "</a>");
        $dialog.find("h2").text($(this).attr('title') || $(this).text() || I18n.t('titles.equella_content_preview', "Equella Content Preview"));
        var $iframe = $dialog.find("iframe");
        setTimeout(function() {
          $iframe.css('background', '#fff');
        }, 2500);
        $("body").append($dialog);
        $dialog.dialog({
          autoOpen: false,
          width: 'auto',
          resizable: false,
          title: I18n.t('titles.equella_content_preview', "Equella Content Preview"),
          close: function() {
            $dialog.find("iframe").attr('src', 'about:blank');
          }
        });
      }
      $dialog.find(".original_link").attr('href', $(this).attr('href'));
      $dialog.dialog('close').dialog('open');
      $dialog.find("iframe").attr('src', $(this).attr('href'));
    });


    // Adds a way to automatically open dialogs by just giving them the .dialog_opener class.
    // Uses the aria-controls attribute to specify id of dialog to open because that is already
    // a best practice accessibility-wise (as a side note you should also add "role=button").
    // You can pass in options to the dialog with the data-dialog-options attribute.
    //
    // Examples:
    //
    // <a class="dialog_opener" aria-controls="foobar" role="button" href="#">
    // opens the dialog with id="foobar"
    //
    // <a class="dialog_opener" aria-controls="my_dialog" data-dialog-opts="{resizable:false, width: 300}" role="button" href="#">
    // opens the .my_dialog dialog and passes the options {resizable:false, width: 300}

    // the :not clause is to not allow users access to this functionality in their content.
    $('.dialog_opener[aria-controls]:not(.user_content *)').live('click', function(event){
      var link = this;
      $('#' + $(this).attr('aria-controls')).ifExists(function($dialog){
        event.preventDefault();

        // if the linked dialog has not already been initialized, initialize it (passing in opts)
        if (!$dialog.data('dialog')) {
          $dialog.dialog($.extend({
            autoOpen: false,
            modal: true
          }, $(link).data('dialogOpts')));
          $dialog.fixDialogButtons();
        }

        $dialog.dialog('open');
      });
    });
    if ($.filePreviewsEnabled()) {
      $("a.scribd_file_preview_link").live('click', function(event) {
        event.preventDefault();
        var $link = $(this).loadingImage({image_size: 'small'}).hide();
        $.ajaxJSON($link.attr('href').replace(/\/download/, ""), 'GET', {}, function(data) {
          var attachment = data && data.attachment;
          $link.loadingImage('remove');
          if (attachment &&
                ($.isPreviewable(attachment.content_type, 'google') ||
                 attachment.canvadoc_session_url)) {
            var $div = $("<span><br /></span>")
              .insertAfter($link.parents(".link_holder:last"))
              .loadDocPreview({
                canvadoc_session_url: attachment.canvadoc_session_url,
                mimeType: attachment.content_type,
                public_url: attachment.authenticated_s3_url,
                attachment_preview_processing: attachment.workflow_state == 'pending_upload' || attachment.workflow_state == 'processing'
              })
              .append(
                $('<a href="#" style="font-size: 0.8em;" class="hide_file_preview_link">' + htmlEscape(I18n.t('links.minimize_file_preview', 'Minimize File Preview')) + '</a>')
                .click(function(event) {
                  event.preventDefault();
                  $link.show();
                  $div.remove();
                  $.trackEvent('hide_embedded_content', 'hide_file_preview');
                })
              );
            $.trackEvent('show_embedded_content', 'show_file_preview');
          }
        }, function() {
          $link.loadingImage('remove').hide();
        });
      });
    } else {
      $("a.scribd_file_preview_link").live('click', function(event) {
        event.preventDefault();
        alert(I18n.t('alerts.file_previews_disabled', 'File previews have been disabled for this Canvas site'));
      });
    }

    // publishing the 'userContent/change' will run enhanceUserContent at most once every 50ms
    var enhanceUserContentTimeout;
    $.subscribe('userContent/change', function(){
      clearTimeout(enhanceUserContentTimeout);
      enhanceUserContentTimeout = setTimeout(enhanceUserContent, 50);
    });


    $(document).bind('user_content_change', enhanceUserContent);
    setInterval(enhanceUserContent, 15000);
    setTimeout(enhanceUserContent, 1000);

    $(".zone_cached_datetime").each(function() {
      if($(this).attr('title')) {
        var datetime = tz.parse($(this).attr('title'));
        if (datetime) {
          $(this).text($.datetimeString(datetime));
        }
      }
    });

    $(".show_sub_messages_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".subcontent").find(".communication_sub_message.toggled_communication_sub_message").removeClass('toggled_communication_sub_message');
      $(this).parents(".communication_sub_message").remove();
    });
    $(".show_comments_link").click(function(event) {
      event.preventDefault();
      $(this).closest("ul").find("li").show();
      $(this).closest("li").remove();
    });
    $(".communication_message .message_short .read_more_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".communication_message").find(".message_short").hide().end()
        .find(".message").show();
    });
    $(".communication_message .close_notification_link").live('click', function(event) {
      event.preventDefault();
      var $message = $(this).parents(".communication_message");
      $message.confirmDelete({
        url: $(this).attr('rel'),
        noMessage: true,
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $(".communication_message .add_entry_link").click(function(event) {
      event.preventDefault();
      var $message = $(this).parents(".communication_message");
      var $reply = $message.find(".reply_message").hide();
      var $response = $message.find(".communication_sub_message.blank").clone(true).removeClass('blank');
      $reply.before($response.show());
      var id = _.uniqueId("textarea_");
      $response.find("textarea.rich_text").attr('id', id);
      $(document).triggerHandler('richTextStart', $("#" + id));
      $response.find("textarea:first").focus().select();
    });
    $(document).bind('richTextStart', function(event, $editor) {
      if(!$editor || $editor.length === 0) { return; }
      $editor = $($editor);
      if(!$editor || $editor.length === 0) { return; }
      RichContentEditor.initSidebar({
        show: function() { $('#sidebar_content').hide() },
        hide: function() { $('#sidebar_content').show() }
      })
      RichContentEditor.loadNewEditor($editor, { focus: true })
    }).bind('richTextEnd', function(event, $editor) {
      if(!$editor || $editor.length === 0) { return; }
      $editor = $($editor);
      if(!$editor || $editor.length === 0) { return; }
      RichContentEditor.destroyRCE($editor);
    });

    $(".cant_record_link").click(function(event) {
      event.preventDefault();
      $("#cant_record_dialog").dialog({
        modal: true,
        title: I18n.t('titles.cant_create_recordings', "Can't Create Recordings?"),
        width: 400
      });
    });

    $(".communication_message .content .links .show_users_link,.communication_message .header .show_users_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".communication_message").find(".content .users_list").slideToggle();
    });
    $(".communication_message .delete_message_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".communication_message").confirmDelete({
        noMessage: true,
        url: $(this).attr('href'),
        success: function() {
          $(this).slideUp();
        }
      });
    });
    $(".communication_sub_message .add_conversation_message_form").formSubmit({
      beforeSubmit: function(data) {
        $(this).find("button").attr('disabled', true);
        $(this).find(".submit_button").text(I18n.t('status.posting_message', "Posting Message..."));
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');

        // message is the message div containing this form, and conversation the
        // owning conversation. we make a copy of this div before filling it out
        // so that we can use it for the next message (if any)
        var $message = $(this).parents(".communication_sub_message")
        var $conversation = $message.parents(".communication_message");

        // fill out this message, display the new info, and remove the form
        message_data = data.messages[0];
        $message.fillTemplateData({
          data: {
            post_date: $.datetimeString(message_data.created_at),
            message: message_data.body
          },
          htmlValues: ['message']
        });
        $message.find(".message").show();
        $(this).remove();

        // turn the "add message" button back on
        $conversation.find(".reply_message").show();

        // notify the user and any other watchers in the document
        $.flashMessage('Message Sent!');
        $(document).triggerHandler('user_content_change');
        if(location.pathname === '/') {
          $.trackEvent('dashboard_comment', 'create');
        }
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).find("button").attr('disabled', false);
        $(this).find(".submit_button").text("Post Failed, Try Again");
        $(this).formErrors(data);
      }
    });
    $(".communication_sub_message .add_sub_message_form").formSubmit({
      beforeSubmit: function(data) {
        $(this).find("button").attr('disabled', true);
        $(this).find(".submit_button").text(I18n.t('status.posting_message', "Posting Message..."));
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');
        var $message = $(this).parents(".communication_sub_message");
        if($(this).hasClass('submission_comment_form')) {
          var user_id = $(this).getTemplateData({textValues: ['submission_user_id']}).submission_user_id;
          var submission = null;
          for(var idx in data) {
            var s = data[idx].submission;
            if(s.user_id == user_id) {
              submission = s;
            }
          }
          if(submission) {
            var comment = submission.submission_comments[submission.submission_comments.length - 1].submission_comment;
            comment.post_date = $.datetimeString(comment.created_at);
            comment.message = comment.formatted_body || comment.comment;
            $message.fillTemplateData({
              data: comment,
              htmlValues: ['message']
            });
          }
        } else {
          var entry = data.discussion_entry;
          entry.post_date = $.datetimeString(entry.created_at);
          $message.find(".content > .message_html").val(entry.message);
          $message.fillTemplateData({
            data: entry,
            htmlValues: ['message']
          });
        }
        $message.find(".message").show();
        $message.find(".user_content").removeClass('enhanced');
        $message.parents(".communication_message").find(".reply_message").removeClass('lonely_behavior_message').show();
        $(document).triggerHandler('richTextEnd', $(this).find("textarea.rich_text"));
        $(document).triggerHandler('user_content_change');
        $(this).remove();
        if(location.href.match(/dashboard/)) {
          $.trackEvent('dashboard_comment', 'create');
        }
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).find("button").attr('disabled', false);
        $(this).find(".submit_button").text(I18n.t('errors.posting_message_failed', "Post Failed, Try Again"));
        $(this).formErrors(data);
      }
    });
    $(".communication_sub_message form .cancel_button").click(function() {
      var $form = $(this).parents(".communication_sub_message");
      var $message = $(this).parents(".communication_message");
      $(document).triggerHandler('richTextEnd', $form.find("textarea.rich_text"));
      $form.remove();
      $message.find(".reply_message").show();
    });
    $(".communication_message,.communication_sub_message").bind('focusin mouseenter', function() {
      $(this).addClass('communication_message_hover');
    }).bind('focusout mouseleave', function(){
      $(this).removeClass('communication_message_hover');
    });
    $(".communication_sub_message .more_options_reply_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      var params = null;
      if($form.hasClass('submission_comment_form')) {
        params = {comment: ($form.find("textarea:visible:first").val() || "")};
      } else {
        params = {message: ($form.find("textarea:visible:first").val() || "")};
      }
      location.href = $(this).attr('href') + "?message=" + encodeURIComponent(params.message);
    });
    $(".communication_message.new_activity_message").ifExists(function(){
      this.find(".message_type img").click(function() {
        var $this = $(this),
            c = $.trim($this.attr('class'));

        $this.parents(".message_type").find("img").removeClass('selected');

        $this
          .addClass('selected')
          .parents(".new_activity_message")
            .find(".message_type_text").text($this.attr('title')).end()
            .find(".activity_form").hide().end()
            .find("textarea, :text").val("").end()
            .find("." + c + "_form").show()
              .find(".context_select").change();
      });
      this.find(".context_select").change(function() {
        var $this = $(this),
            thisVal = $this.val(),
            $message = $this.parents(".communication_message"),
            $form = $message.find("form");
        $form.attr('action', $message.find("." + thisVal + "_form_url").attr('href'));
        $form.data('context_name', this.options[this.selectedIndex].text);
        $form.data('context_code', thisVal);
        $message.find(".roster_list").hide().find(":checkbox").each(function() { $(this).attr('checked', false); });
        $message.find("." + thisVal + "_roster_list").show();
      }).triggerHandler('change');
      this.find(".cancel_button").click(function(event) {
        $(this).parents(".communication_message").hide().prev(".new_activity_message").show();
      });
      this.find(".new_activity_message_link").click(function(event) {
        event.preventDefault();
        $(this).parents(".communication_message").hide().next(".new_activity_message")
          .find(".message_type img.selected").click().end()
          .show()
          .find(":text:visible:first").focus().select();
      });
      this.find("form.message_form").formSubmit({
        beforeSubmit: function(data) {
          $("button").attr('disabled', true);
          $("button.submit_button").text(I18n.t('status.posting_message', "Posting Message..."));
        },
        success: function(data) {
          $("button").attr('disabled', false);
          $("button.submit_button").text("Post Message");
          var context_code = $(this).data('context_code') || "";
          var context_name = $(this).data('context_name') || "";
          if($(this).hasClass('discussion_topic_form')) {
            var topic = data.discussion_topic;
            topic.context_code = context_name;
            topic.user_name = $("#identity .user_name").text();
            topic.post_date = $.datetimeString(topic.created_at);
            topic.topic_id = topic.id;
            var $template = $(this).parents(".communication_message").find(".template");
            var $message = $template.find(".communication_message").clone(true);
            $message.find(".header .title,.behavior_content .less_important a").attr('href', $template.find("." + context_code + "_topic_url").attr('href'));
            $message.find(".add_entry_link").attr('href', $template.find("." + context_code + "_topics_url").attr('href'));
            $message.find(".user_name").attr('href', $template.find("." + context_code + "_user_url").attr('href'));
            $message.find(".topic_assignment_link,.topic_assignment_url").attr('href', $template.find("." + context_code + "_assignment_url").attr('href'));
            $message.find(".attachment_name,.topic_attachment_url").attr('href', $template.find("." + context_code + "_attachment_url").attr('href'));
            var entry = {discussion_topic_id: topic.id};
            $message.fillTemplateData({
              data: topic,
              hrefValues: ['topic_id', 'user_id', 'assignment_id', 'attachment_id'],
              avoid: '.subcontent'
            });
            $message.find(".subcontent").fillTemplateData({
              data: entry,
              hrefValues: ['topic_id', 'user_id']
            });
            $message.find(".subcontent form").attr('action', $template.find("." + context_code + "_entries_url").attr('href'));
            $message.fillFormData(entry, {object_name: 'discussion_entry'});
            $(this).parents(".communication_message").after($message.hide());
            $message.slideDown();
            $(this).parents(".communication_message").slideUp();
            $(this).parents(".communication_message").prev(".new_activity_message").slideDown();
          } else if($(this).hasClass('announcement_form')) { // do nothing
          } else {
            location.reload();
          }
        },
        error: function(data) {
          $("button").attr('disabled', false);
          $("button.submit_button").text(I18n.t('errors.posting_message_failed', "Post Failed, Try Again"));
          $(this).formErrors(data);
        }
      });
    });
    $("#topic_list .show_all_messages_link").show().click(function(event) {
      event.preventDefault();
      $("#topic_list .topic_message").show();
      $(this).hide();
    });

    // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    // vvvvvvvvvvvvvvvvv BEGIN stuf form making pretty dates vvvvvvvvvvvvvvvvvv
    // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    var timeAgoEvents  = [];
    function timeAgoRefresh() {
      timeAgoEvents = $(".time_ago_date:visible").toArray();
      processNextTimeAgoEvent();
    }
    function processNextTimeAgoEvent() {
      var eventElement = timeAgoEvents.shift();
      if (eventElement) {
        var $event = $(eventElement),
            date = $event.data('parsed_date') || Date.parse($event.data('timestamp') || "");
        if (date) {
          var diff = new Date() - date;
          $event.data('timestamp', date.toISOString());
          $event.data('parsed_date', date);
          var fudgedDate = $.fudgeDateForProfileTimezone(date);
          var defaultDateString = fudgedDate.toString("MMM d, yyyy") + fudgedDate.toString(" h:mmtt").toLowerCase();
          var dateString = defaultDateString;
          if(diff < (24 * 3600 * 1000)) {
            if(diff < (3600 * 1000)) {
              if(diff < (60 * 1000)) {
                dateString = I18n.t('#time.less_than_a_minute_ago', "less than a minute ago");
              } else {
                var minutes = parseInt(diff / (60 * 1000), 10);
                dateString = I18n.t('#time.count_minutes_ago',
                    {one: "1 minute ago", other: "%{count} minutes ago"},
                    {count: minutes});
              }
            } else {
              var hours = parseInt(diff / (3600 * 1000), 10);
              dateString = I18n.t('#time.count_hours_ago',
                  {one: "1 hour ago", other: "%{count} hours ago"},
                  {count: hours});
            }
          }
          $event.text(dateString);
          $event.attr('title', defaultDateString);
        }
        setTimeout(processNextTimeAgoEvent, 1);
      } else {
        setTimeout(timeAgoRefresh, 60000);
      }
    }
    setTimeout(timeAgoRefresh, 100);
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // ^^^^^^^^^^^^^^^^^^ END stuff for making pretty dates ^^^^^^^^^^^^^^^^^^^
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    var sequence_url = $('#sequence_footer .sequence_details_url').filter(':last').attr('href');
    if (sequence_url) {
      $.ajaxJSON(sequence_url, 'GET', {}, function(data) {
        var $sequence_footer = $('#sequence_footer');
        if (data.current_item) {
          $('#sequence_details .current').fillTemplateData({data: data.current_item.content_tag});
          $.each({previous:'.prev', next:'.next'}, function(label, cssClass) {
            var $link = $sequence_footer.find(cssClass);
            if (data[label + '_item'] || data[label + '_module']) {
              var tag = (data[label + '_item']    && data[label + '_item'].content_tag) ||
                        (data[label + '_module']  && data[label + '_module'].context_module);

              if (!data[label + '_item']) {
                tag.title = tag.title || tag.name;
                if( tag.workflow_state === "unpublished" ){
                  tag.title += " (" + I18n.t("draft", "Draft") + ")"
                }
                tag.text = (label == 'previous' ?
                  I18n.t('buttons.previous_module', "Previous Module") :
                  I18n.t('buttons.next_module', "Next Module"));
                $link.addClass('module_button');
              }
              $link.fillTemplateData({ data: tag });
              if (data[label + '_item']) {
                $link.attr('href', $.replaceTags($sequence_footer.find('.module_item_url').attr('href'), 'id', tag.id));
              } else {
                $link.attr('href', $.replaceTags($sequence_footer.find('.module_url').attr('href'), 'id', tag.id) + '/items/' + (label === 'previous' ? 'last' : 'first'));
              }
            } else {
              $link.hide();
            }
          });
          $sequence_footer.show();
          $(window).resize(); //this will be helpful for things like $.fn.fillWindowWithMe so that it knows the dimensions of the page have changed.
        }
      });
    } else {
      var sf = $('#sequence_footer')
      if (sf.length) {
        var el = $(sf[0]);
        el.moduleSequenceFooter({
          courseID: el.attr("data-course-id"),
          assetType: el.attr("data-asset-type"),
          assetID: el.attr("data-asset-id")
        });
      }
    }

    // this is for things like the to-do, recent items and upcoming, it
    // happend a lot so rather than duplicating it everywhere I stuck it here
    $("#right-side").delegate(".more_link", "click", function(event) {
      var $this = $(this);
      var $children = $this.parents("ul").children(':hidden').show();
      $this.closest('li').remove();

      // if they are using the keyboard to navigate (they hit enter on the link instead of actually
      // clicking it) then put focus on the first of the now-visible items--otherwise, since the
      // .more_link is hidden, focus would be completely lost and leave a blind person stranded.
      // don't want to set focus if came from a mouse click because then you'd have 2 of the tooltip
      // bubbles staying visible, see #9211
      if (event.screenX === 0) {
        $children.first().find(":tabbable:first").focus();
      }
      return false;
    });

    $('#right-side').on('click', '.disable-todo-item-link', function (event) {
      event.preventDefault();
      var $item = $(this).parents("li, div.topic_message").last();
      var $prevItem = $(this).closest('.to-do-list > li').prev()
      var toFocus = ($prevItem.find('.disable-todo-item-link').length && $prevItem.find('.disable-todo-item-link')) ||
                    $('.todo-list-header')
      var url = $(this).data('api-href');
      var flashMessage = $(this).data('flash-message');
      function remove(delete_url) {
        $item.confirmDelete({
          url: delete_url,
          noMessage: true,
          success: function() {
            if (flashMessage) {
              $.flashMessage(flashMessage);
            }
            $(this).slideUp(function() {
              $(this).remove();
              toFocus.focus();
            });
          }
        });
      }

      remove(url);
    });


    // in 2 seconds (to give time for everything else to load), find all the external links and add give them
    // the external link look and behavior (force them to open in a new tab)
    setTimeout(function() {
      $("#content a:external,#content a.explicit_external_link").each(function(){
        $(this)
          .not(".open_in_a_new_tab")
          .not(":has(img)")
          .not(".not_external")
          .not(".exclude_external_icon")
          .addClass('external')
          .children("span.ui-icon-extlink").remove().end()
          .html('<span>' + $(this).html() + '</span>')
          .attr('target', '_blank')
          .attr('rel', 'noreferrer')
          .append('<span class="ui-icon ui-icon-extlink ui-icon-inline" title="' + htmlEscape(I18n.t('titles.external_link', 'Links to an external site.')) + '"/>');
      });
    }, 2000);
  });

  $('input[placeholder], textarea[placeholder]').placeholder();

  /**
   * Expose functions for testing
   */
  return {
    enhanceUserContent: enhanceUserContent
  }
});
