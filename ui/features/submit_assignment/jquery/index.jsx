/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

// xsslint safeString.method I18n.t

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import axios from '@canvas/axios'
import HomeworkSubmissionLtiContainer from '../backbone/HomeworkSubmissionLtiContainer'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {recordEulaAgreement, verifyPledgeIsChecked} from './helper'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.tree'
import '@canvas/jquery/jquery.instructure_forms' /* ajaxJSONPreparedFiles, getFormData */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* fragmentChange, showIf, /\.log\(/ */
import '@canvas/util/templateData'
import '@canvas/media-comments'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jqueryui/tabs'
import React from 'react'
import ReactDOM from 'react-dom'
import FileBrowser from '@canvas/rce/FileBrowser'
import {ProgressCircle} from '@instructure/ui-progress'
import {Alert} from '@instructure/ui-alerts'
import Attachment from '../react/Attachment'
import {EmojiPicker, EmojiQuickPicker} from '@canvas/emoji'
import {captureException} from '@sentry/react'
import ready from '@instructure/ready'

const I18n = useI18nScope('submit_assignment')

let submissionAttachmentIndex = -1

RichContentEditor.preloadRemoteModule()

function insertEmoji(emoji) {
  const $textarea = $(this).find('.submission_comment_textarea')
  $textarea.val((_i, text) => text + emoji.native)
  $textarea.trigger('focus')
}

ready(function () {
  let submitting = false
  const submissionForm = $('.submit_assignment_form')

  const homeworkSubmissionLtiContainer = new HomeworkSubmissionLtiContainer()

  // Add screen reader message for student annotation assignments
  const accessibilityAlert = I18n.t(
    'The student annotation tab includes the document for the assignment. Tabs with additional submission types may also be available.'
  )
  const alertMount = () => document.getElementById('annotated-screenreader-alert')

  if (alertMount()) {
    ReactDOM.render(
      <Alert screenReaderOnly={true} liveRegion={alertMount} liveRegionPoliteness="assertive">
        {accessibilityAlert}
      </Alert>,
      alertMount()
    )
  }

  submissionForm.on('focus', '.textarea-emoji-container', function (_e) {
    const $container = $(this)
    const box = $container.find('.submission_comment_textarea')
    if (box.length && !box.hasClass('focus_or_content')) {
      box.addClass('focus_or_content')

      if (!ENV.EMOJIS_ENABLED) {
        return
      }

      const $emojiPicker = $container.find('.emoji-picker-container')
      if ($emojiPicker.length) {
        ReactDOM.render(<EmojiPicker insertEmoji={insertEmoji.bind(this)} />, $emojiPicker[0])
        $emojiPicker.show()
      }

      const $emojiQuickPicker = $container.find('.emoji-quick-picker-container')
      if ($emojiQuickPicker.length) {
        ReactDOM.render(
          <EmojiQuickPicker insertEmoji={insertEmoji.bind(this)} />,
          $emojiQuickPicker[0]
        )
        $emojiQuickPicker.show()
      }
    }
  })

  submissionForm.submit(function (event) {
    const self = this
    const $turnitin = $(this).find('.turnitin_pledge')
    const $vericite = $(this).find('.vericite_pledge')

    if (!verifyPledgeIsChecked($turnitin)) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }

    if (!verifyPledgeIsChecked($vericite)) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }

    const valid =
      !$(this).is('#submit_online_text_entry_form') ||
      $(this).validateForm({
        object_name: 'submission',
        required: ['body'],
        property_validations: {
          body(value) {
            const bodyHtml = document.createElement('div')
            bodyHtml.insertAdjacentHTML('beforeend', value)
            if (bodyHtml.querySelector(`[data-placeholder-for]`)) {
              return I18n.t('File has not finished uploading')
            }
          },
        },
      })
    if (!valid) return false

    RichContentEditor.closeRCE($('#submit_online_text_entry_form textarea:first'))

    $(this)
      .find("button[type='submit']")
      .text(I18n.t('messages.submitting', 'Submitting...'))
      .prop('disabled', true)

    if ($(this).attr('id') === 'submit_online_upload_form') {
      event.preventDefault() && event.stopPropagation()
      const fileElements = $(this)
        .find('input[type=file]:visible')
        .filter(function () {
          return $(this).val() !== ''
        })

      Object.values(webcamBlobs)
        .filter(blob => blob)
        .forEach(blob => {
          fileElements.push({
            name: 'webcam-picture.png',
            size: blob.size,
            type: blob.type,
            files: [blob],
          })
        })

      const emptyFiles = $(this)
        .find('input[type=file]:visible')
        .filter(function () {
          return this.files[0] && this.files[0].size === 0
        })

      const uploadedAttachmentIds = $(this).find('#submission_attachment_ids').val()

      const reenableSubmitButton = function () {
        $(self)
          .find('button[type=submit]')
          .text(I18n.t('#button.submit_assignment', 'Submit Assignment'))
          .prop('disabled', false)
      }

      const progressIndicator = function (event) {
        if (event.lengthComputable) {
          const mountPoint = document.getElementById('progress_indicator')

          if (mountPoint) {
            ReactDOM.render(
              <ProgressCircle
                screenReaderLabel={I18n.t('Uploading Progress')}
                size="x-small"
                valueMax={event.total}
                valueNow={event.loaded}
                meterColor="info"
                formatScreenReaderValue={({valueNow, valueMax}) =>
                  I18n.t('%{percent}% complete', {percent: Math.round((valueNow * 100) / valueMax)})
                }
              />,
              mountPoint
            )
          }
        }
      }

      // warn user if they haven't uploaded any files
      if (fileElements.length === 0 && uploadedAttachmentIds === '') {
        $.flashError(
          I18n.t('#errors.no_attached_file', 'You must attach at least one file to this assignment')
        )
        reenableSubmitButton()
        return false
      }

      // throw error if the user tries to upload an empty file
      // to prevent S3 from erroring
      if (emptyFiles.length) {
        $.flashError(I18n.t('Attached files must be greater than 0 bytes'))
        reenableSubmitButton()
        return false
      }

      // If there are restrictions on file type, don't accept submission if the file extension is not allowed
      if (ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.length > 0) {
        const subButton = $(this).find('button[type=submit]')
        let badExt = false
        $.each(uploadedAttachmentIds.split(','), (index, id) => {
          if (id.length > 0) {
            const ext = $('#submission_attachment_ids')
              .data(String(id))
              .split('.')
              .pop()
              .toLowerCase()
            if ($.inArray(ext, ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS) < 0) {
              badExt = true
              $.flashError(
                I18n.t(
                  '#errors.wrong_file_extension',
                  'The file you selected with extension "%{extension}", is not authorized for submission',
                  {extension: ext}
                )
              )
            }
          }
        })
        if (badExt) {
          subButton
            .text(I18n.t('#button.submit_assignment', 'Submit Assignment'))
            .prop('disabled', false)
          return false
        }
      }

      $.ajaxJSONPreparedFiles.call(this, {
        handle_files(attachments, data) {
          const ids = (data['submission[attachment_ids]'] || '').split(',').filter(id => id !== '')
          for (const idx in attachments) {
            ids.push(attachments[idx].id)
          }
          data['submission[attachment_ids]'] = ids.join(',')
          return data
        },
        context_code: $('#submit_assignment').data('context_code'),
        asset_string: $('#submit_assignment').data('asset_string'),
        intent: 'submit',
        file_elements: fileElements,
        formData: $(this).getFormData(),
        formDataTarget: 'url',
        url: $(this).attr('action'),
        onProgress: progressIndicator,
        success(data) {
          submitting = true
          const url = new URL(window.location.href)
          url.hash = ''
          if (window.ENV.CONFETTI_ENABLED && !data?.submission?.late) {
            url.searchParams.set('confetti', 'true')
          }
          window.location = url.toString()
        },
        error(_data) {
          submissionForm
            .find("button[type='submit']")
            .text(I18n.t('messages.submit_failed', 'Submit Failed, please try again'))
          submissionForm.find('button').prop('disabled', false)
        },
      })
    } else {
      submitting = true
    }
  })

  $(window).on('beforeunload', e => {
    if ($('#submit_assignment:visible').length > 0 && !submitting) {
      e.returnValue = I18n.t(
        'messages.not_submitted_yet',
        'You haven\'t finished submitting your assignment.  You still need to click "Submit" to finish turning it in.  Do you want to leave this page anyway?'
      )
      return e.returnValue
    }
  })

  $(document).fragmentChange((event, hash) => {
    if (hash && hash.indexOf('#submit') === 0) {
      $('.submit_assignment_link').triggerHandler('click', true)
    }
  })

  $('input.turnitin_pledge').click(e => {
    recordEulaAgreement('#eula_agreement_timestamp', e.target.checked)
  })

  function showSubmissionContent() {
    const el = $('#submit_assignment')
    el.show()
    el[0].scrollIntoView({behavior: 'smooth', block: 'end'})
    $('.submit_assignment_link').hide()
    createSubmitAssignmentTabs()
  }

  $('.submit_assignment_link').click(function (event, skipConfirmation) {
    event.preventDefault()
    const late = $(this).hasClass('late')
    if (late && !skipConfirmation) {
      let result
      if ($('.resubmit_link').length > 0) {
        // eslint-disable-next-line no-alert
        result = window.confirm(
          I18n.t(
            'messages.now_overdue',
            'This assignment is now overdue.  Any new submissions will be marked as late.  Continue anyway?'
          )
        )
      } else {
        // eslint-disable-next-line no-alert
        result = window.confirm(
          I18n.t('messages.overdue', 'This assignment is overdue.  Do you still want to submit it?')
        )
      }
      if (!result) {
        return
      }
    }

    showSubmissionContent()
  })

  $('.switch_text_entry_submission_views').click(function (event) {
    event.preventDefault()
    RichContentEditor.callOnRCE($('#submit_online_text_entry_form textarea:first'), 'toggle')
    //  todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(this).siblings('.switch_text_entry_submission_views').andSelf().toggle()
  })

  $('.submit_assignment_form .cancel_button').click(() => {
    RichContentEditor.closeRCE($('#submit_online_text_entry_form textarea:first'))
    $('#submit_assignment').hide()
    $('.submit_assignment_link').show()
  })

  function createSubmitAssignmentTabs() {
    $('#submit_assignment_tabs').tabs({
      beforeActivate(event, ui) {
        // determine if this is an external tool
        const $tabLink = ui.newTab.children('a:first-child')
        if ($tabLink.hasClass('external-tool')) {
          const externalToolId = $tabLink.data('id')
          homeworkSubmissionLtiContainer.embedLtiLaunch(externalToolId)
        }
      },
      activate(event, ui) {
        if (ui.newTab.find('a').hasClass('submit_online_text_entry_option')) {
          const $el = $('#submit_online_text_entry_form textarea:first')
          if (!RichContentEditor.callOnRCE($el, 'exists?')) {
            RichContentEditor.loadNewEditor($el, {
              manageParent: true,
              resourceType: 'assignment.submission',
            })
          }
        }

        const $tabLink = ui.newTab.children('a:first-child')
        if ($tabLink.hasClass('external-tool')) {
          $tabLink.trigger('click')
        }
      },
      create(event, ui) {
        if (ui.tab.find('a').hasClass('submit_online_text_entry_option')) {
          const $el = $('#submit_online_text_entry_form textarea:first')
          if (!RichContentEditor.callOnRCE($el, 'exists?')) {
            RichContentEditor.loadNewEditor($el, {
              manageParent: true,
              resourceType: 'assignment.submission',
            })
          }
        }
      },
    })
  }

  const fileBrowser = (
    <FileBrowser
      selectFile={fileInfo => {
        $('#submission_attachment_ids').val(fileInfo.id)
        $('#submission_attachment_ids').data(String(fileInfo.id), fileInfo.name)
        $.screenReaderFlashMessageExclusive(
          I18n.t('selected %{filename}', {filename: fileInfo.name})
        )
      }}
      allowUpload={false}
      useContextAssets={false}
    />
  )

  $('.toggle_uploaded_files_link').click(event => {
    event.preventDefault()
    const fileEl = $('#uploaded_files')
    if (fileEl.is(':hidden')) {
      $.screenReaderFlashMessage(I18n.t('File tree expanded'))
      ReactDOM.render(fileBrowser, document.getElementById('uploaded_files'))
    } else {
      $.screenReaderFlashMessage(I18n.t('File tree collapsed'))
    }
    fileEl.slideToggle()
  })

  const webcamBlobs = {}

  $('.add_another_file_link')
    .click(function (event) {
      event.preventDefault()
      const clone = $('#submission_attachment_blank').clone(true)

      clone.removeAttr('id').show().insertBefore(this)

      const wrapperDom = clone.find('.attachment_wrapper')[0]
      if (wrapperDom) {
        const index = ++submissionAttachmentIndex
        ReactDOM.render(
          <Attachment
            index={index}
            setBlob={blob => {
              webcamBlobs[index] = blob
            }}
          />,
          wrapperDom
        )
      }
      toggleRemoveAttachmentLinks()
    })
    .click()

  $('.remove_attachment_link').click(function (event) {
    event.preventDefault()
    $(this).parents('.submission_attachment').remove()
    checkAllowUploadSubmit()
    toggleRemoveAttachmentLinks()
  })

  // Post message for anybody to listen to //
  if (window.opener) {
    try {
      window.opener.postMessage(
        {
          type: 'event',
          payload: 'done',
        },
        window.opener.location.toString()
      )
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e)
      captureException(e)
    }
  }

  function toggleRemoveAttachmentLinks() {
    $('#submit_online_upload_form .remove_attachment_link').showIf(
      $('#submit_online_upload_form .submission_attachment:not(#submission_attachment_blank)')
        .length > 1
    )
  }
  function checkAllowUploadSubmit() {
    // disable the submit button if any extensions are bad
    $('#submit_online_upload_form button[type=submit]').prop(
      'disabled',
      !!$('.bad_ext_msg:visible').length
    )
  }
  function getFilename(fileInput) {
    return fileInput.val().replace(/^.*?([^\\\/]*)$/, '$1')
  }
  function updateRemoveLinkAltText(fileInput) {
    let altText = I18n.t('remove empty attachment')
    if (fileInput.val()) {
      const filename = getFilename(fileInput)
      altText = I18n.t('remove %{filename}', {filename})
    }
    fileInput.parent().find('img').attr('alt', altText)
  }
  $(document).on('change', '.submission_attachment input[type=file]', function () {
    updateRemoveLinkAltText($(this))
    if ($(this).val() === '') return

    $(this).focus()
    const filename = getFilename($(this))
    $.screenReaderFlashMessage(I18n.t('File selected for upload: %{filename}', {filename}))
    if (ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.length < 1) return

    const ext = $(this).val().split('.').pop().toLowerCase()
    $(this)
      .parents('.submission_attachment')
      .find('.bad_ext_msg')
      .showIf($.inArray(ext, ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS) < 0)
    checkAllowUploadSubmit()
  })

  const annotatedDocumentSubmission = $('.annotated-document-submission')
  if (ENV.SUBMISSION_ID && annotatedDocumentSubmission.length) {
    return axios
      .post('/api/v1/canvadoc_session', {
        submission_attempt: 'draft',
        submission_id: ENV.SUBMISSION_ID,
      })
      .then(result => {
        $(annotatedDocumentSubmission).attr('src', result.data.canvadocs_session_url)
      })
      .catch(error => {
        annotatedDocumentSubmission.replaceWith(
          `<div>${I18n.t('There was an error loading the document.')}</div>`
        )

        return error
      })
      .then(error => {
        if (ENV.FIRST_ANNOTATION_SUBMISSION) {
          showSubmissionContent()
        }

        if (error) {
          throw new Error(error)
        }
      })
  }
})

ready(() => {
  $('#submit_media_recording_form .submit_button')
    .prop('disabled', true)
    .text(I18n.t('messages.record_before_submitting', 'Record Before Submitting'))
  $('#media_media_recording_submission_holder .record_media_comment_link').click(event => {
    event.preventDefault()
    $('#media_media_recording_submission').mediaComment('create', 'any', (id, type) => {
      $('#submit_media_recording_form .submit_button')
        .prop('disabled', false)
        .text(I18n.t('buttons.submit_assignment', 'Submit Assignment'))
      $('#submit_media_recording_form .media_comment_id').val(id)
      $('#submit_media_recording_form .media_comment_type').val(type)
      $('#media_media_recording_submission_holder').children().hide()
      $('#media_media_recording_ready').show()
      $('#media_comment_submit_button').prop('disabled', false)
      $('#media_media_recording_thumbnail').attr('id', 'media_comment_' + id)
    })
  })
})
