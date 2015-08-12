define [
  'Backbone'
  'underscore'
  'react'
  'jst/assignments/DueDateOverride'
  'compiled/util/DateValidator'
  'i18n!overrides'
  'jsx/due_dates/DueDates'
], (Backbone, _, React, template, DateValidator, I18n, DueDates) ->

  class DueDateOverrideView extends Backbone.View

    template: template

    # =================
    #   ui interaction
    # =================

    render: ->
      div = @$el[0]
      return unless div

      DueDates = React.createFactory(DueDates)
      React.render(
        DueDates(
          overrides: @model.overrides.models,
          syncWithBackbone: @setNewOverridesCollection,
          sections: @model.sections.models,
          defaultSectionId: @model.defaultDueDateSectionId
        ), div)

    validateBeforeSave: (data, errors) =>
      return errors unless data
      errors = @validateDates(data, errors)
      errors = @validateTokenInput(data,errors)
      errors

    validateDates: (data, errors) =>
      checkedRows = []
      for override in data.assignment_overrides
        continue if _.contains(checkedRows, override.rowKey)
        dateValidator = new DateValidator({date_range: ENV.VALID_DATE_RANGE, data: override})
        rowErrors = dateValidator.validateDates()
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

    # ==============================
    #     syncing with react data
    # ==============================

    setNewOverridesCollection: (newOverrides) =>
      @model.overrides.reset(newOverrides)
      onlyVisibleToOverrides = ENV.DIFFERENTIATED_ASSIGNMENTS_ENABLED && !@model.overrides.containsDefaultDueDate()
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
