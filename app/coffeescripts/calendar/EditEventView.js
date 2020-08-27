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

import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!calendar.edit'
import {showFlashAlert} from 'jsx/shared/FlashAlert'
import tz from 'timezone'
import Backbone from 'Backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import 'jquery.instructure_forms'
import editCalendarEventFullTemplate from 'jst/calendar/editCalendarEventFull'
import MissingDateDialogView from '../views/calendar/MissingDateDialogView'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import unflatten from '../object/unflatten'
import deparam from '../util/deparam'
import KeyboardShortcuts from '../views/editor/KeyboardShortcuts'
import coupleTimeFields from '../util/coupleTimeFields'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'
import CalendarConferenceWidget from 'jsx/conferences/calendar/CalendarConferenceWidget'
import filterConferenceTypes from 'jsx/conferences/utils/filterConferenceTypes'

RichContentEditor.preloadRemoteModule()

// #
// View for editing a calendar event on it's own page
export default class EditCalendarEventView extends Backbone.View {
  initialize() {
    this.render = this.render.bind(this)
    this.attachKeyboardShortcuts = this.attachKeyboardShortcuts.bind(this)
    this.toggleDuplicateOptions = this.toggleDuplicateOptions.bind(this)
    this.destroyModel = this.destroyModel.bind(this)
    // boilerplate that could be replaced with data bindings
    this.toggleUsingSectionClass = this.toggleUsingSectionClass.bind(this)
    this.toggleUseSectionDates = this.toggleUseSectionDates.bind(this)
    this.enableDuplicateFields = this.enableDuplicateFields.bind(this)
    this.duplicateCheckboxChanged = this.duplicateCheckboxChanged.bind(this)
    this.renderConferenceWidget = this.renderConferenceWidget.bind(this)

    super.initialize(...arguments)
    this.model.fetch().done(() => {
      const picked_params = _.pick(
        {...this.model.attributes, ...deparam()},
        'start_at',
        'start_date',
        'start_time',
        'end_time',
        'title',
        'description',
        'location_name',
        'location_address',
        'duplicate',
        'web_conference'
      )
      if (picked_params.start_at) {
        picked_params.start_date = tz.format(
          $.fudgeDateForProfileTimezone(picked_params.start_at),
          'date.formats.default'
        )
      } else {
        picked_params.start_date = tz.format(
          $.fudgeDateForProfileTimezone(picked_params.start_date),
          'date.formats.default'
        )
      }

      const attrs = this.model.parse(picked_params)
      // if start and end are at the beginning of a day, assume it is an all day date
      attrs.all_day =
        !!(attrs.start_at && attrs.start_at.equals(attrs.end_at)) &&
        attrs.start_at.equals(attrs.start_at.clearTime())
      this.model.set(attrs)
      this.render()

      // populate inputs with params passed through the url
      if (picked_params.duplicate) {
        Object.keys(picked_params.duplicate).forEach(key => {
          const oldKey = key
          if (key !== 'append_iterator') {
            key = `duplicate_${key}`
          }
          picked_params[key] = picked_params.duplicate[oldKey]
          delete picked_params.duplicate[key]
        })

        picked_params.duplicate = !!picked_params.duplicate
      }

      return Object.keys(picked_params).forEach(key => {
        const $e = this.$el.find(`input[name='${key}'], select[name='${key}']`)
        const value = $e.prop('type') === 'checkbox' ? [picked_params[key]] : picked_params[key]
        $e.val(value)
        if (key === 'duplicate') {
          this.enableDuplicateFields($e.val())
        }
        return $e.change()
      })
    })

    return this.model.on('change:use_section_dates', this.toggleUsingSectionClass)
  }

  render() {
    super.render(...arguments)
    this.$('.date_field').date_field({
      datepicker: {dateFormat: datePickerFormat(I18n.t('#date.formats.default'))}
    })
    this.$('.time_field').time_field()
    this.$('.date_start_end_row').each((_unused, row) => {
      const date = $('.start_date', row).first()
      const start = $('.start_time', row).first()
      const end = $('.end_time', row).first()
      return coupleTimeFields(start, end, date)
    })

    const $textarea = this.$('textarea')
    RichContentEditor.initSidebar()
    RichContentEditor.loadNewEditor($textarea, {focus: true, manageParent: true})

    _.defer(this.attachKeyboardShortcuts)
    _.defer(this.toggleDuplicateOptions)
    _.defer(this.renderConferenceWidget)

    return this
  }

  setConference = conference => {
    this.model.set('web_conference', conference)
    setTimeout(this.renderConferenceWidget, 0)
  }

  getActiveConferenceTypes() {
    const conferenceTypes = ENV.conferences?.conference_types || []
    const context = this.model.get('context_code')
    return filterConferenceTypes(conferenceTypes, context)
  }

  renderConferenceWidget() {
    if (!ENV.CALENDAR?.CONFERENCES_ENABLED) {
      return
    }
    const conferenceNode = document.getElementById('calendar_event_conference_selection')
    const activeConferenceTypes = this.getActiveConferenceTypes()
    if (!this.model.get('web_conference') && activeConferenceTypes.length === 0) {
      conferenceNode.closest('fieldset').className = 'hide'
    } else {
      conferenceNode.closest('fieldset').className = ''
      ReactDOM.render(
        <CalendarConferenceWidget
          context={this.model.get('context_code')}
          conference={this.model.get('web_conference')}
          setConference={this.setConference}
          conferenceTypes={activeConferenceTypes}
        />,
        conferenceNode
      )
    }
  }

  attachKeyboardShortcuts() {
    if (!ENV.use_rce_enhancements) {
      return $('.switch_event_description_view')
        .first()
        .before(new KeyboardShortcuts().render().$el)
    }
  }

  toggleDuplicateOptions() {
    return this.$el.find('.duplicate_event_toggle_row').toggle(this.model.isNew())
  }

  destroyModel() {
    const msg = I18n.t(
      'confirm_delete_calendar_event',
      'Are you sure you want to delete this calendar event?'
    )
    if (confirm(msg)) {
      return this.$el.disableWhileLoading(
        this.model.destroy({
          success: () =>
            this.redirectWithMessage(
              I18n.t('event_deleted', '%{event_title} deleted successfully', {
                event_title: this.model.get('title')
              })
            )
        })
      )
    }
  }

  // boilerplate that could be replaced with data bindings
  toggleUsingSectionClass() {
    this.$('#editCalendarEventFull').toggleClass(
      'use_section_dates',
      this.model.get('use_section_dates')
    )
    return $('.show_if_using_sections input').prop('disabled', !this.model.get('use_section_dates'))
  }

  toggleUseSectionDates(e) {
    this.model.set('use_section_dates', !this.model.get('use_section_dates'))
    return this.updateRemoveChildEvents(e)
  }

  toggleHtmlView(event) {
    if (event != null) event.preventDefault()

    RichContentEditor.callOnRCE($('textarea[name=description]'), 'toggle')
    // hide the clicked link, and show the other toggle link.
    // todo: replace .andSelf with .addBack when JQuery is upgraded.
    return $(event.currentTarget)
      .siblings('a')
      .andSelf()
      .toggle()
  }

  updateRemoveChildEvents(e) {
    const value = $(e.target).prop('checked') ? '' : '1'
    return $('input[name=remove_child_events]').val(value)
  }

  redirectWithMessage(message) {
    $.flashMessage(message)
    if (this.model.get('return_to_url')) {
      window.location = this.model.get('return_to_url')
    }
  }

  submit(event) {
    if (event != null) event.preventDefault()

    const eventData = unflatten(this.getFormData())
    eventData.use_section_dates = eventData.use_section_dates === '1'
    if (eventData.remove_child_events === '1') {
      delete eventData.child_event_data
    }

    if ($('#use_section_dates').prop('checked')) {
      const dialog = new MissingDateDialogView({
        validationFn() {
          const $fields = $('[name*=start_date]:visible').filter(function() {
            return $(this).val() === ''
          })
          if ($fields.length > 0) {
            return $fields
          } else {
            return true
          }
        },
        labelFn(input) {
          return $(input)
            .parents('.date_start_end_row')
            .prev('label')
            .text()
        },
        success: $dialog => {
          $dialog.dialog('close')
          this.$el.disableWhileLoading(
            this.model.save(eventData, {
              success: () =>
                this.redirectWithMessage(I18n.t('event_saved', 'Event Saved Successfully'))
            })
          )
          return $dialog.remove()
        }
      })
      if (dialog.render()) return
    }

    if (ENV.CALENDAR?.CONFERENCES_ENABLED) {
      const conference = this.model.get('web_conference')
      if (conference) {
        eventData.web_conference = {
          ...conference,
          title:
            conference.conference_type === 'LtiConference' ? eventData.title : conference.title,
          user_settings: {
            ...conference.user_settings,
            scheduled_date: eventData.start_at ? eventData.start_at.toISOString() : null
          }
        }
      } else {
        eventData.web_conference = ''
      }
    }

    return this.saveEvent(eventData)
  }

  saveEvent(eventData) {
    return this.$el.disableWhileLoading(
      this.model.save(eventData, {
        success: () => this.redirectWithMessage(I18n.t('event_saved', 'Event Saved Successfully')),
        error: (_model, response, _options) =>
          showFlashAlert({
            message: response.responseText,
            err: null,
            type: 'error'
          })
      })
    )
  }

  toJSON() {
    const result = super.toJSON(...arguments)
    result.use_rce_enhancements = ENV.use_rce_enhancements
    result.recurringEventLimit = 200
    return result
  }

  getFormData() {
    let data = this.$el.getFormData()

    // pull the true, parsed dates from the inputs to calculate start_at and end_at correctly
    const keys = Object.keys(data).filter(key => /start_date/.test(key))
    keys.forEach(start_date_key => {
      const start_time_key = start_date_key.replace(/start_date/, 'start_time')
      const end_time_key = start_date_key.replace(/start_date/, 'end_time')
      const start_at_key = start_date_key.replace(/start_date/, 'start_at')
      const end_at_key = start_date_key.replace(/start_date/, 'end_at')

      const start_date = this.$el.find(`[name='${start_date_key}']`).data('date')
      const start_time = this.$el.find(`[name='${start_time_key}']`).data('date')
      const end_time = this.$el.find(`[name='${end_time_key}']`).data('date')
      if (!start_date) return

      data = _.omit(data, start_date_key, start_time_key, end_time_key)

      let start_at = start_date.toString('yyyy-MM-dd')
      if (start_time) {
        start_at += start_time.toString(' HH:mm')
      }
      data[start_at_key] = tz.parse(start_at)

      let end_at = start_date.toString('yyyy-MM-dd')
      if (end_time) {
        end_at += end_time.toString(' HH:mm')
      }
      return (data[end_at_key] = tz.parse(end_at))
    })

    if (this.$el.find('#duplicate_event').prop('checked')) {
      data.duplicate = {
        count: this.$el.find('#duplicate_count').val(),
        interval: this.$el.find('#duplicate_interval').val(),
        frequency: this.$el.find('#duplicate_frequency').val(),
        append_iterator: this.$el.find('#append_iterator').is(':checked')
      }
    }
    return data
  }

  static title() {
    return super.title('event', 'Event')
  }

  enableDuplicateFields(shouldEnable) {
    const elts = this.$el.find('.duplicate_fields').find('input')
    const disableValue = !shouldEnable
    elts.prop('disabled', disableValue)
    return this.$el.find('.duplicate_event_row').toggle(!disableValue)
  }

  duplicateCheckboxChanged(jsEvent, _propagate) {
    return this.enableDuplicateFields(jsEvent.target.checked)
  }
}

EditCalendarEventView.prototype.el = $('#content')
EditCalendarEventView.prototype.template = editCalendarEventFullTemplate
EditCalendarEventView.prototype.events = {
  'submit form': 'submit',
  'change #use_section_dates': 'toggleUseSectionDates',
  'click .delete_link': 'destroyModel',
  'click .switch_event_description_view': 'toggleHtmlView',
  'change "#duplicate_event': 'duplicateCheckboxChanged'
}
EditCalendarEventView.type = 'event'
