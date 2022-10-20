/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import GradingTypes from './grading-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'

const I18n = useI18nScope('cyoe_assignment_sidebar_score')

// stack overflow suggests this implementation
const isNumeric = n => {
  const parsed = numberHelper.parse(n)
  return !Number.isNaN(Number(parsed)) && Number.isFinite(Number(parsed))
}

const haveGradingScheme = assignment => (assignment ? !!assignment.grading_scheme : false)

const getGradingType = assignment => {
  const type = assignment ? assignment.grading_type : GradingTypes.percent.key
  if (
    (type === GradingTypes.letter_grade.key || type === GradingTypes.gpa_scale.key) &&
    !haveGradingScheme(assignment)
  ) {
    return GradingTypes.percent.key
  }
  return type
}

const percentToScore = (score, assignment) => {
  const gradingType = getGradingType(assignment)
  if (gradingType === GradingTypes.points.key) {
    return percentToPoints(score, assignment)
  } else if (
    gradingType === GradingTypes.letter_grade.key ||
    gradingType === GradingTypes.gpa_scale.key
  ) {
    return percentToLetterGrade(score, assignment)
  } else {
    return percentToExternalPercent(score)
  }
}

export const transformScore = (score, assignment, isUpperBound) => {
  // The backend stores nil for the upper and lowerbound scoring types
  if (!score) {
    if (isUpperBound) {
      score = '1'
    } else {
      score = '0'
    }
  }
  return formatScore(percentToScore(score, assignment), assignment)
}

const formatScore = (score, assignment) => {
  const gradingType = getGradingType(assignment)
  if (gradingType === GradingTypes.points.key) {
    return I18n.t('%{score} pts', {
      score: I18n.n(score, {precision: 2, strip_insignificant_zeros: true}),
    })
  } else if (
    gradingType === GradingTypes.letter_grade.key ||
    gradingType === GradingTypes.gpa_scale.key
  ) {
    return score
  } else {
    return I18n.n(score, {precision: 2, percentage: true, strip_insignificant_zeros: true})
  }
}

const percentToPoints = (score, assignment) => {
  if (!isNumeric(score)) {
    return score
  }
  if (score === 0) {
    return '0'
  }
  const percent = numberHelper.parse(score)
  const pointsPossible = Number(assignment.points_possible) || 100
  return parseFloat((percent * pointsPossible).toFixed(2))
}

const percentToLetterGrade = (score, assignment) => {
  if (score === '') {
    return ''
  }
  const parsed = numberHelper.parse(score)
  const letterGrade = {letter: null, score: -Infinity}
  for (const k in assignment.grading_scheme) {
    const v = numberHelper.parse(assignment.grading_scheme[k])
    if ((v <= parsed && v > letterGrade.score) || (v === 0 && v > parsed)) {
      letterGrade.score = v
      letterGrade.letter = k
    }
  }
  return letterGrade.letter ? letterGrade.letter : parsed
}

const percentToExternalPercent = score => {
  if (!isNumeric(score)) {
    return score
  }
  return Math.floor(score * 100)
}

export const i18nGrade = (grade, assignment) => {
  if (
    typeof grade === 'string' &&
    assignment.grading_type !== GradingTypes.letter_grade.key &&
    assignment.grading_type !== GradingTypes.gpa_scale.key
  ) {
    const number = numberHelper.parse(grade.replace(/%$/, ''))
    if (!Number.isNaN(Number(number))) {
      return formatScore(number, assignment)
    }
  }
  return grade
}
