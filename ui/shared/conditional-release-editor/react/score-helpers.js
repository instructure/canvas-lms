/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

import GradingTypes from './grading-types'
import numberHelper from '@canvas/i18n/numberHelper'

const I18n = useI18nScope('conditional_release')

const TEN_E_8 = 10e8

// stack overflow suggests this implementation
export const isNumeric = n => {
  n = numberHelper.parse(n)
  return !Number.isNaN(Number(n)) && Number.isFinite(Number(n))
}

const haveGradingScheme = assignment => {
  return assignment ? !!assignment.get('grading_scheme') : false
}

export const getGradingType = assignment => {
  const type = assignment ? assignment.get('grading_type') : GradingTypes.percent.key
  if (
    (type === GradingTypes.letter_grade.key || type === GradingTypes.gpa_scale.key) &&
    !haveGradingScheme(assignment)
  ) {
    return GradingTypes.percent.key
  }
  return type
}

export const percentToScore = (score, assignment) => {
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

export const scoreToPercent = (score, assignment) => {
  const gradingType = getGradingType(assignment)
  if (gradingType === GradingTypes.points.key) {
    return pointsToPercent(score, assignment)
  } else if (
    gradingType === GradingTypes.letter_grade.key ||
    gradingType === GradingTypes.gpa_scale.key
  ) {
    return letterGradeToPercent(score, assignment)
  } else {
    return externalPercentToPercent(score)
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

const floor8 = r => {
  return Math.floor(r * TEN_E_8) / TEN_E_8
}

const formatScore = (score, assignment) => {
  const gradingType = getGradingType(assignment)
  if (gradingType === GradingTypes.points.key) {
    return I18n.t('%{score} pts', {score: I18n.n(score)})
  } else if (
    gradingType === GradingTypes.letter_grade.key ||
    gradingType === GradingTypes.gpa_scale.key
  ) {
    return score
  } else {
    return I18n.n(score, {percentage: true})
  }
}

export const formatReaderOnlyScore = (score, assignment) => {
  const gradingType = getGradingType(assignment)
  if (gradingType === GradingTypes.points.key) {
    return I18n.t('%{score} points', {score: I18n.n(numberHelper.parse(score))})
  } else if (
    gradingType === GradingTypes.letter_grade.key ||
    gradingType === GradingTypes.gpa_scale.key
  ) {
    return I18n.t('%{score} letter grade', {score})
  } else {
    return I18n.t('%{score} percent', {score: I18n.n(numberHelper.parse(score))})
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
  const pointsPossible = Number(assignment.get('points_possible')) || 100
  return (percent * pointsPossible).toFixed(2)
}

const pointsToPercent = (score, assignment) => {
  if (!isNumeric(score)) {
    return score
  }
  if (score === 0) {
    return '0'
  }
  const pointsPossible = Number(assignment.get('points_possible')) || 100
  return I18n.n(floor8(numberHelper.parse(score) / pointsPossible))
}

const percentToLetterGrade = (score, assignment) => {
  if (score === '') {
    return ''
  }
  const letterGrade = {letter: null, score: -Infinity}
  const parsedScore = numberHelper.parse(score)
  assignment.get('grading_scheme').forEach((v, k) => {
    v = numberHelper.parse(v)
    if ((v <= parsedScore && v > letterGrade.score) || (v === 0 && v > parsedScore)) {
      letterGrade.score = v
      letterGrade.letter = k
    }
  })
  return letterGrade.letter ? letterGrade.letter : score
}

const letterGradeToPercent = (score, assignment) => {
  if (score === '') {
    return ''
  }
  const percent = assignment.getIn(['grading_scheme', score.toString()])
  if (percent === 0) {
    return '0'
  }
  return percent || score
}

const percentToExternalPercent = score => {
  if (!isNumeric(score)) {
    return score
  }
  return I18n.n(Math.floor(numberHelper.parse(score) * 100))
}

const externalPercentToPercent = score => {
  if (!isNumeric(score)) {
    return score
  }
  return I18n.n(numberHelper.parse(score) / 100.0)
}

export const getScoringRangeSplitWarning = () => {
  return I18n.t(
    'Splitting disabled: there can only be a maximum of three assignment groups in a scoring range.'
  )
}
