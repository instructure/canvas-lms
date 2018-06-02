/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Big from 'big.js'
import round from 'compiled/util/round'
import {gradeToScore, scoreToGrade} from '../../gradebook/GradingSchemeHelper'
import numberHelper from '../../shared/helpers/numberHelper'

const MAX_PRECISION = 15 // the maximum precision of a score persisted to the database

function toNumber(bigValue) {
  return Number.parseFloat(bigValue.round(MAX_PRECISION).toString(), 10)
}

function pointsFromPercentage(percentage, pointsPossible) {
  return toNumber(new Big(percentage).div(100).times(pointsPossible))
}

function percentageFromPoints(points, pointsPossible) {
  return toNumber(new Big(points).div(pointsPossible).times(100))
}

function invalid(value) {
  return {
    enteredAs: null,
    excused: false,
    grade: value,
    score: null,
    valid: false
  }
}

function parseAsGradingScheme(value, options) {
  if (!options.gradingScheme) {
    return null
  }

  const percentage = gradeToScore(value, options.gradingScheme)
  if (percentage == null) {
    return null
  }

  return {
    enteredAs: 'gradingScheme',
    percent: options.pointsPossible ? percentage : 0,
    points: options.pointsPossible ? pointsFromPercentage(percentage, options.pointsPossible) : 0,
    schemeKey: scoreToGrade(percentage, options.gradingScheme)
  }
}

function parseAsPercent(value, options) {
  const percentage = numberHelper.parse(value.replace(/[%％﹪٪]/, ''))
  if (isNaN(percentage)) {
    return null
  }

  let percent = percentage
  let points = pointsFromPercentage(percentage, options.pointsPossible)

  if (!options.pointsPossible) {
    points = numberHelper.parse(value)
    if (isNaN(points)) {
      percent = 0
      points = 0
    }
  }

  return {
    enteredAs: 'percent',
    percent,
    points,
    schemeKey: scoreToGrade(percent, options.gradingScheme)
  }
}

function parseAsPoints(value, options) {
  const points = numberHelper.parse(value)
  if (isNaN(points)) {
    return null
  }

  const percent = options.pointsPossible ? percentageFromPoints(points, options.pointsPossible) : 0

  return {
    enteredAs: 'points',
    percent: null,
    points,
    schemeKey: scoreToGrade(percent, options.gradingScheme)
  }
}

function parseForGradingScheme(value, options) {
  const result =
    parseAsGradingScheme(value, options) ||
    parseAsPoints(value, options) ||
    parseAsPercent(value, options)

  if (result) {
    return {
      enteredAs: result.enteredAs,
      excused: false,
      grade: result.schemeKey,
      score: result.points,
      valid: true
    }
  }

  return invalid(value)
}

function parseForPercent(value, options) {
  const result = parseAsPercent(value, options) || parseAsGradingScheme(value, options)

  if (result) {
    return {
      enteredAs: result.enteredAs,
      excused: false,
      grade: `${result.percent}%`,
      score: result.points,
      valid: true
    }
  }

  return invalid(value)
}

function parseForPoints(value, options) {
  const result =
    parseAsPoints(value, options) ||
    parseAsGradingScheme(value, options) ||
    parseAsPercent(value, options)

  if (result) {
    return {
      enteredAs: result.enteredAs,
      excused: false,
      grade: `${result.points}`,
      score: result.points,
      valid: true
    }
  }

  return invalid(value)
}

function parseForPassFail(value, options) {
  const cleanValue = value.toLowerCase()
  const result = {enteredAs: 'passFail', excused: false, grade: cleanValue, valid: true}

  if (cleanValue === 'complete') {
    result.score = options.pointsPossible || 0
  } else if (cleanValue === 'incomplete') {
    result.score = 0
  } else {
    return invalid(value)
  }

  return result
}

export function isExcused(grade) {
  return `${grade}`.trim().toLowerCase() === 'ex'
}

export function parseTextValue(value, options) {
  const trimmedValue = value != null ? `${value}`.trim() : ''

  if (trimmedValue === '') {
    return {enteredAs: null, excused: false, grade: null, score: null, valid: true}
  }

  if (isExcused(trimmedValue)) {
    return {enteredAs: 'excused', excused: true, grade: null, score: null, valid: true}
  }

  switch (options.enterGradesAs) {
    case 'gradingScheme': {
      return parseForGradingScheme(trimmedValue, options)
    }
    case 'percent': {
      return parseForPercent(trimmedValue, options)
    }
    case 'passFail': {
      return parseForPassFail(trimmedValue, options)
    }
    default: {
      return parseForPoints(trimmedValue, options)
    }
  }
}

export function hasGradeChanged(submission, gradeInfo, options) {
  if (!gradeInfo.valid) {
    // the given submission is always assumed to be valid
    return true
  }

  if (gradeInfo.excused !== submission.excused) {
    return true
  }

  if (gradeInfo.enteredAs === 'gradingScheme') {
    /*
     * When the value given is a grading scheme key, it must be compared to
     * the grade on the submission instead of the score. This avoids updating
     * the grade when the stored score and interpreted score differ and the
     * input value was not changed.
     *
     * To avoid updating the grade in cases where the stored grade is of a
     * different type but otherwise equivalent, get the grading data for the
     * stored grade and compare it to the grading data from the input.
     */
    const submissionGradeInfo = parseTextValue(submission.enteredGrade, options)
    return submissionGradeInfo.grade !== gradeInfo.grade
  }

  return submission.enteredScore !== gradeInfo.score
}
