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

import _ from 'underscore'
import Big from 'big.js'

export function add(a, b) {
  return new Big(a || 0).plus(b || 0)
}

export function divide(a, b) {
  return new Big(a || 0).div(b || 0)
}

export function multiply(a, b) {
  return new Big(a || 0).times(b || 0)
}

export function toNumber(big) {
  return Number.parseFloat(big, 10)
}

export function bigSum(values) {
  return values.reduce((total, value) => total.plus(value || 0), Big(0))
}

export function sum(collection) {
  const bigValue = _.reduce(collection, add, 0)
  return toNumber(bigValue)
}

export function sumBy(collection, attr) {
  const values = _.map(collection, attr)
  return sum(values)
}

export function scoreToPercentage(score, pointsPossible) {
  const floatingPointResult = score / pointsPossible * 100
  if (!Number.isFinite(floatingPointResult)) {
    return floatingPointResult
  }

  return toNumber(multiply(divide(score, pointsPossible), 100))
}

export function weightedPercent({score, possible, weight}) {
  return (score && weight) ? Big(score).div(possible).times(weight) : Big(0)
}
