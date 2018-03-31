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
  'i18n!assignment'
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/GradingTypeSelector'
  '../../jquery/toggleAccessibly',
  '../../jquery/fixDialogButtons'
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
    @optionProperty 'lockedItems'

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

    gradingTypeMap: () ->
      percent:      I18n.t 'grading_type_options.percent', 'Percentage'
      pass_fail:    I18n.t 'grading_type_options.pass_fail', 'Complete/Incomplete'
      points:       I18n.t 'grading_type_options.points', 'Points'
      letter_grade: I18n.t 'grading_type_options.letter_grade', 'Letter Grade'
      gpa_scale:    I18n.t 'grading_type_options.gpa_scale', 'GPA Scale'
      not_graded:   I18n.t 'grading_type_options.not_graded', 'Not Graded'

    toJSON: =>
      gradingType: @parentModel.gradingType()
      isNotGraded: @parentModel.isNotGraded()
      isLetterOrGpaGraded: @parentModel.isLetterGraded() || @parentModel.isGpaScaled()
      gpaScaleQuestionLabel: I18n.t('gpa_scale_explainer', "What is GPA Scale Grading?")
      isGpaScaled: @parentModel.isGpaScaled()
      gradingStandardId: @parentModel.gradingStandardId()
      nested: @nested
      preventNotGraded: @preventNotGraded || (@lockedItems?.points && !@parentModel.isNotGraded())
      freezeGradingType: _.include(@parentModel.frozenAttributes(), 'grading_type') ||
                         @parentModel.inClosedGradingPeriod() || (@lockedItems?.points && @parentModel.isNotGraded())
      gradingTypeMap: @gradingTypeMap()
