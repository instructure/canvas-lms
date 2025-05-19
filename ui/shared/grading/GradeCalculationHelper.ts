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

import {map, reduce} from 'lodash'
import Big from 'big.js'

export function add(a: number, b: number): Big {
  return new Big(a || 0).plus(b || 0)
}

export function divide(a: number, b: number): Big {
  return new Big(a || 0).div(b || 0)
}

export function multiply(a: number, b: number): Big {
  return new Big(a || 0).times(b || 0)
}

export function toNumber(big: Big) {
  // @ts-expect-error
  return Number.parseFloat(big)
}

export function bigSum(values: Big[]) {
  return values.reduce((total, value) => total.plus(value || 0), Big(0))
}

// @ts-expect-error
export function sum(collection) {
  // @ts-expect-error
  const bigValue = reduce(collection, add, 0)
  // @ts-expect-error
  return toNumber(bigValue)
}

// @ts-expect-error
export function sumBy(collection, attr) {
  const values = map(collection, attr)
  return sum(values)
}

export function scoreToPercentage(score: number, pointsPossible: number) {
  const floatingPointResult = (score / pointsPossible) * 100
  if (!Number.isFinite(floatingPointResult)) {
    return floatingPointResult
  }

  // @ts-expect-error
  return toNumber(multiply(divide(score, pointsPossible), 100))
}

export function scoreToScaledPoints(score: number, pointsPossible: number, scalingFactor: number) {
  const scoreAsScaledPoints = score / (pointsPossible / scalingFactor)
  if (!Number.isFinite(scoreAsScaledPoints)) {
    return scoreAsScaledPoints
  }

  // @ts-expect-error
  return toNumber(divide(score, divide(pointsPossible, scalingFactor)))
}

export function weightedPercent({
  score,
  possible,
  weight,
}: {
  score: number
  possible: number
  weight: number
}) {
  return score && weight && possible ? Big(score).div(possible).times(weight) : Big(0)
}

// this function is in place to ensure we round consistently with the backend when calculating total grades
export function totalGradeRound(n: number | string | null, digits = 0) {
  try {
    if (n == null) {
      return NaN
    }
    const floatNumber = parseFloat(n.toString())
    return parseFloat(Big(floatNumber).round(digits).toString())
  } catch (error) {
    return NaN
  }
}
