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
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import DueDateOverride from '@canvas/assignments/jst/DueDateOverride.handlebars'
import DateValidator from '@canvas/grading/DateValidator'
import ValidatedMixin from '@canvas/forms/backbone/views/ValidatedMixin'
import {useScope as useI18nScope} from '@canvas/i18n'
import DueDates from '../../react/DueDates'
import CoursePacingNotice from '../../react/CoursePacingNotice'
import StudentGroupStore from '../../react/StudentGroupStore'
import DifferentiatedModulesSection from '../../react/DifferentiatedModulesSection'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'
import * as tz from '@canvas/datetime'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('DueDateOverrideView')

const indexOf = [].indexOf
const hasProp = {}.hasOwnProperty

extend(DueDateOverrideView, Backbone.View)

function DueDateOverrideView() {
  this.getAllDates = this.getAllDates.bind(this)
  this.getOverrides = this.getOverrides.bind(this)
  this.sectionsWithoutOverrides = this.sectionsWithoutOverrides.bind(this)
  this.overridesContainDefault = this.overridesContainDefault.bind(this)
  this.containsSectionsWithoutOverrides = this.containsSectionsWithoutOverrides.bind(this)
  this.getDefaultDueDate = this.getDefaultDueDate.bind(this)
  this.setNewOverridesCollection = this.setNewOverridesCollection.bind(this)
  this.showError = this.showError.bind(this)
  this.validateGroupOverrides = this.validateGroupOverrides.bind(this)
  this.validateTokenInput = this.validateTokenInput.bind(this)
  this.validateDatetimes = this.validateDatetimes.bind(this)
  this.clearExistingDueDateErrors = this.clearExistingDueDateErrors.bind(this)
  this.postToSIS = this.postToSIS.bind(this)
  this.validateBeforeSave = this.validateBeforeSave.bind(this)
  return DueDateOverrideView.__super__.constructor.apply(this, arguments)
}

DueDateOverrideView.mixin(ValidatedMixin)

DueDateOverrideView.prototype.template = DueDateOverride

// =================
//   ui interaction
// =================
DueDateOverrideView.prototype.render = function () {
  const div = this.$el[0]
  if (!div) {
    return
  }
  if (this.options && this.options.inPacedCourse && this.options.isModuleItem) {
    return ReactDOM.render(
      React.createElement(CoursePacingNotice, {
        courseId: this.options.courseId,
      }),
      div
    )
  }

  const assignToSection = ENV.FEATURES?.differentiated_modules
    ? React.createElement(DifferentiatedModulesSection, {
        onSync: this.setNewOverridesCollection,
        defaultSectionId: this.model.defaultDueDateSectionId,
        overrides: this.model.overrides.models.map(model => model.toJSON().assignment_override),
        assignmentId: this.model.assignment.get('id'),
        assignmentName: this.model.assignment.get('name') || this.model.assignment.get('title'),
        isOnlyVisibleToOverrides: this.model.assignment.isOnlyVisibleToOverrides(),
        pointsPossible: this.model.assignment.get('points_possible'),
        type: this.model.assignment.objectType().toLowerCase(),
        importantDates: this.model.assignment.get('important_dates'),
        onTrayOpen: () => this.trigger('tray:open'),
        onTrayClose: () => this.trigger('tray:close'),
      })
    : React.createElement(DueDates, {
        overrides: this.model.overrides.models,
        syncWithBackbone: this.setNewOverridesCollection,
        sections: this.model.sections.models,
        defaultSectionId: this.model.defaultDueDateSectionId,
        selectedGroupSetId: this.model.assignment.get('group_category_id'),
        gradingPeriods: this.gradingPeriods,
        hasGradingPeriods: this.hasGradingPeriods,
        isOnlyVisibleToOverrides: this.model.assignment.isOnlyVisibleToOverrides(),
        dueAt: tz.parse(this.model.assignment.get('due_at')),
        dueDatesReadonly: this.options.dueDatesReadonly,
        availabilityDatesReadonly: this.options.availabilityDatesReadonly,
        importantDates: this.model.assignment.get('important_dates'),
        defaultDueTime: ENV.DEFAULT_DUE_TIME,
      })

  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(assignToSection, div)
}

DueDateOverrideView.prototype.gradingPeriods = GradingPeriodsAPI.deserializePeriods(
  ENV.active_grading_periods
)

DueDateOverrideView.prototype.hasGradingPeriods = !!ENV.HAS_GRADING_PERIODS

DueDateOverrideView.prototype.validateBeforeSave = function (data, errors) {
  if (!data) {
    return errors
  }
  errors = this.validateDatetimes(data, errors)
  errors = this.validateTokenInput(data, errors)
  errors = this.validateGroupOverrides(data, errors)
  return errors
}

DueDateOverrideView.prototype.postToSIS = function (data) {
  let grading_type, post_to_sis, valid_grading_type
  const object_type = this.model.assignment.objectType()
  const data_post_to_sis = data.postToSIS
  post_to_sis = false
  if (object_type === 'Assignment' || object_type === 'Discussion') {
    grading_type = $('#assignment_grading_type').find(':selected').val()
    post_to_sis = grading_type !== 'not_graded' && data_post_to_sis
  } else if (object_type === 'Quiz') {
    grading_type = $('#quiz_assignment_id').find(':selected').val()
    valid_grading_type = grading_type !== 'practice_quiz' && grading_type !== 'survey'
    post_to_sis = valid_grading_type && data_post_to_sis
  }
  return post_to_sis
}

DueDateOverrideView.prototype.clearExistingDueDateErrors = function () {
  const ref = ['due_at', 'unlock_at', 'lock_at']
  const results = []
  for (let i = 0, len = ref.length; i < len; i++) {
    const element = ref[i]
    const $dateInput = $('[data-date-type="' + element + '"]')
    results.push($dateInput.removeAttr('data-error-type'))
  }
  return results
}

DueDateOverrideView.prototype.validateDatetimes = function (data, errors) {
  // Need to clear these out each pass in order to ensure proper
  // focus handling for accessibility
  let $dateInput, element, i, len, msg, override, rowErrors
  this.clearExistingDueDateErrors(data)
  const checkedRows = []
  const dateValidator = new DateValidator({
    date_range: {...ENV.VALID_DATE_RANGE},
    hasGradingPeriods: this.hasGradingPeriods,
    gradingPeriods: this.gradingPeriods,
    userIsAdmin: ENV.current_user_is_admin,
    postToSIS: this.postToSIS(data),
  })
  // Don't validate duplicates
  const ref = data.assignment_overrides
  for (i = 0, len = ref.length; i < len; i++) {
    override = ref[i]
    if ((checkedRows || []).includes(override.rowKey)) {
      continue
    }
    rowErrors = dateValidator.validateDatetimes(override)
    // eslint-disable-next-line no-loop-func
    Object.keys(rowErrors).forEach(function (key) {
      return (rowErrors[key] = {
        message: rowErrors[key],
      })
    })
    errors = Object.assign(errors, rowErrors)
    for (element in rowErrors) {
      if (!hasProp.call(rowErrors, element)) continue
      msg = rowErrors[element]
      $dateInput = $('[data-date-type="' + element + '"][data-row-key="' + override.rowKey + '"]')
      $dateInput.attr('data-error-type', element)
      msg = Object.assign(msg, {
        element: $dateInput,
        showError: this.showError,
      })
    }
    checkedRows.push(override.rowKey)
  }
  return errors
}

DueDateOverrideView.prototype.validateTokenInput = function (data, errors) {
  let $inputWrapper, $nameInput, i, identifier, len, row, rowKey
  const validRowKeys = (data.assignment_overrides || []).map(function (e) {
    return e.rowKey
  })
  const blankOverrideMsg = I18n.t('You must have a student or section selected')
  const ref = $('.Container__DueDateRow-item')
  for (i = 0, len = ref.length; i < len; i++) {
    row = ref[i]
    rowKey = '' + $(row).attr('data-row-key')
    identifier = 'tokenInputFor' + rowKey
    $inputWrapper = $('[data-row-identifier="' + identifier + '"]')[0]
    $nameInput = $($inputWrapper).find('input')
    $nameInput.removeAttr('data-error-type')
    if ((validRowKeys || []).includes(rowKey)) {
      continue
    }
    errors = Object.assign(errors, {
      blankOverrides: {
        message: blankOverrideMsg,
        element: $nameInput,
        showError: this.showError,
      },
    })
    $nameInput.attr('data-error-type', 'blankOverrides')
  }
  return errors
}

DueDateOverrideView.prototype.validateGroupOverrides = function (data, errors) {
  // if the StudentGroupStore hasn't gotten all of the group data
  // then skip the front end validation as it might result
  // in an annoying false positive
  // note: the backend will still catch this issue
  let $nameInput, i, identifier, len, row, rowKey
  if (!StudentGroupStore.fetchComplete()) {
    return errors
  }
  const validGroups = StudentGroupStore.groupsFilteredForSelectedSet()
  const validGroupIds = (validGroups || []).map(function (e) {
    return e.id
  })
  const groupOverrides = data.assignment_overrides.filter(function (ao) {
    return !!ao.group_id
  })
  const invalidGroupOverrides = groupOverrides.filter(function (ao) {
    const ref = ao.group_id
    return indexOf.call(validGroupIds, ref) < 0
  })
  const invalidGroupOverrideRowKeys = (invalidGroupOverrides || []).map(function (e) {
    return e.rowKey
  })
  const invalidGroupOverrideMessage = I18n.t(
    "You cannot assign to a group outside of the assignment's group set"
  )
  const ref = $('.Container__DueDateRow-item')
  for (i = 0, len = ref.length; i < len; i++) {
    row = ref[i]
    rowKey = '' + $(row).attr('data-row-key')
    if (!(invalidGroupOverrideRowKeys || []).includes(rowKey)) {
      continue
    }
    identifier = 'tokenInputFor' + rowKey
    $nameInput = $('[data-row-identifier="' + identifier + '"]').find('input')
    errors = Object.assign(errors, {
      invalidGroupOverride: {
        message: invalidGroupOverrideMessage,
        element: $nameInput,
        showError: this.showError,
      },
    })
  }
  return errors
}

DueDateOverrideView.prototype.showError = function (element, message) {
  // some forms will already handle this on their own, this exists
  // as a fallback for forms that do not
  if (!element) {
    return
  }
  return element.errorBox(message).css('z-index', '20').attr('role', 'alert')
}

// ==============================
//     syncing with react data
// ==============================

DueDateOverrideView.prototype.setNewOverridesCollection = function (newOverrides, importantDates) {
  if (newOverrides !== undefined) {
    this.model.overrides.reset(newOverrides)
    const onlyVisibleToOverrides = !this.model.overrides.containsDefaultDueDate()
    this.model.assignment.isOnlyVisibleToOverrides(onlyVisibleToOverrides)
  }
  return this.model.assignment.importantDates(importantDates)
}

// =================
//    model info
// =================
DueDateOverrideView.prototype.getDefaultDueDate = function () {
  return this.model.getDefaultDueDate()
}

DueDateOverrideView.prototype.containsSectionsWithoutOverrides = function () {
  return this.model.containsSectionsWithoutOverrides()
}

DueDateOverrideView.prototype.overridesContainDefault = function () {
  return this.model.overridesContainDefault()
}

DueDateOverrideView.prototype.sectionsWithoutOverrides = function () {
  return this.model.sectionsWithoutOverrides()
}

DueDateOverrideView.prototype.getOverrides = function () {
  return this.model.overrides.toJSON()
}

DueDateOverrideView.prototype.getAllDates = function () {
  return this.model.overrides.datesJSON()
}

export default DueDateOverrideView
