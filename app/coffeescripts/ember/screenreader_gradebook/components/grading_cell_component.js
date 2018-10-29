//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!grading_cell'
import GRADEBOOK_TRANSLATIONS from '../../../gradebook/GradebookTranslations'
import GradebookHelpers from '../../../gradebook/GradebookHelpers'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'
import OutlierScoreHelper from 'jsx/grading/helpers/OutlierScoreHelper'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import _ from 'underscore'
import Ember from 'ember'
import $ from 'jquery'
import 'jquery.ajaxJSON'

const GradingCellComponent = Ember.Component.extend({
  value: null,
  excused: null,
  shouldSaveExcused: false,

  isPoints: Ember.computed.equal('assignment.grading_type', 'points'),
  isPercent: Ember.computed.equal('assignment.grading_type', 'percent'),
  isLetterGrade: Ember.computed.equal('assignment.grading_type', 'letter_grade'),
  isPassFail: Ember.computed.equal('assignment.grading_type', 'pass_fail'),
  isInPastGradingPeriodAndNotAdmin: function() {
    return this.submission != null ? this.submission.gradeLocked : undefined
  }.property('submission'),
  nilPointsPossible: Ember.computed.none('assignment.points_possible'),
  isGpaScale: Ember.computed.equal('assignment.grading_type', 'gpa_scale'),

  passFailGrades: [
    {
      label: I18n.t('grade_ungraded', 'Ungraded'),
      value: '-'
    },
    {
      label: I18n.t('grade_complete', 'Complete'),
      value: 'complete'
    },
    {
      label: I18n.t('grade_incomplete', 'Incomplete'),
      value: 'incomplete'
    },
    {
      label: I18n.t('Excused'),
      value: 'EX'
    }
  ],

  outOfText: function() {
    if (this.submission && this.submission.excused) {
      return I18n.t('Excused')
    } else if (this.get('isGpaScale')) {
      return ''
    } else if (this.get('isLetterGrade') || this.get('isPassFail')) {
      return I18n.t('(%{score} out of %{points})', {
        points: I18n.n(this.assignment.points_possible),
        score: this.get('entered_score')
      })
    } else if (this.get('nilPointsPossible')) {
      return I18n.t('No points possible')
    } else {
      return I18n.t('(out of %{points})', {points: I18n.n(this.assignment.points_possible)})
    }
  }.property('submission.score', 'assignment'),

  changeGradeURL() {
    return ENV.GRADEBOOK_OPTIONS.change_grade_url
  },

  saveURL: function() {
    const submission = this.get('submission')
    return this.changeGradeURL()
      .replace(':assignment', submission.assignment_id)
      .replace(':submission', submission.user_id)
  }.property('submission.assignment_id', 'submission.user_id'),

  score: function() {
    if (this.submission.score != null) {
      return I18n.n(this.submission.score)
    } else {
      return ' -'
    }
  }.property('submission.score'),

  entered_score: function() {
    if (this.submission.entered_score != null) {
      return I18n.n(this.submission.entered_score)
    } else {
      return ' -'
    }
  }.property('submission.entered_score'),

  late_penalty: function() {
    if (this.submission.points_deducted != null) {
      return I18n.n(-1 * this.submission.points_deducted)
    } else {
      return ' -'
    }
  }.property('submission.points_deducted'),

  points_possible: function() {
    if (this.assignment.points_possible != null) {
      return I18n.n(this.assignment.points_possible)
    } else {
      return ' -'
    }
  }.property('assignment.points_possible'),

  final_grade: function() {
    if (this.submission.grade != null) {
      return GradeFormatHelper.formatGrade(this.submission.grade)
    } else {
      return ' -'
    }
  }.property('submission.grade'),

  ajax(url, options) {
    const {type, data} = options
    return $.ajaxJSON(url, type, data)
  },

  excusedToggled: function() {
    if (this.shouldSaveExcused) {
      this.updateSubmissionExcused()
    }
  }.observes('excused'),

  updateSubmissionExcused() {
    const url = this.get('saveURL')
    const value = __guard__(this.$('#submission-excused'), x => x[0].checked)

    const save = this.ajax(url, {
      type: 'PUT',
      data: {'submission[excuse]': value}
    })
    return save.then(this.boundUpdateSuccess, this.onUpdateError)
  },

  setExcusedWithoutTriggeringSave(isExcused) {
    this.shouldSaveExcused = false
    this.set('excused', isExcused)
    return (this.shouldSaveExcused = true)
  },

  submissionDidChange: function() {
    const newVal = (this.submission != null
    ? this.submission.excused
    : undefined)
      ? 'EX'
      : (this.submission != null ? this.submission.entered_grade : undefined) || '-'

    this.setExcusedWithoutTriggeringSave(
      this.submission != null ? this.submission.excused : undefined
    )
    if (this.get('isPassFail')) {
      this.set('value', newVal)
    } else {
      this.set('value', GradeFormatHelper.formatGrade(newVal))
    }
  }
    .observes('submission')
    .on('init'),

  onUpdateSuccess(submission) {
    this.sendAction('on-submit-grade', submission.all_submissions)
    if (!submission.excused) {
      const outlierScoreHelper = new OutlierScoreHelper(
        submission.score,
        this.assignment.points_possible
      )
      if (outlierScoreHelper.hasWarning()) {
        $.flashWarning(outlierScoreHelper.warningMessage())
      }
    }
  },

  onUpdateError() {
    $.flashError(GRADEBOOK_TRANSLATIONS.submission_update_error)
  },

  focusOut(event) {
    const isGradeInput = event.target.id === 'student_and_assignment_grade'
    const submission = this.get('submission')

    if (!submission || !isGradeInput) {
      return
    }

    const url = this.get('saveURL')
    let value = this.$('input, select').val()

    const excused = typeof value === 'string' && value.toUpperCase() === 'EX'
    this.setExcusedWithoutTriggeringSave(excused)

    if (this.get('isPassFail') && value === '-') {
      value = ''
    }

    value = GradeFormatHelper.delocalizeGrade(value)

    if (value === submission.grade) {
      return
    }
    const data =
      typeof value === 'string' && value.toUpperCase() === 'EX'
        ? {'submission[excuse]': true}
        : {'submission[posted_grade]': value}
    const save = this.ajax(url, {
      type: 'PUT',
      data
    })
    return save.then(this.boundUpdateSuccess, this.onUpdateError)
  },

  bindSave: function() {
    this.boundUpdateSuccess = _.bind(this.onUpdateSuccess, this)
  }.on('init'),

  click(event) {
    const {target} = event
    const hasCheckboxClass = target.classList[0] === 'checkbox'
    const isCheckBox = target.type === 'checkbox'

    if (hasCheckboxClass || isCheckBox) {
      return this.$('#submission-excused').focus()
    } else {
      return this.$('input, select').select()
    }
  },

  focus() {
    return this.$('input, select').select()
  }
})

export default GradingCellComponent

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
