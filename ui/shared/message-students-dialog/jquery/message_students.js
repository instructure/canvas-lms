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
import natcompare from '@canvas/util/natcompare'
import numberHelper from '@canvas/i18n/numberHelper'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('public_message_students')
/* showIf */

let currentSettings = {}

function checkSendable() {
  const $message_students_dialog = messageStudentsDialog()
  disableSend(
    $message_students_dialog.find('#body').val().length == 0 ||
      $message_students_dialog.find('.student:not(.blank):visible').length == 0
  )
}

function disableButtons(disabled, buttons) {
  if (buttons == null) {
    buttons = messageStudentsDialog().find('button')
  }
  buttons.toggleClass('disabled', disabled).attr('aria-disabled', disabled)
}

function disableSend(disabled) {
  disableButtons(disabled, messageStudentsDialog().find('.send_button'))
}

function messageStudentsDialog() {
  return $('#message_students_dialog')
}

function showStudentsMessageSentTo() {
  const $message_students_dialog = messageStudentsDialog()
  const optionIdx = parseInt($message_students_dialog.find('select').val(), 10) || 0
  const option = currentSettings.options[optionIdx]
  const studentsHash = $message_students_dialog.data('students_hash')
  let cutoff = numberHelper.parse($message_students_dialog.find('.cutoff_score').val())
  if (Number.isNaN(Number(cutoff))) {
    cutoff = null
  }

  const studentElements = Object.values(studentsHash)
  let selectedStudentIds = []
  if (studentsHash) {
    if (option && option.callback) {
      selectedStudentIds = option.callback.call(window.messageStudents, cutoff, studentElements)
    } else if (currentSettings.callback) {
      selectedStudentIds = currentSettings.callback.call(
        window.messageStudents,
        option.text,
        cutoff,
        studentElements
      )
    }
  }

  if (currentSettings.subjectCallback) {
    $message_students_dialog
      .find('[name=subject]')
      .val(currentSettings.subjectCallback(option.text, cutoff))
  }
  $message_students_dialog.find('.cutoff_holder').showIf(option.cutoff)

  $message_students_dialog
    .find('.student_list')
    .toggleClass('show_score', !!(option.cutoff || option.score))
  disableButtons(selectedStudentIds.length === 0)

  const selectedIdSet = new Set(selectedStudentIds)
  Object.entries(studentsHash).forEach(([studentId, studentElement]) => {
    studentElement.showIf(selectedIdSet.has(studentId))
  })
}

/* global messageStudents */
window.messageStudents = function (settings) {
  const $message_students_dialog = messageStudentsDialog()
  currentSettings = settings
  $message_students_dialog.find('.message_types').empty()
  for (let idx = 0, l = settings.options.length; idx < l; idx++) {
    const $option = $('<option/>')
    const option = settings.options[idx]
    $option.val(idx).text(option.text)
    $message_students_dialog.find('.message_types').append($option)
  }

  const title = settings.title,
    $li = $message_students_dialog.find('ul li.blank:first'),
    $ul = $message_students_dialog.find('ul'),
    students_hash = {}

  $message_students_dialog.find('ul li:not(.blank)').remove()

  const sortedStudents = settings.students.slice()
  sortedStudents.sort(natcompare.byKey('sortableName'))

  for (let i = 0; i < sortedStudents.length; i++) {
    const student = sortedStudents[i]
    const $student = $li.clone(true).removeClass('blank')

    $student.find('.name').text(student.name)
    $student.find('.score').text(student.score)
    const remove_text = I18n.t('Remove %{student} from recipients', {
      student: student.name,
    })
    const $remove_button = $student.find('.remove-button')
    $remove_button
      .attr('title', remove_text)
      .append($("<span class='screenreader-only'></span>").text(remove_text))
    $remove_button.click(function (event) {
      event.preventDefault()
      // hide the selected student
      const $s = $(this).closest('li')
      $s.hide('fast', checkSendable)
      // focus the next visible student, or the subject field if that was the last one in the list
      const $next = $s.nextAll(':visible:first')
      if ($next.length) {
        $('button', $next).focus()
      } else {
        $('#message_assignment_recipients #subject').focus()
      }
    })

    $student.data('id', student.id)
    $student.user_data = student

    $ul.append($student.show())
    students_hash[student.id] = $student
  }

  $ul.show()

  const dialogTitle = I18n.t('Message Students for %{course_name}', {
    course_name: title,
  })

  $message_students_dialog.data('students_hash', students_hash)
  $message_students_dialog.find('.asset_title').text(title)
  $message_students_dialog.find('.out_of').showIf(settings.points_possible != null)
  $message_students_dialog.find('.send_button').text(I18n.t('send_message', 'Send Message'))
  $message_students_dialog.find('.points_possible').text(I18n.n(settings.points_possible))
  $message_students_dialog.find('[name=context_code]').val(settings.context_code)

  $message_students_dialog.find('textarea').val('')
  $message_students_dialog.find('select')[0].selectedIndex = 0
  $message_students_dialog.find('select').trigger('change')
  $message_students_dialog
    .dialog({
      width: 600,
      modal: true,
      open: (_event, _ui) => {
        $message_students_dialog
          .closest('.ui-dialog')
          .attr('role', 'dialog')
          .attr('aria-label', dialogTitle)
      },
      close: (_event, _ui) => {
        $message_students_dialog.closest('.ui-dialog').removeAttr('role').removeAttr('aria-label')
      },
      zIndex: 1000,
    })
    .dialog('open')
    .dialog('option', 'title', dialogTitle)
    .on('dialogclose', settings.onClose)

  showStudentsMessageSentTo()
}

$(document).ready(() => {
  const $message_students_dialog = messageStudentsDialog()
  $message_students_dialog.find('button').click(e => {
    const btn = $(e.target)
    if (btn.hasClass('disabled')) {
      e.preventDefault()
      e.stopPropagation()
    }
  })
  $('#message_assignment_recipients').formSubmit({
    processData(data) {
      const ids = []
      $(this)
        .find('.student:visible')
        .each(function () {
          ids.push($(this).data('id'))
        })
      if (ids.length == 0) {
        return false
      }
      data.recipients = ids.join(',')
      return data
    },
    beforeSubmit(_data) {
      disableButtons(true)
      $(this).find('.send_button').text(I18n.t('Sending Message...'))
    },
    success(_data) {
      $.flashMessage(I18n.t('Message sent!'))
      disableButtons(false)
      $(this).find('.send_button').text(I18n.t('Send Message'))
      $('#message_students_dialog').dialog('close')
    },
    error(_data) {
      disableButtons(false)
      $(this).find('.send_button').text(I18n.t('Sending Message Failed, please try again'))
    },
  })

  const closeDialog = function () {
    $message_students_dialog.dialog('close')
  }

  $message_students_dialog.find('.cancel_button').click(closeDialog)
  $message_students_dialog.find('select').change(showStudentsMessageSentTo).change(checkSendable)
  $message_students_dialog
    .find('.cutoff_score')
    .bind('change blur keyup', showStudentsMessageSentTo)
    .bind('change blur keyup', checkSendable)
  $message_students_dialog.find('#body').bind('change blur keyup', checkSendable)
})

export default messageStudents
