/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {each, isEmpty, includes, extend as lodashExtend} from 'lodash'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DialogFormView, {
  isSmallTablet,
  getResponsiveWidth,
} from '@canvas/forms/backbone/views/DialogFormView'
import DateValidator from '@canvas/grading/DateValidator'
import template from '../../jst/CreateAssignment.handlebars'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import numberHelper from '@canvas/i18n/numberHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import round from '@canvas/round'
import $ from 'jquery'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'
import SisValidationHelper from '@canvas/sis/SisValidationHelper'
import '@canvas/datetime/jquery'
import * as tz from '@canvas/datetime'
import {encodeQueryString} from '@canvas/query-string-encoding'

const I18n = useI18nScope('CreateAssignmentView')

extend(CreateAssignmentView, DialogFormView)

function CreateAssignmentView() {
  this._dueAtHasChanged = this._dueAtHasChanged.bind(this)
  this._validatePointsPossible = this._validatePointsPossible.bind(this)
  this.onSaveFail = this.onSaveFail.bind(this)
  this.getFormData = this.getFormData.bind(this)
  this.onSaveSuccess = this.onSaveSuccess.bind(this)
  return CreateAssignmentView.__super__.constructor.apply(this, arguments)
}

CreateAssignmentView.prototype.defaults = {
  width: getResponsiveWidth(320, 500),
  height: 380,
}

CreateAssignmentView.prototype.events = lodashExtend({}, CreateAssignmentView.prototype.events, {
  'click .dialog_closer': 'close',
  'click .save_and_publish': 'saveAndPublish',
  'click .more_options': 'moreOptions',
  'blur .points_possible': 'roundPointsPossible',
})

CreateAssignmentView.prototype.template = template

CreateAssignmentView.prototype.wrapperTemplate = wrapper

CreateAssignmentView.optionProperty('assignmentGroup')

CreateAssignmentView.prototype.initialize = function (options) {
  CreateAssignmentView.__super__.initialize.call(this, {
    assignmentGroup: options.assignmentGroup,
    title: this.model != null ? I18n.t('Edit Assignment') : null,
  })
  if (this.model == null) {
    this.model = this.generateNewAssignment()
  }
  return this.on('close', function () {
    return this.$el[0].reset()
  })
}

CreateAssignmentView.prototype.onSaveSuccess = function () {
  this.shouldPublish = false
  CreateAssignmentView.__super__.onSaveSuccess.apply(this, arguments)
  ENV.PERMISSIONS.by_assignment_id &&
    (ENV.PERMISSIONS.by_assignment_id[this.model.id] = {
      update: ENV.PERMISSIONS.manage_assignments,
    })
  if (this.assignmentGroup) {
    this.assignmentGroup.get('assignments').add(this.model)
    return (this.model = this.generateNewAssignment())
  }
}

CreateAssignmentView.prototype.getFormData = function () {
  const data = CreateAssignmentView.__super__.getFormData.apply(this, arguments)
  const unfudged = $.unfudgeDateForProfileTimezone(data.due_at)
  if (unfudged != null) {
    data.due_at = this._getDueAt(unfudged)
  }
  if (this.shouldPublish) {
    data.published = true
  }
  if (data.points_possible) {
    data.points_possible = numberHelper.parse(data.points_possible)
  }
  return data
}

CreateAssignmentView.prototype.saveAndPublish = function (event) {
  this.shouldPublish = true
  this.disableWhileLoadingOpts = {
    buttons: ['.save_and_publish'],
  }
  return this.submit(event)
}

CreateAssignmentView.prototype.onSaveFail = function (xhr) {
  this.shouldPublish = false
  this.disableWhileLoadingOpts = {}
  return CreateAssignmentView.__super__.onSaveFail.call(this, xhr)
}

CreateAssignmentView.prototype.moreOptions = function () {
  const valid = ['submission_types', 'name', 'due_at', 'points_possible', 'assignment_group_id']
  const data = this.getFormData()
  if (this.assignmentGroup) {
    data.assignment_group_id = this.assignmentGroup.get('id')
  }
  const dataParams = {}
  each(data, function (value, key) {
    if (includes(valid, key)) {
      return (dataParams[key] = value)
    }
  })
  if (dataParams.submission_types === 'online_quiz') {
    const button = this.$('.more_options')
    button.prop('disabled', true)
    return $.post(this.newQuizUrl(), dataParams)
      .done(
        (function (_this) {
          return function (response) {
            return _this.redirectTo(response.url)
          }
        })(this)
      )
      .always(function () {
        return button.prop('disabled', false)
      })
  } else {
    const url = this.assignmentGroup ? this.newAssignmentUrl() : this.model.htmlEditUrl()
    return this.redirectTo(url + '?' + encodeQueryString(dataParams))
  }
}

CreateAssignmentView.prototype.redirectTo = function (url) {
  return (window.location.href = url)
}

CreateAssignmentView.prototype.generateNewAssignment = function () {
  const assign = new Assignment()
  if (this.assignmentGroup) {
    assign.assignmentGroupId(this.assignmentGroup.id)
  }
  return assign
}

CreateAssignmentView.prototype.toJSON = function () {
  const json = this.model.toView()
  const uniqLabel = this.assignmentGroup
    ? 'ag_' + this.assignmentGroup.get('id')
    : 'assign_' + this.model.get('id')
  lodashExtend(json, {
    canChooseType: this.assignmentGroup != null,
    uniqLabel,
    disableDueAt: this.disableDueAt(),
    postToSISName: ENV.SIS_NAME,
    isInClosedPeriod: this.model.inClosedGradingPeriod(),
    defaultToolName: ENV.DEFAULT_ASSIGNMENT_TOOL_NAME,
    small_tablet: isSmallTablet,
  })
  // # master_course_restrictions only apply if this is a child course
  // # and is restricted by a master course.
  // # the handlebars template doesn't do logical combinations conditions,
  // # so summarize here
  const doRestrictionsApply =
    !!json.is_master_course_child_content && !!json.restricted_by_master_course
  const ref = json.master_course_restrictions
  for (const k in ref) {
    const v = ref[k]
    json.master_course_restrictions[k] = doRestrictionsApply && v
  }
  return json
}

CreateAssignmentView.prototype.currentUserIsAdmin = function () {
  return ENV.current_user_is_admin
}

CreateAssignmentView.prototype.disableDueAt = function () {
  return includes(this.model.frozenAttributes(), 'due_at') || this.model.inClosedGradingPeriod()
}

CreateAssignmentView.prototype.openAgain = function () {
  CreateAssignmentView.__super__.openAgain.apply(this, arguments)
  this.hideErrors()
  const timeField = this.$el.find('.datetime_field')
  if (
    this.model.multipleDueDates() ||
    this.model.isOnlyVisibleToOverrides() ||
    this.model.nonBaseDates() ||
    this.disableDueAt()
  ) {
    return timeField.tooltip({
      position: {
        my: 'center bottom',
        at: 'center top-10',
        collision: 'fit fit',
      },
      tooltipClass: 'center bottom vertical',
      content() {
        return $($(this).data('tooltipSelector')).html()
      },
    })
  } else if (!timeField.hasClass('hasDatepicker')) {
    timeField.datetime_field()
    return timeField.change(function (e) {
      let newDate
      const trimmedInput = $.trim(e.target.value)
      newDate = timeField.data('unfudged-date')
      newDate = trimmedInput === '' ? null : newDate
      if (tz.isMidnight(newDate)) {
        if (ENV.DEFAULT_DUE_TIME) {
          newDate = tz.parse(tz.format(newDate, '%F ' + ENV.DEFAULT_DUE_TIME))
        } else {
          newDate = tz.changeToTheSecondBeforeMidnight(newDate)
        }
      }
      const dateStr = $.dateString(newDate, {
        format: 'medium',
      })
      const timeStr = $.timeString(newDate)
      return timeField.data('inputdate', newDate).val(dateStr + ' ' + timeStr)
    })
  }
}

CreateAssignmentView.prototype.newAssignmentUrl = function () {
  return ENV.URLS.new_assignment_url
}

CreateAssignmentView.prototype.newQuizUrl = function () {
  return ENV.URLS.new_quiz_url
}

CreateAssignmentView.prototype.validateBeforeSave = function (data, errors) {
  errors = this._validateTitle(data, errors)
  errors = this._validatePointsPossible(data, errors)
  errors = this._validateDueDate(data, errors)
  return errors
}

CreateAssignmentView.prototype._validateTitle = function (data, errors) {
  let max_name_length
  if (includes(this.model.frozenAttributes(), 'title')) {
    return errors
  }
  const post_to_sis = data.post_to_sis === '1'
  max_name_length = 256
  if (
    post_to_sis &&
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT &&
    data.grading_type !== 'not_graded'
  ) {
    max_name_length = ENV.MAX_NAME_LENGTH
  }
  const validationHelper = new SisValidationHelper({
    postToSIS: post_to_sis,
    maxNameLength: max_name_length,
    name: data.name,
    maxNameLengthRequired: ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT,
  })
  if (!data.name || $.trim(data.name.toString()).length === 0) {
    errors.name = [
      {
        message: I18n.t('name_is_required', 'Name is required!'),
      },
    ]
  } else if (validationHelper.nameTooLong()) {
    errors.name = [
      {
        message: I18n.t('Name is too long, must be under %{length} characters', {
          length: max_name_length + 1,
        }),
      },
    ]
  }
  return errors
}

CreateAssignmentView.prototype._validatePointsPossible = function (data, errors) {
  if (includes(this.model.frozenAttributes(), 'points_possible')) {
    return errors
  }
  // eslint-disable-next-line no-restricted-globals
  if (data.points_possible && isNaN(data.points_possible)) {
    errors.points_possible = [
      {
        message: I18n.t('points_possible_number', 'Points possible must be a number'),
      },
    ]
  }
  return errors
}

CreateAssignmentView.prototype._getDueAt = function (dueAt) {
  // # If the minutes value of the date is 59, set the seconds to 59 so
  // # the date ends up being one second before the following hour. Otherwise,
  // # set it to 0 seconds.
  // #
  // # If the user has not changed the date, don't touch the seconds value
  // # (so that we don't clobber a date set by the API).
  if (this._dueAtHasChanged(dueAt.toISOString())) {
    dueAt.setSeconds(dueAt.getMinutes() === 59 ? 59 : 0)
  } else {
    dueAt.setSeconds(new Date(this.model.dueAt()).getSeconds())
  }
  return dueAt.toISOString()
}

CreateAssignmentView.prototype._dueAtHasChanged = function (dueAt) {
  const originalDueAt = new Date(this.model.dueAt())
  const newDueAt = new Date(dueAt)
  // Since a user can't edit the seconds field in the UI and the form also
  // thinks that the seconds is always set to 00, we compare by everything
  // except seconds.
  originalDueAt.setSeconds(0)
  newDueAt.setSeconds(0)
  return originalDueAt.getTime() !== newDueAt.getTime()
}

CreateAssignmentView.prototype._validateDueDate = function (data, errors) {
  if (!data.due_at) {
    return errors
  }
  const validRange = ENV.VALID_DATE_RANGE
  data.lock_at = this.model.lockAt()
  data.unlock_at = this.model.unlockAt()
  data.persisted = !this._dueAtHasChanged(data.due_at)
  const dateValidator = new DateValidator({
    date_range: lodashExtend({}, validRange),
    hasGradingPeriods: !!ENV.HAS_GRADING_PERIODS,
    gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods),
    userIsAdmin: this.currentUserIsAdmin(),
  })
  const errs = dateValidator.validateDatetimes(data)
  if (isEmpty(errs)) {
    return errors
  }
  // need to override default error message to focus only on due date field for quick add/edit
  if (errs.lock_at) {
    errs.due_at = I18n.t('Due date cannot be after lock date')
  }
  if (errs.unlock_at) {
    errs.due_at = I18n.t('Due date cannot be before unlock date')
  }
  errors.due_at = [
    {
      message: errs.due_at,
    },
  ]
  return errors
}

CreateAssignmentView.prototype.roundPointsPossible = function (e) {
  const value = $(e.target).val()
  const rounded_value = round(numberHelper.parse(value), 2)
  // eslint-disable-next-line no-restricted-globals
  if (isNaN(rounded_value)) {
    // do nothing
  } else {
    return $(e.target).val(I18n.n(rounded_value))
  }
}

export default CreateAssignmentView
