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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import editApptCalendarEventTemplate from '../jst/editApptCalendarEvent.handlebars'

const I18n = createI18nScope('appt_calendar_event_dialog')

export default class EditApptCalendarEventDialog {
  constructor(event) {
    this.event = event
    const form = $(`#${event.id}`)
    if (form.length) {
      form.find('.error-message').remove()
      this.form = form
    } else {
      this.form = $(`<div id="${event.id}"></div>`)
        .html(editApptCalendarEventTemplate(this.event))
        .appendTo('body')
    }

    const $maxParticipantsOption = this.form.find('[type=checkbox][name=max_participants_option]')
    this.$maxParticipants = this.form.find('[name=max_participants]')

    $maxParticipantsOption.change(() =>
      this.$maxParticipants.prop('disabled', !$maxParticipantsOption.prop('checked')),
    )

    if (this.event.calendarEvent.participants_per_appointment) {
      $maxParticipantsOption.click()
      this.$maxParticipants.val(this.event.calendarEvent.participants_per_appointment)
    }

    this.dialog = this.form.dialog({
      autoOpen: false,
      width: 'auto',
      resizable: false,
      title: I18n.t('title', 'Edit %{name}', {name: this.event.title}),
      buttons: [
        {
          text: I18n.t('update', 'Update'),
          click: this.save,
        },
      ],
      modal: true,
      zIndex: 1000,
    })
    this.dialog.submit(event => {
      event.preventDefault()
      return this.save()
    })
  }

  showErrorMessage = (selector, message) => {
    let errorContainer = $('#error-message')
    if (errorContainer.length) return
    errorContainer = $('<div />', {
      id: 'error-message',
      class: 'error-message',
      tabindex: '-1',
    }).appendTo(selector)
    $('<i />', {
      class: 'icon-warning icon-Solid',
      'aria-hidden': true,
      tabindex: '-1',
    }).appendTo(errorContainer)
    $('<span />', {
      role: 'alert',
      'aria-live': 'polite',
      tabindex: '-1',
    })
      .text(message)
      .appendTo(errorContainer)
  }

  show() {
    this.dialog.dialog('open')
  }

  save = () => {
    const formData = this.dialog.getFormData()

    const limit_participants = formData.max_participants_option === '1'
    const {max_participants} = formData

    if (limit_participants && max_participants <= 0) {
      if (this.event.calendarEvent.participant_type === 'Group') {
        this.$maxParticipants.errorBox(I18n.t('You must allow at least one group to attend'))
      } else {
        this.showErrorMessage(
          $('#max_participants_container'),
          I18n.t('invalid_participants', 'Please enter a value greater or equal to 1'),
        )
      }
      return false
    }

    this.event.calendarEvent.description = formData.description
    if (limit_participants) {
      this.event.calendarEvent.total_slots = max_participants
      this.event.calendarEvent.remaining_slots =
        max_participants - this.event.calendarEvent.child_events.length
    } else {
      this.event.calendarEvent.total_slots = undefined
      this.event.calendarEvent.remaining_slots = undefined
    }

    const participants_per_appointment = limit_participants ? max_participants : ''
    this.event.save({
      'calendar_event[description]': formData.description,
      'calendar_event[participants_per_appointment]': participants_per_appointment,
    })

    this.dialog.dialog('destroy')
    this.form.remove()
  }
}
