#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'jquery'
  'Backbone'
  'underscore'
  'react'
  'react-dom'
  'jst/assignments/DueDateOverride'
  '../../util/DateValidator'
  '../ValidatedMixin'
  'i18n!overrides'
  'jsx/due_dates/DueDates'
  'jsx/due_dates/StudentGroupStore'
  '../../api/gradingPeriodsApi'
  'timezone'
  'jquery.instructure_forms.js' # errorBox
], (
  $,
  Backbone,
  _,
  React,
  ReactDOM,
  DueDateOverride,
  DateValidator,
  ValidatedMixin,
  I18n,
  DueDates,
  StudentGroupStore,
  GradingPeriodsAPI,
  tz
) ->

  class DueDateOverrideView extends Backbone.View
    @mixin ValidatedMixin
    template: DueDateOverride

    # =================
    #   ui interaction
    # =================

    render: ->
      div = @$el[0]
      return unless div

      DueDatesElement = React.createElement(DueDates, {
        overrides: @model.overrides.models,
        syncWithBackbone: @setNewOverridesCollection,
        sections: @model.sections.models,
        defaultSectionId: @model.defaultDueDateSectionId,
        selectedGroupSetId: @model.assignment.get("group_category_id"),
        gradingPeriods: @gradingPeriods,
        hasGradingPeriods: @hasGradingPeriods,
        isOnlyVisibleToOverrides: @model.assignment.isOnlyVisibleToOverrides(),
        dueAt: tz.parse(@model.assignment.get("due_at")),
        dueDatesReadonly: @options.dueDatesReadonly,
        availabilityDatesReadonly: @options.availabilityDatesReadonly
      })

      ReactDOM.render(DueDatesElement, div)

    gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods)

    hasGradingPeriods: !!ENV.HAS_GRADING_PERIODS

    validateBeforeSave: (data, errors) =>
      return errors unless data
      errors = @validateDatetimes(data, errors)
      errors = @validateTokenInput(data,errors)
      errors = @validateGroupOverrides(data,errors)
      errors

    postToSIS: (data) =>
      object_type = @model.assignment.objectType()
      data_post_to_sis = data.postToSIS
      post_to_sis = false
      if object_type == 'Assignment' || object_type == 'Discussion'
        grading_type = $('#assignment_grading_type').find(":selected").val()
        post_to_sis = grading_type != 'not_graded' && data_post_to_sis
      else if object_type == 'Quiz'
        grading_type = $('#quiz_assignment_id').find(":selected").val()
        valid_grading_type = grading_type != 'practice_quiz' && grading_type != 'survey'
        post_to_sis = valid_grading_type && data_post_to_sis
      post_to_sis

    clearExistingDueDateErrors: =>
      for element in ['due_at', 'unlock_at', 'lock_at']
        $dateInput = $('[data-date-type="'+element+'"]')
        $dateInput.removeAttr('data-error-type')

    validateDatetimes: (data, errors) =>
      # Need to clear these out each pass in order to ensure proper
      # focus handling for accessibility
      @clearExistingDueDateErrors(data)
      checkedRows = []
      for override in data.assignment_overrides
        # Don't validate duplicates
        continue if _.contains(checkedRows, override.rowKey)

        dateValidator = new DateValidator({
          date_range: _.extend({}, ENV.VALID_DATE_RANGE)
          data: override
          forIndividualStudents: override.student_ids?.length
          hasGradingPeriods: @hasGradingPeriods
          gradingPeriods: @gradingPeriods
          userIsAdmin: _.contains(ENV.current_user_roles, "admin"),
          postToSIS: @postToSIS(data)
        })
        rowErrors = dateValidator.validateDatetimes()
        _.keys(rowErrors).forEach((key, val) =>
          rowErrors[key] = {message: rowErrors[key]}
        )
        errors = _.extend(errors, rowErrors)
        for own element, msg of rowErrors
          $dateInput = $('[data-date-type="'+element+'"][data-row-key="'+override.rowKey+'"]')
          $dateInput.attr('data-error-type', element)
          msg = _.extend(msg, { element: $dateInput, showError: @showError })
        checkedRows.push(override.rowKey)
      errors

    validateTokenInput: (data, errors) =>
      validRowKeys = _.pluck(data.assignment_overrides, "rowKey")
      blankOverrideMsg = I18n.t('You must have a student or section selected')
      for row in $('.Container__DueDateRow-item')
        rowKey = "#{$(row).attr('data-row-key')}"
        identifier = 'tokenInputFor' + rowKey
        $inputWrapper = $('[data-row-identifier="'+identifier+'"]')[0]
        $nameInput = $($inputWrapper).find("input")
        $nameInput.removeAttr('data-error-type')
        continue if _.contains(validRowKeys, rowKey)
        errors = _.extend(errors, { blankOverrides: {message: blankOverrideMsg, element: $nameInput, showError: @showError} })
        $nameInput.attr('data-error-type', "blankOverrides")
      errors

    validateGroupOverrides: (data, errors) =>
      # if the StudentGroupStore hasn't gotten all of the group data
      # then skip the front end validation as it might result
      # in an annoying false positive
      # note: the backend will still catch this issue
      return errors unless StudentGroupStore.fetchComplete()

      validGroups = StudentGroupStore.groupsFilteredForSelectedSet()
      validGroupIds = _.pluck(validGroups, "id")
      groupOverrides = _.filter(data.assignment_overrides, (ao) -> !!ao.group_id)
      invalidGroupOverrides = _.filter(groupOverrides, (ao) ->
        ao.group_id not in validGroupIds
      )
      invalidGroupOverrideRowKeys = _.pluck(invalidGroupOverrides, "rowKey")
      invalidGroupOverrideMessage = I18n.t("You cannot assign to a group outside of the assignment's group set")
      for row in $('.Container__DueDateRow-item')
        rowKey = "#{$(row).attr('data-row-key')}"
        continue unless _.contains(invalidGroupOverrideRowKeys, rowKey)
        identifier = 'tokenInputFor' + rowKey
        $nameInput = $('[data-row-identifier="'+identifier+'"]').find("input")
        errors = _.extend(errors, { invalidGroupOverride: {message: invalidGroupOverrideMessage, element: $nameInput, showError: @showError} })
      errors

    showError: (element, message) =>
      # some forms will already handle this on their own, this exists
      # as a fallback for forms that do not
      return unless element
      element.errorBox(message).css("z-index", "20").attr('role', 'alert')

    # ==============================
    #     syncing with react data
    # ==============================

    setNewOverridesCollection: (newOverrides) =>
      @model.overrides.reset(newOverrides)
      onlyVisibleToOverrides = !@model.overrides.containsDefaultDueDate()
      @model.assignment.isOnlyVisibleToOverrides(onlyVisibleToOverrides)

    # =================
    #    model info
    # =================

    getDefaultDueDate: =>
      @model.getDefaultDueDate()

    containsSectionsWithoutOverrides: =>
      @model.containsSectionsWithoutOverrides()

    overridesContainDefault: =>
      @model.overridesContainDefault()

    sectionsWithoutOverrides: =>
      @model.sectionsWithoutOverrides()

    getOverrides: =>
      @model.overrides.toJSON()

    getAllDates: () =>
      @model.overrides.datesJSON()
