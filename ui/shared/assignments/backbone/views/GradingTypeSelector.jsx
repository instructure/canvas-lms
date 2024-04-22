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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {includes} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/GradingTypeSelector.handlebars'
import '../../jquery/toggleAccessibly'
import '@canvas/util/jquery/fixDialogButtons'
import React from 'react'
import ReactDOM from 'react-dom'
import {GradingSchemesSelector} from '@canvas/grading-scheme'

const I18n = useI18nScope('assignment_grading_type')

const GRADING_TYPE = '#assignment_grading_type'
const VIEW_GRADING_LEVELS = '#view-grading-levels'
const GPA_SCALE_QUESTION = '#gpa-scale-question'

extend(GradingTypeSelector, Backbone.View)

function GradingTypeSelector() {
  this.toJSON = this.toJSON.bind(this)
  this.showGradingSchemeDialog = this.showGradingSchemeDialog.bind(this)
  this.showGpaDialog = this.showGpaDialog.bind(this)
  this.handleGradingTypeChange = this.handleGradingTypeChange.bind(this)
  return GradingTypeSelector.__super__.constructor.apply(this, arguments)
}

GradingTypeSelector.prototype.template = template

GradingTypeSelector.prototype.els = (function () {
  const els = {}
  els['' + GRADING_TYPE] = '$gradingType'
  els['' + VIEW_GRADING_LEVELS] = '$viewGradingLevels'
  els['' + GPA_SCALE_QUESTION] = '$gpaScaleQuestion'
  return els
})()

GradingTypeSelector.prototype.events = (function () {
  const events = {}
  events['change ' + GRADING_TYPE] = 'handleGradingTypeChange'
  events['click .edit_letter_grades_link'] = 'showGradingSchemeDialog'
  events['click ' + GPA_SCALE_QUESTION] = 'showGpaDialog'
  return events
})()

GradingTypeSelector.optionProperty('parentModel')

GradingTypeSelector.optionProperty('nested')

GradingTypeSelector.optionProperty('preventNotGraded')

GradingTypeSelector.optionProperty('lockedItems')

GradingTypeSelector.optionProperty('canEditGrades')

GradingTypeSelector.prototype.handleGradingTypeChange = function (_ev) {
  const gradingType = this.$gradingType.val()
  this.$viewGradingLevels.toggleAccessibly(
    gradingType === 'letter_grade' || gradingType === 'gpa_scale'
  )
  if (ENV.GRADING_SCHEME_UPDATES_ENABLED) {
    if (gradingType === 'letter_grade' || gradingType === 'gpa_scale') {
      $('#grading_scheme_selector-target').show()
      this.renderGradingSchemeSelector()
    } else {
      $('#grading_scheme_selector-target').hide()
    }
  }
  this.$gpaScaleQuestion.toggleAccessibly(gradingType === 'gpa_scale')
  // ¯\_(ツ)_/¯
  // was only an expression in CoffeeScript
  // this.showGpaDialog
  return this.trigger('change:gradingType', gradingType)
}

GradingTypeSelector.prototype.showGpaDialog = function (ev) {
  ev.preventDefault()
  return $('#gpa-scale-dialog').dialog({
    title: I18n.t('titles.gpa_scale_explainer', 'What is GPA Scale Grading?'),
    text: I18n.t('gpa_scale_explainer', 'What is GPA Scale Grading?'),
    width: 600,
    height: 310,
    close() {
      return $(ev.target).focus()
    },
    modal: true,
    zIndex: 1000,
  })
}

GradingTypeSelector.prototype.showGradingSchemeDialog = function (ev) {
  // TODO: clean up. slightly dependent on grading_standards.js
  // NOTE grading_standards.js is loaded in a course settings
  // context while this coffeescript appears not to be.
  ev.preventDefault()
  return $('#edit_letter_grades_form')
    .dialog({
      title: I18n.t('titles.grading_scheme_info', 'View/Edit Grading Scheme'),
      width: 600,
      height: 310,
      close() {
        return $(ev.target).focus()
      },
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()
}

GradingTypeSelector.prototype.gradingTypeMap = function () {
  return {
    percent: I18n.t('grading_type_options.percent', 'Percentage'),
    pass_fail: I18n.t('grading_type_options.pass_fail', 'Complete/Incomplete'),
    points: I18n.t('grading_type_options.points', 'Points'),
    letter_grade: I18n.t('grading_type_options.letter_grade', 'Letter Grade'),
    gpa_scale: I18n.t('grading_type_options.gpa_scale', 'GPA Scale'),
    not_graded: I18n.t('grading_type_options.not_graded', 'Not Graded'),
  }
}

GradingTypeSelector.prototype.toJSON = function () {
  let ref, ref1
  return {
    gradingType: this.parentModel.gradingType(),
    isNotGraded: this.parentModel.isNotGraded(),
    isLetterOrGpaGraded: this.parentModel.isLetterGraded() || this.parentModel.isGpaScaled(),
    gpaScaleQuestionLabel: I18n.t('gpa_scale_explainer', 'What is GPA Scale Grading?'),
    isGpaScaled: this.parentModel.isGpaScaled(),
    gradingStandardId: this.parentModel.gradingStandardId(),
    grading_scheme_updates:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.GRADING_SCHEME_UPDATES_ENABLED : void 0) ||
      false,
    nested: this.nested,
    preventNotGraded:
      this.preventNotGraded ||
      (((ref = this.lockedItems) != null ? ref.points : void 0) && !this.parentModel.isNotGraded()),
    freezeGradingType:
      includes(this.parentModel.frozenAttributes(), 'grading_type') ||
      this.parentModel.inClosedGradingPeriod() ||
      (((ref1 = this.lockedItems) != null ? ref1.points : void 0) &&
        this.parentModel.isNotGraded()) ||
      (!this.canEditGrades && this.parentModel.gradedSubmissionsExist()),
    gradingTypeMap: this.gradingTypeMap(),
  }
}

GradingTypeSelector.prototype.afterRender = function () {
  const gradingType = this.$gradingType.val()
  if (gradingType === 'letter_grade' || gradingType === 'gpa_scale') {
    this.renderGradingSchemeSelector()
  }
}

GradingTypeSelector.prototype.handleGradingStandardIdChanged = function (gradingStandardId) {
  $('.grading_standard_id').val(gradingStandardId)
}

GradingTypeSelector.prototype.renderGradingSchemeSelector = function () {
  if (!(typeof ENV !== 'undefined' && ENV !== null ? ENV.GRADING_SCHEME_UPDATES_ENABLED : void 0)) {
    return
  }
  // Is there a default for the course?
  const courseDefaultGradingSchemeId = ENV.COURSE_DEFAULT_GRADING_SCHEME_ID
  const props = {
    initiallySelectedGradingSchemeId: this.parentModel.gradingStandardId()
      ? this.parentModel.gradingStandardId()
      : undefined,
    canManage: ENV.PERMISSIONS.manage_grading_schemes,
    courseDefaultSchemeId: courseDefaultGradingSchemeId,
    onChange: this.handleGradingStandardIdChanged,
    contextId: ENV.COURSE_ID,
    contextType: 'Course',
    archivedGradingSchemesEnabled: ENV.ARCHIVED_GRADING_SCHEMES_ENABLED,
    assignmentId: ENV.ASSIGNMENT?.id ?? this.parentModel.id ? String(this.parentModel.id) : undefined,
  }
  const mountPoint = document.querySelector('#grading_scheme_selector-target')
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(React.createElement(GradingSchemesSelector, props), mountPoint)
}

export default GradingTypeSelector
