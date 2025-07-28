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

import React from 'react'
import ReactDOM from 'react-dom'
import {createRoot} from 'react-dom/client'
import round from '@canvas/round'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {EmojiPicker, EmojiQuickPicker} from '@canvas/emoji'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* ajaxJSONFiles */
import {datetimeString} from '@canvas/datetime/date-functions'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* fragmentChange, showIf */
import '@canvas/loading-image'
import '@canvas/util/templateData'
import '@canvas/media-comments'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import '@canvas/rubrics/jquery/rubric_assessment'
import sanitizeHtml from 'sanitize-html-with-tinymce'
import {containsHtmlTags, formatMessage} from '@canvas/util/TextHelper'
import CheckpointGradeRoot from '../react/CheckpointGradeRoot'
import StudentAssetReportModalWrapper from '../react/StudentAssetReportModalWrapper'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import theme from '@instructure/canvas-theme'
import ready from '@instructure/ready'
import TextEntryAssetReportStatusLink from '../react/TextEntryAssetReportStatusLink'

const I18n = createI18nScope('submissions')
/* global rubricAssessment */

const rubricAssessments = ENV.rubricAssessments

$('#content').addClass('padless')
let fileIndex = 1
function submissionLoaded(data) {
  if (data.submission) {
    const d = []
    d.push(data)
    data = d
  }
  for (const jdx in data) {
    const submission = data[jdx].submission
    const comments = submission.visible_submission_comments || submission.submission_comments
    const anonymizableId = ENV.SUBMISSION.user_id ? 'user_id' : 'anonymous_id'
    // Be sure not to compare numeric and stringified user IDs
    if (submission[anonymizableId].toString() !== ENV.SUBMISSION[anonymizableId]) {
      continue
    }

    for (const idx in comments) {
      const comment = comments[idx].submission_comment || comments[idx]
      if ($('#submission_comment_' + comment.id).length > 0) {
        continue
      }
      const $comment = $('#comment_blank').clone(true).removeAttr('id')
      comment.posted_at = datetimeString(comment.created_at)
      $comment.fillTemplateData({
        data: comment,
        id: 'submission_comment_' + comment.id,
      })
      if (comment.media_comment_id) {
        const $media_comment_link = $('#comment_media_blank').clone(true).removeAttr('id')
        $media_comment_link.fillTemplateData({
          data: comment,
        })
        $comment.find('.comment').empty().append($media_comment_link.show())
      } else {
        for (const jdx_ in comment.attachments) {
          const attachment = comment.attachments[jdx_].attachment
          const $attachment = $('#comment_attachment_blank').clone(true).removeAttr('id')
          attachment.comment_id = comment.id
          $attachment.fillTemplateData({
            data: attachment,
            hrefValues: ['comment_id', 'id'],
          })
          $comment.find('.comment_attachments').append($attachment.show())
        }
      }
      $('.comments .comment_list').append($comment.show()).scrollTop(10000)
      if ($('.grading_comment').val() === comment.comment) {
        $('.grading_comment').val('')
      }
    }
    $('.comments .comment_list .play_comment_link').mediaCommentThumbnail('small')
    $('.save_comment_button').prop('disabled', false)
    if (submission) {
      showGrade(submission)
      $('.submission_details').fillTemplateData({
        data: submission,
      })
      $('#add_comment_form .comment_attachments').empty()
    }
  }
  $('.submission_header').loadingImage('remove')
}
function callIfSet(value, fn, ...additionalArgs) {
  return value == null ? '' : fn.call(this, value, ...additionalArgs)
}
function roundAndFormat(value) {
  return I18n.n(round(value, round.DEFAULT))
}
function formatGradeOptions() {
  if (ENV.GRADING_TYPE === 'letter_grade') {
    return {gradingType: ENV.GRADING_TYPE}
  }

  return {}
}
function showGrade(submission) {
  if (['pass', 'fail', 'complete', 'incomplete'].indexOf(submission.entered_grade) > -1) {
    $('.grading_box').val(submission.entered_grade)
  } else {
    $('.grading_box').val(
      callIfSet(submission.entered_grade, GradeFormatHelper.formatGrade, formatGradeOptions()),
    )
  }
  $('.late_penalty').text(callIfSet(-submission.points_deducted, roundAndFormat))
  $('.published_grade').text(callIfSet(submission.published_grade, GradeFormatHelper.formatGrade))
  $('.grade').text(callIfSet(submission.grade, GradeFormatHelper.formatGrade))

  if (submission.excused) {
    $('.entered_grade').text(I18n.t('Excused'))
  } else {
    const formattedGrade = callIfSet(
      submission.entered_grade,
      GradeFormatHelper.formatGrade,
      formatGradeOptions(),
    )
    $('.entered_grade').text(formattedGrade)
  }

  if (!submission.excused && submission.points_deducted) {
    $('.late-penalty-display').show()
  } else {
    $('.late-penalty-display').hide()
  }
}
function makeRubricAccessible($rubric) {
  $rubric.show()
  const $tabs = $rubric.find(':tabbable')
  const tabBounds = [$tabs.first()[0], $tabs.last()[0]]
  const keyCodes = {
    9: 'tab',
    13: 'enter',
    27: 'esc',
  }
  $('.hide_rubric_link').keydown(function (e) {
    if (keyCodes[e.which] === 'enter') {
      e.preventDefault()
      $(this).click()
    }
  })
  $tabs.each(function () {
    $(this).bind('keydown', e => {
      if (keyCodes[e.which] === 'esc') $('.hide_rubric_link').click()
    })
  })
  $(tabBounds).each(function (_e) {
    $(this).bind('keydown', function (e) {
      if (keyCodes[e.which] === 'tab') {
        const isLeavingHolder = $(this).is($(tabBounds).first()) ? e.shiftKey : !e.shiftKey
        if (isLeavingHolder) {
          e.preventDefault()
          const thisEl = this
          const target = $.grep(tabBounds, el => el != thisEl)
          $(target).focus()
        }
      }
    })
  })
  $rubric
    .siblings()
    .attr('data-hide_from_rubric', true)
    .end()
    .parentsUntil('#application')
    .siblings()
    .not('#aria_alerts')
    .attr('data-hide_from_rubric', true)
  $rubric.hide()
}
function toggleRubric($rubric) {
  const ariaSetting = $rubric.is(':visible')
  $('#application').find('[data-hide_from_rubric]').attr('aria-hidden', ariaSetting)
}
function closeRubric() {
  $('#rubric_holder').fadeOut(function () {
    toggleRubric($(this))
    $('.assess_submission_link').focus()
  })
}
function openRubric() {
  validateComments()
  $('#rubric_holder').fadeIn(function () {
    toggleRubric($(this))
    refreshEventHandlers()
    $(this).find('.hide_rubric_link').focus()
  })
}

function validateComments() {
  $('.rubric-comment textarea').each(function () {
    validateComment($(this))
  })
}

function validateComment($commentTextArea) {
  const newValue = $commentTextArea.val().trim()
  if (newValue !== '') {
    handleValidationClear($commentTextArea)
  } else {
    const $wrapper = $commentTextArea.closest('.rubric-comment')
    showErrorMessage($wrapper, I18n.t('A comment is required.'))
  }
}

function handleValidationClear($textArea) {
  const $wrapper = $textArea.closest('.rubric-comment')
  if ($wrapper.find('.error-message').length) {
    setTimeout(() => {
      $wrapper.find('.error-message').remove()
      $textArea.removeClass('error-textarea')
      $textArea.next('span').css('border-color', theme.colors?.ui?.surfaceAttention)
    }, 100)
  }
}

function refreshEventHandlers() {
  $('.add-comment-button-wrapper button')
    .off('click.commentHandler')
    .on('click.commentHandler', function () {
      const $row = $(this).closest('tr[data-testid="rubric-criterion"]')
      setTimeout(() => {
        const $comment = $row.find('.rubric-comment textarea')
        addEvents($comment)
      }, 500)
    })

  function addEvents($textAreas = $('.rubric-comment textarea')) {
    $textAreas
      .off('input.commentHandler blur.commentHandler') // avoid multiple bindings
      .on('input.commentHandler blur.commentHandler', function () {
        const $commentTextArea = $(this)
        validateComment($commentTextArea)
      })
  }

  addEvents()
}
function showErrorMessage(selector, message) {
  let errorContainer = selector.find('.error-message')
  if (errorContainer.length) return
  errorContainer = $('<div />', {
    class: 'error-message',
    tabindex: '-1',
  }).appendTo(selector)
  $('<i />', {
    class: 'icon-warning icon-Solid',
  }).appendTo(errorContainer)
  $('<span />', {
    role: 'alert',
    'aria-live': 'polite',
    tabindex: '-1',
  })
    .text(message)
    .appendTo(errorContainer)
  selector.find('textarea').addClass('error-textarea')
  selector.find('.error-textarea').next('span').css('border-color', theme.colors?.ui?.surfaceError)
}

function windowResize() {
  const $frame = $('#preview_frame')
  const margin_top = 20
  const height = window.screen.height - margin_top
  $frame.height(height)
  $('#rubric_holder').css({maxHeight: height - 50, overflow: 'auto', zIndex: 5})
  $('.comments').css({maxHeight: height})
}

function insertEmoji(emoji) {
  const $textarea = $('.grading_comment')
  $textarea.val((_i, text) => text + emoji.native)
  $textarea.focus()
}

// This `setup` function allows us to control when the setup is triggered.
// submissions.js requires this file and then immediately triggers it,
// while submissionsSpec.jsx triggers it after setup is complete.
export function setup() {
  $(document).ready(function () {
    // Render Checkpoint Score Boxes if applicable
    // The mount point is only available if checkpoints are enabled and the assignment has checkpoints
    // For reference the mount point is located in the "views/submissions/show.html.erb" file
    const mountPoint = document.getElementById('checkpoints-grade-inputs-mount-point')
    if (mountPoint) {
      const root = createRoot(mountPoint)
      const props = {
        assignment: {
          grading_type: ENV.GRADING_TYPE,
          total_score: ENV.SUBMISSION.submission.grade || '',
          checkpoint_submissions: [
            {
              tag: 'reply_to_topic',
              points_possible: ENV.CHECKPOINT_SUBMISSIONS.reply_to_topic.points_possible,
              submission_score: ENV.CHECKPOINT_SUBMISSIONS.reply_to_topic.entered_score,
              submission_id: ENV.CHECKPOINT_SUBMISSIONS.reply_to_topic.submission_id,
            },
            {
              tag: 'reply_to_entry',
              points_possible: ENV.CHECKPOINT_SUBMISSIONS.reply_to_entry.points_possible,
              submission_score: ENV.CHECKPOINT_SUBMISSIONS.reply_to_entry.entered_score,
              submission_id: ENV.CHECKPOINT_SUBMISSIONS.reply_to_entry.submission_id,
            },
          ],
        },
      }
      root.render(<CheckpointGradeRoot {...props} />)
    }

    if (ENV.EMOJIS_ENABLED) {
      ReactDOM.render(
        <EmojiPicker insertEmoji={insertEmoji} />,
        document.getElementById('emoji-picker-container'),
      )

      ReactDOM.render(
        <EmojiQuickPicker insertEmoji={insertEmoji} />,
        document.getElementById('emoji-quick-picker-container'),
      )
    }
    let textAreaErrorRoot
    const comments = document.getElementsByClassName('comment_content')
    Array.from(comments).forEach(comment => {
      const content = comment.dataset.content
      const formattedComment = containsHtmlTags(content)
        ? sanitizeHtml(content)
        : formatMessage(content)
      comment.innerHTML = formattedComment
    })
    const textAreaContainer = document.getElementById('textarea-container')
    const textAreaElement = document.querySelector('textarea.grading_comment')
    const clearTextAreaErrors = () => {
      if (textAreaErrorRoot) {
        textAreaErrorRoot.unmount()
        textAreaContainer?.classList.remove('error-outline')
        textAreaContainer?.removeAttribute('aria-label')
      }
    }
    textAreaElement?.addEventListener('input', _event => {
      // clear any errors when input changes
      clearTextAreaErrors()
    })
    $('.comments .comment_list .play_comment_link').mediaCommentThumbnail('small')
    $(window).bind('resize', windowResize).triggerHandler('resize')
    $('.comments_link').click(event => {
      event.preventDefault()
      $('.comments').slideToggle(() => {
        $('.comments .media_comment_content').empty()
        $('.comments textarea:visible').focus().select()
      })
    })
    $('.save_comment_button').click(_event => {
      $(document).triggerHandler('comment_change')
    })
    // post new comment but no grade
    $(document).bind('comment_change', _event => {
      $('.save_comment_button').prop('disabled', true)
      $('.submission_header').loadingImage()
      const url = $('.update_submission_url').attr('href')
      const method = $('.update_submission_url').attr('title')
      const formData = {
        'submission[assignment_id]': ENV.SUBMISSION.assignment_id,
        'submission[group_comment]': $('#submission_group_comment').prop('checked') ? '1' : '0',
      }
      const fileInputs = $("#add_comment_form input[type='file']")
      let hasFiles = false
      fileInputs.each((_idx, input) => {
        if (input.files.length > 0) {
          hasFiles = true
          return
        }
      })

      const anonymizableIdKey = ENV.SUBMISSION.user_id ? 'user_id' : 'anonymous_id'
      formData[`submission[${anonymizableIdKey}]`] = ENV.SUBMISSION[anonymizableIdKey]

      if ($('#media_media_recording:visible').length > 0) {
        const comment_id = $('#media_media_recording').data('comment_id')
        const comment_type = $('#media_media_recording').data('comment_type')
        formData['submission[media_comment_type]'] = comment_type || 'video'
        formData['submission[media_comment_id]'] = comment_id
        formData['submission[comment]'] = ''
      } else {
        if ($('.grading_comment').val() && $('.grading_comment').val != '') {
          formData['submission[comment]'] = $('.grading_comment').val()
        }
        if (!formData['submission[comment]'] && hasFiles) {
          formData['submission[comment]'] = I18n.t(
            'see_attached_files',
            'Please see attached files',
          )
        }
      }
      if (
        !formData['submission[comment]'] &&
        !formData['submission[media_comment_id]'] &&
        !hasFiles
      ) {
        $('.submission_header').loadingImage('remove')
        $('.save_comment_button').prop('disabled', false)
        textAreaElement?.focus()
        const message = I18n.t('Comment or file required to save')
        textAreaContainer?.classList.add('error-outline')
        textAreaContainer?.setAttribute('aria-label', message)
        const textAreaErrorContainer = document.getElementById('textarea-error-container')
        textAreaErrorRoot = createRoot(textAreaErrorContainer)
        textAreaErrorRoot.render(
          <FormattedErrorMessage
            message={message}
            margin="xx-small 0 small 0"
            iconMargin="0 xx-small xxx-small 0"
          />,
        )
        return
      }
      if (hasFiles) {
        $.ajaxJSONFiles(url + '.text', method, formData, fileInputs, submissionLoaded)
      } else {
        $.ajaxJSON(url, method, formData, submissionLoaded)
      }
    })
    $('.cancel_comment_button').click(_event => {
      $('.grading_comment').val('')
      $('.comments_link').click()
    })
    $('.grading_value').change(_event => {
      $(document).triggerHandler('grading_change')
    })
    // post new grade but no comments
    $(document).bind('grading_change', _event => {
      $('.save_comment_button').prop('disabled', true)
      $('.submission_header').loadingImage()
      const url = $('.update_submission_url').attr('href')
      const method = $('.update_submission_url').attr('title')
      const formData = {
        'submission[assignment_id]': ENV.SUBMISSION.assignment_id,
        'submission[user_id]': ENV.SUBMISSION.user_id,
        'submission[group_comment]': $('#submission_group_comment').prop('checked') ? '1' : '0',
      }
      if ($('.grading_value:visible').length > 0) {
        formData['submission[grade]'] = GradeFormatHelper.delocalizeGrade($('.grading_value').val())
        $.ajaxJSON(url, method, formData, submissionLoaded)
      } else {
        $('.submission_header').loadingImage('remove')
        $('.save_comment_button').prop('disabled', false)
      }
    })
    $('.attach_comment_file_link').click(event => {
      event.preventDefault()
      const $attachment = $('#comment_attachment_input_blank').clone(true).removeAttr('id')
      $attachment.find('input').attr('name', 'attachments[' + fileIndex++ + '][uploaded_data]')
      $('#add_comment_form .comment_attachments').append($attachment.slideDown())
    })
    document.addEventListener('change', function (event) {
      if (event.target.matches('#add_comment_form input[type="file"]')) {
        const inputElement = event.target
        const parentElement = inputElement.parentNode

        if (inputElement.files && inputElement.files.length > 0) {
          const fileName = inputElement.files[0].name

          // Hide the input element
          inputElement.style.height = '0'
          inputElement.style.width = '0'
          // Also remove the link to remove the input
          const deleteLink = Array.from(parentElement.children).find(child =>
            child.classList.contains('delete_comment_attachment_link'),
          )
          deleteLink?.remove()

          // Clear any existing errors
          clearTextAreaErrors()

          // Replace with Pill
          const container = document.createElement('div')
          parentElement.appendChild(container)
          const fileRoot = createRoot(container)
          const removeFile = (root, input) => {
            root.unmount()
            input.remove()
          }
          fileRoot.render(
            <Flex direction="column" margin="0 0 small 0">
              <Flex.Item>
                <Tag
                  text={<AccessibleContent alt={fileName}>{fileName}</AccessibleContent>}
                  dismissible={true}
                  onClick={() => removeFile(fileRoot, inputElement)}
                  data-testid="submission_comment_file_tag"
                />
              </Flex.Item>
            </Flex>,
          )
        } else {
          console.log('No file selected')
        }
      }
    })
    $('.delete_comment_attachment_link').click(function (event) {
      event.preventDefault()
      $(this)
        .parents('.comment_attachment_input')
        .slideUp(function () {
          $(this).remove()
        })
    })
    $('.save_rubric_button').click(function () {
      const $rubric = $(this).parents('#rubric_holder').find('.rubric')
      const submitted_data = rubricAssessment.assessmentData($rubric)
      const $rubricComments = $('.rubric-comment')

      let hasError = false
      $rubricComments.each(function () {
        const $wrapper = $(this)
        const $commentTextArea = $wrapper.find('textarea')

        if ($commentTextArea.length > 0 && $commentTextArea.val().trim() === '') {
          showErrorMessage($wrapper, I18n.t('A comment is required.'))
          hasError = true
        } else {
          // If the textarea has a value, remove any existing error styles/messages
          setTimeout(() => {
            $wrapper.find('.error-message').remove()
            $commentTextArea.removeClass('error-textarea')
            $commentTextArea.next('span').removeClass('error-textarea__outline')
          }, 1000)
        }
      })

      // If any comment is invalid, prevent submission
      if (hasError) {
        return false
      }

      const url = $('.update_rubric_assessment_url').attr('href')
      const method = 'POST'
      $rubric.loadingImage()
      $.ajaxJSON(url, method, submitted_data, data => {
        $rubric.loadingImage('remove')
        const assessment = data
        let found = false
        if (assessment.rubric_association) {
          rubricAssessment.updateRubricAssociation($rubric, data.rubric_association)
          delete assessment.rubric_association
        }
        for (const idx in rubricAssessments) {
          const a = rubricAssessments[idx].rubric_assessment
          if (a && assessment && assessment.id == a.id) {
            rubricAssessments[idx].rubric_assessment = assessment
            found = true
          }
        }
        if (!found) {
          if (!data.rubric_assessment) {
            data = {rubric_assessment: data}
          }
          rubricAssessments.push(data)
          const $option = $(document.createElement('option'))
          $option
            .val(assessment.id)
            .text(assessment.assessor_name)
            .attr('id', 'rubric_assessment_option_' + assessment.id)
          $('#rubric_assessments_select').prepend($option).val(assessment.id)
        }
        $('#rubric_assessment_option_' + assessment.id).text(assessment.assessor_name)
        $('#new_rubric_assessment_option').remove()
        $('#rubric_assessments_list').show()

        if (assessment.assessment_type === 'peer_review') {
          $('.save_rubric_button').remove()
        }

        /* the 500 timeout is due to the fadeOut in the closeRubric function, which defaults to 400.
          We need to ensure any warning messages are read out after the fadeOut manages the page focus
          so that any messages are not interrupted in voiceover utilities */
        setTimeout(() => {
          rubricAssessment.populateRubric($rubric, assessment, submitted_data)
          const submission = assessment.artifact
          if (submission) {
            showGrade(submission)
          }
        }, 500)
        closeRubric()
      })
    })
    $('#rubric_holder .rubric').css({width: 'auto', marginTop: 0})
    makeRubricAccessible($('#rubric_holder'))
    $('.hide_rubric_link').click(event => {
      event.preventDefault()
      closeRubric()
    })
    $('.assess_submission_link').click(event => {
      event.preventDefault()
      $('#rubric_assessments_select').change()
      if (ENV.mark_rubric_comments_read_url) {
        $.ajaxJSON(ENV.mark_rubric_comments_read_url, 'PUT', {}, () => {})
        $('.rubric_comment.unread_indicator').hide()
        $('.submission-details-header__rubric .assess_submission_link').attr('title', '')
      }
      openRubric()
    })
    $('#rubric_assessments_select')
      .change(function () {
        const id = $(this).val()
        let found = null
        for (const idx in rubricAssessments) {
          const assessment = rubricAssessments[idx].rubric_assessment
          if (assessment.id == id) {
            found = assessment
          }
        }

        const container = $('#rubric_holder .rubric')
        rubricAssessment.populateNewRubric(container, found, ENV.rubricAssociation)

        const current_user = !found || found.assessor_id == ENV.RUBRIC_ASSESSMENT.assessor_id
        $('#rubric_holder .save_rubric_button').showIf(current_user)
      })
      .change()
    $('.media_comment_link').click(event => {
      event.preventDefault()
      $('#media_media_recording').show()
      const $recording = $('#media_media_recording').find('.media_recording')
      $recording.mediaComment(
        'create',
        'any',
        (id, type) => {
          $('#media_media_recording').data('comment_id', id).data('comment_type', type)
          $(document).triggerHandler('comment_change')
          $('#add_comment_form').show()
          $('#media_media_recording').hide()
          $recording.empty()
        },
        () => {
          $('#add_comment_form').show()
          $('#media_media_recording').hide()
        },
      )
    })
    $(document).on('click', '#media_recorder_container a', _event => {
      $('#add_comment_form').show()
      $('#media_media_recording').hide()
    })
    $('.comments .comment_list')
      .delegate('.play_comment_link', 'click', function (event) {
        event.preventDefault()
        const comment_id = $(this)
          .parents('.comment_media')
          .getTemplateData({textValues: ['media_comment_id']}).media_comment_id
        if (comment_id) {
          $(this)
            .parents('.comment_media')
            .find('.media_comment_content')
            .mediaComment('show', comment_id, 'video', this)
        }
      })

      // this is to prevent the default behavior of loading the video inline from happening
      // the .delegate(".play_comment_link"... and the .delegate('a.instructure_inline_media_comment'...
      // are actually selecting the same links I just wanted to use the different selectors because
      // instructure.js uses 'a.instructure_inline_media_comment' as the selector for its .live handler
      // to show things inline.
      .delegate('a.instructure_inline_media_comment', 'click', e => {
        // dont let it bubble past this so it doesnt get to the .live handler to show the video inline
        e.preventDefault()
        e.stopPropagation()
      })

    showGrade(ENV.SUBMISSION.submission)
  })
}
// necessary for tests
export function teardown() {
  $(window).unbind('resize', windowResize)
  $(document).unbind('comment_change')
  $(document).unbind('grading_change')
}
$(document).fragmentChange((event, hash) => {
  if (hash === '#rubric') {
    $('.assess_submission_link:visible:first').click()
  } else if (hash.match(/^#comment/)) {
    let params = null
    try {
      params = JSON.parse(hash.substring(8))
    } catch (e) {
      // no-op
    }
    if (params && params.comment) {
      $('.grading_comment').val(params.comment)
    }
    $('.grading_comment').focus().select()
  }
})
INST.refreshGrades = function () {
  const url = $('.submission_data_url').attr('href')
  setTimeout(() => {
    $.ajaxJSON(url, 'GET', {}, submissionLoaded)
  }, 500)
}

$(document).ready(() => {
  window.addEventListener(
    'message',
    event => {
      if (event.data === 'refreshGrades') {
        INST.refreshGrades()
      }
    },
    false,
  )
})

ready(() => {
  const mountPoint = document.getElementById('asset_report_modal')
  if (mountPoint) {
    const root = createRoot(mountPoint)
    root.render(<StudentAssetReportModalWrapper />)
  }
})

ready(() => {
  const reports = ENV['ASSET_REPORTS']
  const assetProcessors = ENV['ASSET_PROCESSORS'] || []
  const assignmentName = ENV['ASSIGNMENT_NAME'] || ''
  const mountPoint = document.getElementById('asset_report_text_entry_status_container')

  // if lti_asset_processor FF is off, reports will be undefined
  if (!mountPoint || !reports || !assetProcessors || !assetProcessors.length) {
    return
  }

  if (mountPoint) {
    const root = createRoot(mountPoint)
    const attempt = mountPoint.dataset['attempt']
    root.render(
      <TextEntryAssetReportStatusLink
        reports={reports}
        assetProcessors={assetProcessors}
        assignmentName={assignmentName}
        attempt={attempt}
      />,
    )
  }
})
