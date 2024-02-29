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
import {omit, defer, pick} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import moment from 'moment-timezone'
import Backbone from '@canvas/backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import '@canvas/jquery/jquery.instructure_forms'
import editCalendarEventFullTemplate from '../../jst/editCalendarEventFull.handlebars'
import MissingDateDialogView from '@canvas/due-dates/backbone/views/MissingDateDialogView'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import unflatten from 'obj-unflatten'
import deparam from 'deparam'
import coupleTimeFields from '@canvas/calendar/jquery/coupleTimeFields'
import {renderDeleteCalendarEventDialog} from '@canvas/calendar/react/RecurringEvents/DeleteCalendarEventDialog'
import datePickerFormat from '@canvas/datetime/datePickerFormat'
import CalendarConferenceWidget from '@canvas/calendar-conferences/react/CalendarConferenceWidget'
import filterConferenceTypes from '@canvas/calendar-conferences/filterConferenceTypes'
import FrequencyPicker, {
  FrequencyPickerErrorBoundary,
} from '@canvas/calendar/react/RecurringEvents/FrequencyPicker/FrequencyPicker'
import Course from '@canvas/courses/backbone/models/Course'
import {renderUpdateCalendarEventDialog} from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'
import {
  RRULEToFrequencyOptionValue,
  updateRRuleForNewDate,
} from '@canvas/calendar/react/RecurringEvents/FrequencyPicker/utils'
import {CommonEventShowError} from '@canvas/calendar/jquery/CommonEvent/CommonEvent'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import EditCalendarEventHeader from '../../react/components/EditCalendarEventHeader'

const I18n = useI18nScope('calendar.edit')

RichContentEditor.preloadRemoteModule()

// #
// View for editing a calendar event on it's own page
export default class EditCalendarEventView extends Backbone.View {
  initialize() {
    this.render = this.render.bind(this)
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
      const picked_params = pick(
        {...this.model.attributes, ...deparam()},
        'start_at',
        'start_date',
        'start_time',
        'end_time',
        'title',
        'new_context_code',
        'description',
        'location_name',
        'location_address',
        'duplicate',
        'web_conference',
        'important_dates',
        'blackout_date',
        'context_type',
        'course_pacing_enabled',
        'course_sections',
        'rrule',
        'calendar_event_context_code'
      )
      if (picked_params.start_date) {
        // this comes from the calendar via url params when editing an event
        picked_params.start_date = new Intl.DateTimeFormat(ENV.LOCALE, {
          month: 'short',
          day: 'numeric',
          year: 'numeric',
          timeZone: ENV.TIMEZONE,
        }).format(new Date(picked_params.start_date))
      } else if (picked_params.start_at) {
        // this comes from the query to canvas for the event
        picked_params.start_date = new Intl.DateTimeFormat(ENV.LOCALE, {
          month: 'short',
          day: 'numeric',
          year: 'numeric',
          timeZone: ENV.TIMEZONE,
        }).format(new Date(picked_params.start_at))
      } else {
        picked_params.start_date = new Intl.DateTimeFormat(ENV.LOCALE, {
          month: 'short',
          day: 'numeric',
          year: 'numeric',
          timeZone: ENV.TIMEZONE,
        }).format(new Date())
      }

      if (picked_params.new_context_code) {
        picked_params.context_code = picked_params.new_context_code
      }

      const attrs = this.model.parse(picked_params)
      // if start and end are at the beginning of a day, assume it is an all day date
      attrs.all_day =
        !!(attrs.start_at && attrs.start_at.equals(attrs.end_at)) &&
        attrs.start_at.equals(attrs.start_at.clearTime())
      this.model.set(attrs)
      this.frequency = attrs.rrule
        ? RRULEToFrequencyOptionValue(
            moment.tz(attrs.start_date, 'MMM D, YYYY', ENV.TIMEZONE),
            attrs.rrule
          )
        : 'not-repeat'
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
        if (key === 'important_dates') {
          this.$el
            .find('#calendar_event_important_dates')
            .prop('checked', picked_params[key] === 'true')
        }
        if (key === 'blackout_date') {
          this.$el
            .find('#calendar_event_blackout_date')
            .prop('checked', picked_params[key] === 'true')
        }
        if (key === 'calendar_event_context_code' && picked_params.course_sections?.length > 0) {
          const active_section_id = picked_params[key].split('_')[2]
          const eventDateKeys = ['start_date', 'start_time', 'end_time']
          eventDateKeys.forEach(dateKey => {
            const $element = this.$el.find(
              `input[name='child_event_data[${active_section_id}][${dateKey}]']`
            )
            $element.val(picked_params[dateKey])
          })
        }
        if (key === 'course_sections') {
          const sections = picked_params[key]
          sections.forEach(section => {
            if (section.event) {
              const timeKeys = ['start_time', 'end_time']
              timeKeys.forEach(timeKey => {
                const $element = this.$el.find(
                  `input[name='child_event_data[${section.id}][${timeKey}]']`
                )
                const newValue = section.event.all_day ? '' : $element.val().toUpperCase()
                $element.val(newValue)
                $element.change()
              })
            }
          })
        }
        return $e.change()
      })
    })

    this.conferencesKey = 0
    this.hasConferenceField =
      this.model.get('web_conference') || this.getActiveConferenceTypes().length > 0
    this.oldConference = this.model.get('web_conference')
    this.unsavedFields = {}
    return this.model.on('change:use_section_dates', this.toggleUsingSectionClass)
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
    const conferenceNode = document.getElementById('calendar_event_conference_selection')
    const activeConferenceTypes = this.getActiveConferenceTypes()
    if (!this.model.get('web_conference') && activeConferenceTypes.length === 0) {
      conferenceNode.closest('fieldset').className = 'hide'
    } else {
      conferenceNode.closest('fieldset').className = ''
      ReactDOM.render(
        <CalendarConferenceWidget
          key={this.conferencesKey}
          context={this.model.get('context_code')}
          conference={this.model.get('web_conference')}
          setConference={this.setConference}
          conferenceTypes={activeConferenceTypes}
          disabled={this.conferencesDisabled}
        />,
        conferenceNode
      )
    }
  }

  toggleRecurringEeventFrequencyPicker(event) {
    if (event.target.checked) {
      this.$el.find('#recurring_event_frequency_picker').addClass('hidden')
      this.model.set('rrule', null)
      this.renderRecurringEventFrequencyPicker()
    } else {
      this.$el.find('#recurring_event_frequency_picker').removeClass('hidden')
    }
  }

  showDuplicates(duplicatesEnabled) {
    if (this.model.isNew()) {
      this.$el.find('.label_with_checkbox[for="duplicate_event"]').toggle(duplicatesEnabled)
      $('#duplicate_event').prop('checked', false)
      this.enableDuplicateFields(false)
    }
  }

  _handleFrequencyChange(newFrequency, newRRule) {
    if (newFrequency !== 'custom') {
      this.model.set('rrule', newRRule)
      this.frequency = newFrequency
      this.renderRecurringEventFrequencyPicker()
    }
  }

  renderHeaderComponent() {
    const title = this.model.id == null ? 
      I18n.t('Create New Calendar Event') : 
      I18n.t('Edit %{title}', {title: this.model.get('title')})

    ReactDOM.render(
      <EditCalendarEventHeader title={title} />,
      document.getElementById('header_component_root')
    )
  }

  renderRecurringEventFrequencyPicker() {
    if (!this.model.get('use_section_dates')) {
      const pickerNode = document.getElementById('recurring_event_frequency_picker')
      const start = this.$el.find('[name="start_date"]').val()
      const eventStart = start ? moment.tz(start, 'MMM D, YYYY', ENV.TIMEZONE) : moment('invalid')

      const rrule = this.model.get('rrule')
      const date = eventStart.isValid() ? eventStart.toISOString(true) : undefined

      let courseEndAt

      if (this.course) {
        courseEndAt = this.course.get('restrict_enrollments_to_course_dates')
          ? this.course.get('end_at')
          : this.course.get('term')?.end_at
      }

      ReactDOM.render(
        <div id="recurring_event_frequency_picker" style={{margin: '.5rem 0 1rem'}}>
          <FrequencyPickerErrorBoundary>
            <FrequencyPicker
              key={date || 'not-repeat'}
              date={date}
              interaction={eventStart.isValid() ? 'enabled' : 'disabled'}
              locale={ENV.LOCALE || 'en'}
              timezone={ENV.TIMEZONE}
              initialFrequency={this.frequency}
              rrule={rrule}
              width="fit"
              onChange={this.handleFrequencyChange}
              courseEndAt={courseEndAt || undefined}
            />
          </FrequencyPickerErrorBoundary>
        </div>,
        pickerNode
      )
    }
  }

  afterRender() {
    this.handleFrequencyChange = this._handleFrequencyChange.bind(this)
    this.renderHeaderComponent()
    this.renderRecurringEventFrequencyPicker()
    this.showDuplicates(this.model.get('use_section_dates'))

    this.$el.find('[name="start_date"]').on('change', () => {
      const start = this.$el.find('[name="start_date"]').val()
      const eventStart = start ? moment.tz(start, 'MMM D, YYYY', ENV.TIMEZONE) : moment('invalid')
      if (eventStart.isValid() && this.model.get('rrule') && this.frequency !== 'saved-custom') {
        this.model.set('rrule', updateRRuleForNewDate(eventStart, this.model.get('rrule')))
      }
      this.renderRecurringEventFrequencyPicker()
    })

    const context_code = this.model.get('context_code')
    const [context_type, context_id] = context_code.split('_')
    if (context_type === 'course') {
      this.course = new Course()
      this.course.urlRoot = `/api/v1/courses/${context_id}?include[]=term`
      this.course
        .fetch()
        .done(() => this.renderRecurringEventFrequencyPicker())
        .fail(err =>
          showFlashAlert({
            message: 'Failed to fetch course data.',
            err,
            type: 'error',
          })
        )
    }
  }

  render() {
    super.render(...arguments)
    this.$('.date_field').date_field({
      datepicker: {dateFormat: datePickerFormat(I18n.t('#date.formats.default'))},
    })
    this.$('.time_field').time_field()
    this.$('.date_start_end_row').each((_unused, row) => {
      const date = $('.start_date', row).first()
      const start = $('.start_time', row).first()
      const end = $('.end_time', row).first()
      return coupleTimeFields(start, end, date)
    })

    const enableOrDisable = selector => {
      if ($('#calendar_event_blackout_date').is(':checked')) {
        this.unsavedFields[selector] = $(selector).val()
        $(selector).val('')
        $(selector).prop('disabled', true)
      } else {
        $(selector).val(this.unsavedFields[selector])
        $(selector).prop('disabled', false)
      }
    }

    const enableOrDisableConferenceField = () => {
      this.conferencesKey++
      this.conferencesDisabled = !this.conferencesDisabled
      if (this.conferencesDisabled) {
        this.oldConference = this.model.get('web_conference')
        this.model.set('web_conference', null)
      } else {
        this.model.set('web_conference', this.oldConference)
      }
      this.renderConferenceWidget()
    }

    const onBlackoutDateCheckboxChange = () => {
      enableOrDisable('#more_options_start_time')
      enableOrDisable('#more_options_end_time')
      enableOrDisable('#calendar_event_location_name', '#ln_blackout_date_tooltip')
      enableOrDisable('#calendar_event_location_address')
      if (this.hasConferenceField) {
        enableOrDisable('#calendar_event_conference_field')
        enableOrDisableConferenceField()
      }
    }
    if (this.model.get('blackout_date') === 'true') onBlackoutDateCheckboxChange()

    $('#calendar_event_blackout_date').on('change', onBlackoutDateCheckboxChange)

    const $textarea = this.$('textarea')
    RichContentEditor.loadNewEditor($textarea, {focus: true, manageParent: true})

    defer(this.toggleDuplicateOptions)
    defer(this.renderConferenceWidget)
    defer(this.disableDatePickers)

    return this
  }

  toggleDuplicateOptions() {
    return this.$el.find('.duplicate_event_toggle_row').toggle(this.model.isNew())
  }

  destroyModel() {
    let delModalContainer = document.getElementById('delete_modal_container')
    if (!delModalContainer) {
      delModalContainer = document.createElement('div')
      delModalContainer.id = 'delete_modal_container'
      document.body.appendChild(delModalContainer)
    }
    renderDeleteCalendarEventDialog(delModalContainer, {
      isOpen: true,
      onCancel: () => {
        ReactDOM.unmountComponentAtNode(delModalContainer)
      },
      onDeleting: () => {},
      onDeleted: () => {
        ReactDOM.unmountComponentAtNode(delModalContainer)
        this.redirectWithMessage(
          I18n.t('event_deleted', '%{event_title} deleted successfully', {
            event_title: this.model.get('title'),
          })
        )
      },
      delUrl: this.model.url(),
      isRepeating: !!this.model.get('series_uuid'),
      isSeriesHead: !!this.model.get('series_head'),
    })
  }

  // boilerplate that could be replaced with data bindings
  toggleUsingSectionClass() {
    this.$('#editCalendarEventFull').toggleClass(
      'use_section_dates',
      this.model.get('use_section_dates')
    )
  }

  toggleUseSectionDates(e) {
    this.model.set('use_section_dates', !this.model.get('use_section_dates'))
    this.toggleRecurringEeventFrequencyPicker(e)
    this.showDuplicates(e.target.checked)
    return this.updateRemoveChildEvents(e)
  }

  disableDatePickers() {
    $('.date_field:disabled + button').prop('disabled', true)
  }

  toggleHtmlView(event) {
    if (event != null) event.preventDefault()

    RichContentEditor.callOnRCE($('textarea[name=description]'), 'toggle')
    // hide the clicked link, and show the other toggle link.
    // todo: replace .andSelf with .addBack when JQuery is upgraded.
    return $(event.currentTarget).siblings('a').andSelf().toggle()
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
          const $fields = $('[name*=start_date]:visible').filter(function () {
            return $(this).val() === ''
          })
          if ($fields.length > 0) {
            return $fields
          } else {
            return true
          }
        },
        labelFn(input) {
          return $(input).parents('.date_start_end_row').prev('label').text()
        },
        success: $dialog => {
          $dialog.dialog('close')
          this.$el.disableWhileLoading(
            this.model.save(eventData, {
              success: () =>
                this.redirectWithMessage(I18n.t('event_saved', 'Event Saved Successfully')),
            })
          )
          return $dialog.remove()
        },
      })
      if (dialog.render()) return
    }

    const conference = this.model.get('web_conference')
    if (conference && !eventData.blackout_date) {
      eventData.web_conference = {
        ...conference,
        title: conference.conference_type === 'LtiConference' ? eventData.title : conference.title,
        user_settings: {
          ...conference.user_settings,
          scheduled_date: eventData.start_at ? eventData.start_at.toISOString() : null,
        },
      }
    } else {
      eventData.web_conference = ''
    }

    if (!this.validateFormData(eventData)) {
      return false
    }

    return this.saveEvent(eventData)
  }

  validateFormData({title, start_at}) {
    // Form data:
    // blackout_date, description, end_at, important_dates, location_address,
    // location_name, start_at, title
    const errors = []
    if (title.length === 0) {
      errors.push({
        field: $('#calendar_event_title'),
        text: I18n.t('errors.title_required', 'You must enter a title'),
      })
    }
    if (!start_at) {
      errors.push({
        field: $('#calendar_event_date'),
        text: I18n.t('errors.start_date_required', 'You must enter a date'),
      })
    }
    if (errors.length) {
      let offset
      errors.forEach(err => {
        const errorBox = err.field.errorBox(err.text)
        offset ||= errorBox.offset()
      })
      if (offset) {
        // Scrolls to the the uppermost field, in this page title field could be it.
        $('html,body').scrollTo({top: offset.top, left: 0})
      }
      return false
    }
    return true
  }

  async saveEvent(eventData) {
    RichContentEditor.closeRCE(this.$('textarea'))

    if (this.model.get('series_uuid') && this.model.get('rrule')) {
      const which = await renderUpdateCalendarEventDialog(this.model.attributes)
      if (which === undefined) return
      this.model.set('which', which)
    }

    return this.$el.disableWhileLoading(
      this.model.save(eventData, {
        success: () => this.redirectWithMessage(I18n.t('event_saved', 'Event Saved Successfully')),
        error: (model, response, _options) => {
          CommonEventShowError(JSON.parse(response.responseText))
        },
        skipDefaultError: true,
      })
    )
  }

  shouldShowBlackoutDatesCheckbox() {
    const context_type = this.model.get('context_type')
    const course_pacing_enabled = this.model.get('course_pacing_enabled') === 'true'
    return (
      ENV.FEATURES?.account_level_blackout_dates &&
      (context_type === 'account' || (context_type === 'course' && course_pacing_enabled))
    )
  }

  toJSON() {
    const result = super.toJSON(...arguments)
    result.recurringEventLimit = 200
    result.k5_context = ENV.K5_SUBJECT_COURSE || ENV.K5_HOMEROOM_COURSE || ENV.K5_ACCOUNT
    result.should_show_blackout_dates = this.shouldShowBlackoutDatesCheckbox()
    result.disableSectionDates =
      result.use_section_dates &&
      result.course_sections.filter(
        section => !section.permissions.manage_calendar && section.event
      ).length > 0
        ? 'disabled'
        : ''
    return result
  }

  getFormData() {
    let data = this.$el.getFormData()
    data.blackout_date = this.$el.find('#calendar_event_blackout_date').prop('checked')
    if (data.blackout_date) {
      data.start_time = data.start_date
      data.end_time = data.start_date
      data.location_name = ''
      data.location_address = ''
    }

    // pull the true, parsed dates from the inputs to calculate start_at and end_at correctly
    const keys = Object.keys(data).filter(key => /start_date/.test(key))
    keys.forEach(start_date_key => {
      const start_time_key = start_date_key.replace(/start_date/, 'start_time')
      const end_time_key = start_date_key.replace(/start_date/, 'end_time')
      const start_at_key = start_date_key.replace(/start_date/, 'start_at')
      const end_at_key = start_date_key.replace(/start_date/, 'end_at')

      const start_date = this.$el.find(`[name='${start_date_key}']`).change().data('date')
      const start_time = this.$el.find(`[name='${start_time_key}']`).change().data('date')
      const end_time = this.$el.find(`[name='${end_time_key}']`).change().data('date')
      if (!start_date) return

      data = omit(data, start_date_key, start_time_key, end_time_key)

      let start_at = start_date.toString('yyyy-MM-dd')
      if (start_time && !data.blackout_date) {
        start_at += start_time.toString(' HH:mm')
      }
      data[start_at_key] = tz.parse(start_at)

      let end_at = start_date.toString('yyyy-MM-dd')
      if (end_time && !data.blackout_date) {
        end_at += end_time.toString(' HH:mm')
      }
      return (data[end_at_key] = tz.parse(end_at))
    })

    if (this.$el.find('#duplicate_event').prop('checked')) {
      data.duplicate = {
        count: this.$el.find('#duplicate_count').val(),
        interval: this.$el.find('#duplicate_interval').val(),
        frequency: this.$el.find('#duplicate_frequency').val(),
        append_iterator: this.$el.find('#append_iterator').is(':checked'),
      }
    }

    data.important_dates = this.$el.find('#calendar_event_important_dates').prop('checked')
    data.rrule = this.model.get('rrule')
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

  cancel() {
    RichContentEditor.closeRCE(this.$('textarea'))
  }
}

EditCalendarEventView.prototype.el = $('#content')
EditCalendarEventView.prototype.template = editCalendarEventFullTemplate
EditCalendarEventView.prototype.events = {
  'submit form': 'submit',
  'change #use_section_dates': 'toggleUseSectionDates',
  'click .delete_link': 'destroyModel',
  'click .switch_event_description_view': 'toggleHtmlView',
  'change #duplicate_event': 'duplicateCheckboxChanged',
  'click .btn[role="button"]': 'cancel',
}
EditCalendarEventView.type = 'event'
