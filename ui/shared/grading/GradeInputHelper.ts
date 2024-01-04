// @ts-nocheck
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
import {gradeToScoreLowerBound, gradeToScoreUpperBound, indexOfGrade} from './GradingSchemeHelper'
import {scoreToGrade} from '@instructure/grading-utils'
import numberHelper from '@canvas/i18n/numberHelper'
import type {GradeInput, GradeResult} from './grading.d'
import {EnvGradebookCommon} from '@canvas/global/env/EnvGradebook'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

// Allow unchecked access to ENV variables that should exist in this context
declare const ENV: GlobalEnv & EnvGradebookCommon

const MAX_PRECISION = 15 // the maximum precision of a score persisted to the database
const PERCENTAGES = /[%％﹪٪]/

export const GradingSchemeBounds = Object.freeze({
  LOWER: 'LOWER',
  UPPER: 'UPPER',
})

function toNumber(bigValue: Big): number {
  return parseFloat(bigValue.round(MAX_PRECISION).toString())
}

function pointsFromPercentage(percentage: number, pointsPossible: number): number {
  return toNumber(new Big(percentage).div(100).times(pointsPossible))
}

function percentageFromPoints(points: number, pointsPossible: number): number {
  return toNumber(new Big(points).div(pointsPossible).times(100))
}

function invalid(value) {
  return {
    enteredAs: null,
    late_policy_status: null,
    excused: false,
    grade: value,
    score: null,
    valid: false,
  }
}

function parseAsGradingScheme(value: number, options): null | GradeInput {
  if (!options.gradingScheme) {
    return null
  }

  const gradeToScore = options.useLowerBound ? gradeToScoreLowerBound : gradeToScoreUpperBound
  const percentage = gradeToScore(value, options.gradingScheme)
  if (percentage == null) {
    return null
  }

  return {
    enteredAs: 'gradingScheme',
    percent: options.pointsPossible ? percentage : 0,
    points: options.pointsPossible ? pointsFromPercentage(percentage, options.pointsPossible) : 0,
    schemeKey: scoreToGrade(percentage, options.gradingScheme),
  }
}

function parseAsPercent(value: string, options): null | GradeInput {
  const percentage = numberHelper.parse(value.replace(PERCENTAGES, ''))
  if (Number.isNaN(Number(percentage))) {
    return null
  }

  let percent = percentage
  let points = pointsFromPercentage(percentage, options.pointsPossible)

  if (!options.pointsPossible) {
    points = numberHelper.parse(value)
    if (Number.isNaN(Number(points))) {
      percent = 0
      points = 0
    }
  }

  return {
    enteredAs: 'percent',
    percent,
    points,
    schemeKey: scoreToGrade(percent, options.gradingScheme),
  }
}

function parseAsPoints(value: string, options): null | GradeInput {
  const points = numberHelper.parse(value)
  if (Number.isNaN(Number(points))) {
    return null
  }

  const percent = options.pointsPossible ? percentageFromPoints(points, options.pointsPossible) : 0

  return {
    enteredAs: 'points',
    percent: null,
    points,
    schemeKey: scoreToGrade(percent, options.gradingScheme),
  }
}

function parseForGradingScheme(value, options): GradeResult {
  const result: null | GradeInput =
    parseAsGradingScheme(value, options) ||
    parseAsPoints(value, options) ||
    parseAsPercent(value, options)

  if (result) {
    return {
      enteredAs: result.enteredAs,
      late_policy_status: null,
      excused: false,
      grade: result.schemeKey,
      score: result.points,
      valid: true,
    }
  }

  return invalid(value)
}

function parseForPercent(value, options): GradeResult {
  const result: null | GradeInput =
    parseAsPercent(value, options) || parseAsGradingScheme(value, options)

  if (result) {
    return {
      enteredAs: result.enteredAs,
      late_policy_status: null,
      excused: false,
      grade: `${result.percent}%`,
      score: result.points,
      valid: true,
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
      late_policy_status: null,
      excused: false,
      grade: `${result.points}`,
      score: result.points,
      valid: true,
    }
  }

  return invalid(value)
}

function parseForPassFail(value: string, options: {pointsPossible: number}): GradeResult {
  const cleanValue = value.toLowerCase()

  const result: GradeResult = {
    enteredAs: 'passFail',
    late_policy_status: null,
    excused: false,
    grade: cleanValue,
    valid: true,
    score: null,
  }

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

type ParseResult = {
  enteredValue: string
  isCleared: boolean
  isExcused: boolean
  isPoints: boolean
  isPercentage: boolean
  isSchemeKey: boolean | null
  value: null | number
}

export function parseEntryValue(value, gradingScheme): ParseResult {
  const trimmedValue = value != null ? `${value}`.trim() : ''

  const result: ParseResult = {
    enteredValue: trimmedValue,
    isCleared: trimmedValue === '',
    isExcused: isExcused(trimmedValue),
    isPercentage: false,
    isPoints: false,
    isSchemeKey: gradingScheme ? false : null,
    value: null,
  }

  if (PERCENTAGES.test(trimmedValue)) {
    const percentage = numberHelper.parse(trimmedValue.replace(PERCENTAGES, ''))
    if (!Number.isNaN(percentage)) {
      result.isPercentage = true
      result.value = toNumber(new Big(percentage))
    }
  } else {
    const points = numberHelper.parse(trimmedValue)
    if (!Number.isNaN(points)) {
      result.isPoints = true
      result.value = points
    }
  }

  if (gradingScheme) {
    const keyIndex = indexOfGrade(trimmedValue, gradingScheme.data)
    if (keyIndex !== -1) {
      result.isSchemeKey = true
      result.value = gradingScheme.data[keyIndex][0]
    }
  }

  return result
}

export function isMissing(grade) {
  return `${grade}`.trim().toLowerCase() === 'mi'
}

export function parseTextValue(value: string, options): GradeResult {
  const trimmedValue = value != null ? `${value}`.trim() : ''

  if (trimmedValue === '') {
    return {
      enteredAs: null,
      late_policy_status: null,
      excused: false,
      grade: null,
      score: null,
      valid: true,
    }
  }

  if (isExcused(trimmedValue)) {
    return {
      enteredAs: 'excused',
      late_policy_status: null,
      excused: true,
      grade: null,
      score: null,
      valid: true,
    }
  }

  if (ENV.GRADEBOOK_OPTIONS.assignment_missing_shortcut && isMissing(trimmedValue)) {
    return {
      enteredAs: 'missing',
      late_policy_status: 'missing',
      excused: false,
      grade: null,
      score: null,
      valid: true,
    }
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

  if (ENV.GRADEBOOK_OPTIONS.assignment_missing_shortcut && 'late_policy_status' in submission) {
    if (
      gradeInfo.late_policy_status !== null &&
      gradeInfo.late_policy_status !== submission.late_policy_status
    ) {
      return true
    }
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

  if (gradeInfo.enteredAs === 'passFail' && options.pointsPossible === 0) {
    return submission.enteredGrade !== gradeInfo.grade
  }

  return submission.enteredScore !== gradeInfo.score
}
