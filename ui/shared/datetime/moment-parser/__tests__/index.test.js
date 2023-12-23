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

import tz from 'timezone'
import moment from 'moment'
import detroit from 'timezone/America/Detroit'
import {createDateTimeMoment, specifiesTimezone, toRFC3339WithoutTZ} from '../index'

const moonwalk = new Date(Date.UTC(1969, 6, 21, 2, 56))
const tzDetroit = tz(detroit, 'America/Detroit')

let originalMomentLocale

beforeEach(() => {
  originalMomentLocale = moment.locale()
})

afterEach(() => {
  moment.locale(originalMomentLocale)
  originalMomentLocale = null
})

test('moment(one-arg) complains', () => {
  expect(() => {
    createDateTimeMoment('June 24 at 10:00pm')
  }).toThrow(/ only works on /)
})

test('moment(non-string, fmt-string) complains', () => {
  expect(() => {
    createDateTimeMoment(moonwalk, 'MMMM D h:mmA')
  }).toThrow(/ only works on /)
})

test('moment(date-string, non-string) complains', () => {
  expect(() => {
    createDateTimeMoment('June 24 at 10:00pm', 123)
  }).toThrow(/ only works on /)
})

test('moment(date-string, fmt-string) works', () =>
  expect(createDateTimeMoment('June 24 at 10:00pm', 'MMMM D h:mmA')).toBeTruthy())

test('moment(date-string, [fmt-strings]) works', () =>
  expect(createDateTimeMoment('June 24 at 10:00pm', ['MMMM D h:mmA', 'L'])).toBeTruthy())

test('moment passes through invalid results', () => {
  const m = createDateTimeMoment('not a valid date', 'L')
  expect(m.isValid()).toEqual(false)
})

test('moment accepts excess input, but all format used', () => {
  const m = createDateTimeMoment('12pm and more', 'ha')
  expect(m.isValid()).toEqual(true)
})

test('moment rejects excess format', () => {
  const m = createDateTimeMoment('12pm', 'h:mma')
  expect(m.isValid()).toEqual(false)
})

test('moment returns moment for valid results', () => {
  const m = createDateTimeMoment('June 24, 2015 at 10:00pm -04:00', 'MMMM D, YYYY h:mmA Z')
  expect(m.isValid()).toEqual(true)
})

test('moment sans-timezone info parses according to profile timezone', () => {
  const expected = new Date(1435197600000) // 10pm EDT on June 24, 2015
  const m = createDateTimeMoment('June 24, 2015 at 10:00pm', 'MMMM D, YYYY h:mmA')
  expect(specifiesTimezone(m)).toEqual(false)
  expect(tzDetroit(toRFC3339WithoutTZ(m))).toEqual(+expected)
})

test('moment with-timezone info parses according to that timezone', () => {
  const expected = new Date(1435204800000) // 10pm MDT on June 24, 2015
  const m = createDateTimeMoment('June 24, 2015 at 10:00pm -06:00', 'MMMM D, YYYY h:mmA Z')
  expect(specifiesTimezone(m)).toEqual(true)
  expect(+m.toDate()).toEqual(+expected)
  expect(tzDetroit(m.format())).toEqual(+expected)
})

test('moment can change locales with single arity', () => {
  moment.locale('en')
  const m1 = createDateTimeMoment('mercredi 1 juillet 2015 15:00', 'LLLL')
  expect(m1._locale._abbr.match(/fr/)).toBeFalsy()
  expect(m1.isValid()).toBeFalsy()

  moment.locale('fr')
  const m2 = createDateTimeMoment('mercredi 1 juillet 2015 15:00', 'LLLL')
  expect(m2._locale._abbr.match(/fr/)).toBeTruthy()
  expect(m2.isValid()).toBeTruthy()
})

describe('specifiesTimezone', () => {
  it('is true when format contains Z and input contains a timezone', () => {
    expect(
      specifiesTimezone(
        createDateTimeMoment('June 24, 2015 at 10:00pm -06:00', 'MMMM D, YYYY h:mmA Z')
      )
    ).toEqual(true)
  })

  it('is false when format contains Z but input has no timezone', () => {
    expect(
      specifiesTimezone(createDateTimeMoment('June 24, 2015 at 10:00pm', 'MMMM D, YYYY h:mmA Z'))
    ).toEqual(false)
  })

  it('is false when format does not contain Z even if the input contains a timezone', () => {
    expect(
      specifiesTimezone(
        createDateTimeMoment('June 24, 2015 at 10:00pm -06:00', 'MMMM D, YYYY h:mmA')
      )
    ).toEqual(false)
  })
})
