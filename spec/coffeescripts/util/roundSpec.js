/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import round from 'compiled/util/round'

QUnit.module('round')
const x = 1234.56789
test('round', () => {
  ok(round(x, 6) === x)
  ok(round(x, 5) === x)
  ok(round(x, 4) === 1234.5679)
  ok(round(x, 3) === 1234.568)
  ok(round(x, 2) === 1234.57)
  ok(round(x, 1) === 1234.6)
  ok(round(x, 0) === 1235)
})

test('round without a digits argument rounds to 0', () => {
  ok(round(x) === 1235)
})

test('round.DEFAULT is 2', () => ok(round.DEFAULT === 2))

test('round will convert non-numbers to a Number and round it', () => {
  equal(round(`${x}`), 1235)
})

test('round will round decimals up when rounding off a 5', () => {
  // example specifically requires correct rounding
  // naive rounding will otherwise result in 78.83
  equal(round(78.835, 2), 78.84)
})
