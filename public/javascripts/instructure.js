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
import KeyboardNavDialog from 'compiled/views/KeyboardNavDialog'
import I18n from 'i18n!instructure_js'
import $ from 'jquery'
import _ from 'underscore'
import tz from 'timezone'
import htmlEscape from './str/htmlEscape'
import preventDefault from 'compiled/fn/preventDefault'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import './instructure_helper'
import 'jqueryui/draggable'
import './jquery.ajaxJSON'
import './jquery.doc_previews' /* filePreviewsEnabled, loadDocPreview */
import {trackEvent} from 'jquery.google-analytics'
import './jquery.instructure_date_and_time' /* datetimeString, dateString, fudgeDateForProfileTimezone */
import './jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */
import 'jqueryui/dialog'
import './jquery.instructure_misc_helpers' /* replaceTags, youTubeID */
import './jquery.instructure_misc_plugins' /* ifExists, .dim, confirmDelete, showIf, fillWindowWithMe */
import './jquery.keycodes'
import './jquery.loadingImg'
import 'compiled/jquery.rails_flash_notifications'
import './jquery.templateData'
import 'compiled/jquery/fixDialogButtons'
import 'compiled/jquery/mediaCommentThumbnail'
import './vendor/date'
import 'vendor/jquery.ba-tinypubsub' /* /\.publish\(/ */
import 'jqueryui/resizable'
import 'jqueryui/sortable'
import 'jqueryui/tabs'
import 'compiled/behaviors/trackEvent'

function handleYoutubeLink() {
  const $link = $(this)
  const href = $link.attr('href')
  const id = $.youTubeID(href || '')
  if (id && !$link.hasClass('inline_disabled')) {
    const $after = $(`
      <a
        href="${htmlEscape(href)}"
        class="youtubed"
      >
        <img src="/images/play_overlay.png"
          class="media_comment_thumbnail"
          style="background-image: url(//img.youtube.com/vi/${htmlEscape(id)}/2.jpg)"
          alt="${htmlEscape($link.data('preview-alt') || '')}"
        />
      </a>
    `)
    $after.click(
      preventDefault(function() {
        const $video = $(`
        <span class='youtube_holder' style='display: block;'>
          <iframe
            src='//www.youtube.com/embed/${htmlEscape(id)}?autoplay=1&rel=0&hl=en_US&fs=1'
            frameborder='0'
            width='425'
            height='344'
            allowfullscreen
          ></iframe>
          <br/>
          <a
            href='#'
            style='font-size: 0.8em;'
            class='hide_youtube_embed_link'
          >
            ${htmlEscape(I18n.t('links.minimize_youtube_video', 'Minimize Video'))}
          </a>
        </span>
      `)
        $video.find('.hide_youtube_embed_link').click(
          preventDefault(() => {
            $video.remove()
            $after.show()
            trackEvent('hide_embedded_content', 'hide_you_tube')
          })
        )
        $(this)
          .after($video)
          .hide()
      })
    )
    trackEvent('show_embedded_content', 'show_you_tube')
    $link.addClass('youtubed').after($after)
  }
}
trackEvent('Route', window.location.pathname.replace(/\/$/, '').replace(/\d+/g, '--') || '/')
const JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE = '.dialog, .draggable, .resizable, .sortable, .tabs'
export function enhanceUserContent() {
  if (ENV.SKIP_ENHANCING_USER_CONTENT) {
    return
  }

  const $content = $('#content')
  $('.user_content:not(.enhanced):visible').addClass('unenhanced')
  $('.user_content.unenhanced:visible')
    .each(function() {
      const $this = $(this)
      $this.find('img').each((i, img) => {
        const handleWidth = () =>
          $(img).css(
            'maxWidth',
            Math.min($content.width(), $this.width(), $(img).width() || img.naturalWidth)
          )
        if (img.naturalWidth === 0) {
          img.addEventListener('load', handleWidth)
        } else {
          handleWidth()
        }
      })
      $this.data('unenhanced_content_html', $this.html())
    })
    .find('.enhanceable_content')
    .show()
    .filter(JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE)
    .ifExists($elements => {
      const msg =
        'Deprecated use of magic jQueryUI widget markup detected:\n\n' +
        "You're relying on undocumented functionality where Canvas makes " +
        'jQueryUI widgets out of rich content that has the following class names: ' +
        JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE +
        '.\n\n' +
        'Canvas is moving away from jQueryUI for our own widgets and this behavior ' +
        "will go away. Rather than relying on the internals of Canvas's JavaScript, " +
        'you should use your own custom JS file to do any such customizations.'
      console.error(msg, $elements)
    })
    .end()
    .filter('.dialog')
    .each(function() {
      const $dialog = $(this)
      $dialog.hide()
      $dialog
        .closest('.user_content')
        .find("a[href='#" + $dialog.attr('id') + "']")
        .click(event => {
          event.preventDefault()
          $dialog.dialog()
        })
    })
    .end()
    .filter('.draggable')
    .draggable()
    .end()
    .filter('.resizable')
    .resizable()
    .end()
    .filter('.sortable')
    .sortable()
    .end()
    .filter('.tabs')
    .each(function() {
      $(this).tabs()
    })
    .end()
    .end()
    .find('a:not(.not_external, .external):external')
    .each(function() {
      const externalLink = htmlEscape(I18n.t('titles.external_link', 'Links to an external site.'))
      $(this)
        .not(':has(img)')
        .addClass('external')
        .html('<span>' + $(this).html() + '</span>')
        .attr('target', '_blank')
        .attr('rel', 'noreferrer noopener')
        .append(
          '<span aria-hidden="true" class="ui-icon ui-icon-extlink ui-icon-inline" title="' +
            $.raw(externalLink) +
            '"/>'
        )
        .append('<span class="screenreader-only">&nbsp;(' + $.raw(externalLink) + ')</span>')
    })
    .end()
  if ($.filePreviewsEnabled()) {
    $('a.instructure_scribd_file')
      .not('.inline_disabled')
      .each(function() {
        const $link = $(this)
        if ($.trim($link.text())) {
          const $span = $("<span class='instructure_file_holder link_holder'/>"),
            $scribd_link = $(
              "<a class='file_preview_link' aria-hidden='true' href='" +
                htmlEscape($link.attr('href')) +
                "' title='" +
                htmlEscape(I18n.t('titles.preview_document', 'Preview the document')) +
                "' style='padding-left: 5px;'><img src='/images/preview.png' alt='" +
                htmlEscape(I18n.t('titles.preview_document', 'Preview the document')) +
                "'/></a>"
            )
          $link
            .removeClass('instructure_scribd_file')
            .before($span)
            .appendTo($span)
          $span.append($scribd_link)
          if ($link.hasClass('auto_open')) {
            $scribd_link.click()
          }
        }
      })
  }
  $('.user_content.unenhanced a,.user_content.unenhanced+div.answers a')
    .find('img.media_comment_thumbnail')
    .each(function() {
      $(this)
        .closest('a')
        .addClass('instructure_inline_media_comment')
    })
    .end()
    .filter('.instructure_inline_media_comment')
    .removeClass('no-underline')
    .mediaCommentThumbnail('normal')
    .end()
    .filter('.instructure_video_link, .instructure_audio_link')
    .mediaCommentThumbnail('normal', true)
    .end()
    .not('.youtubed')
    .each(handleYoutubeLink)
  $('.user_content.unenhanced')
    .removeClass('unenhanced')
    .addClass('enhanced')
  setTimeout(() => {
    $('.user_content form.user_content_post_form:not(.submitted)')
      .submit()
      .addClass('submitted')
  }, 10)
}
$(function() {
  // handle all of the click events that were triggered before the dom was ready (and thus weren't handled by jquery listeners)
  if (window._earlyClick) {
    // unset the onclick handler we were using to capture the events
    document.removeEventListener('click', window._earlyClick)
    if (window._earlyClick.clicks) {
      // wait to fire the "click" events till after all of the event hanlders loaded at dom ready are initialized
      setTimeout(function() {
        $.each(_.uniq(window._earlyClick.clicks), function() {
          // cant use .triggerHandler because it will not bubble,
          // but we do want to preventDefault, so this is what we have to do
          const event = $.Event('click')
          event.preventDefault()
          $(this).trigger(event)
        })
      }, 1)
    }
  }
  // this next block of code adds the ellipsis on the breadcrumb if it overflows one line
  const $breadcrumbs = $('#breadcrumbs')
  if ($breadcrumbs.length) {
    let $breadcrumbEllipsis
    let addedEllipsisClass = false
    // if we ever change the styling of the breadcrumbs so their height changes, change this too. the * 1.5 part is just in case to ever handle any padding or margin.
    const hightOfOneBreadcrumb = 27 * 1.5
    let taskID
    const resizeBreadcrumb = () => {
      if (taskID) (window.cancelIdleCallback || window.cancelAnimationFrame)(taskID)
      taskID = (window.requestIdleCallback || window.requestAnimationFrame)(() => {
        let maxWidth = 500
        $breadcrumbEllipsis = $breadcrumbEllipsis || $breadcrumbs.find('.ellipsible')
        $breadcrumbEllipsis.ifExists(() => {
          $breadcrumbEllipsis.css('maxWidth', '')
          for (let i = 0; $breadcrumbs.height() > hightOfOneBreadcrumb && i < 20; i++) {
            // the i here is just to make sure we don't get into an ifinite loop somehow
            if (!addedEllipsisClass) {
              addedEllipsisClass = true
              $breadcrumbEllipsis.addClass('ellipsis')
            }
            $breadcrumbEllipsis.css('maxWidth', (maxWidth -= 20))
          }
        })
      })
    }
    resizeBreadcrumb() // force it to run once right now
    $(window).resize(resizeBreadcrumb)
    // end breadcrumb ellipsis
  }
  KeyboardNavDialog.prototype.bindOpenKeys.call({$el: $('#keyboard_navigation')})
  $('#switched_role_type').ifExists(function() {
    const context_class = $(this).attr('class')
    const $img = $('<img/>')
    let switched_roles_message = null
    switch ($(this).data('role')) {
      case 'TeacherEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.teacher',
          'You have switched roles temporarily for this course, and are now viewing the course as a teacher.  You can restore your role and permissions from the course home page.'
        )
        break
      case 'StudentEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.student',
          'You have switched roles temporarily for this course, and are now viewing the course as a student.  You can restore your role and permissions from the course home page.'
        )
        break
      case 'TaEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.ta',
          'You have switched roles temporarily for this course, and are now viewing the course as a TA.  You can restore your role and permissions from the course home page.'
        )
        break
      case 'ObserverEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.observer',
          'You have switched roles temporarily for this course, and are now viewing the course as an observer.  You can restore your role and permissions from the course home page.'
        )
        break
      case 'DesignerEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.designer',
          'You have switched roles temporarily for this course, and are now viewing the course as a designer.  You can restore your role and permissions from the course home page.'
        )
        break
      default:
        switched_roles_message = I18n.t(
          'switched_roles_message.student',
          'You have switched roles temporarily for this course, and are now viewing the course as a student.  You can restore your role and permissions from the course home page.'
        )
    }
    $img
      .attr('src', '/images/warning.png')
      .attr('title', switched_roles_message)
      .css({
        paddingRight: 2,
        width: 12,
        height: 12
      })
    $('#crumb_' + context_class)
      .find('a')
      .prepend($img)
  })
  $('a.show_quoted_text_link').live('click', function(event) {
    const $text = $(this)
      .parents('.quoted_text_holder')
      .children('.quoted_text')
    if ($text.length > 0) {
      event.preventDefault()
      $text.show()
      $(this).hide()
    }
  })
  $('a.equella_content_link').live('click', function(event) {
    event.preventDefault()
    let $dialog = $('#equella_preview_dialog')
    if (!$dialog.length) {
      $dialog = $('<div/>')
      $dialog.attr('id', 'equella_preview_dialog').hide()
      $dialog.html(
        "<h2/><iframe style='background: url(/images/ajax-loader-medium-444.gif) no-repeat left top; width: 800px; height: 350px; border: 0;' src='about:blank' borderstyle='0'/><div style='text-align: right;'><a href='#' class='original_link external external_link' target='_blank'>" +
          htmlEscape(
            I18n.t('links.view_equella_content_in_new_window', 'view the content in a new window')
          ) +
          '</a>'
      )
      $dialog
        .find('h2')
        .text(
          $(this).attr('title') ||
            $(this).text() ||
            I18n.t('titles.equella_content_preview', 'Equella Content Preview')
        )
      const $iframe = $dialog.find('iframe')
      setTimeout(() => {
        $iframe.css('background', '#fff')
      }, 2500)
      $('body').append($dialog)
      $dialog.dialog({
        autoOpen: false,
        width: 'auto',
        resizable: false,
        title: I18n.t('titles.equella_content_preview', 'Equella Content Preview'),
        close() {
          $dialog.find('iframe').attr('src', 'about:blank')
        }
      })
    }
    $dialog.find('.original_link').attr('href', $(this).attr('href'))
    $dialog.dialog('close').dialog('open')
    $dialog.find('iframe').attr('src', $(this).attr('href'))
  })
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
  $('.dialog_opener[aria-controls]:not(.user_content *)').live('click', function(event) {
    const link = this
    $('#' + $(this).attr('aria-controls')).ifExists($dialog => {
      event.preventDefault()
      // if the linked dialog has not already been initialized, initialize it (passing in opts)
      if (!$dialog.data('dialog')) {
        $dialog.dialog(
          $.extend(
            {
              autoOpen: false,
              modal: true
            },
            $(link).data('dialogOpts')
          )
        )
        $dialog.fixDialogButtons()
      }
      $dialog.dialog('open')
    })
  })
  if ($.filePreviewsEnabled()) {
    $('a.file_preview_link').live('click', function(event) {
      event.preventDefault()
      const $link = $(this)
        .loadingImage({image_size: 'small'})
        .hide()
      $.ajaxJSON(
        $link
          .attr('href')
          .replace(/\/download/, '') // download as part of the path
          .replace(/wrap=1&?/, '') // wrap=1 as part of the query_string
          .replace(/[?&]$/, ''), // any trailing chars if wrap=1 was at the end
        'GET',
        {},
        data => {
          const attachment = data && data.attachment
          $link.loadingImage('remove')
          if (
            attachment &&
            ($.isPreviewable(attachment.content_type, 'google') || attachment.canvadoc_session_url)
          ) {
            const $div = $('<div>')
              .insertAfter($link.parents('.link_holder:last'))
              .loadDocPreview({
                canvadoc_session_url: attachment.canvadoc_session_url,
                mimeType: attachment.content_type,
                public_url: attachment.public_url,
                attachment_preview_processing:
                  attachment.workflow_state == 'pending_upload' ||
                  attachment.workflow_state == 'processing'
              })
            const $minimizeLink = $(
              '<a href="#" style="font-size: 0.8em;" class="hide_file_preview_link">' +
                htmlEscape(I18n.t('links.minimize_file_preview', 'Minimize File Preview')) +
                '</a>'
            ).click(event => {
              event.preventDefault()
              $link.show()
              $link.focus()
              $div.remove()
              trackEvent('hide_embedded_content', 'hide_file_preview')
            })
            $div.prepend($minimizeLink)
            if (Object.prototype.hasOwnProperty.call(event, 'originalEvent')) {
              // Only focus this link if the open preview link was initiated by a real browser event
              // If it was triggered by our auto_open stuff it shouldn't focus here.
              $minimizeLink.focus()
            }
            trackEvent('show_embedded_content', 'show_file_preview')
          }
        },
        () => {
          $link.loadingImage('remove').hide()
        }
      )
    })
  } else {
    $('a.file_preview_link').live('click', event => {
      event.preventDefault()
      alert(
        I18n.t(
          'alerts.file_previews_disabled',
          'File previews have been disabled for this Canvas site'
        )
      )
    })
  }
  // publishing the 'userContent/change' will run enhanceUserContent at most once every 50ms
  let enhanceUserContentTimeout
  $.subscribe('userContent/change', () => {
    clearTimeout(enhanceUserContentTimeout)
    enhanceUserContentTimeout = setTimeout(enhanceUserContent, 50)
  })
  $(document).bind('user_content_change', enhanceUserContent)
  $(() => {
    setInterval(enhanceUserContent, 15000)
    setTimeout(enhanceUserContent, 15)
  })
  $('.zone_cached_datetime').each(function() {
    if ($(this).attr('title')) {
      const datetime = tz.parse($(this).attr('title'))
      if (datetime) {
        $(this).text($.datetimeString(datetime))
      }
    }
  })
  $('.show_sub_messages_link').click(function(event) {
    event.preventDefault()
    $(this)
      .parents('.subcontent')
      .find('.communication_sub_message.toggled_communication_sub_message')
      .removeClass('toggled_communication_sub_message')
    $(this)
      .parents('.communication_sub_message')
      .remove()
  })
  $('.show_comments_link').click(function(event) {
    event.preventDefault()
    $(this)
      .closest('ul')
      .find('li')
      .show()
    $(this)
      .closest('li')
      .remove()
  })
  $('.communication_message .message_short .read_more_link').click(function(event) {
    event.preventDefault()
    $(this)
      .parents('.communication_message')
      .find('.message_short')
      .hide()
      .end()
      .find('.message')
      .show()
  })
  $('.communication_message .close_notification_link').live('click', function(event) {
    event.preventDefault()
    const $message = $(this).parents('.communication_message')
    $message.confirmDelete({
      url: $(this).attr('rel'),
      noMessage: true,
      success() {
        $(this).slideUp(function() {
          $(this).remove()
        })
      }
    })
  })
  $('.communication_message .add_entry_link').click(function(event) {
    event.preventDefault()
    const $message = $(this).parents('.communication_message')
    const $reply = $message.find('.reply_message').hide()
    const $response = $message
      .find('.communication_sub_message.blank')
      .clone(true)
      .removeClass('blank')
    $reply.before($response.show())
    const id = _.uniqueId('textarea_')
    $response.find('textarea.rich_text').attr('id', id)
    $(document).triggerHandler('richTextStart', $('#' + id))
    $response
      .find('textarea:first')
      .focus()
      .select()
  })
  $(document)
    .bind('richTextStart', (event, $editor) => {
      if (!$editor || $editor.length === 0) {
        return
      }
      $editor = $($editor)
      if (!$editor || $editor.length === 0) {
        return
      }
      RichContentEditor.initSidebar({
        show() {
          $('#sidebar_content').hide()
        },
        hide() {
          $('#sidebar_content').show()
        }
      })
      RichContentEditor.loadNewEditor($editor, {focus: true})
    })
    .bind('richTextEnd', (event, $editor) => {
      if (!$editor || $editor.length === 0) {
        return
      }
      $editor = $($editor)
      if (!$editor || $editor.length === 0) {
        return
      }
      RichContentEditor.destroyRCE($editor)
    })
  $(
    '.communication_message .content .links .show_users_link,.communication_message .header .show_users_link'
  ).click(function(event) {
    event.preventDefault()
    $(this)
      .parents('.communication_message')
      .find('.content .users_list')
      .slideToggle()
  })
  $('.communication_message .delete_message_link').click(function(event) {
    event.preventDefault()
    $(this)
      .parents('.communication_message')
      .confirmDelete({
        noMessage: true,
        url: $(this).attr('href'),
        success() {
          $(this).slideUp()
        }
      })
  })
  $('.communication_sub_message .add_conversation_message_form').formSubmit({
    beforeSubmit(_data) {
      $(this)
        .find('button')
        .attr('disabled', true)
      $(this)
        .find('.submit_button')
        .text(I18n.t('status.posting_message', 'Posting Message...'))
      $(this).loadingImage()
    },
    success(data) {
      $(this).loadingImage('remove')
      // message is the message div containing this form, and conversation the
      // owning conversation. we make a copy of this div before filling it out
      // so that we can use it for the next message (if any)
      const $message = $(this).parents('.communication_sub_message')
      const $conversation = $message.parents('.communication_message')
      // fill out this message, display the new info, and remove the form
      const message_data = data.messages[0]
      $message.fillTemplateData({
        data: {
          post_date: $.datetimeString(message_data.created_at),
          message: message_data.body
        },
        htmlValues: ['message']
      })
      $message.find('.message').show()
      $(this).remove()
      // turn the "add message" button back on
      $conversation.find('.reply_message').show()
      // notify the user and any other watchers in the document
      $.flashMessage('Message Sent!')
      $(document).triggerHandler('user_content_change')
      if (window.location.pathname === '/') {
        trackEvent('dashboard_comment', 'create')
      }
    },
    error(data) {
      $(this).loadingImage('remove')
      $(this)
        .find('button')
        .attr('disabled', false)
      $(this)
        .find('.submit_button')
        .text('Post Failed, Try Again')
      $(this).formErrors(data)
    }
  })
  $('.communication_sub_message .add_sub_message_form').formSubmit({
    beforeSubmit(_data) {
      $(this)
        .find('button')
        .attr('disabled', true)
      $(this)
        .find('.submit_button')
        .text(I18n.t('status.posting_message', 'Posting Message...'))
      $(this).loadingImage()
    },
    success(data) {
      $(this).loadingImage('remove')
      const $message = $(this).parents('.communication_sub_message')
      if ($(this).hasClass('submission_comment_form')) {
        const user_id = $(this).getTemplateData({textValues: ['submission_user_id']})
          .submission_user_id
        let submission = null
        for (const idx in data) {
          const s = data[idx].submission
          if (s.user_id == user_id) {
            submission = s
          }
        }
        if (submission) {
          const comment =
            submission.submission_comments[submission.submission_comments.length - 1]
              .submission_comment
          comment.post_date = $.datetimeString(comment.created_at)
          comment.message = comment.formatted_body || comment.comment
          $message.fillTemplateData({
            data: comment,
            htmlValues: ['message']
          })
        }
      } else {
        const entry = data.discussion_entry
        entry.post_date = $.datetimeString(entry.created_at)
        $message.find('.content > .message_html').val(entry.message)
        $message.fillTemplateData({
          data: entry,
          htmlValues: ['message']
        })
      }
      $message.find('.message').show()
      $message.find('.user_content').removeClass('enhanced')
      $message
        .parents('.communication_message')
        .find('.reply_message')
        .removeClass('lonely_behavior_message')
        .show()
      $(document).triggerHandler('richTextEnd', $(this).find('textarea.rich_text'))
      $(document).triggerHandler('user_content_change')
      $(this).remove()
      if (window.location.href.match(/dashboard/)) {
        trackEvent('dashboard_comment', 'create')
      }
    },
    error(data) {
      $(this).loadingImage('remove')
      $(this)
        .find('button')
        .attr('disabled', false)
      $(this)
        .find('.submit_button')
        .text(I18n.t('errors.posting_message_failed', 'Post Failed, Try Again'))
      $(this).formErrors(data)
    }
  })
  $('.communication_sub_message form .cancel_button').click(function() {
    const $form = $(this).parents('.communication_sub_message')
    const $message = $(this).parents('.communication_message')
    $(document).triggerHandler('richTextEnd', $form.find('textarea.rich_text'))
    $form.remove()
    $message.find('.reply_message').show()
  })
  $('.communication_message,.communication_sub_message')
    .bind('focusin mouseenter', function() {
      $(this).addClass('communication_message_hover')
    })
    .bind('focusout mouseleave', function() {
      $(this).removeClass('communication_message_hover')
    })
  $('.communication_sub_message .more_options_reply_link').click(function(event) {
    event.preventDefault()
    const $form = $(this).parents('form')
    let params = null
    if ($form.hasClass('submission_comment_form')) {
      params = {comment: $form.find('textarea:visible:first').val() || ''}
    } else {
      params = {message: $form.find('textarea:visible:first').val() || ''}
    }
    window.location.href = $(this).attr('href') + '?message=' + encodeURIComponent(params.message)
  })
  $('.communication_message.new_activity_message').ifExists(function() {
    this.find('.message_type img').click(function() {
      const $this = $(this),
        c = $.trim($this.attr('class'))
      $this
        .parents('.message_type')
        .find('img')
        .removeClass('selected')
      $this
        .addClass('selected')
        .parents('.new_activity_message')
        .find('.message_type_text')
        .text($this.attr('title'))
        .end()
        .find('.activity_form')
        .hide()
        .end()
        .find('textarea, :text')
        .val('')
        .end()
        .find('.' + c + '_form')
        .show()
        .find('.context_select')
        .change()
    })
    this.find('.context_select')
      .change(function() {
        const $this = $(this),
          thisVal = $this.val(),
          $message = $this.parents('.communication_message'),
          $form = $message.find('form')
        $form.attr('action', $message.find('.' + thisVal + '_form_url').attr('href'))
        $form.data('context_name', this.options[this.selectedIndex].text)
        $form.data('context_code', thisVal)
        $message
          .find('.roster_list')
          .hide()
          .find(':checkbox')
          .each(function() {
            $(this).attr('checked', false)
          })
        $message.find('.' + thisVal + '_roster_list').show()
      })
      .triggerHandler('change')
    this.find('.cancel_button').click(function(_event) {
      $(this)
        .parents('.communication_message')
        .hide()
        .prev('.new_activity_message')
        .show()
    })
    this.find('.new_activity_message_link').click(function(event) {
      event.preventDefault()
      $(this)
        .parents('.communication_message')
        .hide()
        .next('.new_activity_message')
        .find('.message_type img.selected')
        .click()
        .end()
        .show()
        .find(':text:visible:first')
        .focus()
        .select()
    })
    this.find('form.message_form').formSubmit({
      beforeSubmit(_data) {
        $('button').attr('disabled', true)
        $('button.submit_button').text(I18n.t('status.posting_message', 'Posting Message...'))
      },
      success(data) {
        $('button').attr('disabled', false)
        $('button.submit_button').text('Post Message')
        const context_code = $(this).data('context_code') || ''
        const context_name = $(this).data('context_name') || ''
        if ($(this).hasClass('discussion_topic_form')) {
          const topic = data.discussion_topic
          topic.context_code = context_name
          topic.user_name = $('#identity .user_name').text()
          topic.post_date = $.datetimeString(topic.created_at)
          topic.topic_id = topic.id
          const $template = $(this)
            .parents('.communication_message')
            .find('.template')
          const $message = $template.find('.communication_message').clone(true)
          $message
            .find('.header .title,.behavior_content .less_important a')
            .attr('href', $template.find('.' + context_code + '_topic_url').attr('href'))
          $message
            .find('.add_entry_link')
            .attr('href', $template.find('.' + context_code + '_topics_url').attr('href'))
          $message
            .find('.user_name')
            .attr('href', $template.find('.' + context_code + '_user_url').attr('href'))
          $message
            .find('.topic_assignment_link,.topic_assignment_url')
            .attr('href', $template.find('.' + context_code + '_assignment_url').attr('href'))
          $message
            .find('.attachment_name,.topic_attachment_url')
            .attr('href', $template.find('.' + context_code + '_attachment_url').attr('href'))
          const entry = {discussion_topic_id: topic.id}
          $message.fillTemplateData({
            data: topic,
            hrefValues: ['topic_id', 'user_id', 'assignment_id', 'attachment_id'],
            avoid: '.subcontent'
          })
          $message.find('.subcontent').fillTemplateData({
            data: entry,
            hrefValues: ['topic_id', 'user_id']
          })
          $message
            .find('.subcontent form')
            .attr('action', $template.find('.' + context_code + '_entries_url').attr('href'))
          $message.fillFormData(entry, {object_name: 'discussion_entry'})
          $(this)
            .parents('.communication_message')
            .after($message.hide())
          $message.slideDown()
          $(this)
            .parents('.communication_message')
            .slideUp()
          $(this)
            .parents('.communication_message')
            .prev('.new_activity_message')
            .slideDown()
        } else if ($(this).hasClass('announcement_form')) {
          // do nothing
        } else {
          window.location.reload()
        }
      },
      error(data) {
        $('button').attr('disabled', false)
        $('button.submit_button').text(
          I18n.t('errors.posting_message_failed', 'Post Failed, Try Again')
        )
        $(this).formErrors(data)
      }
    })
  })
  $('#topic_list .show_all_messages_link')
    .show()
    .click(function(event) {
      event.preventDefault()
      $('#topic_list .topic_message').show()
      $(this).hide()
    })
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // vvvvvvvvvvvvvvvvv BEGIN stuf form making pretty dates vvvvvvvvvvvvvvvvvv
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  let timeAgoEvents = []
  function timeAgoRefresh() {
    timeAgoEvents = [...document.querySelectorAll('.time_ago_date')].filter($.expr.filters.visible)
    processNextTimeAgoEvent()
  }
  function processNextTimeAgoEvent() {
    const eventElement = timeAgoEvents.shift()
    if (eventElement) {
      const $event = $(eventElement),
        date = $event.data('parsed_date') || Date.parse($event.data('timestamp') || '')
      if (date) {
        const diff = new Date() - date
        $event.data('timestamp', date.toISOString())
        $event.data('parsed_date', date)
        const fudgedDate = $.fudgeDateForProfileTimezone(date)
        const defaultDateString =
          fudgedDate.toString('MMM d, yyyy') + fudgedDate.toString(' h:mmtt').toLowerCase()
        let dateString = defaultDateString
        if (diff < 24 * 3600 * 1000) {
          if (diff < 3600 * 1000) {
            if (diff < 60 * 1000) {
              dateString = I18n.t('#time.less_than_a_minute_ago', 'less than a minute ago')
            } else {
              const minutes = parseInt(diff / (60 * 1000), 10)
              dateString = I18n.t(
                '#time.count_minutes_ago',
                {one: '1 minute ago', other: '%{count} minutes ago'},
                {count: minutes}
              )
            }
          } else {
            const hours = parseInt(diff / (3600 * 1000), 10)
            dateString = I18n.t(
              '#time.count_hours_ago',
              {one: '1 hour ago', other: '%{count} hours ago'},
              {count: hours}
            )
          }
        }
        $event.text(dateString)
        $event.attr('title', defaultDateString)
      }
      setTimeout(processNextTimeAgoEvent, 1)
    } else {
      setTimeout(timeAgoRefresh, 60000)
    }
  }
  setTimeout(timeAgoRefresh, 100)
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // ^^^^^^^^^^^^^^^^^^ END stuff for making pretty dates ^^^^^^^^^^^^^^^^^^^
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  const sequence_url = $('#sequence_footer .sequence_details_url')
    .filter(':last')
    .attr('href')
  if (sequence_url) {
    $.ajaxJSON(sequence_url, 'GET', {}, data => {
      const $sequence_footer = $('#sequence_footer')
      if (data.current_item) {
        $('#sequence_details .current').fillTemplateData({data: data.current_item.content_tag})
        $.each({previous: '.prev', next: '.next'}, (label, cssClass) => {
          const $link = $sequence_footer.find(cssClass)
          if (data[label + '_item'] || data[label + '_module']) {
            const tag =
              (data[label + '_item'] && data[label + '_item'].content_tag) ||
              (data[label + '_module'] && data[label + '_module'].context_module)
            if (!data[label + '_item']) {
              tag.title = tag.title || tag.name
              if (tag.workflow_state === 'unpublished') {
                tag.title += ' (' + I18n.t('draft', 'Draft') + ')'
              }
              tag.text =
                label == 'previous'
                  ? I18n.t('buttons.previous_module', 'Previous Module')
                  : I18n.t('buttons.next_module', 'Next Module')
              $link.addClass('module_button')
            }
            $link.fillTemplateData({data: tag})
            if (data[label + '_item']) {
              $link.attr(
                'href',
                $.replaceTags($sequence_footer.find('.module_item_url').attr('href'), 'id', tag.id)
              )
            } else {
              $link.attr(
                'href',
                $.replaceTags($sequence_footer.find('.module_url').attr('href'), 'id', tag.id) +
                  '/items/' +
                  (label === 'previous' ? 'last' : 'first')
              )
            }
          } else {
            $link.hide()
          }
        })
        $sequence_footer.show()
        $(window).resize() // this will be helpful for things like $.fn.fillWindowWithMe so that it knows the dimensions of the page have changed.
      }
    })
  } else {
    const sf = $('#sequence_footer')
    if (sf.length) {
      const el = $(sf[0])
      import('compiled/jquery/ModuleSequenceFooter').then(() => {
        el.moduleSequenceFooter({
          courseID: el.attr('data-course-id'),
          assetType: el.attr('data-asset-type'),
          assetID: el.attr('data-asset-id')
        })
      })
    }
  }
  // this is for things like the to-do, recent items and upcoming, it
  // happend a lot so rather than duplicating it everywhere I stuck it here
  $('#right-side').delegate('.more_link', 'click', function(event) {
    const $this = $(this)
    const $children = $this
      .parents('ul')
      .children(':hidden')
      .show()
    $this.closest('li').remove()
    // if they are using the keyboard to navigate (they hit enter on the link instead of actually
    // clicking it) then put focus on the first of the now-visible items--otherwise, since the
    // .more_link is hidden, focus would be completely lost and leave a blind person stranded.
    // don't want to set focus if came from a mouse click because then you'd have 2 of the tooltip
    // bubbles staying visible, see #9211
    if (event.screenX === 0) {
      $children
        .first()
        .find(':tabbable:first')
        .focus()
    }
    return false
  })
  $('#right-side').on('click', '.disable-todo-item-link', function(event) {
    event.preventDefault()
    const $item = $(this)
      .parents('li, div.topic_message')
      .last()
    const $prevItem = $(this)
      .closest('.to-do-list > li')
      .prev()
    const toFocus =
      ($prevItem.find('.disable-todo-item-link').length &&
        $prevItem.find('.disable-todo-item-link')) ||
      $('.todo-list-header')
    const url = $(this).data('api-href')
    const flashMessage = $(this).data('flash-message')
    function remove(delete_url) {
      $item.confirmDelete({
        url: delete_url,
        noMessage: true,
        success() {
          if (flashMessage) {
            $.flashMessage(flashMessage)
          }
          $(this).slideUp(function() {
            $(this).remove()
            toFocus.focus()
          })
        }
      })
    }
    remove(url)
  })
  // in 100ms (to give time for everything else to load), find all the external links and add give them
  // the external link look and behavior (force them to open in a new tab)
  setTimeout(function() {
    const content = document.getElementById('content')
    if (!content) return
    const links = content.querySelectorAll(
      `a[href*="//"]:not([href*="${window.location.hostname}"])`
    ) // technique for finding "external" links copied from https://davidwalsh.name/external-links-css
    for (let i = 0; i < links.length; i++) {
      const $link = $(links[i])
      // don't mess with the ones that were already processed in enhanceUserContent
      if ($link.hasClass('external')) continue
      const $linkToReplace = $link
        .not('.open_in_a_new_tab')
        .not(':has(img)')
        .not('.not_external')
        .not('.exclude_external_icon')
      if ($linkToReplace.length) {
        const indicatorText = I18n.t('titles.external_link', 'Links to an external site.')
        const $linkIndicator = $('<span class="ui-icon ui-icon-extlink ui-icon-inline"/>').attr(
          'title',
          indicatorText
        )
        $linkIndicator.append($('<span class="screenreader-only"/>').text(indicatorText))
        $linkToReplace
          .addClass('external')
          .children('span.ui-icon-extlink')
          .remove()
          .end()
          .html('<span>' + $link.html() + '</span>')
          .attr('target', '_blank')
          .attr('rel', 'noreferrer noopener')
          .append($linkIndicator)
      }
    }
  }, 100)
})
