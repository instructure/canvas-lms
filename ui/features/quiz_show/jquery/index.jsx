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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import MessageStudentsDialog from '@canvas/message-students-dialog'
import QuizArrowApplicator from '@canvas/quizzes/jquery/quiz_arrows'
import inputMethods from '@canvas/quizzes/jquery/quiz_inputs'
import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import PublishButtonView from '@canvas/publish-button-view'
import QuizLogAuditingEventDumper from '@canvas/quiz-log-auditing/jquery/dump_events'
import CyoeStats from '@canvas/conditional-release-stats/react/index'
import '@canvas/datetime/jquery' /* dateString, time_field, datetime_field */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* ifExists, confirmDelete */
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/message-students-dialog/jquery/message_students' /* messageStudents */
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'

const I18n = useI18nScope('quizzes.show')

$(document).ready(function () {
  if (ENV.QUIZ_SUBMISSION_EVENTS_URL) {
    QuizLogAuditingEventDumper(true)
  }

  $('#preview_quiz_button').click(_e => {
    $('#js-sequential-warning-dialogue div a').attr('href', $('#preview_quiz_button').attr('href'))
  })

  function ensureStudentsLoaded(callback) {
    if ($('#quiz_details').length) {
      return callback()
    } else {
      return $.get(ENV.QUIZ_DETAILS_URL, html => {
        $('#quiz_details_wrapper').html(html)
        callback()
      })
    }
  }

  const arrowApplicator = new QuizArrowApplicator()
  arrowApplicator.applyArrows()
  // quiz_show is being pulled into ember show for now. only hide inputs
  // when we don't have a .allow-inputs
  if (!$('.allow-inputs').length) {
    inputMethods.disableInputs('[type=radio], [type=checkbox]')
    inputMethods.setWidths()
  }

  $('form.edit_quizzes_quiz').on('submit', function (e) {
    e.preventDefault()
    e.stopImmediatePropagation()
    $(this).find('.loading').removeClass('hidden')
    const data = $(this).serializeArray()
    const url = $(this).attr('action')
    $.ajax({
      url,
      data,
      type: 'POST',
      success() {
        $('.edit_quizzes_quiz').parents('.alert').hide()
      },
    })
  })

  $('.delete_quiz_link').click(function (event) {
    event.preventDefault()
    let deleteConfirmMessage = I18n.t(
      'confirms.delete_quiz',
      'Are you sure you want to delete this quiz?'
    )
    const submittedCount = parseInt($('#quiz_details_wrapper').data('submitted-count'), 10)
    if (submittedCount > 0) {
      deleteConfirmMessage +=
        '\n\n' +
        I18n.t(
          'confirms.delete_quiz_submissions_warning',
          {
            one: 'Warning: 1 student has already taken this quiz. If you delete it, any completed submissions will be deleted and no longer appear in the gradebook.',
            other:
              'Warning: %{count} students have already taken this quiz. If you delete it, any completed submissions will be deleted and no longer appear in the gradebook.',
          },
          {count: submittedCount}
        )
    }
    $('nothing').confirmDelete({
      url: $(this).attr('href'),
      message: deleteConfirmMessage,
      success() {
        window.location.href = ENV.QUIZZES_URL
      },
    })
  })

  let hasOpenedQuizDetails = false
  $('.quiz_details_link').click(event => {
    event.preventDefault()
    $('#quiz_details_wrapper').disableWhileLoading(
      ensureStudentsLoaded(() => {
        const $quizResultsText = $('#quiz_details_text')
        $('#quiz_details').slideToggle()
        if (hasOpenedQuizDetails) {
          if (ENV.IS_SURVEY) {
            $quizResultsText.text(
              I18n.t('links.show_student_survey_results', 'Show Student Survey Results')
            )
          } else {
            $quizResultsText.text(
              I18n.t('links.show_student_quiz_results', 'Show Student Quiz Results')
            )
          }
        } else if (ENV.IS_SURVEY) {
          $quizResultsText.text(
            I18n.t('links.hide_student_survey_results', 'Hide Student Survey Results')
          )
        } else {
          $quizResultsText.text(
            I18n.t('links.hide_student_quiz_results', 'Hide Student Quiz Results')
          )
        }
        hasOpenedQuizDetails = !hasOpenedQuizDetails
      })
    )
  })

  $('.message_students_link').click(event => {
    event.preventDefault()
    ensureStudentsLoaded(() => {
      const submissionList = ENV.QUIZ_SUBMISSION_LIST
      const unsubmittedStudents = submissionList.UNSUBMITTED_STUDENTS
      const submittedStudents = submissionList.SUBMITTED_STUDENTS
      const haveTakenQuiz = I18n.t(
        'students_who_have_taken_the_quiz',
        'Students who have taken the quiz'
      )
      const haveNotTakenQuiz = I18n.t(
        'students_who_have_not_taken_the_quiz',
        'Students who have NOT taken the quiz'
      )
      const dialog = new MessageStudentsDialog({
        context: ENV.QUIZ.title,
        recipientGroups: [
          {name: haveTakenQuiz, recipients: submittedStudents},
          {name: haveNotTakenQuiz, recipients: unsubmittedStudents},
        ],
      })
      dialog.open()
    })
  })

  function openSendTo(event, open = true) {
    if (event) event.preventDefault()
    ReactDOM.render(
      <DirectShareUserModal
        open={open}
        sourceCourseId={ENV.COURSE_ID}
        contentShare={{content_type: 'quiz', content_id: ENV.QUIZ.id}}
        onDismiss={() => {
          openSendTo(null, false)
          $('.al-trigger').focus()
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  $('.direct-share-send-to-menu-item').click(openSendTo)

  function openCopyTo(event, open = true) {
    if (event) event.preventDefault()
    ReactDOM.render(
      <DirectShareCourseTray
        open={open}
        sourceCourseId={ENV.COURSE_ID}
        contentSelection={{quizzes: [ENV.QUIZ.id]}}
        onDismiss={() => {
          openCopyTo(null, false)
          $('.al-trigger').focus()
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  $('.direct-share-copy-to-menu-item').click(openCopyTo)

  $('#let_students_take_this_quiz_button').ifExists(function ($link) {
    const $unlock_for_how_long_dialog = $('#unlock_for_how_long_dialog')

    $link.click(() => {
      $unlock_for_how_long_dialog.dialog('open')
      return false
    })

    const $lock_at = $(this).find('.datetime_field')

    $unlock_for_how_long_dialog.dialog({
      autoOpen: false,
      modal: true,
      resizable: false,
      width: 400,
      buttons: {
        Unlock() {
          $('#quiz_unlock_form')
            // append this back to the form since it got moved to be a child of body when we called .dialog('open')
            .append($(this).dialog('destroy'))
            .find('#quiz_lock_at')
            .val($lock_at.data('iso8601'))
            .end()
            .submit()
        },
      },
      zIndex: 1000,
    })

    $lock_at.datetime_field()
  })

  $('#lock_this_quiz_now_link').ifExists($link => {
    $link.click(e => {
      e.preventDefault()
      $('#quiz_lock_form').submit()
    })
  })

  if ($('ul.page-action-list').find('li').length > 0) {
    $('ul.page-action-list').show()
  }

  $('#publish_quiz_form').formSubmit({
    beforeSubmit(_data) {
      $(this)
        .find('button')
        .prop('disabled', true)
        .text(I18n.t('buttons.publishing', 'Publishing...'))
    },
    success(_data) {
      $(this).find('button').text(I18n.t('buttons.already_published', 'Published!'))
      window.location.reload()
    },
  })

  function renderItemAssignToTray(open, returnFocusTo, itemProps) {
    ReactDOM.render(
      <ItemAssignToTray
        open={open}
        onClose={() => {
          ReactDOM.unmountComponentAtNode(document.getElementById('assign-to-mount-point'))
        }}
        onDismiss={() => {
          renderItemAssignToTray(false, returnFocusTo, itemProps)
          returnFocusTo.focus()
        }}
        itemType="quiz"
        iconType="quiz"
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        {...itemProps}
      />,
      document.getElementById('assign-to-mount-point')
    )
  }

  $('.assign-to-link').on('click keyclick', function (event) {
    event.preventDefault()
    const returnFocusTo = $(event.target).closest('ul').prev('.al-trigger')

    const courseId = event.target.getAttribute('data-quiz-context-id')
    const itemName = event.target.getAttribute('data-quiz-name')
    const itemContentId = event.target.getAttribute('data-quiz-id')
    const pointsString = event.target.getAttribute('data-quiz-points-possible')
    const pointsPossible = pointsString ? parseFloat(pointsString) : undefined
    renderItemAssignToTray(true, returnFocusTo, {
      courseId,
      itemName,
      itemContentId,
      pointsPossible,
    })
  })

  const $el = $('#quiz-publish-link')
  const model = new Quiz($.extend(ENV.QUIZ, {unpublishable: !$el.hasClass('disabled')}))
  const view = new PublishButtonView({model, el: $el})

  const refresh = function () {
    window.location.reload()
  }
  view.on('publish', refresh)
  view.on('unpublish', refresh)
  view.render()

  const graphsRoot = document.getElementById('crs-graphs')
  const detailsParent = document.getElementById('not_right_side')
  CyoeStats.init(graphsRoot, detailsParent)

  if ($('#assignment_external_tools').length) {
    AssignmentExternalTools.attach(
      $('#assignment_external_tools')[0],
      'assignment_view',
      parseInt(ENV.COURSE_ID, 10),
      parseInt(ENV.QUIZ.assignment_id, 10)
    )
  }
})
