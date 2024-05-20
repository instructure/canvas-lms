/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import round from '@canvas/round'
import I18n from '@canvas/i18n'
import {scoreToPercentage, scoreToScaledPoints} from '@canvas/grading/GradeCalculationHelper'
import Gradebook from '../../Gradebook'
import type {DeprecatedGradingScheme} from '@canvas/grading/grading.d'

function getGradePercentage(score: number, pointsPossible: number) {
  const grade = scoreToPercentage(score, pointsPossible)
  return round(grade, round.DEFAULT)
}

export interface AssignmentGroupCellData {
  score: number
  possible: number
  percentage: number
  scaledScore: number
  scaledPossible: number
  displayAsScaledPoints: boolean
}

function render(assignmentGroupCellData: AssignmentGroupCellData) {
  let assignmentGroupGrade
  if (assignmentGroupCellData.displayAsScaledPoints) {
    // display scaled points instead of percentage
    assignmentGroupGrade = assignmentGroupCellData.scaledPossible
      ? `${assignmentGroupCellData.scaledScore} / ${assignmentGroupCellData.scaledPossible}`
      : '-'
  } else {
    // display percentage
    assignmentGroupGrade = assignmentGroupCellData.possible
      ? assignmentGroupCellData.percentage
      : '–'
  }
  return `
    <div class="gradebook-cell">
      <div class="gradebook-tooltip">${assignmentGroupCellData.score} / ${assignmentGroupCellData.possible}</div>
      <span class="percentage">${assignmentGroupGrade}</span>
    </div>
  `
}

type Getters = {
  getCourseGradingScheme(): DeprecatedGradingScheme | null
}

export default class AssignmentGroupCellFormatter {
  options: Getters

  constructor(gradebook: Gradebook) {
    this.options = {
      getCourseGradingScheme(): DeprecatedGradingScheme | null {
        return gradebook.getCourseGradingScheme()
      },
    }
  }

  // @ts-expect-error
  render = (_row, _cell, value, _columnDef, _dataContext) => {
    if (value == null) {
      return ''
    }

    let percentage = getGradePercentage(value.score, value.possible)
    percentage = Number.isFinite(percentage) ? percentage : 0

    let possible = round(value.possible, round.DEFAULT)
    possible = possible ? I18n.n(possible) : possible
    let displayAsScaledPoints = false
    let scaledScore = NaN
    let scaledPossible = NaN

    const scheme = this.options.getCourseGradingScheme()
    if (scheme) {
      displayAsScaledPoints = scheme.pointsBased
      const scalingFactor = scheme.scalingFactor

      if (displayAsScaledPoints && value.possible) {
        scaledPossible = I18n.n(scalingFactor, {
          precision: 1,
        })
        scaledScore = I18n.n(scoreToScaledPoints(value.score, value.possible, scalingFactor), {
          precision: 1,
        })
      }
    }

    const templateOpts = {
      percentage: I18n.n(round(percentage, round.DEFAULT), {percentage: true}),
      possible,
      score: I18n.n(round(value.score, round.DEFAULT)),
      displayAsScaledPoints,
      scaledScore,
      scaledPossible,
    }

    return render(templateOpts)
  }
}
