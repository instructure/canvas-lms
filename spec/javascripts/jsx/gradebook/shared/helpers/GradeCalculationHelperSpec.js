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

import {sum, sumBy} from 'jsx/gradebook/shared/helpers/GradeCalculationHelper'

QUnit.module('GradeCalculationHelper.sum', () => {
  test('sums up values', () => {
    strictEqual(sum([1.25, 2]), 3.25)
  })

  test('treats null as 0', () => {
    strictEqual(sum([1.25, null]), 1.25)
  })

  test('handles being passed only null values', () => {
    strictEqual(sum([null, null]), 0)
  })

  test('treats undefined as 0', () => {
    strictEqual(sum([1.25, undefined]), 1.25)
  })

  test('handles being passed only undefined values', () => {
    strictEqual(sum([undefined, undefined]), 0)
  })

  test('handles being passed a mix of null and undefined values', () => {
    strictEqual(sum([null, 1.25, undefined]), 1.25)
  })

  test('handles being passed a collection of exclusively null and undefined values', () => {
    strictEqual(sum([null, undefined]), 0)
  })

  test('avoids floating point rounding issues', () => {
    const values = [7, 6.1, 7, 6.9, 6.27]
    const floatingPointSum = values.reduce((total, value) => total + value)
    strictEqual(floatingPointSum, 33.269999999999996)
    strictEqual(sum(values), 33.27)
  })
})

QUnit.module('GradeCalculationHelper.sumBy', (hooks) => {
  let collection

  hooks.beforeEach(() => {
    collection = [{price: 1.25, weight: 5}, {price: 2, weight: 3.5}]
  })

  test('sums up the items in the collection by the specified attribute', () => {
    strictEqual(sumBy(collection, 'price'), 3.25)
  })

  test('treats null as 0', () => {
    collection[1].price = null
    strictEqual(sumBy(collection, 'price'), 1.25)
  })

  test('handles being passed only null values', () => {
    collection[0].price = null
    collection[1].price = null
    strictEqual(sumBy(collection, 'price'), 0)
  })

  test('treats undefined as 0', () => {
    collection[1].price = undefined
    strictEqual(sumBy(collection, 'price'), 1.25)
  })

  test('handles being passed only undefined values', () => {
    collection[0].price = undefined
    collection[1].price = undefined
    strictEqual(sumBy(collection, 'price'), 0)
  })

  test('handles being passed a mix of null and undefined values', () => {
    collection.push({price: null})
    collection.push({price: undefined})
    strictEqual(sumBy(collection, 'price'), 3.25)
  })

  test('handles being passed a collection of exclusively null and undefined values', () => {
    collection[0].price = null
    collection[1].price = undefined
    strictEqual(sumBy(collection, 'price'), 0)
  })

  test('avoids floating point rounding issues', () => {
    const prices = [7, 6.1, 7, 6.9, 6.27]
    collection = [7, 6.1, 7, 6.9, 6.27].map((price) => ({price}))
    const floatingPointSum = prices.reduce((total, value) => total + value)
    strictEqual(floatingPointSum, 33.269999999999996)
    strictEqual(sumBy(collection, 'price'), 33.27)
  })
})
