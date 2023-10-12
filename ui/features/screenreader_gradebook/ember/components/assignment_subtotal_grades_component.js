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

import I18n from '@canvas/i18n'
import Ember from 'ember'
import round from '@canvas/round'
import {scoreToGrade} from '@instructure/grading-utils'
import {scoreToPercentage, scoreToScaledPoints} from '@canvas/grading/GradeCalculationHelper'

const AssignmentSubtotalGradesComponent = Ember.Component.extend({
  tagName: '',
  subtotal: null,
  student: null,
  weightingScheme: null,
  gradingStandard: null,
  hasGrade: Ember.computed.bool('values.possible'),
  hasWeightedGroups: Ember.computed.equal('weightingScheme', 'percent'),

  letterGrade: function () {
    const standard = this.get('gradingStandard')
    if (!standard || !this.get('hasGrade')) {
      return null
    }
    const percentage = parseFloat(this.get('rawPercent').toPrecision(4))
    return scoreToGrade(percentage, standard)
  }.property('gradingStandard', 'hasGrade'),

  values: function () {
    const student = this.get('student')
    return Ember.get(student, `${this.get('subtotal.key')}`)
  }.property('subtotal', 'student', 'student.total_grade'),

  points: function () {
    const values = this.get('values')
    return `${I18n.n(round(values.score, round.DEFAULT))} / ${I18n.n(
      round(values.possible, round.DEFAULT)
    )}`
  }.property('values'),

  rawPercent: function () {
    const values = this.get('values')
    return scoreToPercentage(values.score, values.possible)
  }.property('values'),

  percent: function () {
    let scoreText = I18n.n(round(this.get('rawPercent'), round.DEFAULT), {percentage: true})

    if (this.get('gradingStandard') && this.get('gradingStandardPointsBased')) {
      const scalingFactor = this.get('gradingStandardScalingFactor')
      const values = this.get('values')
      if (values.possible) {
        const scaledPossible = I18n.n(scalingFactor, {
          precision: 1,
        })
        const scaledScore = I18n.n(
          scoreToScaledPoints(values.score, values.possible, scalingFactor),
          {
            precision: 1,
          }
        )
        scoreText = `${scaledScore} / ${scaledPossible}`
      }
    }
    return scoreText
  }.property('values'),

  scoreDetail: function () {
    const points = this.get('points')
    return `(${points})`
  }.property('points'),

  weight: function () {
    return I18n.n(this.get('subtotal').weight, {percentage: true})
  }.property('subtotal'),
})

export default AssignmentSubtotalGradesComponent
