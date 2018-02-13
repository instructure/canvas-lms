/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import secondsToTime from 'compiled/util/secondsToTime'

QUnit.module('secondsToTime')

test('less than one minute', () => {
  equal(secondsToTime(0), '00:00')
  equal(secondsToTime(1), '00:01')
  equal(secondsToTime(11), '00:11')
})

test('less than one hour', () => {
  equal(secondsToTime(61), '01:01')
  equal(secondsToTime(900), '15:00')
  equal(secondsToTime(3599), '59:59')
})

test('less than 100 hours', () => {
  equal(secondsToTime(32400), '09:00:00')
  equal(secondsToTime(359999), '99:59:59')
})

test('more than 100 hours', () => {
  equal(secondsToTime(360000), '100:00:00')
  equal(secondsToTime(478861), '133:01:01')
  equal(secondsToTime(8000542), '2222:22:22')
})
