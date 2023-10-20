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

// @ts-ignore
import Big from 'big.js'

/**
 * @deprecated
 */
export type GradingStandard = [string, number]

export interface GradingSchemeDataRow {
  name: string
  value: number
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

  const roundedScore = parseFloat(Big(score).round(4))
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
