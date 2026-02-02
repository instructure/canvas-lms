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
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {uniqueId, sortBy} from 'es-toolkit/compat'
import {fromNow} from '@canvas/fuzzy-relative-time'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {
  enhanceUserContent,
  makeAllExternalLinksExternalLinks,
} from '@instructure/canvas-rce/enhance-user-content'
import {getMountPoint} from '@canvas/top-navigation/react/TopNavPortalBase'
import 'jqueryui/dialog'
import 'jqueryui/draggable'
import 'jqueryui/resizable'
import 'jqueryui/sortable'
import 'jqueryui/tabs'
import '@canvas/jquery/jquery.ajaxJSON'
import {datetimeString, fudgeDateForProfileTimezone} from '@canvas/datetime/date-functions'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags, youTubeID */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* ifExists, .dim, confirmDelete, showIf, fillWindowWithMe */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'
import '@instructure/date-js'
import {captureException} from '@sentry/browser'
import preventDefault from '@canvas/util/preventDefault'

const I18n = createI18nScope('instructure_js')

const dateFormatter = new Intl.DateTimeFormat(ENV?.LOCALE ?? navigator.language, {
  // ddd, D MMM YYYY HH:mma
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
}).format

export function formatTimeAgoTitle(date) {
  const fudgedDate = fudgeDateForProfileTimezone(date)
  return dateFormatter(fudgedDate)
}

// This is temporarily here while we finish the announced deprecation of
// this functionality. It's been warning users for nine years but is still
// apparently fairly widely used, so it has to stay until we can get users
// transitioned off of it. It has to go because it decorates customer content
// with jQueryUI functionality, which we are moving away from entirely, and
// also there are security concerns with it.
const JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE = '.dialog, .draggable, .resizable, .sortable, .tabs'
function deprecationWarning(els) {
  const msg =
    'Deprecated use of magic jQueryUI widget markup detected:\n\n' +
    "You're relying on undocumented functionality where Canvas makes " +
    'jQueryUI widgets out of rich content that has the following class names: ' +
    JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE +
    '.\n\n' +
    'Canvas is moving away from jQueryUI for our own widgets and this behavior ' +
    "will go away. Rather than relying on the internals of Canvas's JavaScript, " +
    'you should use your own custom JS file to do any such customizations.'
  console.error(msg, els)
  captureException(new Error(msg))
}

function enhanceUserJQueryWidgetContent() {
  $('.user_content.unenhanced')
    .find('.enhanceable_content')
    .show()
    .filter(JQUERY_UI_WIDGETS_WE_TRY_TO_ENHANCE)
    .ifExists(deprecationWarning)
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
  const breadcrumbs = document.getElementById('breadcrumbs')
  if (breadcrumbs === null || getMountPoint() !== null) return // if page uses InstUI top nav
  let breadcrumbEllipsis
  let addedEllipsisClass = false
  const heightOfOneBreadcrumb = 27 * 1.5
  let taskID
  function resizeBreadcrumb() {
    if (taskID) (window.cancelIdleCallback || window.cancelAnimationFrame)(taskID)
    taskID = (window.requestIdleCallback || window.requestAnimationFrame)(() => {
      let maxWidth = 500
      breadcrumbEllipsis = breadcrumbEllipsis || breadcrumbs.querySelector('.ellipsible')
      if (breadcrumbEllipsis) {
        breadcrumbEllipsis.style.maxWidth = ''
        for (let i = 0; breadcrumbs.offsetHeight > heightOfOneBreadcrumb && i < 20; i++) {
          if (!addedEllipsisClass) {
            addedEllipsisClass = true
            breadcrumbEllipsis.classList.add('ellipsis')
          }
          maxWidth -= 20
          breadcrumbEllipsis.style.maxWidth = `${maxWidth}px`
        }
      }
    })
  }
  resizeBreadcrumb() // force it to run once right now
  window.addEventListener('resize', resizeBreadcrumb)
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
          'You have switched roles temporarily for this course, and are now viewing the course as a teacher.  You can restore your role and permissions from the course home page.',
        )
        break
      case 'StudentEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.student',
          'You have switched roles temporarily for this course, and are now viewing the course as a student.  You can restore your role and permissions from the course home page.',
        )
        break
      case 'TaEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.ta',
          'You have switched roles temporarily for this course, and are now viewing the course as a TA.  You can restore your role and permissions from the course home page.',
        )
        break
      case 'ObserverEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.observer',
          'You have switched roles temporarily for this course, and are now viewing the course as an observer.  You can restore your role and permissions from the course home page.',
        )
        break
      case 'DesignerEnrollment':
        switched_roles_message = I18n.t(
          'switched_roles_message.designer',
          'You have switched roles temporarily for this course, and are now viewing the course as a designer.  You can restore your role and permissions from the course home page.',
        )
        break
      default:
        switched_roles_message = I18n.t(
          'switched_roles_message.student',
          'You have switched roles temporarily for this course, and are now viewing the course as a student.  You can restore your role and permissions from the course home page.',
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

let enhanceUserContentTimeout
function enhanceUserContentWhenAsked() {
  if (ENV?.SKIP_ENHANCING_USER_CONTENT) {
    return
  }

  clearTimeout(enhanceUserContentTimeout)
  enhanceUserContentTimeout = setTimeout(
    () =>
      enhanceUserContent(document, {
        customEnhance: enhanceUserJQueryWidgetContent,
        canvasOrigin: ENV?.DEEP_LINKING_POST_MESSAGE_ORIGIN || window.location?.origin,
        kalturaSettings: INST.kalturaSettings,
        disableGooglePreviews: !!INST.disableGooglePreviews,
        new_math_equation_handling: !!ENV?.FEATURES?.new_math_equation_handling,
        explicit_latex_typesetting: !!ENV?.FEATURES?.explicit_latex_typesetting,
        locale: ENV?.LOCALE ?? 'en',
        showYoutubeAdOverlay: ENV?.FEATURES?.youtube_overlay,
      }),
    50,
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
  document.querySelectorAll('.communication_message').forEach(message => {
    message.addEventListener('click', e => {
      const entry = e.target.closest('.add_entry_link')
      if (!entry) return
      e.preventDefault()

      // Find and hide reply message
      const reply = message.querySelector('.reply_message')
      if (reply) reply.style.display = 'none'

      // Clone the blank response template
      const blankResponse = message.querySelector('.communication_sub_message.blank')
      if (blankResponse === null) return

      const response = blankResponse.cloneNode(true)
      response.classList.remove('blank')
      response.style.display = 'block'

      // Insert the response before the reply element
      if (reply) reply.parentNode.insertBefore(response, reply)

      // Unfortunately we still need jQuery for the RCE launch because
      // the RCE uses the jQuery event system
      const textarea = response.querySelector('textarea.rich_text')
      if (textarea) {
        const id = uniqueId('textarea_')
        textarea.id = id
        $(document).triggerHandler('richTextStart', $('#' + id))
      }

      // Focus and select the first textarea
      const firstTextarea = response.querySelector('textarea')
      if (firstTextarea) {
        firstTextarea.focus()
        firstTextarea.select()
      }
    })
  })
}

function showAndHideRCEWhenAsked() {
  // Note: We're keeping jQuery event handling here because:
  // 1. Custom events with data like 'richTextStart' are handled differently in jQuery vs native
  // 2. Much of the existing code uses triggerHandler() to pass jQuery elements
  // 3. RichContentEditor expects jQuery elements
  //
  // TODO: Implement a way to handle rich text editing without relying on jQuery, but
  // that will require native event handling that can handle complex data, and also
  // modifying the RCE to match.

  const $document = $(document)

  $document.on('richTextStart', (_e, $editor) => {
    if (!$editor || $editor.length === 0) return

    // Ensure we're working with a jQuery object as RichContentEditor expects
    if (!($editor instanceof $)) $editor = $($editor)
    if (!$editor || $editor.length === 0) return
    RichContentEditor.loadNewEditor($editor, {focus: true})
  })

  $document.on('richTextEnd', (_e, $editor) => {
    if (!$editor || $editor.length === 0) return

    // Ensure we're working with a jQuery object as RichContentEditor expects
    if (!($editor instanceof $)) $editor = $($editor)
    if (!$editor || $editor.length === 0) return
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

          if (s.user_id == user_id) {
            submission = s
          }
        }
        if (submission) {
          const comment =
            submission.submission_comments[submission.submission_comments.length - 1]
              .submission_comment
          comment.post_date = datetimeString(comment.created_at)
          comment.message = comment.formatted_body || comment.comment
          $message.fillTemplateData({
            data: comment,
            htmlValues: ['message'],
          })
        }
      } else {
        const entry = data.discussion_entry
        entry.post_date = datetimeString(entry.created_at)
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
  // vvvvvvvvvvvvvvvvv BEGIN stuff for making pretty dates vvvvvvvvvvvvvvvvvv
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  let timeAgoEvents = []
  function timeAgoRefresh() {
    timeAgoEvents = Array.from(document.querySelectorAll('.time_ago_date')).filter(
      $.expr.filters.visible,
    )
    processNextTimeAgoEvent()
  }
  function processNextTimeAgoEvent() {
    const eventElement = timeAgoEvents.shift()
    if (eventElement) {
      const $event = $(eventElement),
        date = $event.data('parsed_date') || Date.parse($event.data('timestamp') || '')
      if (date) {
        const diff = new Date() - date
        const relative = diff < 24 * 3600 * 1000 // less than 24 hours ago
        $event.data('timestamp', date.toISOString())
        $event.data('parsed_date', date)
        $event.text(relative ? fromNow(date) : formatTimeAgoTitle(date))
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
          onFetchSuccess: () => {
            $('.module-sequence-footer-right').prepend($('#mark-as-done-container'))
            $('#mark-as-done-container').css({'margin-right': '4px'})
          },
        })
      })
      .catch(ex => {
        console.error(ex)
        captureException(ex)
      })
  }
}

function showRightSideHiddenItemsWhenClicked() {
  // this is for things like the to-do, recent items and upcoming, it
  // happened a lot so rather than duplicating it everywhere I stuck it here
  const rightSide = document.getElementById('right-side')
  if (!rightSide) return

  rightSide.addEventListener('click', event => {
    const target = event.target.closest('.more_link')
    if (!target) return

    event.preventDefault()

    const ul = target.closest('ul')
    const hiddenCSS = ':scope > li[style*="display: none"], :scope > li[hidden]'
    const hiddenItems = Array.from(ul.querySelectorAll(hiddenCSS))

    // Show all hidden items
    hiddenItems.forEach(item => {
      item.style.display = ''
      if (item.hasAttribute('hidden')) item.removeAttribute('hidden')
    })

    // Remove the "more" list item
    target.closest('li')?.remove()

    // if they are using the keyboard to navigate (they hit enter on the link instead of actually
    // clicking it) then put focus on the first of the now-visible items--otherwise, since the
    // .more_link is hidden, focus would be completely lost and leave a blind person stranded.
    // don't want to set focus if came from a mouse click because then you'd have 2 of the tooltip
    // bubbles staying visible, see #9211
    if (event.screenX === 0 && hiddenItems.length > 0) {
      const focusableCSS = 'a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
      hiddenItems[0].querySelector(focusableCSS)?.focus()
    }
  })
}

function confirmAndDeleteRightSideTodoItemsWhenClicked() {
  const rightSide = document.getElementById('right-side')
  if (!rightSide) return

  rightSide.addEventListener('click', event => {
    const target = event.target.closest('.disable-todo-item-link')
    if (!target) return

    event.preventDefault()

    // Find the item to be removed (equivalent to $(this).parents('li, div.topic_message').last())
    const item = target.closest('li') || target.closest('div.topic_message')
    if (!item) return

    // Find previous item for focus management
    const todoList = target.closest('.to-do-list')
    let toFocus

    if (todoList) {
      const parentLi = target.closest('li')
      const prevItem = parentLi.previousElementSibling
      if (prevItem) {
        toFocus = prevItem.querySelector('.disable-todo-item-link')
      }
    }

    if (!toFocus) {
      toFocus = document.querySelector('.todo-list-header')
    }

    // Get data attributes
    const url = target.dataset.apiHref
    const flashMessage = target.dataset.flashMessage

    // This is a complex part because confirmDelete is a jQuery plugin
    // We need to use the jQuery implementation for now since creating a full
    // native confirmation dialog with AJAX would be too complex
    const $item = $(item)
    $item.confirmDelete({
      url: url,
      noMessage: true,
      success() {
        if (flashMessage) {
          $.flashMessage(flashMessage)
        }

        // Use jQuery for animation for now (slideUp with callback)
        $(this).slideUp(function () {
          this.remove()
          toFocus?.focus()
        })
      },
    })
  })
}

// this really belongs in enhanced-user-content2/instructure_helper
// but it uses FilePreview to render the file preview overlay, and
// that has so many dependencies on things like @canvas/files/backbone/models/File.js
// this it'll be too time consuming to decouple it from canvas in our
// timeframe. Solve it for now by using postMessage from enhanced-user-content2
// (which we hope to decouple from canvas) to ask canvas to render the preview
function showFilePreviewInOverlayHandler({file_id, verifier, access_token, instfs_id, location}) {
  import('../react/showFilePreview')
    .then(module => {
      module.showFilePreview(file_id, verifier, access_token, instfs_id, location)
    })
    .catch(err => {
      showFlashAlert({
        message: I18n.t('Something went wrong loading the file previewer.'),
        type: 'error',
      })

      console.log(err)
    })
}

function wireUpFilePreview() {
  if (
    ENV?.PLATFORM_SERVICE_SPEEDGRADER_ENABLED &&
    window.location.href.includes('gradebook/speed_grader')
  ) {
    return
  }
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

export const registerFixDialogButtonsPlugin = () => {
  // Registers a jQuery plugin that converts button markup in dialogs
  // to proper jQueryUI dialog buttons. This is called during boot to
  // make the .fixDialogButtons() method available throughout the app.
  $.fn.fixDialogButtons = function () {
    return this.each(function () {
      const $dialog = $(this)
      const $buttons = $dialog.find('.button-container:last .btn, button[type=submit]')
      if ($buttons.length) {
        $dialog.find('.button-container:last, button[type=submit]').hide()
        let buttons = $.map($buttons.toArray(), button => {
          const $button = $(button)
          let classes = $button.attr('class') || ''
          const id = $button.attr('id')

          // if you add the class 'dialog_closer' to any of the buttons,
          // clicking it will cause the dialog to close
          if ($button.is('.dialog_closer')) {
            $button.off('.fixdialogbuttons')
            $button.on(
              'click.fixdialogbuttons',
              preventDefault(() => $dialog.dialog('close')),
            )
          }

          if ($button.prop('type') === 'submit' && $button[0].form) {
            classes += ' button_type_submit'
          }

          return {
            text: $button.text(),
            'data-text-while-loading': $button.data('textWhileLoading'),
            click: () => $button.click(),
            class: classes,
            id,
          }
        })
        // put the primary button(s) on the far right
        buttons = sortBy(buttons, button => (button.class.match(/btn-primary/) ? 1 : 0))
        $dialog.dialog('option', 'buttons', buttons)
      }
    })
  }
}

export function enhanceTheEntireUniverse() {
  ;[
    ellipsifyBreadcrumbs,
    bindKeyboardShortcutsHelpPanel,
    warnAboutRolesBeingSwitched,
    expandQuotedTextWhenClicked,
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
    showRightSideHiddenItemsWhenClicked,
    confirmAndDeleteRightSideTodoItemsWhenClicked,
    makeAllExternalLinksExternalLinks,
    wireUpFilePreview,
    setDialogCloseText,
    registerFixDialogButtonsPlugin,
  ].map(x => x())
}
