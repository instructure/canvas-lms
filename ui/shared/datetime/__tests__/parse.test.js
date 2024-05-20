/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'
import timezone from 'timezone'
import * as tz from '..'
import {moonwalk, equal, setup} from './helpers'

setup(this)

test('parse(valid datetime string)', () => {
  equal(+tz.parse(moonwalk.toISOString()), +moonwalk)
})

test('parse(timestamp integer)', () => {
  equal(+tz.parse(+moonwalk), +moonwalk)
})

test('parse(Date object)', () => {
  equal(+tz.parse(moonwalk), +moonwalk)
})

test('parse(date array)', () => {
  equal(+tz.parse([1969, 7, 21, 2, 56]), +moonwalk)
})

test('parse(datetime string with timezone)', () => {
  moment.tz.setDefault('America/New_York')
  // same tz as the default, so it doesn't get fudged
  equal(tz.parse('November 11, 1955', 'America/New_York').toISOString(), '1955-11-11T05:00:00.000Z') // -5
  // different tz, so gets fudged to midnight.
  equal(tz.parse('November 11, 1955', 'Asia/Kamchatka').toISOString(), '1955-11-11T00:00:00.000Z') // +12
  equal(tz.parse('November 11, 1955', 'Pacific/Honolulu').toISOString(), '1955-11-11T00:00:00.000Z') // -10
})

test('parse() should return null on failure', () => equal(tz.parse('bogus'), null))

test('parse() should return a date on success', () => equal(typeof tz.parse(+moonwalk), 'object'))

test('parse("") should fail', () => equal(tz.parse(''), null))

test('parse(null) should fail', () => equal(tz.parse(null), null))

test('parse(integer) should be ms since epoch', () => equal(+tz.parse(2016), +timezone(2016)))

test('parse("looks like integer") should be a year', () =>
  equal(+tz.parse('2016'), +tz.parse('2016-01-01')))

test('parse() should parse relative to UTC by default', () =>
  equal(+tz.parse('1969-07-21 02:56'), +moonwalk))
