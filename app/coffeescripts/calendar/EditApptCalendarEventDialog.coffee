#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!appt_calendar_event_dialog'
  'jquery'
  'jst/calendar/editApptCalendarEvent'
], (I18n, $, editApptCalendarEventTemplate) ->

  class EditApptCalendarEventDialog
    constructor: (@event) ->
      @form = $('<div></div>')
               .html(editApptCalendarEventTemplate(@event))
               .appendTo('body')

      $maxParticipantsOption = @form.find('[type=checkbox][name=max_participants_option]')
      @$maxParticipants      = @form.find('[name=max_participants]')

      $maxParticipantsOption.change =>
        @$maxParticipants.prop('disabled', not $maxParticipantsOption.prop('checked'))

      if @event.calendarEvent.participants_per_appointment
        $maxParticipantsOption.click()
        @$maxParticipants.val(@event.calendarEvent.participants_per_appointment)

      @dialog = @form.dialog
        autoOpen: false
        width: 'auto'
        resizable: false
        title: I18n.t('title', 'Edit %{name}', name: @event.title)
        buttons: [
          {
            text: I18n.t 'update', 'Update'
            click: @save
          }
        ]
      @dialog.submit (event) =>
        event.preventDefault()
        @save()

    show: -> @dialog.dialog('open')

    save: =>
      formData = @dialog.getFormData()

      limit_participants = formData.max_participants_option == "1"
      max_participants = formData.max_participants

      if limit_participants and max_participants <= 0
        if @event.calendarEvent.participant_type is 'Group'
          @$maxParticipants.errorBox(I18n.t 'You must allow at least one group to attend')
        else
          @$maxParticipants.errorBox(I18n.t 'invalid_participants', 'You must allow at least one user to attend')
        return false

      @event.calendarEvent.description = formData.description
      if limit_participants
        @event.calendarEvent.total_slots = max_participants
        @event.calendarEvent.remaining_slots = max_participants - @event.calendarEvent.child_events.length
      else
        @event.calendarEvent.total_slots = undefined
        @event.calendarEvent.remaining_slots = undefined

      participants_per_appointment = if limit_participants then max_participants else ""
      @event.save
        'calendar_event[description]': formData.description
        'calendar_event[participants_per_appointment]': participants_per_appointment

      @dialog.dialog('destroy')
      @form.remove()
