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

import {convertFriendlyDatetimeToUTC, parseModule} from '../moduleHelpers'
import moment from 'moment'
import {getFixture} from './fixtures'

describe('convertFriendlyDatetimeToUTC', () => {
  beforeAll(() => {
    window.ENV.TIMEZONE = 'America/Denver'
    moment.tz.setDefault('America/Denver')
  })

  it('returns undefined if input is undefined, null, or empty', () => {
    expect(convertFriendlyDatetimeToUTC(undefined)).toBe(undefined)
    expect(convertFriendlyDatetimeToUTC(null)).toBe(undefined)
    expect(convertFriendlyDatetimeToUTC('')).toBe(undefined)
  })

  it('returns a UTC date string if input is a date-like string', () => {
    expect(convertFriendlyDatetimeToUTC('Aug 2, 2023 at 12am')).toBe('2023-08-02T06:00:00.000Z')
    expect(convertFriendlyDatetimeToUTC('Jan 8, 2023')).toBe('2023-01-08T07:00:00.000Z')
    expect(convertFriendlyDatetimeToUTC('May 10, 2022 at 1:44pm')).toBe('2022-05-10T19:44:00.000Z')
  })
})

describe('parseModule', () => {
  it('parses the name', () => {
    const element = getFixture('name')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: 'Module 1',
      unlockAt: undefined,
      requireSequentialProgress: false,
      publishFinalGrade: false,
    })
  })

  it('parses unlockAt', () => {
    const element = getFixture('unlockAt')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: '2023-08-02T06:00:00.000Z',
      requireSequentialProgress: false,
      publishFinalGrade: false,
    })
  })

  it('parses requireSequentialProgress', () => {
    const element = getFixture('requiresSequentialProgress')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: undefined,
      requireSequentialProgress: true,
      publishFinalGrade: false,
    })
  })

  it('parses publishFinalGrade', () => {
    const element = getFixture('publishFinalGrade')
    expect(parseModule(element)).toEqual({
      moduleId: '8',
      moduleName: '',
      unlockAt: undefined,
      requireSequentialProgress: false,
      publishFinalGrade: true,
    })
  })
})
