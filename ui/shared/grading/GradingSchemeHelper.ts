// @ts-nocheck
/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import type {DeprecatedGradingScheme, GradingStandard} from './grading.d'
import {GradingSchemeDataRow} from '@canvas/grading-scheme'

export function indexOfGrade(
  grade: null | string | number,
  gradingSchemes: DeprecatedGradingScheme[]
) {
  const cleanGrade = `${grade}`.trim().toLowerCase()
  return gradingSchemes.findIndex(entry => entry[0].toLowerCase() === cleanGrade)
}

export function gradeToScoreUpperBound(grade: number, gradingSchemes: DeprecatedGradingScheme[]) {
  const index = indexOfGrade(grade, gradingSchemes)

  if (index === -1) {
    // if the given grade is not in the scheme, return null
    return null
  }

  if (index === 0) {
    // if the given grade is the highest in the scheme, return 100 (percent)
    return 100
  }

  const matchingSchemeValue = gradingSchemes[index][1]
  const nextHigherSchemeValue = gradingSchemes[index - 1][1]
  const schemeValuesDiff = round(nextHigherSchemeValue - matchingSchemeValue, 4) * 100
  let percentageOffset = 1

  if (schemeValuesDiff <= 1) {
    // The maximum granularity currently supported by grading schemes right
    // now is 2 decimal places. If the matchingSchemeValue has too small of a
    // range, then a percentageOffset of 1% or even .1% may be too large, so
    // set it to 0.01% in that case (the most granular possible).
    if (schemeValuesDiff <= 0.1) {
      percentageOffset = 0.01
    } else {
      percentageOffset = 0.1
    }
  }

  return round(nextHigherSchemeValue * 100 - percentageOffset, 2)
}

export function gradeToScoreLowerBound(
  grade: null | number,
  gradingSchemes: DeprecatedGradingScheme[]
) {
  const index = indexOfGrade(grade, gradingSchemes)

  if (index === -1) {
    // if the given grade is not in the scheme, return null
    return null
  }

  const matchingSchemeValue = gradingSchemes[index][1]

  return round(matchingSchemeValue * 100, 2)
}

/**
 * @deprecated Use scoreToLetterGrade(score: number, gradingSchemeDataRows: GradingSchemeDataRow[]) instead, which takes
 * a more reasonably typed object model than the 2d array that this function takes in for gradingScheme data rows.
 * @param score
 * @param gradingSchemes
 */
export function scoreToGrade(score: number, gradingSchemes: GradingStandard[]) {
  // Because scoreToGrade is being used in a non typescript file, ui/features/grade_summary/jquery/index.js,
  // score can be NaN despite its type being declared as a number
  if (typeof score !== 'number' || Number.isNaN(score) || gradingSchemes == null) {
    return null
  }

  // convert deprecated 2d array format to newer GradingSchemeDataRow[] format
  const gradingSchemeDataRows = gradingSchemes.map(row => ({name: row[0], value: row[1]}))
  return scoreToLetterGrade(score, gradingSchemeDataRows)
}

export function scoreToLetterGrade(score: number, gradingSchemeDataRows: GradingSchemeDataRow[]) {
  // Because scoreToGrade is being used in a non typescript file, ui/features/grade_summary/jquery/index.js,
  // score can be NaN despite its type being declared as a number
  if (typeof score !== 'number' || Number.isNaN(score) || gradingSchemeDataRows == null) {
    return null
  }

  const roundedScore = round(score, 4)
  // does the following need .toPrecision(4) ?
  const scoreWithLowerBound = Math.max(roundedScore, 0)
  const letter = gradingSchemeDataRows.find((row, i) => {
    const schemeScore: string = (row.value * 100).toPrecision(4)
    // The precision of the lower bound (* 100) must be limited to eliminate
    // floating-point errors.
    // e.g. 0.545 * 100 returns 54.50000000000001 in JavaScript.
    return scoreWithLowerBound >= parseFloat(schemeScore) || i === gradingSchemeDataRows.length - 1
  }) as GradingSchemeDataRow
  if (!letter) {
    throw new Error('grading scheme not found')
  }
  return letter.name
}
