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

import I18n from 'i18n!submit_assignment'
import $ from 'jquery'
import _ from 'underscore'
import GoogleDocsTreeView from 'compiled/views/GoogleDocsTreeView'
import homework_submission_tool from 'jst/assignments/homework_submission_tool'
import HomeworkSubmissionLtiContainer from 'compiled/external_tools/HomeworkSubmissionLtiContainer'
import RCEKeyboardShortcuts from 'compiled/views/editor/KeyboardShortcuts' /* TinyMCE Keyboard Shortcuts for a11y */
import iframeAllowances from 'jsx/external_apps/lib/iframeAllowances'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import {uploadFile} from 'jsx/shared/upload_file'
import {
  submitContentItem,
  recordEulaAgreement,
  verifyPledgeIsChecked
} from './submit_assignment_helper'
import 'compiled/jquery.rails_flash_notifications'
import './jquery.ajaxJSON'
import './jquery.inst_tree'
import './jquery.instructure_forms' /* ajaxJSONPreparedFiles, getFormData */
import 'jqueryui/dialog'
import './jquery.instructure_misc_plugins' /* fragmentChange, showIf, /\.log\(/ */
import './jquery.templateData'
import './media_comments'
import './vendor/jquery.scrollTo'
import 'jqueryui/tabs'
import React from 'react'
import ReactDOM from 'react-dom'
import FileBrowser from 'jsx/shared/rce/FileBrowser'
import {ProgressCircle} from '@instructure/ui-progress'

var SubmitAssignment = {
  // This ensures that the tool links in the "More" tab (which only appears with 4
  // or more tools) behave properly when clicked
  moreToolsListClickHandler(event) {
    event.preventDefault()

    const tool = $(this).data('tool')
    const url = `/courses/${ENV.COURSE_ID}/external_tools/${tool.id}/resource_selection?homework=1&assignment_id=${ENV.SUBMIT_ASSIGNMENT.ID}`

    // create return view and attach postMessage listener for tools launched in dialog from the More tab
    SubmitAssignment.homeworkSubmissionLtiContainer.embedLtiLaunch(tool.get('id'))

    const width = tool.get('homework_submission').selection_width || tool.get('selection_width')
    const height = tool.get('homework_submission').selection_height || tool.get('selection_height')
    const title = tool.get('display_text')
    const $div = $('<div/>', {
      id: 'homework_selection_dialog',
      style: 'padding: 0; overflow-y: hidden;'
    }).appendTo($('body'))

    $div
      .append(
        $('<iframe/>', {
          frameborder: 0,
          src: url,
          allow: iframeAllowances(),
          id: 'homework_selection_iframe',
          tabindex: '0'
        }).css({width, height})
      )
      .bind('selection', (selectionEvent, _data) => {
        submitContentItem(selectionEvent.contentItems[0])
        $div.off('dialogbeforeclose', SubmitAssignment.dialogCancelHandler)
        $div.dialog('close')
      })
      .on('dialogbeforeclose', SubmitAssignment.dialogCancelHandler)
      .dialog({
        width: 'auto',
        height: 'auto',
        title,
        close() {
          $div.remove()
        }
      })

    const tabHelperHeight = 35
    $div.append(
      $('<div/>', {id: 'tab-helper', style: 'height:0px;padding:5px', tabindex: '0'})
        .focus(function() {
          $(this).height(`${tabHelperHeight}px`)
          const joke = document.createTextNode(
            I18n.t('Q: What goes black, white, black, white?  A: A panda rolling down a hill.')
          )
          this.appendChild(joke)
        })
        .blur(function() {
          $(this)
            .html('')
            .height('0px')
        })
    )

    return $div
  },

  beforeUnloadHandler(e) {
    return (e.returnValue = I18n.t('Changes you made may not be saved.'))
  },
  dialogCancelHandler(event, ui) {
    const r = confirm(I18n.t('Are you sure you want to cancel? Changes you made may not be saved.'))
    if (r == false) {
      event.preventDefault()
    }
  }
}

window.submissionAttachmentIndex = -1

RichContentEditor.preloadRemoteModule()

$(document).ready(function() {
  let submitting = false,
    submissionForm = $('.submit_assignment_form')

  const homeworkSubmissionLtiContainer = new HomeworkSubmissionLtiContainer(
    '#submit_from_external_tool_form'
  )

  // store for launching of tools from the More tab
  SubmitAssignment.homeworkSubmissionLtiContainer = homeworkSubmissionLtiContainer

  // Add the Keyboard shortcuts info button
  if (!ENV.use_rce_enhancements) {
    const keyboardShortcutsView = new RCEKeyboardShortcuts()
    keyboardShortcutsView.render().$el.insertBefore($('.switch_text_entry_submission_views:first'))
  }

  // grow and shrink the comments box on focus/blur if the user
  // hasn't entered any content.
  submissionForm
    .delegate('#submission_comment', 'focus', function(e) {
      const box = $(this)
      if (box.val().trim() === '') {
        box.addClass('focus_or_content')
      }
    })
    .delegate('#submission_comment', 'blur', function(e) {
      const box = $(this)
      if (box.val().trim() === '') {
        box.removeClass('focus_or_content')
      }
    })

  submissionForm.submit(function(event) {
    const self = this
    const $turnitin = $(this).find('.turnitin_pledge')
    const $vericite = $(this).find('.vericite_pledge')
    if ($('#external_tool_submission_type').val() == 'online_url_to_file') {
      event.preventDefault()
      event.stopPropagation()
      uploadFileFromUrl()
      return
    }

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
        required: ['body']
      })
    if (!valid) return false

    $(this)
      .find("button[type='submit']")
      .text(I18n.t('messages.submitting', 'Submitting...'))
    $(this)
      .find('button')
      .attr('disabled', true)

    if ($(this).attr('id') == 'submit_online_upload_form') {
      event.preventDefault() && event.stopPropagation()
      const fileElements = $(this)
        .find('input[type=file]:visible')
        .filter(function() {
          return $(this).val() !== ''
        })

      const emptyFiles = $(this)
        .find('input[type=file]:visible')
        .filter(function() {
          return this.files[0] && this.files[0].size === 0
        })

      const uploadedAttachmentIds = $(this)
        .find('#submission_attachment_ids')
        .val()

      const reenableSubmitButton = function() {
        $(self)
          .find('button[type=submit]')
          .text(I18n.t('#button.submit_assignment', 'Submit Assignment'))
          .prop('disabled', false)
      }

      const progressIndicator = function(event) {
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
          const ids = (data['submission[attachment_ids]'] || '').split(',')
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
        error(data) {
          submissionForm
            .find("button[type='submit']")
            .text(I18n.t('messages.submit_failed', 'Submit Failed, please try again'))
          submissionForm.find('button').attr('disabled', false)
        }
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
    if (hash && hash.indexOf('#submit') == 0) {
      $('.submit_assignment_link').triggerHandler('click', true)
      if (hash == '#submit_google_doc') {
        $('#submit_assignment_tabs').tabs('select', '.google_doc_form')
      }
    }
  })

  $('input.turnitin_pledge').click(e => {
    recordEulaAgreement('#eula_agreement_timestamp', e.target.checked)
  })

  $('.submit_assignment_link').click(function(event, skipConfirmation) {
    event.preventDefault()
    const late = $(this).hasClass('late')
    const now = new Date()
    if (late && !skipConfirmation) {
      let result
      if ($('.resubmit_link').length > 0) {
        result = confirm(
          I18n.t(
            'messages.now_overdue',
            'This assignment is now overdue.  Any new submissions will be marked as late.  Continue anyway?'
          )
        )
      } else {
        result = confirm(
          I18n.t('messages.overdue', 'This assignment is overdue.  Do you still want to submit it?')
        )
      }
      if (!result) {
        return
      }
    }
    $('#submit_assignment').show()
    $('.submit_assignment_link').hide()
    $('html,body').scrollTo($('#submit_assignment'))
    createSubmitAssignmentTabs()
    homeworkSubmissionLtiContainer.loadExternalTools()
    $('#submit_assignment_tabs li')
      .first()
      .focus()
  })

  $('.switch_text_entry_submission_views').click(function(event) {
    event.preventDefault()
    RichContentEditor.callOnRCE($('#submit_online_text_entry_form textarea:first'), 'toggle')
    //  todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(this)
      .siblings('.switch_text_entry_submission_views')
      .andSelf()
      .toggle()
  })

  $('.submit_assignment_form .cancel_button').click(() => {
    $('#submit_assignment').hide()
    $('.submit_assignment_link').show()
  })

  function createSubmitAssignmentTabs() {
    $('#submit_assignment_tabs').tabs({
      beforeActivate(event, ui) {
        // determine if this is an external tool
        if (ui.newTab.context.classList.contains('external-tool')) {
          const externalToolId = $(ui.newTab.context).data('id')
          homeworkSubmissionLtiContainer.embedLtiLaunch(externalToolId)
        }
      },
      activate(event, ui) {
        if (ui.newTab.find('a').hasClass('submit_online_text_entry_option')) {
          const $el = $('#submit_online_text_entry_form textarea:first')
          if (!RichContentEditor.callOnRCE($el, 'exists?')) {
            RichContentEditor.loadNewEditor($el, {manageParent: true})
          }
        }

        if (ui.newTab.attr('aria-controls') === 'submit_google_doc_form') {
          listGoogleDocs()
        }

        if (ui.newTab.context.classList[0] === 'external-tool') {
          ui.newTab.find('a').click()
        }
      },
      create(event, ui) {
        if (ui.tab.find('a').hasClass('submit_online_text_entry_option')) {
          const $el = $('#submit_online_text_entry_form textarea:first')
          if (!RichContentEditor.callOnRCE($el, 'exists?')) {
            RichContentEditor.loadNewEditor($el, {manageParent: true})
          }
        }

        // list Google Docs if Google Docs tab is active
        if (ui.tab.attr('aria-controls') === 'submit_google_doc_form') {
          listGoogleDocs()
        }
      }
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

  $('.add_another_file_link')
    .click(function(event) {
      event.preventDefault()
      $('#submission_attachment_blank')
        .clone(true)
        .removeAttr('id')
        .show()
        .insertBefore(this)
        .find('input')
        .attr('name', 'attachments[' + ++submissionAttachmentIndex + '][uploaded_data]')
      toggleRemoveAttachmentLinks()
    })
    .click()

  $('.remove_attachment_link').click(function(event) {
    event.preventDefault()
    $(this)
      .parents('.submission_attachment')
      .remove()
    checkAllowUploadSubmit()
    toggleRemoveAttachmentLinks()
  })

  function listGoogleDocs() {
    const url = window.location.pathname + '/list_google_docs'
    $.get(
      url,
      {},
      (data, textStatus) => {
        const tree = new GoogleDocsTreeView({model: data})
        $('div#google_docs_container').html(tree.el)
        tree.render()
        tree.on('activate-file', file_id => {
          $('#submit_google_doc_form')
            .find("input[name='google_doc[document_id]']")
            .val(file_id)
          const submitButton = $('#submit_google_doc_form').find('[disabled].btn-primary')
          if (submitButton) {
            submitButton.removeAttr('disabled')
          }
        })
      },
      'json'
    )
  }

  $('#auth-google').live('click', function(e) {
    e.preventDefault()
    const href = $(this).attr('href')
    reauth(href)
  })

  // Post message for anybody to listen to //
  if (window.opener) {
    try {
      window.opener.postMessage(
        {
          type: 'event',
          payload: 'done'
        },
        window.opener.location.toString()
      )
    } catch (e) {
      console.error(e)
    }
  }

  function reauth(auth_url) {
    const modal = window.open(
      auth_url,
      'Authorize Google Docs',
      'menubar=no,directories=no,location=no,height=500,width=500'
    )
    $(window).on('message', event => {
      event = event.originalEvent
      if (
        !event ||
        !event.data ||
        event.origin !== window.location.protocol + '//' + window.location.host
      )
        return

      if (event.data.type == 'event' && event.data.payload == 'done') {
        if (modal) modal.close()

        reloadGoogleDrive()
      }
    })
  }

  function reloadGoogleDrive() {
    $('#submit_google_doc_form.auth').hide()
    $('#submit_google_doc_form.submit_assignment_form').removeClass('hide')
    listGoogleDocs()
  }

  function toggleRemoveAttachmentLinks() {
    $('#submit_online_upload_form .remove_attachment_link').showIf(
      $('#submit_online_upload_form .submission_attachment:not(#submission_attachment_blank)')
        .length > 1
    )
  }
  function checkAllowUploadSubmit() {
    // disable the submit button if any extensions are bad
    $('#submit_online_upload_form button[type=submit]').attr(
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
    fileInput
      .parent()
      .find('img')
      .attr('alt', altText)
  }
  $('.submission_attachment input[type=file]').live('change', function() {
    updateRemoveLinkAltText($(this))
    if ($(this).val() === '') return

    $(this).focus()
    const filename = getFilename($(this))
    $.screenReaderFlashMessage(I18n.t('File uploaded: %{filename}', {filename}))
    if (ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.length < 1) return

    const ext = $(this)
      .val()
      .split('.')
      .pop()
      .toLowerCase()
    $(this)
      .parent()
      .find('.bad_ext_msg')
      .showIf($.inArray(ext, ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS) < 0)
    checkAllowUploadSubmit()
  })
})

$('#submit_google_doc_form').submit(() => {
  // make sure we have a document selected
  if (
    !$('#submit_google_doc_form')
      .find("input[name='google_doc[document_id]']")
      .val()
  ) {
    return false
  }

  $('#uploading_google_doc_message').dialog({
    title: I18n.t('titles.uploading', 'Uploading Submission'),
    modal: true,
    overlay: {
      backgroundColor: '#000',
      opacity: 0.7
    }
  })
})

$(document).ready(() => {
  $('#submit_media_recording_form .submit_button')
    .attr('disabled', true)
    .text(I18n.t('messages.record_before_submitting', 'Record Before Submitting'))
  $('#media_media_recording_submission_holder .record_media_comment_link').click(event => {
    event.preventDefault()
    $('#media_media_recording_submission').mediaComment('create', 'any', (id, type) => {
      $('#submit_media_recording_form .submit_button')
        .attr('disabled', false)
        .text(I18n.t('buttons.submit_assignment', 'Submit Assignment'))
      $('#submit_media_recording_form .media_comment_id').val(id)
      $('#submit_media_recording_form .media_comment_type').val(type)
      $('#media_media_recording_submission_holder')
        .children()
        .hide()
      $('#media_media_recording_ready').show()
      $('#media_comment_submit_button').attr('disabled', false)
      $('#media_media_recording_thumbnail').attr('id', 'media_comment_' + id)
    })
  })
})

const $tools = $('#submit_from_external_tool_form')

function uploadFileFromUrl() {
  const preflightUrl = $('#homework_file_url').attr('href')
  const preflightData = {
    url: $('#external_tool_url').val(),
    name: $('#external_tool_filename').val(),
    content_type: $('#external_tool_content_type').val()
  }
  const uploadPromise = uploadFile(preflightUrl, preflightData, null)
    .then(attachment => {
      $('#external_tool_submission_type').val('online_upload')
      $('#external_tool_file_id').val(attachment.id)
      $tools.submit()
    })
    .catch(error => {
      console.log(error)
      $tools.find('.submit').text(I18n.t('file_retrieval_error', 'Retrieving File Failed'))
      $.flashError(
        I18n.t(
          'invalid_file_retrieval',
          'There was a problem retrieving the file sent from this tool.'
        )
      )
    })
  $tools.disableWhileLoading(uploadPromise, {
    buttons: {'.submit': I18n.t('getting_file', 'Retrieving File...')}
  })
  return uploadPromise
}

$('#submit_from_external_tool_form .tools li').live(
  'click',
  SubmitAssignment.moreToolsListClickHandler
)

export default SubmitAssignment
