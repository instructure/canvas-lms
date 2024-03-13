/* eslint-disable @typescript-eslint/no-shadow */
/* eslint-disable eqeqeq */
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
import timing from './quiz_timing'
import openModerateStudentDialog from './openModerateStudentDialog'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery' /* datetimeString */
import '@canvas/jquery/jquery.instructure_forms' /* fillFormData, getFormData */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData' /* fillTemplateData */
import 'date-js'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('quizzes.moderate')
/* Date.parse */

const DIALOG_WIDTH = 490
/**
 * Updates the digit(s) in the "gets X extra minutes" message in a student's
 * block.
 *
 * @param {jQuery} $studentBlock
 *        Selector to the student block you're updating.
 *
 * @param {Number} extraTime
 *        The submission's extra allotted time.
 */
const updateExtraTime = function ($studentBlock, extraTime) {
  const $extraTime = $studentBlock.find('.extra_time_allowed')

  if (extraTime > 0) {
    $extraTime.text($extraTime.text().replace(/\d(.*\d)?/, I18n.n(extraTime)))
  }

  $extraTime.toggle(extraTime > 0)
}

/* global moderation */
window.moderation = {
  updateTimes() {
    const now = new Date()
    moderation.studentsCurrentlyTakingQuiz = !!$('#students .student.in_progress')
    $('#students .student.in_progress').each(function () {
      const $row = $(this)
      const row = $row.data('timing') || {}
      const started_at = $row.attr('data-started-at')
      const end_at = $row.attr('data-end-at')
      if (!row.referenceDate) {
        $.extend(row, timing.setReferenceDate(started_at, end_at, now))
      }
      if (!row.referenceDate) {
        return
      }
      $row.data('timing', row)
      const diff = row.referenceDate.getTime() - now.getTime() - row.clientServerDiff
      if (row.isDeadline && diff < 0) {
        $row.find('.time').text(I18n.t('time_up', 'Time Up!'))
        return
      }
      $row.data('minutes_left', diff / 60000)
      const date = new Date(Math.abs(diff))
      const yr = date.getUTCFullYear() - 1970
      let mon = date.getUTCMonth()
      mon += 12 * yr
      const day = date.getUTCDate() - 1
      const hr = date.getUTCHours()
      const min = date.getUTCMinutes()
      const sec = date.getUTCSeconds()
      const times = []
      if (mon) {
        times.push(mon < 10 ? '0' + mon : mon)
      }
      if (day) {
        times.push(day < 10 ? '0' + day : day)
      }
      if (hr) {
        times.push(hr < 10 ? '0' + hr : hr)
      }
      times.push(min < 10 ? '0' + min : min)
      times.push(sec < 10 ? '0' + sec : sec)
      $row.find('.time').text(times.join(':'))
    })
  },
  updateSubmission(submission, updateLastUpdatedAt) {
    const $student = $('#student_' + submission.user_id)
    if (updateLastUpdatedAt) {
      moderation.lastUpdatedAt = new Date(
        Math.max(Date.parse(submission.updated_at), moderation.lastUpdatedAt)
      )
    }
    let state_text = ''
    if (
      submission.workflow_state === 'complete' ||
      submission.workflow_state === 'pending_review'
    ) {
      state_text = I18n.t('finished_in_duration', 'finished in %{duration}', {
        duration: submission.finished_in_words,
      })
    }
    const data = {
      attempt: submission.attempt || '--',
      extra_time: submission.extra_time,
      extra_attempts: submission.extra_attempts,
      score: submission.kept_score == null ? null : I18n.n(submission.kept_score),
    }
    if (submission.attempts_left == -1) {
      data.attempts_left = '--'
    } else if (submission.attempts_left) {
      data.attempts_left = submission.attempts_left
    }
    if (submission.workflow_state !== 'untaken') {
      data.time = state_text
    }
    $student
      .fillTemplateData({data})
      .toggleClass('extendable', submission['extendable?'])
      .toggleClass('in_progress', submission.workflow_state === 'untaken')
      .toggleClass('manually_unlocked', !!submission.manually_unlocked)
      .attr('data-started-at', submission.started_at || '')
      .attr('data-end-at', submission.end_at || '')
      .data('timing', null)
      .find('.unlocked')
      .showIf(submission.manually_unlocked)

    updateExtraTime($student, submission.extra_time)
  },
  lastUpdatedAt: '',
  studentsCurrentlyTakingQuiz: false,
}

$(document).ready(function (_event) {
  timing.initTimes()
  setInterval(moderation.updateTimes, 500)
  let updateErrors = 0
  const moderate_url = $('.update_url').attr('href')
  moderation.lastUpdatedAt = Date.parse($('.last_updated_at').text())
  let currently_updating = false
  const $updating_img = $('.reload_link img')
  function updating(bool) {
    currently_updating = bool
    if (bool) {
      $updating_img.attr(
        'src',
        $updating_img.attr('src').replace('ajax-reload.gif', 'ajax-reload-animated.gif')
      )
    } else {
      $updating_img.attr(
        'src',
        $updating_img.attr('src').replace('ajax-reload-animated.gif', 'ajax-reload.gif')
      )
    }
  }
  function updateSubmissions(repeat) {
    if (currently_updating) {
      return
    }
    updating(true)
    const last_updated_at = moderation.lastUpdatedAt && moderation.lastUpdatedAt.toISOString()

    $.ajaxJSON(
      replaceTags(moderate_url, 'update', last_updated_at),
      'GET',
      {},
      data => {
        updating(false)
        if (repeat) {
          if (data.length || moderation.studentsCurrentlyTakingQuiz) {
            setTimeout(() => {
              updateSubmissions(true)
            }, 60000)
          } else {
            setTimeout(() => {
              updateSubmissions(true)
            }, 180000)
          }
        }
        for (const idx in data) {
          moderation.updateSubmission(data[idx], true)
        }
      },
      _data => {
        updating(false)
        updateErrors++
        if (updateErrors > 5) {
          $.flashMessage(
            I18n.t(
              'errors.server_communication_failed',
              'There was a problem communicating with the server.  The system will try again in five minutes, or you can reload the page'
            )
          )
          updateErrors = 0
          if (repeat) {
            setTimeout(() => {
              updateSubmissions(true)
            }, 300000)
          }
        } else if (repeat) {
          setTimeout(() => {
            updateSubmissions(true)
          }, 120000)
        }
      }
    )
  }
  setTimeout(() => {
    updateSubmissions(true)
  }, 1000)
  function checkChange() {
    const cnt = $('.student_check:checked').length
    $('#checked_count').text(cnt)
    $('.moderate_multiple_link').showIf(cnt)
  }
  $('#check_all').change(function () {
    const isChecked = $(this).is(':checked')
    $('.student_check').each((index, elem) => {
      $(elem).prop('checked', isChecked)
    })
    checkChange()
  })
  $('.student_check').change(function () {
    if (!$(this).prop('checked')) {
      $('#check_all').prop('checked', false)
    }
    checkChange()
  })

  $(document).on('click', '.moderate_multiple_link', function (event) {
    event.preventDefault()
    const student_ids = []
    const data = {}
    $('.student_check:checked').each(function () {
      const $student = $(this).parents('.student')
      student_ids.push($(this).attr('data-id'))
      const student_data = {
        manually_unlocked: $student.hasClass('manually_unlocked') ? '1' : '0',
        extra_attempts: parseInt($student.find('.extra_attempts').text(), 10) || '',
        extra_time: parseInt($student.find('.extra_time').text(), 10) || '',
      }
      $.each(['manually_unlocked', 'extra_attempts', 'extra_time'], function () {
        if (data[this] == null) {
          data[this] = student_data[this].toString()
        } else if (data[this] != student_data[this].toString()) {
          data[this] = ''
        }
      })
    })
    $('#moderate_student_form').data('ids', student_ids)
    $('#moderate_student_dialog h2').text(
      I18n.t(
        'extensions_for_students',
        {one: 'Extensions for 1 Student', other: 'Extensions for %{count} Students'},
        {count: student_ids.length}
      )
    )
    $('#moderate_student_form').fillFormData(data)
    $('#moderate_student_dialog')
      .dialog({
        title: I18n.t('titles.student_extensions', 'Student Extensions'),
        width: DIALOG_WIDTH,
        modal: true,
        zIndex: 1000,
      })
      .fixDialogButtons()
  })

  $(document).on('click', '.moderate_student_link', function (event) {
    event.preventDefault()
    const $student = $(this).parents('.student')
    const data = {
      manually_unlocked: $student.hasClass('manually_unlocked') ? '1' : '0',
      extra_attempts: parseInt($student.find('.extra_attempts').text(), 10) || '',
      extra_time:
        parseInt($student.find('.extra_time_allowed').text().replace(/[^\d]/g, ''), 10) || '',
    }
    const name = $student.find('.student_name').text()
    $('#moderate_student_form').fillFormData(data)
    $('#moderate_student_form').data('ids', [$student.attr('data-user-id')])
    $('#moderate_student_form').find('button').prop('disabled', false)
    $('#moderate_student_dialog h2').text(
      I18n.t('extensions_for_student', 'Extensions for %{student}', {student: name})
    )

    openModerateStudentDialog($('#moderate_student_dialog'), DIALOG_WIDTH)
  })

  $('.reload_link').click(event => {
    event.preventDefault()
    updateSubmissions()
  })

  $('#extension_extra_time')
    .on('invalid:not_a_number', function (_e) {
      $(this).errorBox(
        I18n.t('errors.quiz_submission_extra_time_not_a_number', 'Extra time must be a number.')
      )
    })
    .on('invalid:greater_than', function (_e) {
      $(this).errorBox(
        I18n.t('errors.quiz_submission_extra_time_too_short', 'Extra time must be greater than 0.')
      )
    })
    .on('invalid:less_than', function (_e) {
      $(this).errorBox(
        I18n.t(
          'errors.quiz_submission_extra_time_too_long',
          'Extra time must be less than than 10080.'
        )
      )
    })

  $('#extension_extra_attempts')
    .on('invalid:not_a_number', function (_e) {
      $(this).errorBox(
        I18n.t(
          'errors.quiz_submission_extra_attempts_not_a_number',
          'Extra attempts must be a number.'
        )
      )
    })
    .on('invalid:greater_than', function (_e) {
      $(this).errorBox(
        I18n.t(
          'errors.quiz_submission_extra_attempts_too_short',
          'Extra attempts must be greater than 0.'
        )
      )
    })
    .on('invalid:less_than', function (_e) {
      $(this).errorBox(
        I18n.t(
          'errors.quiz_submission_extra_attempts_too_long',
          'Extra attempts must be less than than 1000.'
        )
      )
    })

  $('#moderate_student_form').submit(function (event) {
    event.preventDefault()
    event.stopPropagation()
    const ids = $(this).data('ids')
    if (ids.length === 0) {
      return
    }
    const $form = $(this)
    $form
      .find('button')
      .prop('disabled', true)
      .filter('.save_button')
      .text(I18n.t('buttons.saving', 'Saving...'))
    let finished = 0,
      errors = 0
    const formData = $(this).getFormData()

    function valid(data) {
      const extraAttempts = parseInt(data.extra_attempts, 10)
      const extraTime = parseInt(data.extra_time, 10)
      let valid = true

      if (data.extra_attempts && Number.isNaN(Number(extraAttempts))) {
        $('#extension_extra_attempts').trigger('invalid:not_a_number')
        valid = false
      } else if (extraAttempts > 1000) {
        $('#extension_extra_attempts').trigger('invalid:less_than')
        valid = false
      } else if (extraAttempts < 0) {
        $('#extension_extra_attempts').trigger('invalid:greater_than')
        valid = false
      }

      if (data.extra_time && Number.isNaN(Number(extraTime))) {
        $('#extension_extra_time').trigger('invalid:not_a_number')
        valid = false
      } else if (extraTime > 10080) {
        // 1 week
        $('#extension_extra_time').trigger('invalid:less_than')
        valid = false
      } else if (extraTime < 0) {
        $('#extension_extra_time').trigger('invalid:greater_than')
        valid = false
      }
      return valid
    }
    if (!valid(formData)) {
      $form
        .find('button')
        .prop('disabled', false)
        .filter('.save_button')
        .text(I18n.t('buttons.save', 'Save'))
      return
    }

    function checkIfFinished() {
      if (finished >= ids.length) {
        if (errors > 0) {
          if (ids.length == 1) {
            $form
              .find('button')
              .prop('disabled', false)
              .filter('.save_button')
              .text(I18n.t('buttons.save_failed', 'Save Failed, please try again'))
          } else {
            $form
              .find('button')
              .prop('disabled', false)
              .filter('.save_button')
              .text(
                I18n.t(
                  'buttons.save_failed_n_updates_lost',
                  'Save Failed, %{n} Students were not updated',
                  {n: errors}
                )
              )
          }
        } else {
          $form
            .find('button')
            .prop('disabled', false)
            .filter('.save_button')
            .text(I18n.t('buttons.save', 'Save'))
          $('#moderate_student_dialog').dialog('close')
        }
      }
    }
    for (const idx in ids) {
      const id = ids[idx]
      const url = replaceTags($('.extension_url').attr('href'), 'user_id', id)
      $.ajaxJSON(
        url,
        'POST',
        formData,
        // eslint-disable-next-line no-loop-func
        data => {
          finished++
          moderation.updateSubmission(data)
          checkIfFinished()
        },
        // eslint-disable-next-line no-loop-func
        _data => {
          finished++
          errors++
          checkIfFinished()
        }
      )
    }
  })
  $('#moderate_student_dialog')
    .find('.cancel_button')
    .click(() => {
      $('#moderate_student_dialog').dialog('close')
    })
  $(document).on('click', '.extend_time_link', event => {
    event.preventDefault()
    const $row = $(event.target).parents('.student')
    const end_at = $.datetimeString($row.attr('data-end-at'))
    const started_at = $.datetimeString($row.attr('data-started-at'))
    const $dialog = $('#extend_time_dialog')
    $dialog.data('row', $row)
    $dialog.fillTemplateData({
      data: {
        end_at,
        started_at,
      },
    })
    $dialog.find('button').prop('disabled', false)
    $dialog
      .dialog({
        title: I18n.t('titles.extend_quiz_time', 'Extend Quiz Time'),
        width: DIALOG_WIDTH,
        modal: true,
        zIndex: 1000,
      })
      .fixDialogButtons()
  })
  $('#extend_time_dialog')
    .find('.cancel_button')
    .click(() => {
      $('#extend_time_dialog').dialog('close')
    })
    .end()
    .find('.save_button')
    .click(() => {
      const $dialog = $('#extend_time_dialog')
      const data = $dialog.getFormData()
      const params = {}
      data.time = parseInt(data.time, 10) || 0
      if (data.time <= 0) {
        return
      }
      if (
        data.time_type === 'extend_from_now' &&
        data.time < $dialog.data('row').data('minutes_left')
      ) {
        // eslint-disable-next-line no-alert
        const result = window.confirm(
          I18n.t(
            'confirms.taking_time_away',
            'That would be less time than the student currently has.  Continue anyway?'
          )
        )
        if (!result) {
          return
        }
      }
      params[data.time_type] = data.time
      $dialog
        .find('button')
        .prop('disabled', true)
        .filter('.save_button')
        .text(I18n.t('buttons.extending_time', 'Extending Time...'))
      const url = replaceTags(
        $('.extension_url').attr('href'),
        'user_id',
        $dialog.data('row').attr('data-user-id')
      )
      $.ajaxJSON(
        url,
        'POST',
        params,
        data => {
          $dialog
            .find('button')
            .prop('disabled', false)
            .filter('.save_button')
            .text(I18n.t('buttons.extend_time', 'Extend Time'))
          moderation.updateSubmission(data)
          $dialog.dialog('close')
        },
        _data => {
          $dialog
            .find('button')
            .prop('disabled', false)
            .filter('.save_button')
            .text(I18n.t('buttons.time_extension_failed', 'Extend Time Failed, please try again'))
        }
      )
    })

  const outstanding = {
    init(event) {
      event.preventDefault()
      this.$container = $('.child_container')

      this.showDialog()
      this.showResultsList(this.data)
    },
    fetchData() {
      const indexUrl = $('.outstanding_index_url').attr('href')
      $.ajaxJSON(indexUrl, 'GET', null, this.storeDataAndShowAlert.bind(this))
    },
    storeDataAndShowAlert(data) {
      if (data.quiz_submissions.length > 0) {
        this.toggleAlertHeader()
        this.data = data
      }
    },
    toggleAlertHeader() {
      $('.alert').toggle()
    },
    showResultsList(data) {
      this.adjustDialogHeight(data)
      $('#autosubmit_content_description_things_to_do').show()

      this.buildResultList(data)
      $('#autosubmit_form_submit_btn').prop('disabled', false)
    },
    adjustDialogHeight(data) {
      let height = 80
      height += data.quiz_submissions.length * 29
      if (height > 270) {
        height = 270
      }
      this.dialog.animate({height: height + 'px'})
    },
    buildResultList(data) {
      $.each(data.quiz_submissions, (index, qs) => {
        const clone = $('.example_autosubmit_row')
          .clone()
          .removeClass('example_autosubmit_row')
          .appendTo('.outstanding_submissions_list')
          .show()
        clone.children('input').val(qs.id)
        clone
          .find('input')
          .prop('checked', true)
          .attr('id', 'id_' + index)
        clone
          .children('label')
          .attr('for', 'id_' + index)
          .text(data.users[index].sortable_name)
        clone.show()
      })
    },
    submitOutstandings() {
      const gradeUrl = $('.outstanding_grade_url').attr('href')
      const ids = this.$container
        .find('input:checked')
        .map(function extractQSIds() {
          return this.value
        })
        .get()
      const json = {quiz_submission_ids: ids}
      $.ajaxJSON(
        gradeUrl,
        'POST',
        json,
        function successReporting(data, xhr) {
          if (xhr.status === 204) {
            if (ids.length == this.data.users.length) {
              this.toggleAlertHeader()
            }
            $.flashMessage('Successfully graded outstanding quizzes')
            this.closeDialog()
            updateSubmissions()
          }
        }.bind(this)
      )
    },
    cleanUpEventListeners() {
      $('#autosubmit_form_cancel_btn').off()
      $('#autosubmit_form_submit_btn').off()
    },
    closeDialog() {
      $('#autosubmit_content_description_things_to_do').hide()
      $('#autosubmit_content_description_all_done').hide()
      $('.autosubmit_data_row').not('.example_autosubmit_row').remove()
      this.cleanUpEventListeners()
      this.dialog.dialog('close')
    },
    setFocusOnLoad(_event, _ui) {
      $('#autosubmit_form').focus()
    },
    showDialog() {
      this.dialog = $('#autosubmit_form')
        .dialog({
          title: I18n.t('titles.autosubmit_dialog', 'Outstanding Quiz Submissions'),
          modal: true,
          width: DIALOG_WIDTH,
          height: 200,
          close: this.closeDialog.bind(this),
          zIndex: 1000,
        })
        .dialog('open')
        .fixDialogButtons()

      // Set up button behaviors
      $('#autosubmit_form_cancel_btn').on('click keyclick', () => {
        this.closeDialog()
      })
      $('#autosubmit_form_submit_btn').on('click keyclick', this.submitOutstandings.bind(this))

      this.setFocusOnLoad()
    },
  }
  outstanding.fetchData()
  $('#check_outstanding').click(outstanding.init.bind(outstanding))
})
