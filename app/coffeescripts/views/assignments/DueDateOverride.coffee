define [
  'jquery'
  'Backbone'
  'underscore'
  'react'
  'react-dom'
  'jst/assignments/DueDateOverride'
  'compiled/util/DateValidator'
  'i18n!overrides'
  'jsx/due_dates/DueDates'
  'jsx/due_dates/StudentGroupStore'
  'compiled/api/gradingPeriodsApi'
  'timezone'
], ($, Backbone, _, React, ReactDOM, template, DateValidator, I18n, DueDates, StudentGroupStore, GradingPeriodsAPI, tz) ->

  class DueDateOverrideView extends Backbone.View

    template: template

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
        multipleGradingPeriodsEnabled: @multipleGradingPeriodsEnabled,
        isOnlyVisibleToOverrides: @model.assignment.isOnlyVisibleToOverrides(),
        dueAt: tz.parse(@model.assignment.get("due_at"))
      })

      ReactDOM.render(DueDatesElement, div)

    gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods)

    multipleGradingPeriodsEnabled: !!ENV.MULTIPLE_GRADING_PERIODS_ENABLED

    validateBeforeSave: (data, errors) =>
      return errors unless data
      errors = @validateDatetimes(data, errors)
      errors = @validateTokenInput(data,errors)
      errors = @validateGroupOverrides(data,errors)
      errors

    validateDatetimes: (data, errors) =>
      checkedRows = []
      for override in data.assignment_overrides
        continue if _.contains(checkedRows, override.rowKey)
        dateValidator = new DateValidator({
          date_range: _.extend({}, ENV.VALID_DATE_RANGE)
          data: override
          multipleGradingPeriodsEnabled: @multipleGradingPeriodsEnabled
          gradingPeriods: @gradingPeriods
          userIsAdmin: _.contains(ENV.current_user_roles, "admin"),
          postToSIS: @options.postToSIS || data.postToSIS == '1'
        })
        rowErrors = dateValidator.validateDatetimes()
        errors = _.extend(errors, rowErrors)
        for own element, msg of rowErrors
          $dateInput = $('[data-date-type="'+element+'"][data-row-key="'+override.rowKey+'"]')
          $dateInput.errorBox msg
        checkedRows.push(override.rowKey)
      errors

    validateTokenInput: (data, errors) =>
      validRowKeys = _.pluck(data.assignment_overrides, "rowKey")
      blankOverrideMsg = I18n.t('blank_override', 'You must have a student or section selected')
      for row in $('.Container__DueDateRow-item')
        rowKey = "#{$(row).data('row-key')}"
        continue if _.contains(validRowKeys, rowKey)
        identifier = 'tokenInputFor' + rowKey
        $inputWrapper = $('[data-row-identifier="'+identifier+'"]')[0]
        $nameInput = $($inputWrapper).find("input")
        errors = _.extend(errors, { blankOverrides: [message: blankOverrideMsg] })
        $nameInput.errorBox(blankOverrideMsg).css("z-index", "20")
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
      invalidGroupOverrideMessage = I18n.t('invalid_group_override', "You cannot assign to a group outside of the assignment's group set")
      for row in $('.Container__DueDateRow-item')
        rowKey = "#{$(row).data('row-key')}"
        continue unless _.contains(invalidGroupOverrideRowKeys, rowKey)
        identifier = 'tokenInputFor' + rowKey
        $nameInput = $('[data-row-identifier="'+identifier+'"]').find("input")
        errors = _.extend(errors, { invalidGroupOverride: [message: invalidGroupOverrideMessage] })
        $nameInput.errorBox(invalidGroupOverrideMessage).css("z-index", "20")
      errors

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
