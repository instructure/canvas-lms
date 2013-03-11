define [
  'i18n!assignment'
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/GradingTypeSelector'
  'compiled/jquery/toggleAccessibly',
  'compiled/jquery/fixDialogButtons'
], (I18n, Backbone, _, $, template) ->

  class GradingTypeSelector extends Backbone.View

    template: template

    GRADING_TYPE = '#assignment_grading_type'
    VIEW_GRADING_LEVELS = '#view-grading-levels'

    els: do ->
      els = {}
      els["#{GRADING_TYPE}"] = "$gradingType"
      els["#{VIEW_GRADING_LEVELS}"] = "$viewGradingLevels"
      els

    events: do ->
      events = {}
      events["change #{GRADING_TYPE}"] = 'handleGradingTypeChange'
      events["click .edit_letter_grades_link"] = 'showGradingSchemeDialog'
      events

    @optionProperty 'parentModel'
    @optionProperty 'nested'
    @optionProperty 'preventNotGraded'

    handleGradingTypeChange: (ev) =>
      gradingType = @$gradingType.val()
      @$viewGradingLevels.toggleAccessibly gradingType == 'letter_grade'
      @trigger 'change:gradingType', gradingType

    showGradingSchemeDialog: (ev) =>
      # TODO: clean up. slightly dependent on grading_standards.js
      ev.preventDefault()
      $("#edit_letter_grades_form").dialog(
        title: I18n.t('titles.grading_scheme_info', "View/Edit Grading Scheme"),
        width: 600,
        height: 310,
        close: -> $(ev.target).focus()
      ).fixDialogButtons()

    toJSON: =>
      gradingType: @parentModel.gradingType()
      isNotGraded: @parentModel.isNotGraded()
      isLetterGraded: @parentModel.isLetterGraded()
      gradingStandardId: @parentModel.gradingStandardId()
      frozenAttributes: @parentModel.frozenAttributes()
      nested: @nested
      preventNotGraded: @preventNotGraded
