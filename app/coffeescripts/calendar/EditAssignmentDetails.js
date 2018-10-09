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

import I18n from 'i18n!calendar'
import $ from 'jquery'
import moment from 'moment'
import natcompare from '../util/natcompare'
import commonEventFactory from '../calendar/commonEventFactory'
import ValidatedFormView from '../views/ValidatedFormView'
import SisValidationHelper from '../util/SisValidationHelper'
import editAssignmentTemplate from 'jst/calendar/editAssignment'
import editAssignmentOverrideTemplate from 'jst/calendar/editAssignmentOverride'
import wrapper from 'jst/EmptyDialogFormWrapper'
import genericSelectOptionsTemplate from 'jst/calendar/genericSelectOptions'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'
import {showFlashAlert} from 'jsx/shared/FlashAlert'
import withinMomentDates from 'jsx/shared/helpers/momentDateHelper'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_forms'
import 'jquery.instructure_misc_helpers'
import '../calendar/fcMomentHandlebarsHelpers'

export default class EditAssignmentDetailsRewrite extends ValidatedFormView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.setContext = this.setContext.bind(this)
    this.activate = this.activate.bind(this)
    this.moreOptions = this.moreOptions.bind(this)
    this.setContext = this.setContext.bind(this)
    this.contextChange = this.contextChange.bind(this)
    this.setupTimeAndDatePickers = this.setupTimeAndDatePickers.bind(this)
    this.submitAssignment = this.submitAssignment.bind(this)
    this.getFormData = this.getFormData.bind(this)
    this.onSaveSuccess = this.onSaveSuccess.bind(this)
    this.onSaveFail = this.onSaveFail.bind(this)
    super(...args)
  }

  initialize(selector, event, contextChangeCB, closeCB) {
    this.event = event
    this.contextChangeCB = contextChangeCB
    this.closeCB = closeCB
    super.initialize({
      title: this.event.title,
      contexts: this.event.possibleContexts(),
      date: this.event.startDate(),
      postToSISEnabled: ENV.POST_TO_SIS,
      postToSISName: ENV.SIS_NAME,
      postToSIS:
        this.event.eventType === 'assignment' ? this.event.assignment.post_to_sis : undefined,
      datePickerFormat: this.event.allDay ? 'medium_with_weekday' : 'full_with_weekday'
    })
    this.currentContextInfo = null
    if (this.event.override) {
      this.template = editAssignmentOverrideTemplate
    }

    $(selector).append(this.render().el)

    this.setupTimeAndDatePickers()
    this.$el.find('select.context_id').triggerHandler('change', false)

    if (this.model == null) {
      this.model = this.generateNewEvent()
    }

    if (!this.event.isNewEvent()) {
      this.$el.find('.context_select').hide()
      this.$el.attr('method', 'PUT')
      return this.$el.attr(
        'action',
        $.replaceTags(this.event.contextInfo.assignment_url, 'id', this.event.object.id)
      )
    }
  }

  setContext(newContext) {
    this.$el
      .find('select.context_id')
      .val(newContext)
      .triggerHandler('change', false)
  }

  contextInfoForCode(code) {
    return this.event.possibleContexts().find(context => context.asset_string === code)
  }

  activate() {
    this.$el.find('select.context_id').change()
    if (this.event.assignment && this.event.assignment.assignment_group_id) {
      return this.$el
        .find('.assignment_group_select .assignment_group')
        .val(this.event.assignment.assignment_group_id)
    }
  }

  moreOptions(jsEvent) {
    jsEvent.preventDefault()
    const pieces = $(jsEvent.target)
      .attr('href')
      .split('#')
    const data = this.$el.getFormData({object_name: 'assignment'})
    const params = {}
    if (data.name) {
      params.title = data.name
    }
    if (data.due_at && this.$el.find('.datetime_field').data('unfudged-date')) {
      params.due_at = this.$el
        .find('.datetime_field')
        .data('unfudged-date')
        .toISOString()
    }

    if (data.assignment_group_id) {
      params.assignment_group_id = data.assignment_group_id
    }
    params.return_to = window.location.href
    pieces[0] += `?${$.param(params)}`
    return (window.location.href = pieces.join('#'))
  }

  contextChange(jsEvent, propagate) {
    if (this.ignoreContextChange) return

    const context = $(jsEvent.target).val()
    this.currentContextInfo = this.contextInfoForCode(context)
    this.event.contextInfo = this.currentContextInfo
    if (this.currentContextInfo == null) return

    if (propagate !== false) this.contextChangeCB(context)

    // TODO: support adding a new assignment group from this select box
    const assignmentGroupsSelectOptionsInfo = {
      collection: this.currentContextInfo.assignment_groups.sort(natcompare.byKey('name'))
    }
    this.$el
      .find('.assignment_group')
      .html(genericSelectOptionsTemplate(assignmentGroupsSelectOptionsInfo))

    // Update the edit and more options links with the new context
    this.$el.attr('action', this.currentContextInfo.create_assignment_url)
    const moreOptionsUrl = this.event.assignment
      ? `${this.event.assignment.html_url}/edit`
      : this.currentContextInfo.new_assignment_url
    return this.$el.find('.more_options_link').attr('href', moreOptionsUrl)
  }

  generateNewEvent() {
    return commonEventFactory({}, [])
  }

  submitAssignment(e) {
    e.preventDefault()
    const data = this.getFormData()
    this.disableWhileLoadingOpts = {buttons: ['.save_assignment']}
    if (data.assignment != null) {
      return this.submitRegularAssignment(e, data.assignment)
    } else {
      return this.submitOverride(e, data.assignment_override)
    }
  }

  unfudgedDate(date) {
    const unfudged = $.unfudgeDateForProfileTimezone(date)
    if (unfudged) {
      return unfudged.toISOString()
    } else {
      return ''
    }
  }

  getFormData() {
    const data = super.getFormData(...arguments)
    if (data.assignment != null) {
      data.assignment.due_at = this.unfudgedDate(data.assignment.due_at)
    } else {
      data.assignment_override.due_at = this.unfudgedDate(data.assignment_override.due_at)
    }

    return data
  }

  submitRegularAssignment(event, data) {
    data.due_at = this.unfudgedDate(data.due_at)

    if (this.event.isNewEvent()) {
      data.context_code = $(this.$el)
        .find('.context_id')
        .val()
      this.model = commonEventFactory(data, this.event.possibleContexts())
      return this.submit(event)
    } else {
      this.event.title = data.title
      this.event.start = data.due_at // fudged
      this.model = this.event
      return this.submit(event)
    }
  }

  submitOverride(event, data) {
    this.event.start = data.due_at // fudged
    data.due_at = this.unfudgedDate(data.due_at)
    this.model = this.event
    return this.submit(event)
  }

  onSaveSuccess() {
    return this.closeCB()
  }

  onSaveFail(xhr) {
    let resp
    if ((resp = JSON.parse(xhr.responseText))) {
      showFlashAlert({message: resp.error, err: null, type: 'error'})
    }
    this.closeCB()
    this.disableWhileLoadingOpts = {}
    return super.onSaveFail(xhr)
  }

  validateBeforeSave(data, errors) {
    if (data.assignment != null) {
      data = data.assignment
      errors = this._validateTitle(data, errors)
    } else {
      data = data.assignment_override
    }
    errors = this._validateDueDate(data, errors)
    return errors
  }

  _validateTitle(data, errors) {
    const post_to_sis = data.post_to_sis === '1'
    let max_name_length = 256
    const max_name_length_required = ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT

    if (post_to_sis && max_name_length_required) {
      max_name_length = ENV.MAX_NAME_LENGTH
    }

    const validationHelper = new SisValidationHelper({
      postToSIS: post_to_sis,
      maxNameLength: max_name_length,
      name: data.name,
      maxNameLengthRequired: max_name_length_required
    })

    if (!data.name || $.trim(data.name.toString()).length === 0) {
      errors['assignment[name]'] = [{message: I18n.t('name_is_required', 'Name is required!')}]
    } else if (validationHelper.nameTooLong()) {
      errors['assignment[name]'] = [
        {
          message: I18n.t('Name is too long, must be under %{length} characters', {
            length: max_name_length + 1
          })
        }
      ]
    }
    return errors
  }

  _validateDueDate(data, errors) {
    let dueDate
    if (
      this.event.eventType === 'assignment' &&
      this.event.assignment.unlock_at &&
      this.event.assignment.lock_at
    ) {
      const startDate = moment(this.event.assignment.unlock_at)
      const endDate = moment(this.event.assignment.lock_at)
      dueDate = moment(this.event.start)
      if (!withinMomentDates(dueDate, startDate, endDate)) {
        const rangeErrorMessage = I18n.t(
          'Assignment has a locked date. Due date cannot be set outside of locked date range.'
        )
        errors.lock_range = [{message: rangeErrorMessage}]
        showFlashAlert({
          message: rangeErrorMessage,
          err: null,
          type: 'error'
        })
      }
    }
    const post_to_sis = data.post_to_sis === '1'
    if (!post_to_sis) {
      return errors
    }

    const validationHelper = new SisValidationHelper({
      postToSIS: post_to_sis,
      dueDateRequired: ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT,
      dueDate: data.due_at
    })

    const error_tag = data.name != null ? 'assignment[due_at]' : 'assignment_override[due_at]'
    if (validationHelper.dueDateMissing()) {
      errors[error_tag] = [{message: I18n.t('Due Date is required!')}]
    }
    return errors
  }

  setupTimeAndDatePickers() {
    const $field = this.$el.find('.datetime_field')
    return $field.datetime_field({
      datepicker: {
        dateFormat: datePickerFormat(
          this.event.allDay
            ? I18n.t('#date.formats.medium_with_weekday')
            : I18n.t('#date.formats.full_with_weekday')
        )
      }
    })
  }
}
EditAssignmentDetailsRewrite.prototype.defaults = {
  width: 440,
  height: 384
}

EditAssignmentDetailsRewrite.prototype.events = {
  ...EditAssignmentDetailsRewrite.prototype.events,
  'click .save_assignment': 'submitAssignment',
  'click .more_options_link': 'moreOptions',
  'change .context_id': 'contextChange'
}

EditAssignmentDetailsRewrite.prototype.template = editAssignmentTemplate
EditAssignmentDetailsRewrite.prototype.wrapper = wrapper

EditAssignmentDetailsRewrite.optionProperty('assignmentGroup')
