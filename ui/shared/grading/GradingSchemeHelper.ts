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
import type {DeprecatedGradingScheme} from './grading.d'

export function indexOfGrade(
  grade: null | string | number,
  gradingSchemes: DeprecatedGradingScheme[]
) {
  const matches = (entry, key) => entry[0].toLowerCase() === key
  const cleanGrade = `${grade}`.trim().toLowerCase()
  let idx = gradingSchemes.findIndex(entry => matches(entry, cleanGrade))

  if (idx < 0 && /.+−$/.test(cleanGrade)) {
    const gradeWithTrailingDash = cleanGrade.replace(/−$/, '-')
    idx = gradingSchemes.findIndex(entry => matches(entry, gradeWithTrailingDash))
  }

  return idx
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

export function gradePointsToPercentage(
  grade: null | number,
  gradingScheme: DeprecatedGradingScheme
) {
  if (gradingScheme.pointsBased && grade != null) {
    return (grade / gradingScheme.scalingFactor) * 100
  }
}
