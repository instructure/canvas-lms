/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import 'date-js'

QUnit.module('Date')

test('Date.parse', () => {
  // create the same date the "new Date" would if the browser were in UTC
  const utc = function () {
    return new Date(Date.UTC(...arguments))
  }
  const examples = {
    // Mountain
    'Wed May 2 2012 00:00:00 MST': utc(2012, 4, 2, 7, 0, 0),
    'Wed May 2 2012 00:00:00 MDT': utc(2012, 4, 2, 6, 0, 0),
    '2012-05-02T00:00:00-06:00': utc(2012, 4, 2, 6, 0, 0),

    // variations on UTC
    'Wed May 2 2012 00:00:00 UTC': utc(2012, 4, 2, 0, 0, 0),
    'Wed May 2 2012 00:00:00 GMT': utc(2012, 4, 2, 0, 0, 0),
    '2012-05-02T00:00:00Z': utc(2012, 4, 2, 0, 0, 0),
    '2012-05-02T00:00:00-0000': utc(2012, 4, 2, 0, 0, 0),
    '2012-05-02T00:00:00+0000': utc(2012, 4, 2, 0, 0, 0),
    '2012-05-02T00:00:00+00:00': utc(2012, 4, 2, 0, 0, 0),
    '2012-05-02T00:00:00-00:00': utc(2012, 4, 2, 0, 0, 0),

    // partial-hour values
    '2012-05-02T00:00:00+02:30': utc(2012, 4, 1, 21, 30, 0),
    '2012-05-02T00:00:00-02:30': utc(2012, 4, 2, 2, 30, 0),
    '2012-05-02T00:00:00+01:01': utc(2012, 4, 1, 22, 59, 0),
    '2012-05-02T00:00:00-01:01': utc(2012, 4, 2, 1, 1, 0),
    '2012-05-02T00:00:00+01:59': utc(2012, 4, 1, 22, 1, 0),
    '2012-05-02T00:00:00-01:59': utc(2012, 4, 2, 1, 59, 0),
    '2012-05-02T00:00:00+00:01': utc(2012, 4, 1, 23, 59, 0),
    '2012-05-02T00:00:00-00:01': utc(2012, 4, 2, 0, 1, 0),

    // DST-ends edge case
    '2012-11-04T01:00:00-06:00': utc(2012, 10, 4, 7, 0, 0),
  }
  return (() => {
    const result = []
    for (const dateString in examples) {
      const expectedDate = examples[dateString]
      result.push(equal(Date.parse(dateString).valueOf(), expectedDate.valueOf()))
    }
    return result
  })()
})

test('date.getUTCOffset', () => {
  const examples = {
    // Mountain
    ' 360': '-0600',
    ' 420': '-0700',

    // UTC
    '   0': '+0000',

    // partial-hour values
    '-150': '+0230',
    ' 150': '-0230',
    ' -61': '+0101',
    '  61': '-0101',
    '-119': '+0159',
    ' 119': '-0159',
    '  -1': '+0001',
    '   1': '-0001',
  }
  return (() => {
    const result = []
    for (const offset in examples) {
      const expectedResult = examples[offset]
      const date = new Date()
      sandbox.stub(date, 'getTimezoneOffset').returns(Number(offset))
      result.push(equal(date.getUTCOffset(), expectedResult))
    }
    return result
  })()
})

test('date.add* at DST-end', () => {
  // 1ms before 1am on day of DST-end
  const date = new Date(2012, 10, 4, 0, 59, 59, 999)

  // date.set* modifies in place, so we clone, but doesn't return the date
  // object, returning ms-since-epoch instead. fortunately, new Date
  // ms-since-epoch works, so we do that rather than introducing a bunch of
  // temporary variables
  ok(
    date
      .clone()
      .addMilliseconds(1)
      .equals(new Date(date.clone().setUTCMilliseconds(1000)))
  )
  ok(
    date
      .clone()
      .addSeconds(1)
      .equals(new Date(date.clone().setUTCSeconds(60)))
  )
  ok(
    date
      .clone()
      .addMinutes(1)
      .equals(new Date(date.clone().setUTCMinutes(60)))
  )
  ok(
    date
      .clone()
      .addHours(1)
      .equals(new Date(date.clone().setUTCHours(date.getUTCHours() + 1)))
  )
})

test('date.set at DST-end', () => {
  const date = new Date(2012, 10, 4, 0, 0, 0)
  date.set({hour: 14})
  ok(date.getHours() === 14)
  date.set({hour: 1})
  ok(date.getHours() === 1)
})
