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
import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {uniqueId} from 'lodash'
import htmlEscape from '@instructure/html-escape'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {enhanceUserContent} from '@instructure/canvas-rce'
import {makeAllExternalLinksExternalLinks} from '@instructure/canvas-rce/es/enhance-user-content/external_links'
import './instructure_helper'
import 'jqueryui/draggable'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery' /* datetimeString, dateString, fudgeDateForProfileTimezone */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags, youTubeID */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* ifExists, .dim, confirmDelete, showIf, fillWindowWithMe */
import '@canvas/jquery-keycodes'
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
import {captureException} from '@sentry/browser'

const I18n = useI18nScope('instructure_js')

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

// this code was lifted from the original jquery version of enhanceUserContent
// it's what wires up jquery widgets to DOM elements with magic class names
function enhanceUserJQueryWidgetContent() {
  const JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE = '.dialog, .draggable, .resizable, .sortable, .tabs'
  $('.user_content.unenhanced')
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
      captureException(new Error(msg))
    })
    .end()
    .filter('.dialog')
    .each(function () {
      const $dialog = $(this)
      $dialog.hide()
      $dialog
        .closest('.user_content')
        .find("a[href='#" + $dialog.attr('id') + "']")
        .on('click', event => {
          event.preventDefault()
          $dialog.dialog({
            modal: true,
            zIndex: 1000,
          })
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
      height: 12,
    })
    $('#crumb_' + context_class)
      .find('a')
      .prepend($img)
  })
}

function expandQuotedTextWhenClicked() {
  $(document).on('click', 'a.show_quoted_text_link', function (event) {
    const $text = $(this).parents('.quoted_text_holder').children('.quoted_text')
    if ($text.length > 0) {
      event.preventDefault()
      $text.show()
      $(this).hide()
    }
  })
}

function previewEquellaContentWhenClicked() {
  $(document).on('click', 'a.equella_content_link', function (event) {
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
        },
        modal: true,
        zIndex: 1000,
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
  $(document).on('click', '.dialog_opener[aria-controls]:not(.user_content *)', function (event) {
    const link = this
    $('#' + $(this).attr('aria-controls')).ifExists($dialog => {
      event.preventDefault()
      // if the linked dialog has not already been initialized, initialize it (passing in opts)
      if (!$dialog.data('ui-dialog')) {
        $dialog.dialog(
          $.extend(
            {
              autoOpen: false,
              modal: true,
              zIndex: 1000,
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

let enhanceUserContentTimeout
function enhanceUserContentWhenAsked() {
  if (ENV?.SKIP_ENHANCING_USER_CONTENT) {
    return
  }

  clearTimeout(enhanceUserContentTimeout)
  enhanceUserContentTimeout = setTimeout(
    () =>
      enhanceUserContent(document, {
        customEnhanceFunc: enhanceUserJQueryWidgetContent,
        canvasOrigin: ENV?.DEEP_LINKING_POST_MESSAGE_ORIGIN || window.location?.origin,
        kalturaSettings: INST.kalturaSettings,
        disableGooglePreviews: !!INST.disableGooglePreviews,
        new_math_equation_handling: !!ENV?.FEATURES?.new_math_equation_handling,
        explicit_latex_typesetting: !!ENV?.FEATURES?.explicit_latex_typesetting,
        locale: ENV?.LOCALE ?? 'en',
      }),
    50
  )
}

let user_content_mutation_observer = null
function enhanceUserContentRepeatedly() {
  if (!user_content_mutation_observer) {
    user_content_mutation_observer = new MutationObserver(mutationList => {
      if (mutationList.filter(m => m.addedNodes.length > 0).length > 0) {
        enhanceUserContentWhenAsked()
      }
    })
    user_content_mutation_observer.observe(document.getElementById('content') || document.body, {
      subtree: true,
      childList: true,
    })
  }
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
    const id = uniqueId('textarea_')
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
      $(this).find('button').prop('disabled', true)
      $(this).find('.submit_button').text(I18n.t('status.posting_message', 'Posting Message...'))
      $(this).loadingImage()
    },
    success(data) {
      $(this).loadingImage('remove')
      const $message = $(this).parents('.communication_sub_message')
      if ($(this).hasClass('submission_comment_form')) {
        const user_id = $(this).getTemplateData({
          textValues: ['submission_user_id'],
        }).submission_user_id
        let submission = null
        for (const idx in data) {
          const s = data[idx].submission
          // eslint-disable-next-line eqeqeq
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
            htmlValues: ['message'],
          })
        }
      } else {
        const entry = data.discussion_entry
        entry.post_date = $.datetimeString(entry.created_at)
        $message.find('.content > .message_html').val(entry.message)
        $message.fillTemplateData({
          data: entry,
          htmlValues: ['message'],
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
      $(this).find('button').prop('disabled', false)
      $(this)
        .find('.submit_button')
        .text(I18n.t('errors.posting_message_failed', 'Post Failed, Try Again'))
      $(this).formErrors(data)
    },
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
    import('@canvas/module-sequence-footer')
      .then(() => {
        el.moduleSequenceFooter({
          courseID: el.attr('data-course-id'),
          assetType: el.attr('data-asset-type'),
          assetID: el.attr('data-asset-id'),
        })
      })
      .catch(ex => {
        // eslint-disable-next-line no-console
        console.error(ex)
        captureException(ex)
      })
  }
}

function showHideRemoveThingsToRightSideMoreLinksWhenClicked() {
  // this is for things like the to-do, recent items and upcoming, it
  // happend a lot so rather than duplicating it everywhere I stuck it here
  $('#right-side').on('click', '.more_link', function (event) {
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
        },
      })
    }
    remove(url)
  })
}

// this really belongs in enhanced-user-content2/instructure_helper
// but it uses FilePreview to render the file preview overlay, and
// that has so many dependencies on things like @canvas/files/backbone/models/File.js
// this it'll be too time consuming to decouple it from canvas in our
// timeframe. Solve it for now by using postMessage from enhanced-user-content2
// (which we hope to decouple from canvas) to ask canvas to render the preview
function showFilePreviewInOverlayHandler({file_id, verifier}) {
  import('../react/showFilePreview')
    .then(module => {
      module.showFilePreview(file_id, verifier)
    })
    .catch(err => {
      showFlashAlert({
        message: I18n.t('Something went wrong loading the file previewer.'),
        type: 'error',
      })
      // eslint-disable-next-line no-console
      console.log(err)
    })
}

function wireUpFilePreview() {
  window.addEventListener('message', event => {
    if (event.data.subject === 'preview_file') {
      showFilePreviewInOverlayHandler(event.data)
    }
  })
}

const setDialogCloseText = () => {
  // This is done here since we need to translate the close text, but don't
  // have access to I18n from packages/jqueryui. Since we're eventually moving
  // away from jqueryui and only have the single string to translate, its not
  // worth setting up a translation pipeline there.
  $.ui.dialog.prototype.options.closeText = I18n.t('Close')
}

export function enhanceTheEntireUniverse() {
  ;[
    ellipsifyBreadcrumbs,
    bindKeyboardShortcutsHelpPanel,
    warnAboutRolesBeingSwitched,
    expandQuotedTextWhenClicked,
    previewEquellaContentWhenClicked,
    openDialogsWhenClicked,
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
    makeAllExternalLinksExternalLinks,
    wireUpFilePreview,
    setDialogCloseText,
  ].map(x => x())
}
