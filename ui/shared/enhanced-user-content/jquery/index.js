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
import {isolate} from '@canvas/sentry'
import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import _ from 'underscore'
import htmlEscape from 'html-escape'
import preventDefault from 'prevent-default'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import ReactDOM from 'react-dom'
import React from 'react'
import {Link} from '@instructure/ui-link'
import './instructure_helper'
import 'jqueryui/draggable'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/doc-previews' /* loadDocPreview */
import '@canvas/datetime' /* datetimeString, dateString, fudgeDateForProfileTimezone */
import '@canvas/forms/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags, youTubeID */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* ifExists, .dim, confirmDelete, showIf, fillWindowWithMe */
import '@canvas/keycodes'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'
import 'date-js'
import 'jquery-tinypubsub' /* /\.publish\(/ */
import 'jqueryui/resizable'
import 'jqueryui/sortable'
import 'jqueryui/tabs'
import {IconDownloadLine, IconExternalLinkLine} from '@instructure/ui-icons/es/svg'

const I18n = useI18nScope('instructure_js')

// we're doing this so we can use the svg in the img src attribute
// rather than just inlining the svg. This simplified keeping the
// vertical alignment consistent with how it was with the icon font.
// The optional chaining to .src is because the icons are undefined
// in jest tests
const IconDownloadb64src = window.btoa(IconDownloadLine?.src)
const IconExternalLinkb64src = window.btoa(IconExternalLinkLine?.src)

function makeDownloadButton(download_url, filename) {
  const a = document.createElement('a')
  a.setAttribute('class', 'file_download_btn')
  a.setAttribute('role', 'button')
  a.setAttribute('download', '')
  a.setAttribute('style', 'margin-inline-start: 5px; text-decoration: none;')
  a.setAttribute('href', download_url)

  const img = document.createElement('img')
  img.setAttribute('style', 'width:16px; height:16px')
  img.setAttribute('role', 'presentation')
  img.setAttribute('src', `data:image/svg+xml;base64,${IconDownloadb64src}`)
  a.appendChild(img)

  const srspan = document.createElement('span')
  srspan.setAttribute('class', 'screenreader-only')
  srspan.innerHTML = htmlEscape(I18n.t('Download %{filename}', {filename}))
  a.appendChild(srspan)

  return a
}

function makeExternalLinkIcon() {
  const span = document.createElement('span')
  const img = document.createElement('img')
  img.setAttribute('style', 'margin-inline-start: 5px; width:16px; height:16px')
  img.setAttribute('src', `data:image/svg+xml;base64,${IconExternalLinkb64src}`)
  img.setAttribute('alt', '')
  img.setAttribute('role', 'presentation')
  span.appendChild(img)

  const srspan = document.createElement('span')
  srspan.setAttribute('class', 'screenreader-only')
  srspan.innerHTML = htmlEscape(I18n.t('Links to an external site.'))
  span.appendChild(srspan)
  return span
}

let preview_counter = 0
function previewId() {
  return `preview_${++preview_counter}`
}

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
      preventDefault(function () {
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
          })
        )
        $(this).after($video).hide()
      })
    )
    $link.addClass('youtubed').after($after)
  }
}

function buildUrl(url) {
  try {
    return new URL(url)
  } catch (e) {
    // Don't raise an error
  }
}

// Rendering a temporary Link element so we can copy its classnames to anchors with images inside,
// since '@instructure/ui-link' doesn't provide a way to use its CSS themed classes directly.
function handleAnchorsWithImage() {
  const temp = document.createElement('div')
  const tempLinkComponent = React.createElement(
    Link,
    {
      elementRef: e => {
        $('.user_content a:has(img)').each(function () {
          $(this).addClass(e.className)
        })
      }
    },
    // Children prop is required
    React.createElement('img')
  )
  ReactDOM.render(tempLinkComponent, temp)
}

export function enhanceUserContent(visibilityMod) {
  if (ENV.SKIP_ENHANCING_USER_CONTENT) {
    return
  }
  const JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE = '.dialog, .draggable, .resizable, .sortable, .tabs'
  const visibilityQueryMod = visibilityMod === enhanceUserContent.ANY_VISIBILITY ? '' : ':visible'
  $(`.user_content:not(.enhanced)${visibilityQueryMod}`).addClass('unenhanced')
  $(`.user_content.unenhanced${visibilityQueryMod}`)
    .each(function () {
      const $this = $(this)
      $this.find('img').each((i, img) => {
        // if the image file is unpublished it's replaced with the lock image
        // and canvas adds hidden=1 to the URL.
        // we also need to strip the alt text
        if (/hidden=1$/.test(img.getAttribute('src'))) {
          img.setAttribute('alt', I18n.t('This image is currently unavailable'))
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
      console.error(msg, $elements) // eslint-disable-line no-console
    })
    .end()
    .filter('.dialog')
    .each(function () {
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
    .each(function () {
      $(this).tabs()
    })
    .end()
    .end()
    .find('a:not(.not_external, .external):external')
    .each(function () {
      $(this)
        .not(':has(img)')
        .addClass('external')
        .html('<span>' + $(this).html() + '</span>')
        .attr('target', '_blank')
        .attr('rel', 'noreferrer noopener')
        .append($(makeExternalLinkIcon()))
    })
    .end()

  handleAnchorsWithImage()

  $('a.instructure_file_link, a.instructure_scribd_file').each(function () {
    const $link = $(this)
    const href = buildUrl($link[0].href)

    // Don't attempt to enhance links with no href
    if (!href) return

    const matchesCanvasFile = href.pathname.match(
      /(?:\/(courses|groups|users)\/(\d+))?\/files\/(\d+)/
    )
    if (!matchesCanvasFile) {
      // a bug in the new RCE added instructure_file_link class name to all links
      // only proceed if this is a canvas file link
      return
    }
    let $download_btn, $preview_link
    if ($.trim($link.text())) {
      const filename = this.textContent
      // instructure_file_link_holder is used to find file_preview_link
      const $span = $(
        "<span class='instructure_file_holder link_holder instructure_file_link_holder'/>"
      )

      const qs = href.searchParams
      qs.delete('wrap')
      qs.append('download_frd', '1')
      const download_url = `${href.origin}${href.pathname.replace(
        /(?:\/(download|preview))?$/,
        '/download'
      )}?${qs}`
      $download_btn = makeDownloadButton(download_url, filename)

      if ($link.hasClass('instructure_scribd_file')) {
        if ($link.hasClass('no_preview')) {
          // link downloads
          $link.attr('href', download_url)
          $link.removeAttr('target')
        } else if ($link.hasClass('inline_disabled')) {
          // link opens in overlay
          $link.addClass('preview_in_overlay')
        } else {
          // link opens inline preview
          $link.addClass('file_preview_link')
        }
      }
      $link.removeClass('instructure_file_link')
      $link.removeClass('instructure_scribd_file').before($span).appendTo($span)
      $span.append($preview_link)
      $span.append($download_btn)
    }
  })

  // Some schools have been using 'file_preview_link' for inline previews
  // outside of the RCE so find them all after we've gone through and
  // added our own (above)
  $('.instructure_file_link_holder')
    .find('a.file_preview_link, a.scribd_file_preview_link')
    .each(function () {
      const $link = $(this)
      if ($link.siblings('.preview_container').length) {
        return
      }

      const preview_id = previewId()
      $link.attr('aria-expanded', 'false')
      $link.attr('aria-controls', preview_id)
      const $preview_container = $('<div role="region" class="preview_container" />')
        .attr('id', preview_id)
        .css('display', 'none')
      $link.parent().append($preview_container)
      if ($link.hasClass('auto_open')) {
        $link.click()
      }
    })

  $('.user_content.unenhanced a,.user_content.unenhanced+div.answers a')
    .find('img.media_comment_thumbnail')
    .each(function () {
      $(this).closest('a').addClass('instructure_inline_media_comment')
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
  $('.user_content.unenhanced').removeClass('unenhanced').addClass('enhanced')
  setTimeout(() => {
    $('.user_content form.user_content_post_form:not(.submitted)').submit().addClass('submitted')
  }, 10)
  // Remove sandbox attribute from user content iframes to fix busted
  // third-party content, like Google Drive documents.
  document
    .querySelectorAll('.user_content iframe[sandbox="allow-scripts allow-forms allow-same-origin"]')
    .forEach(frame => {
      frame.removeAttribute('sandbox')
      const src = frame.src
      frame.src = src
    })
}

// we need an override control for jest since ":visible" jQuery modifier will
// always say false there
enhanceUserContent.ANY_VISIBILITY = {}

export function formatTimeAgoTitle(date) {
  const fudgedDate = $.fudgeDateForProfileTimezone(date)
  return fudgedDate.toString('MMM d, yyyy h:mmtt')
}

export function formatTimeAgoDate(date) {
  if (typeof date === 'string') {
    date = Date.parse(date)
  }
  const diff = new Date() - date
  if (diff < 24 * 3600 * 1000) {
    if (diff < 3600 * 1000) {
      if (diff < 60 * 1000) {
        return I18n.t('#time.less_than_a_minute_ago', 'less than a minute ago')
      } else {
        const minutes = parseInt(diff / (60 * 1000), 10)
        return I18n.t(
          '#time.count_minutes_ago',
          {one: '1 minute ago', other: '%{count} minutes ago'},
          {count: minutes}
        )
      }
    } else {
      const hours = parseInt(diff / (3600 * 1000), 10)
      return I18n.t(
        '#time.count_hours_ago',
        {one: '1 hour ago', other: '%{count} hours ago'},
        {count: hours}
      )
    }
  } else {
    return formatTimeAgoTitle(date)
  }
}

function retriggerEarlyClicks() {
  // handle all of the click events that were triggered before the dom was ready (and thus weren't handled by jquery listeners)
  if (window._earlyClick) {
    // unset the onclick handler we were using to capture the events
    document.removeEventListener('click', window._earlyClick)
    if (window._earlyClick.clicks) {
      // wait to fire the "click" events till after all of the event hanlders loaded at dom ready are initialized
      setTimeout(function () {
        $.each(_.uniq(window._earlyClick.clicks), function () {
          // cant use .triggerHandler because it will not bubble,
          // but we do want to preventDefault, so this is what we have to do
          const event = $.Event('click')
          event.preventDefault()
          $(this).trigger(event)
        })
      }, 1)
    }
  }
}

function ellipsifyBreadcrumbs() {
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
}

function bindKeyboardShortcutsHelpPanel() {
  KeyboardNavDialog.prototype.bindOpenKeys.call({$el: $('#keyboard_navigation')})
}

function warnAboutRolesBeingSwitched() {
  $('#switched_role_type').ifExists(function () {
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
    $img.attr('src', '/images/warning.png').attr('title', switched_roles_message).css({
      paddingRight: 2,
      width: 12,
      height: 12
    })
    $('#crumb_' + context_class)
      .find('a')
      .prepend($img)
  })
}

function expandQuotedTextWhenClicked() {
  $('a.show_quoted_text_link').live('click', function (event) {
    const $text = $(this).parents('.quoted_text_holder').children('.quoted_text')
    if ($text.length > 0) {
      event.preventDefault()
      $text.show()
      $(this).hide()
    }
  })
}

function previewEquellaContentWhenClicked() {
  $('a.equella_content_link').live('click', function (event) {
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
}

function openDialogsWhenClicked() {
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
  $('.dialog_opener[aria-controls]:not(.user_content *)').live('click', function (event) {
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
}

function previewFilesWhenClicked() {
  $('a.file_preview_link, a.scribd_file_preview_link').live('click', function (event) {
    if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
      // if any modifier keys are pressed, do the browser default thing
      return
    }
    event.preventDefault()
    const $link = $(this)
    if ($link.attr('aria-expanded') === 'true') {
      // close the preview by clicking the "Minimize File Preview" link
      $link.parent().find('.hide_file_preview_link').click()
      return
    }
    $link.loadingImage({image_size: 'small', horizontal: 'right!'})
    $link.attr('aria-expanded', 'true')
    $.ajaxJSON(
      $link
        .attr('href')
        .replace(/\/(download|preview)/, '') // download as part of the path
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
          const $div = $(`[id="${$link.attr('aria-controls')}"]`)
          $div.css('display', 'block').loadDocPreview({
            canvadoc_session_url: attachment.canvadoc_session_url,
            mimeType: attachment.content_type,
            public_url: attachment.public_url,
            attachment_preview_processing:
              attachment.workflow_state === 'pending_upload' ||
              attachment.workflow_state === 'processing'
          })
          const $minimizeLink = $(
            '<a href="#" style="font-size: 0.8em;" class="hide_file_preview_link">' +
              htmlEscape(I18n.t('links.minimize_file_preview', 'Minimize File Preview')) +
              '</a>'
          ).click(event => {
            event.preventDefault()
            $link.attr('aria-expanded', 'false')
            $link.show()
            $link.focus()
            $div.html('').css('display', 'none')
          })
          $div.prepend($minimizeLink)
          if (Object.prototype.hasOwnProperty.call(event, 'originalEvent')) {
            // Only focus this link if the open preview link was initiated by a real browser event
            // If it was triggered by our auto_open stuff it shouldn't focus here.
            $minimizeLink.focus()
          }
        }
      },
      () => {
        $link.loadingImage('remove').hide()
      }
    )
  })

  $('a.preview_in_overlay').live('click', event => {
    let target = null
    if (event.target.href) {
      target = event.target
    } else if (event.currentTarget?.href) {
      target = event.currentTarget
    }
    const matches = target?.href.match(/\/files\/(\d+)/)
    if (matches) {
      if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
        // if any modifier keys are pressed, do the browser default thing
        return
      }
      event.preventDefault()
      const url = new URL(target.href)
      const verifier = url?.searchParams.get('verifier')
      const file_id = matches[1]
      import('../react/showFilePreview')
        .then(module => {
          module.showFilePreview(file_id, verifier)
        })
        .catch(_err => {
          $.flashError(I18n.t('Something went wrong loading the file previewer.'))
        })
    }
  })
}

function enhanceUserContentWhenAsked() {
  // publishing the 'userContent/change' will run enhanceUserContent at most once every 50ms
  let enhanceUserContentTimeout
  $.subscribe('userContent/change', () => {
    clearTimeout(enhanceUserContentTimeout)
    enhanceUserContentTimeout = setTimeout(enhanceUserContent, 50)
  })
  $(document).bind('user_content_change', enhanceUserContent)
}

function enhanceUserContentRepeatedly() {
  $(() => {
    setInterval(enhanceUserContent, 15000)
    setTimeout(enhanceUserContent, 15)
  })
}

// app/views/discussion_topics/_entry.html.erb
function showDiscussionTopicSubMessagesWhenClicked() {
  $('.show_sub_messages_link').click(function (event) {
    event.preventDefault()
    $(this)
      .parents('.subcontent')
      .find('.communication_sub_message.toggled_communication_sub_message')
      .removeClass('toggled_communication_sub_message')
    $(this).parents('.communication_sub_message').remove()
  })
}

// app/views/discussion_topics/_entry.html.erb
function addDiscussionTopicEntryWhenClicked() {
  $('.communication_message .add_entry_link').click(function (event) {
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
    $response.find('textarea:first').focus().select()
  })
}

function showAndHideRCEWhenAsked() {
  $(document)
    .bind('richTextStart', (event, $editor) => {
      if (!$editor || $editor.length === 0) {
        return
      }
      $editor = $($editor)
      if (!$editor || $editor.length === 0) {
        return
      }
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
}

function doThingsWhenDiscussionTopicSubMessageIsPosted() {
  $('.communication_sub_message .add_sub_message_form').formSubmit({
    beforeSubmit(_data) {
      $(this).find('button').attr('disabled', true)
      $(this).find('.submit_button').text(I18n.t('status.posting_message', 'Posting Message...'))
      $(this).loadingImage()
    },
    success(data) {
      $(this).loadingImage('remove')
      const $message = $(this).parents('.communication_sub_message')
      if ($(this).hasClass('submission_comment_form')) {
        const user_id = $(this).getTemplateData({
          textValues: ['submission_user_id']
        }).submission_user_id
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
    },
    error(data) {
      $(this).loadingImage('remove')
      $(this).find('button').attr('disabled', false)
      $(this)
        .find('.submit_button')
        .text(I18n.t('errors.posting_message_failed', 'Post Failed, Try Again'))
      $(this).formErrors(data)
    }
  })
}

function cancelDiscussionTopicSubMessageWhenClicked() {
  $('.communication_sub_message form .cancel_button').click(function () {
    const $form = $(this).parents('.communication_sub_message')
    const $message = $(this).parents('.communication_message')
    $(document).triggerHandler('richTextEnd', $form.find('textarea.rich_text'))
    $form.remove()
    $message.find('.reply_message').show()
  })
}

function highlightDiscussionTopicMessagesOnHover() {
  $('.communication_message,.communication_sub_message')
    .bind('focusin mouseenter', function () {
      $(this).addClass('communication_message_hover')
    })
    .bind('focusout mouseleave', function () {
      $(this).removeClass('communication_message_hover')
    })
}

function makeDatesPretty() {
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
        $event.data('timestamp', date.toISOString())
        $event.data('parsed_date', date)
        $event.text(formatTimeAgoDate(date))
        $event.attr('title', formatTimeAgoTitle(date))
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
}

function doThingsToModuleSequenceFooter() {
  const sf = $('#sequence_footer')
  if (sf.length) {
    const el = $(sf[0])
    import('@canvas/module-sequence-footer').then(() => {
      el.moduleSequenceFooter({
        courseID: el.attr('data-course-id'),
        assetType: el.attr('data-asset-type'),
        assetID: el.attr('data-asset-id')
      })
    })
  }
}

function showHideRemoveThingsToRightSideMoreLinksWhenClicked() {
  // this is for things like the to-do, recent items and upcoming, it
  // happend a lot so rather than duplicating it everywhere I stuck it here
  $('#right-side').delegate('.more_link', 'click', function (event) {
    const $this = $(this)
    const $children = $this.parents('ul').children(':hidden').show()
    $this.closest('li').remove()
    // if they are using the keyboard to navigate (they hit enter on the link instead of actually
    // clicking it) then put focus on the first of the now-visible items--otherwise, since the
    // .more_link is hidden, focus would be completely lost and leave a blind person stranded.
    // don't want to set focus if came from a mouse click because then you'd have 2 of the tooltip
    // bubbles staying visible, see #9211
    if (event.screenX === 0) {
      $children.first().find(':tabbable:first').focus()
    }
    return false
  })
}

function confirmAndDeleteRightSideTodoItemsWhenClicked() {
  $('#right-side').on('click', '.disable-todo-item-link', function (event) {
    event.preventDefault()
    const $item = $(this).parents('li, div.topic_message').last()
    const $prevItem = $(this).closest('.to-do-list > li').prev()
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
          $(this).slideUp(function () {
            $(this).remove()
            toFocus.focus()
          })
        }
      })
    }
    remove(url)
  })
}

function makeAllExternalLinksExternalLinks() {
  // in 100ms (to give time for everything else to load), find all the external links and add give them
  // the external link look and behavior (force them to open in a new tab)
  setTimeout(function () {
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
        const $linkIndicator = makeExternalLinkIcon()
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
}

export default function enhanceTheEntireUniverse() {
  ;[
    retriggerEarlyClicks,
    ellipsifyBreadcrumbs,
    bindKeyboardShortcutsHelpPanel,
    warnAboutRolesBeingSwitched,
    expandQuotedTextWhenClicked,
    previewEquellaContentWhenClicked,
    openDialogsWhenClicked,
    previewFilesWhenClicked,
    enhanceUserContentWhenAsked,
    enhanceUserContentRepeatedly,
    showDiscussionTopicSubMessagesWhenClicked,
    addDiscussionTopicEntryWhenClicked,
    showAndHideRCEWhenAsked,
    doThingsWhenDiscussionTopicSubMessageIsPosted,
    cancelDiscussionTopicSubMessageWhenClicked,
    highlightDiscussionTopicMessagesOnHover,
    makeDatesPretty,
    doThingsToModuleSequenceFooter,
    showHideRemoveThingsToRightSideMoreLinksWhenClicked,
    confirmAndDeleteRightSideTodoItemsWhenClicked,
    makeAllExternalLinksExternalLinks
  ]
    .map(isolate)
    .map(x => x())
}
