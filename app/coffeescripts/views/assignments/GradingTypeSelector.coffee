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
    GPA_SCALE_QUESTION = '#gpa-scale-question'

    els: do ->
      els = {}
      els["#{GRADING_TYPE}"] = "$gradingType"
      els["#{VIEW_GRADING_LEVELS}"] = "$viewGradingLevels"
      els["#{GPA_SCALE_QUESTION}"] = "$gpaScaleQuestion"
      els

    events: do ->
      events = {}
      events["change #{GRADING_TYPE}"] = 'handleGradingTypeChange'
      events["click .edit_letter_grades_link"] = 'showGradingSchemeDialog'
      events["click #{GPA_SCALE_QUESTION}"] = 'showGpaDialog'
      events

    @optionProperty 'parentModel'
    @optionProperty 'nested'
    @optionProperty 'preventNotGraded'

    handleGradingTypeChange: (ev) =>
      gradingType = @$gradingType.val()
      @$viewGradingLevels.toggleAccessibly(gradingType == 'letter_grade' || gradingType == 'gpa_scale')
      @$gpaScaleQuestion.toggleAccessibly(gradingType == 'gpa_scale')
      @showGpaDialog
      @trigger 'change:gradingType', gradingType

    showGpaDialog: (ev) =>
      ev.preventDefault()
      $("#gpa-scale-dialog").dialog(
        title: I18n.t('titles.gpa_scale_explainer', "What is GPA Scale Grading?"),
        text: I18n.t('gpa_scale_explainer', "What is GPA Scale Grading?"),
        width: 600,
        height: 310,
        close: -> $(ev.target).focus()
      )

    showGradingSchemeDialog: (ev) =>
      # TODO: clean up. slightly dependent on grading_standards.js
      # NOTE grading_standards.js is loaded in a course settings
      # context while this coffeescript appears not to be.
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
      isLetterOrGpaGraded: @parentModel.isLetterGraded() || @parentModel.isGpaScaled()
      gpaScaleQuestionLabel: I18n.t('gpa_scale_explainer', "What is GPA Scale Grading?")
      isGpaScaled: @parentModel.isGpaScaled()
      gradingStandardId: @parentModel.gradingStandardId()
      frozenAttributes: @parentModel.frozenAttributes()
      nested: @nested
      preventNotGraded: @preventNotGraded
      inClosedGradingPeriod: @parentModel.inClosedGradingPeriod
