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

import Ember from 'ember'
import {scoreToGrade} from '@instructure/grading-utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {scoreToScaledPoints} from '@canvas/grading/GradeCalculationHelper'

const I18n = useI18nScope('sr_gradebook')

const FinalGradeComponent = Ember.Component.extend({
  percent: function () {
    const percent = this.get('student.total_percent')
    let scoreText = I18n.n(percent, {percentage: true})

    if (this.get('gradingStandard') && this.get('gradingStandardPointsBased')) {
      const scalingFactor = this.get('gradingStandardScalingFactor')
      const studentTotalGrade = this.get('student.total_grade')
      if (studentTotalGrade.possible) {
        const scaledPossible = I18n.n(scalingFactor, {
          precision: 1,
        })
        const scaledScore = I18n.n(
          scoreToScaledPoints(studentTotalGrade.score, studentTotalGrade.possible, scalingFactor),
          {
            precision: 1,
          }
        )
        scoreText = `${scaledScore} / ${scaledPossible}`
      }
    }
    return scoreText
  }.property('student.total_percent', 'student.total_grade', 'grading_standard', 'student'),

  pointRatioDisplay: function () {
    return I18n.t('final_point_ratio', '%{pointRatio} points', {pointRatio: this.get('pointRatio')})
  }.property('pointRatio'),

  pointRatio: function () {
    return `${I18n.n(this.get('student.total_grade.score'))} / ${I18n.n(
      this.get('student.total_grade.possible')
    )}`
  }.property('hide_points_possible', 'student.total_grade.score', 'student.total_grade.possible'),

  letterGrade: function () {
    const percent = this.get('student.total_percent')
    return scoreToGrade(percent, this.get('gradingStandard'))
  }.property('gradingStandard', 'percent'),

  showGrade: Ember.computed.bool('student.total_grade.possible'),

  showPoints: function () {
    return !!(!this.get('hide_points_possible') && this.get('student.total_grade'))
  }.property('hide_points_possible', 'student.total_grade'),

  showLetterGrade: Ember.computed.bool('gradingStandard'),

  actions: {
    onEditFinalGradeOverride(grade) {
      this.sendAction('onEditFinalGradeOverride', grade)
    },
  },
})

export default FinalGradeComponent
