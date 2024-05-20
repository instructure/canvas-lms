/* eslint-disable no-console, @typescript-eslint/no-shadow, eqeqeq, no-alert */
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

import FileUploadQuestionView from '../backbone/views/FileUploadQuestionView'
import File from '@canvas/files/backbone/models/File'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import $ from 'jquery'
import autoBlurActiveInput from './behaviors/autoBlurActiveInput'
import {isEqual, clone} from 'lodash'
import LDBLoginPopup from '../backbone/views/LDBLoginPopup'
import quizTakingPolice from './quiz_taking_police'
import QuizLogAuditing from '@canvas/quiz-log-auditing'
import QuizLogAuditingEventDumper from '@canvas/quiz-log-auditing/jquery/dump_events'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.toJSON'
import '@canvas/datetime/jquery' /* friendlyDatetime, friendlyDate */
import '@canvas/jquery/jquery.instructure_forms' /* getFormData, errorBox */
import 'jqueryui/dialog'
import '@canvas/rails-flash-notifications'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import '@canvas/quizzes/jquery/behaviors/quiz_selectmenu'

const I18n = useI18nScope('quizzes.take_quiz')

RichContentEditor.preloadRemoteModule()

let lastAnswerSelected = null
let lastSuccessfulSubmissionData = null
let showDeauthorizedDialog

const quizSubmission = (function () {
  let timeMod = 0
  const endAt = $('.end_at')
  const endAtParsed = endAt.text() && new Date(endAt.text())
  const dueAt = $('.due_at')
  const dueAtParsed = dueAt.text() && new Date(dueAt.text())
  const startedAt = $('.started_at')
  const $countdownSeconds = $('.countdown_seconds')
  const $timeRunningTimeRemaining = $('.time_running,.time_remaining')
  const $lastSaved = $('#last_saved_indicator')
  const $timerAutosubmitDisabled = $('.timer_autosubmit_disabled'),
    timerAutosubmitDisabledParsed = $timerAutosubmitDisabled.text() === 'true',
    $endAtWithoutTimeLimit = $('.end_at_without_time_limit'),
    endAtWithoutTimeLimitParsed =
      $endAtWithoutTimeLimit.text() && new Date($endAtWithoutTimeLimit.text())
  // $('.time_running,.time_remaining') is probably not yet loaded at the time
  const $timeRunningFunc = function () {
    if ($timeRunningTimeRemaining.length > 0) return $timeRunningTimeRemaining
    return $('.time_running,.time_remaining')
  }

  return {
    countDown: null,
    fiveMinuteDeadline: false,
    oneMinuteDeadline: false,
    submitting: false,
    dialogged: false,
    inBackground: false,
    contentBoxCounter: 0,
    lastSubmissionUpdate: new Date(),
    currentlyBackingUp: false,
    endAt,
    endAtParsed,
    timerAutosubmitDisabledParsed,
    endAtWithoutTimeLimitParsed,
    timeToEndWithoutTimeLimit:
      endAtWithoutTimeLimitParsed && endAtWithoutTimeLimitParsed - new Date(),
    startedAt,
    hasTimeLimit: !!ENV.QUIZ.time_limit,
    timeLeft: parseInt($('.time_left').text(), 10) * 1000,
    timeToDueDate: dueAtParsed - new Date(),
    oneAtATime: $('#submit_quiz_form').hasClass('one_question_at_a_time'),
    cantGoBack: $('#submit_quiz_form').hasClass('cant_go_back'),
    finalSubmitButtonClicked: false,
    clockInterval: 500,
    backupsDisabled: document.location.search.search(/backup=false/) > -1,
    clearAccessCode: true,
    updateSubmission(repeat, autoInterval) {
      /**
       * Transient: CNVS-9844
       * Disable auto-backups if backup=true was passed as a query parameter.
       *
       * This is required to test updating questions via the API.
       */
      if (quizSubmission.backupsDisabled) {
        console.log('[updateSubmission] Aborting because backups are disabled')
        return
      }

      if (quizSubmission.submitting && !repeat) {
        console.log(
          '[updateSubmission] Aborting because submission is in process and repeat is disabled'
        )
        return
      }
      const now = new Date()
      if (!autoInterval && now - quizSubmission.lastSubmissionUpdate < 1000) {
        return
      }
      if (quizSubmission.currentlyBackingUp) {
        console.log('[updateSubmission] Aborting because submission is currently being backed up')
        return
      }

      quizSubmission.currentlyBackingUp = true
      quizSubmission.lastSubmissionUpdate = new Date()
      const data = $('#submit_quiz_form').getFormData()

      $('.question_holder .question').each(function () {
        const value = $(this).hasClass('marked') ? '1' : ''
        data[$(this).attr('id') + '_marked'] = value
      })

      $lastSaved.text(I18n.t('saving', 'Saving...'))
      const url = $('.backup_quiz_submission_url').attr('href')
      ;(function (submissionData) {
        // Need a shallow clone of the data here because $.ajaxJSON modifies in place
        const thisSubmissionData = clone(submissionData)
        // If this is a timeout-based submission and the data is the same as last time,
        // palliate the server by skipping the data submission
        if (
          !quizSubmission.inBackground &&
          repeat &&
          isEqual(submissionData, lastSuccessfulSubmissionData)
        ) {
          $lastSaved.text(
            I18n.t('saving_not_needed', 'No new data to save. Last checked at %{t}', {
              t: $.friendlyDatetime(new Date()),
            })
          )

          quizSubmission.currentlyBackingUp = false

          setTimeout(() => {
            quizSubmission.updateSubmission(true, true)
          }, 30000)
          return
        }
        $.ajaxJSON(
          url,
          'PUT',
          submissionData,
          // Success callback
          data => {
            lastSuccessfulSubmissionData = thisSubmissionData
            $lastSaved.text(
              I18n.t('saved_at', 'Quiz saved at %{t}', {t: $.friendlyDatetime(new Date())})
            )
            quizSubmission.currentlyBackingUp = false
            quizSubmission.inBackground = false
            if (repeat) {
              setTimeout(() => {
                quizSubmission.updateSubmission(true, true)
              }, 30000)
            }
            if (data && data.end_at) {
              const endAtFromServer = Date.parse(data.end_at),
                submissionEndAt = Date.parse(endAt.text()),
                serverEndAtTime = endAtFromServer.getTime(),
                submissionEndAtTime = submissionEndAt.getTime()

              quizSubmission.timeLeft = data.time_left * 1000

              // if the new endAt from the server is different than our current endAt, then notify
              // the user that their time limit's changed and let updateTime do the rest.
              if (serverEndAtTime !== submissionEndAtTime) {
                if (serverEndAtTime > submissionEndAtTime) {
                  $.flashMessage(I18n.t('You have been given extra time on this attempt'))
                } else {
                  $.flashMessage(I18n.t('Your time for this quiz has been reduced.'))
                }

                quizSubmission.endAt.text(data.end_at)
                quizSubmission.endAtParsed = endAtFromServer
              }
            }
            // if timer autosubmission is disabled, we need to know when the fallback autosubmission time is
            if (data && data.hard_end_at) {
              quizSubmission.endAtWithoutTimeLimitParsed = Date.parse(data.hard_end_at)
            }
          },
          // Error callback
          (resp, ec) => {
            quizSubmission.currentlyBackingUp = false

            // has the user logged out?
            // TODO: support this redirect in LDB, by getting out of high security mode.
            if (ec.status === 401 || resp.status === 'unauthorized') {
              showDeauthorizedDialog()
              // since we popped up our own "not logged in" modal, skip the default error handler
              // see jquery.ajaxJSON.js defaultAjaxError
              if ($.inArray(ec, $.ajaxJSON.ignoredXHRs) === -1) {
                $.ajaxJSON.ignoredXHRs.push(ec)
              }
            } else if (ec.status === 403 || resp.status === 'forbidden') {
              // Something has been malaligned and we now need ruby to figure out where we should be
              window.location.reload()
            } else {
              // Connectivity lost?
              const current_user_id = window.ENV.current_user_id || 'none'
              $.ajaxJSON(
                window.location.protocol +
                  '//' +
                  window.location.host +
                  '/simple_response.json?user_id=' +
                  current_user_id +
                  '&rnd=' +
                  Math.round(Math.random() * 9999999),
                'GET',
                {},
                () => {},
                () => {
                  $.flashError(
                    I18n.t(
                      'errors.connection_lost',
                      "Connection to %{host} was lost.  Please make sure you're connected to the Internet before continuing.",
                      {host: window.location.host}
                    )
                  )
                }
              )
            }

            if (repeat) {
              setTimeout(() => {
                quizSubmission.updateSubmission(true)
              }, 30000)
            }
          },
          {
            timeout: 15000,
          }
        )
      })(data)
    },

    updateTime() {
      let currentTimeLeft = (quizSubmission.timeLeft -= quizSubmission.clockInterval)
      let currentTimeToDueDate = null
      if (quizSubmission.timeToDueDate > 0) {
        currentTimeToDueDate = quizSubmission.timeToDueDate -= quizSubmission.clockInterval
      }
      const now = new Date()

      timeMod = (timeMod + 1) % 120

      currentTimeLeft = quizSubmission.floorTimeLeft(currentTimeLeft)

      if (quizSubmission.countDown) {
        const s = new Date(quizSubmission.countDown - now.getTime()).getUTCSeconds()
        if (now.getTime() < quizSubmission.countDown) {
          $countdownSeconds.text(s)
        }

        if (s <= 0 && !quizSubmission.submitting && quizSubmission.shouldSubmitAtEndAt()) {
          quizSubmission.submitting = true
          quizSubmission.submitQuiz()
        }
      }

      if (quizSubmission.isTimeUp(currentTimeLeft) && !ENV.IS_PREVIEW) {
        quizSubmission.showTimeUpDialog(now)
      } else if (currentTimeToDueDate != null && currentTimeLeft > currentTimeToDueDate) {
        quizSubmission.showDueDateWarnings(currentTimeToDueDate)
        quizSubmission.showWarnings(currentTimeLeft)
      } else if (currentTimeLeft == null) {
        quizSubmission.showDueDateWarnings(currentTimeToDueDate)
      } else {
        quizSubmission.showWarnings(currentTimeLeft)
      }
      quizSubmission.updateTimeDisplay(currentTimeLeft)

      // if timer autosubmission is disabled, as a fallback we still autosubmit at the next end_at time
      if (quizSubmission.endAtWithoutTimeLimitParsed) {
        quizSubmission.timeToEndWithoutTimeLimit -= quizSubmission.clockInterval
      }
      if (
        quizSubmission.timerAutosubmitDisabledParsed &&
        !!quizSubmission.endAtWithoutTimeLimitParsed &&
        quizSubmission.endAtWithoutTimeLimitParsed.getTime() !==
          quizSubmission.endAtParsed.getTime() &&
        quizSubmission.timeToEndWithoutTimeLimit < 1000 &&
        !quizSubmission.submitting
      ) {
        quizSubmission.submitting = true
        quizSubmission.submitQuiz()
      }
    },

    shouldSubmitAtEndAt() {
      return (
        !quizSubmission.timerAutosubmitDisabledParsed ||
        (!!quizSubmission.endAtWithoutTimeLimitParsed &&
          quizSubmission.endAtWithoutTimeLimitParsed.getTime() ===
            quizSubmission.endAtParsed.getTime())
      )
    },

    floorTimeLeft(timeLeft) {
      if (timeLeft < 1000) {
        timeLeft = 0
      }

      return timeLeft
    },

    isTimeUp(currentTimeLeft) {
      return currentTimeLeft < 1000 && !quizSubmission.dialogged
    },
    showDueDateWarnings(currentTimeToDueDate) {
      if (
        currentTimeToDueDate > 30000 &&
        currentTimeToDueDate < 60000 &&
        !quizSubmission.oneMinuteDueDateDeadline
      ) {
        quizSubmission.oneMinuteDueDateDeadline = true
        $.flashMessage(
          I18n.t(
            'notices.due_date_one_minute_left',
            'One Minute Left Before Quiz Will Be Marked Late'
          )
        )
      } else if (
        currentTimeToDueDate > 250000 &&
        currentTimeToDueDate < 300000 &&
        !quizSubmission.fiveMinuteDueDateDeadline
      ) {
        quizSubmission.fiveMinuteDueDateDeadline = true
        $.flashMessage(
          I18n.t(
            'notices.due_date_five_minutes_left',
            'Five Minutes Left Before Quiz Will Be Marked Late'
          )
        )
      } else if (
        currentTimeToDueDate > 1770000 &&
        currentTimeToDueDate < 1800000 &&
        !quizSubmission.thirtyMinuteDueDateDeadline
      ) {
        quizSubmission.thirtyMinuteDueDateDeadline = true
        $.flashMessage(
          I18n.t(
            'notices.due_date_thirty_minutes_left',
            'Thirty Minutes Left Before Quiz Will Be Marked Late'
          )
        )
      }
    },
    showWarnings(currentTimeLeft) {
      if (currentTimeLeft > 30000 && currentTimeLeft < 60000 && !quizSubmission.oneMinuteDeadline) {
        quizSubmission.oneMinuteDeadline = true
        $.flashWarning(
          I18n.t('notices.submission_one_minute_left', 'This Quiz Will Be Submitted In One Minute'),
          5000
        )
      } else if (
        currentTimeLeft > 250000 &&
        currentTimeLeft < 300000 &&
        !quizSubmission.fiveMinuteDeadline
      ) {
        quizSubmission.fiveMinuteDeadline = true
        $.flashWarning(
          I18n.t(
            'notices.submission_five_minutes_left',
            'This Quiz Will Be Submitted In Five Minutes'
          ),
          5000
        )
      } else if (
        currentTimeLeft > 1770000 &&
        currentTimeLeft < 1800000 &&
        !quizSubmission.thirtyMinuteDeadline
      ) {
        quizSubmission.thirtyMinuteDeadline = true
        $.flashWarning(
          I18n.t(
            'notices.submission_thirty_minutes_left',
            'This Quiz Will Be Submitted In Thirty Minutes'
          ),
          5000
        )
      }
    },

    showTimeUpDialog(now) {
      quizSubmission.dialogged = true
      quizSubmission.countDown = new Date(now.getTime() + 10000)

      $.screenReaderFlashMessage(I18n.t('times_up', "Time's up! Submitting results in 10 seconds"))
      $('#times_up_dialog')
        .show()
        .dialog({
          title: I18n.t('titles.times_up', "Time's Up!"),
          width: 'auto',
          height: 'auto',
          modal: true,
          overlay: {
            backgroundColor: '#000',
            opacity: 0.7,
          },
          close() {
            if (!quizSubmission.submitting && quizSubmission.shouldSubmitAtEndAt()) {
              quizSubmission.submitting = true
              quizSubmission.submitQuiz()
            }
          },
          zIndex: 1000,
        })
    },

    getTimeElapsed() {
      $('.time_header').text(I18n.beforeLabel(I18n.t('labels.time_elapsed', 'Time Elapsed')))
      const now = new Date().getTime()
      const startedAt = Date.parse(quizSubmission.startedAt.text()).getTime()
      return now - startedAt
    },

    updateTimeDisplay(currentTimeLeft) {
      if (quizSubmission.hasTimeLimit) {
        quizSubmission.updateTimeString(currentTimeLeft)
      } else {
        quizSubmission.updateTimeString(quizSubmission.getTimeElapsed())
      }
    },

    updateTimeString(timeDiff) {
      const date = new Date(Math.abs(timeDiff))
      const yr = date.getUTCFullYear() - 1970
      const mon = date.getUTCMonth()
      const day = date.getUTCDate() - 1
      const hr = date.getUTCHours()
      const min = date.getUTCMinutes()
      const sec = date.getUTCSeconds()
      // Only checking min and sec since those are the only two forced to always display.
      // Plus, it's most likely either none of these will be NaN, or they all will be.
      if (Number.isNaN(Number(min)) || Number.isNaN(Number(sec))) {
        // display a helpful message instead of a NaN time
        $('.time_header').hide()
        $('.hide_time_link').hide()
        $('.time_running').css('color', '#EA0611')
        $timeRunningFunc().text(
          I18n.t(
            "Your browser connectivity may be slow or unstable. In spite of your browser's timer being disconnected, your answers will be recorded for an additional 5 minutes beyond the original time limit on this attempt."
          )
        )
        return
      }
      const times = []
      if (yr) {
        times.push(I18n.t('years_count', 'Year', {count: yr}))
      }
      if (mon) {
        times.push(I18n.t('months_count', 'Month', {count: mon}))
      }
      if (day) {
        times.push(I18n.t('days_count', 'Day', {count: day}))
      }
      if (hr) {
        times.push(I18n.t('hours_count', 'Hour', {count: hr}))
      }
      times.push(I18n.t('minutes_count', 'Minute', {count: min}))
      times.push(I18n.t('seconds_count', 'Second', {count: sec}))

      // the first time we set the time limit on the page, announce it via screenreader
      if (quizSubmission.hasTimeLimit && !$timeRunningFunc().text()) {
        $.screenReaderFlashMessage(
          I18n.t('time_remaining', 'You have %{time} remaining', {time: times.join(', ')})
        )
      }
      $timeRunningFunc().text(times.join(', '))
    },

    updateFinalSubmitButtonState() {
      const allQuestionsAnswered = $('#question_list li:not(.answered, .text_only)').length === 0
      const lastQuizPage = $('#submit_quiz_form').hasClass('last_page')
      const thisQuestionAnswered = $('div.question.answered').length > 0
      const oneAtATime = quizSubmission.oneAtATime

      const active = (oneAtATime && lastQuizPage && thisQuestionAnswered) || allQuestionsAnswered

      quizSubmission.toggleActiveButtonState('#submit_quiz_button', active)
    },

    updateQuestionIndicators(answer, questionId) {
      const listSelector = '#list_' + questionId
      const questionSelector = '#' + questionId
      const combinedId = listSelector + ', ' + questionSelector
      const $questionIcon = $(listSelector + ' i.placeholder')
      if (answer) {
        $(combinedId).addClass('answered')
        $questionIcon.addClass('icon-check').removeClass('icon-question')
        $questionIcon.find('.icon-text').text(I18n.t('question_answered', 'Answered'))
      } else {
        $(combinedId).removeClass('answered')
        $questionIcon.addClass('icon-question').removeClass('icon-check')
        $questionIcon.find('.icon-text').text(I18n.t('question_unanswered', "Haven't Answered Yet"))
      }
    },

    updateNextButtonState(id) {
      const $question = $('#' + id)
      quizSubmission.toggleActiveButtonState('button.next-question', $question.hasClass('answered'))
    },
    toggleActiveButtonState(selector, primary) {
      const addClass = primary ? 'btn-primary' : 'btn-secondary'
      const removeClass = primary ? 'btn-secondary' : 'btn-primary'
      $(selector).addClass(addClass).removeClass(removeClass)
    },
    submitQuiz() {
      const button = $('#submit_quiz_button')
      button.prop('disabled', true)
      const action = button.data('action')
      $('#submit_quiz_form').attr('action', action).submit()
    },
  }
})()

$(window).focus(_evt => {
  quizSubmission.updateSubmission()
})

$(window).blur(_evt => {
  quizSubmission.inBackground = true
})

$(document)
  .mousedown(event => {
    lastAnswerSelected = $(event.target).parents('.answer')[0]
  })
  .keydown(() => {
    lastAnswerSelected = null
  })

// fix screenreader focus for links to href="#target"
$("a[href^='#']")
  .not("a[href='#']")
  .click(function () {
    $($(this).attr('href')).attr('tabindex', -1).focus()
  })

$(function () {
  autoBlurActiveInput()

  if ($('#preview_mode_link').length === 0) {
    let unloadWarned = false

    window.addEventListener('beforeunload', e => {
      if (!quizSubmission.navigatingToRelogin) {
        if (
          !quizSubmission.submitting &&
          !quizSubmission.alreadyAcceptedNavigatingAway &&
          !unloadWarned
        ) {
          quizSubmission.clearAccessCode = true
          setTimeout(() => {
            unloadWarned = false
          }, 0)
          unloadWarned = true
          e.returnValue = I18n.t(
            'confirms.unfinished_quiz',
            "You're about to leave the quiz unfinished.  Continue anyway?"
          )
          return e.returnValue
        }
      }
    })
    window.addEventListener(
      'unload',
      _e => {
        const data = $('#submit_quiz_form').getFormData()
        const url = $('.backup_quiz_submission_url').attr('href')

        data.leaving = !!quizSubmission.clearAccessCode

        $.flashMessage(I18n.t('Saving...'))
        $.ajax({
          url,
          data,
          type: 'POST',
          dataType: 'json',
          async: false,
        })

        // since this is sync, a callback never fires to reset this
        quizSubmission.currentlyBackingUp = false
      },
      false
    )

    $(document).on('click', 'a', function (event) {
      if ($(this).closest('.ui-dialog,.mceToolbar,.ui-selectmenu').length > 0) return

      if ($(this).hasClass('no-warning')) {
        quizSubmission.alreadyAcceptedNavigatingAway = true
        return
      }

      if ($(this).hasClass('file_preview_link')) return

      if (!event.isDefaultPrevented()) {
        const url = $(this).attr('href') || ''
        let hashStripped = window.location.href
        if (hashStripped.indexOf('#')) {
          hashStripped = hashStripped.substring(0, hashStripped.indexOf('#'))
        }
        if (url.indexOf('#') == 0 || url.indexOf(hashStripped + '#') === 0) return
        const result = window.confirm(
          I18n.t(
            'confirms.navigate_away',
            "You're about to navigate away from this page.  Continue anyway?"
          )
        )
        if (!result) {
          event.preventDefault()
        } else {
          quizSubmission.alreadyAcceptedNavigatingAway = true
        }
      }
    })
  }
  const $questions = $('#questions')
  $('#question_list')
    .on('click', '.jump_to_question_link', function (event) {
      event.preventDefault()
      const $obj = $($(this).attr('href'))
      const scrollableSelector = ENV.MOBILE_UI ? '#content' : 'html,body'
      $(scrollableSelector).scrollTo($obj.parent())
      $obj.find(':input:first').focus().select()
    })
    .find('.list_question')
    .bind({
      mouseenter(_event) {
        const $this = $(this),
          data = $this.data()

        if (!quizSubmission.oneAtATime) {
          data.relatedQuestion || (data.relatedQuestion = $('#' + $this.attr('id').substring(5)))
          data.relatedQuestion.addClass('related')
        }
      },
      mouseleave(_event) {
        if (!quizSubmission.oneAtATime) {
          const relatedQuestion = $(this).data('relatedQuestion')
          relatedQuestion && relatedQuestion.removeClass('related')
        }
      },
      click(_event) {
        quizSubmission.clearAccessCode = false
      },
    })

  $questions.find('.group_top,.answer_select').bind({
    mouseenter(_event) {
      $(this).addClass('hover')
    },
    mouseleave(_event) {
      $(this).removeClass('hover')
    },
  })

  $('.file-upload-question-holder').each((i, el) => {
    const $el = $(el)
    const attachID = parseInt($el.find('input.attachment-id').val(), 10)
    const model = new File(ENV.ATTACHMENTS[attachID], {preflightUrl: ENV.UPLOAD_URL})
    const fileUploadView = new FileUploadQuestionView({el, model})

    if (attachID && attachID !== 0) {
      $el.find('.file-upload-box').addClass('file-upload-box-with-file')
    }

    fileUploadView.on('attachmentManipulationComplete', () => {
      quizSubmission.updateSubmission()
    })

    fileUploadView.render()
  })

  $questions
    .on('change', ':checkbox,:radio', function (_event) {
      const $answer = $(this).parents('.answer')
      setTimeout(() => {
        const $math = $answer.find('.math_equation_latex script')
        if ($math) {
          $(this).attr('aria-label', $math.text())
        }
      }, 1000)
      if (lastAnswerSelected == $answer[0]) {
        quizSubmission.updateSubmission()
      }
    })
    .on('mouseup', 'label.upload-label', _event => {
      quizSubmission.updateSubmission()
    })
    .on('change', ':text,textarea,select', function (event, update) {
      const $this = $(this)
      if ($this.hasClass('numerical_question_input')) {
        const val = numberHelper.parse($this.val())
        $this.val(
          Number.isNaN(Number(val)) ? '' : I18n.n(val.toFixed(4), {strip_insignificant_zeros: true})
        )
      }
      if ($this.hasClass('precision_question_input')) {
        const precisionQuestionInputVal = numberHelper.parse($this.val())
        const strVal = precisionQuestionInputVal.toString()
        const precision = strVal.length - (strVal.includes('.') ? 1 : 0)
        $this.val(
          Number.isNaN(precisionQuestionInputVal)
            ? ''
            : I18n.n(precisionQuestionInputVal.toPrecision(precision), {
                strip_insignificant_zeros: true,
                precision,
              })
        )
      }
      if (update !== false) {
        quizSubmission.updateSubmission()
      }
    })
    .on('keyup', '.numerical_question_input', function (_event) {
      const $this = $(this)
      const val = $this.val() + ''
      const $errorBox = $this.data('associated_error_box')

      if (val.match(/^$|^-$/) || numberHelper.validate(val)) {
        if ($errorBox) {
          $this.triggerHandler('click')
        }
      } else if (!$errorBox) {
        $this.errorBox(I18n.t('errors.only_numerical_values', 'only numerical values are accepted'))
      }
    })
    .on('click', '.flag_question', function (e) {
      e.preventDefault()
      const $question = $(this).parents('.question')
      $question.toggleClass('marked')
      $(this).attr('aria-checked', $question.hasClass('marked'))
      $('#list_' + $question.attr('id')).toggleClass('marked')

      let markedText
      if ($('#list_' + $question.attr('id')).hasClass('marked')) {
        markedText = I18n.t(
          'titles.come_back_later',
          'You marked this question to come back to later'
        )
      } else {
        markedText = ''
      }
      $('#list_' + $question.attr('id'))
        .find('.marked-status')
        .text(markedText)

      quizSubmission.updateSubmission()
    })
    .on('change', '.question_input', function (event, update, changedMap) {
      const $this = $(this)
      const tagName = this.tagName.toUpperCase()
      const id = $this.parents('.question').attr('id')
      let val = ''
      if (tagName === 'A') return
      if (changedMap) {
        // reduce redundant jquery lookups and other calls
        if (changedMap[id]) return
        changedMap[id] = true
      }

      if (tagName === 'TEXTAREA') {
        val = RichContentEditor.callOnRCE($this, 'get_code')
        const $tagInstance = $this
        $this
          .siblings('.rce_links')
          .find('.toggle_question_content_views_link')
          .click(function (event) {
            event.preventDefault()
            RichContentEditor.callOnRCE($tagInstance, 'toggle')
            //  todo: replace .andSelf with .addBack when JQuery is upgraded.
            $(this).siblings('.toggle_question_content_views_link').andSelf().toggle()
          })
      } else if ($this.attr('type') === 'text' || $this.attr('type') === 'hidden') {
        val = $this.val()
      } else if (tagName === 'SELECT') {
        const $selects = $this.parents('.question').find('select.question_input')
        val = !$selects.filter(function () {
          return !$(this).val()
        }).length
      } else {
        $this
          .parents('.question')
          .find('.question_input')
          .each(function () {
            if ($(this).prop('checked') || $(this).prop('selected')) {
              val = true
            }
          })
      }

      quizSubmission.updateQuestionIndicators(val, id)
      quizSubmission.updateFinalSubmitButtonState()
      quizSubmission.updateNextButtonState(id)
    })

  $questions.find('.question_input').trigger('change', [false, {}])

  const $hideTimeLink = $('.hide_time_link')
  $hideTimeLink.click(function (event) {
    event.preventDefault()
    if ($('.time_running').css('visibility') !== 'hidden') {
      $('.time_running').css('visibility', 'hidden')
      $(this).text(I18n.t('show_time_link', 'Show Time'))
    } else {
      $('.time_running').css('visibility', 'visible')
      $(this).text(I18n.t('hide_time_link', 'Hide Time'))
    }
  })

  $hideTimeLink.keydown(function (event) {
    // spacebar
    if (event.keyCode === 32) {
      $hideTimeLink.click()
    }
  })

  setTimeout(function () {
    $('#question_list .list_question').each(function () {
      const $this = $(this)
      if ($this.find('.jump_to_question_link').text() === 'Spacer') {
        $this.remove()
      }
    })
  }, 1000)

  // Suppress "<ENTER>" key from submitting a form when clicked inside a text input.
  $('#submit_quiz_form input[type=text]').keypress(e => {
    if (e.keyCode === 13) return false
  })

  $('.quiz_submit').click(_event => {
    quizSubmission.finalSubmitButtonClicked = true
  })

  $('#submit_quiz_form').submit(function (event) {
    $('.question_holder textarea.question_input').each(function () {
      $(this).change()
    })

    let unanswered
    let warningMessage

    if (quizSubmission.cantGoBack) {
      if (!$('.question').hasClass('answered')) {
        warningMessage = I18n.t(
          'confirms.cant_go_back_blank',
          "You can't come back to this question once you hit next. Are you sure you want to leave it blank?"
        )
      }
    }

    if (quizSubmission.finalSubmitButtonClicked) {
      quizSubmission.finalSubmitButtonClicked = false // reset in case user cancels

      if (quizSubmission.cantGoBack) {
        const unseen = $('#question_list .list_question:not(.seen)').length
        if (unseen > 0) {
          warningMessage = I18n.t(
            'confirms.unseen_questions',
            {
              one: "There is still 1 question you haven't seen yet.  Submit anyway?",
              other: "There are still %{count} questions you haven't seen yet.  Submit anyway?",
            },
            {count: unseen}
          )
        }
      } else {
        unanswered = $('#question_list .list_question:not(.answered):not(.text_only)').length
        if (unanswered > 0) {
          warningMessage = I18n.t(
            'confirms.unanswered_questions',
            {
              one: 'You have 1 unanswered question (see the right sidebar for details).  Submit anyway?',
              other:
                'You have %{count} unanswered questions (see the right sidebar for details).  Submit anyway?',
            },
            {count: unanswered}
          )
        }
      }
    }

    if ($('#fileupload_in_progress[value="true"]', $questions).length !== 0) {
      warningMessage = I18n.t(
        'confirms.file_upload_in_progress',
        'File upload is in progress. You may lose your answer before it is complete.'
      )
    }

    if (warningMessage != undefined && !quizSubmission.submitting) {
      const result = window.confirm(warningMessage)
      if (!result) {
        event.preventDefault()
        event.stopPropagation()
        return false
      }
    }

    quizSubmission.submitting = true
  })

  $('.submit_quiz_button').click(event => {
    event.preventDefault()
    $('#times_up_dialog').dialog('close')
  })

  setTimeout(function () {
    $('.question_holder textarea.question_input').each(function () {
      $(this).attr('id', 'question_input_' + quizSubmission.contentBoxCounter++)
      RichContentEditor.loadNewEditor($(this), {
        manageParent: true,
        autosave: {enabled: false},
        maxInitRenderedRCEs: 5,
      })
    })
  }, 2000)

  if (quizTakingPolice) {
    quizTakingPolice.addEventListener('message', e => {
      if (e.data === 'stopwatchTick') {
        quizSubmission.updateTime()
      }
    })

    quizTakingPolice.postMessage({
      code: 'startStopwatch',
      frequency: quizSubmission.clockInterval,
    })
  } else {
    setInterval(quizSubmission.updateTime, quizSubmission.clockInterval)
  }

  setTimeout(() => {
    quizSubmission.updateSubmission(true)
  }, 15000)

  const $submit_buttons = $('#submit_quiz_form button[type=submit]')

  // set the form action depending on the button clicked
  $submit_buttons.click(function (_event) {
    quizSubmission.clearAccessCode = false
    const action = $(this).data('action')
    if (action != undefined) {
      $('#submit_quiz_form').attr('action', action)
    }
  })

  // now that JS has been initialized, enable the next and previous buttons
  $submit_buttons.removeAttr('disabled')
})

showDeauthorizedDialog = function () {
  $('#deauthorized_dialog').dialog({
    modal: true,
    buttons: [
      {
        text: I18n.t('#buttons.cancel', 'Cancel'),
        class: 'dialog_closer',
        click() {
          $(this).dialog('close')
        },
      },
      {
        text: I18n.t('#buttons.login', 'Login'),
        class: 'btn-primary relogin_button button_type_submit',
        click() {
          quizSubmission.navigatingToRelogin = true
          $('#deauthorized_dialog').submit()
        },
      },
    ],
    zIndex: 1000,
  })
}

if (ENV.LOCKDOWN_BROWSER) {
  const ldbLoginPopup = new LDBLoginPopup()
  ldbLoginPopup
    .on('login_success.take_quiz', () => {
      $.flashMessage(I18n.t('login_successful', 'Login successful.'))
    })
    .on('login_failure.take_quiz', () => {
      $.flashError(I18n.t('login_failed', 'Login failed.'))
    })

  showDeauthorizedDialog = ldbLoginPopup.exec.bind(ldbLoginPopup)
}

$(() => {
  const KC_T = 84
  const $timeRunningTimeRemaining = $('.time_running,.time_remaining')

  // we'll use this buffer to read our updates, then we won't have to steal
  // the user's focus or cursor away, and it will still read instantly thanks
  // to [aria-live="assertive"]!
  //
  // 100% win
  const $timer = $('<div />', {
    class: 'screenreader-only',
    'aria-role': 'note',
    'aria-live': 'assertive',
    'aria-atomic': 'true',
    'aria-relevant': 'additions',
  }).appendTo(document.body)

  $(document).on('keydown.timer_quickjump', function readTimeLeft(e) {
    if (e.altKey && (e.shiftKey || e.ctrlKey) && e.which === KC_T) {
      e.preventDefault()
      $timer.text($timeRunningTimeRemaining.text())
    }
  })
  if (ENV.QUIZ_SUBMISSION_EVENTS_URL) {
    QuizLogAuditing.start()
    QuizLogAuditingEventDumper(false)
  }
})

$(document).ready(() => {
  $('.loaded').show()
  $('.loading').hide()
})
