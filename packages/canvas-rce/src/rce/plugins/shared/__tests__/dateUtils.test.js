/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {applyTimezoneOffsetToDate} from '../dateUtils'

describe('dateUtils', () => {
  describe('applyTimezoneOffsetToDate', () => {
    it('with a (-) current timezone > (-) target timezone (no DST)', () => {
      moment.tz.setDefault('America/Caracas') // -04:00
      const date = '2022-01-15T02:00:00Z'
      const targetTimezone = 'America/Denver' // -07:00 (in January, no DST)
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-01-14T23:00:00.000Z')
    })

    it('with a (-) current timezone > (-) target timezone (DST)', () => {
      moment.tz.setDefault('America/Caracas') // -04:00
      const date = '2022-04-15T02:00:00Z'
      const targetTimezone = 'America/Denver' // -06:00 (in April, DST)
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-15T00:00:00.000Z')
    })

    it('with a (-) current timezone < (-) target timezone', () => {
      moment.tz.setDefault('America/Guatemala') // -06:00
      const date = '2022-01-15T02:00:00Z'
      const targetTimezone = 'Europe/Lisbon' // +00:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-01-15T08:00:00.000Z')
    })

    it('with a (+) current timezone < (+) target timezone', () => {
      moment.tz.setDefault('Africa/Lagos') // +01:00
      const date = '2022-04-15T23:00:00Z'
      const targetTimezone = 'Europe/Volgograd' // +03:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-16T01:00:00.000Z')
    })

    it('with a (+) current timezone (DST) > (+) target timezone', () => {
      moment.tz.setDefault('Europe/Sofia') // +03:00 (in DST)
      const date = '2022-04-15T23:00:00Z'
      const targetTimezone = 'Asia/Baku' // +04:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-16T00:00:00.000Z')
    })

    it('with a (+) current timezone (no DST) > (+) target timezone', () => {
      moment.tz.setDefault('Europe/Sofia') // +02:00 (no DST)
      const date = '2022-01-15T23:00:00Z'
      const targetTimezone = 'Asia/Baku' // +04:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-01-16T01:00:00.000Z')
    })

    it('with a (-) current timezone and (+) target timezone', () => {
      moment.tz.setDefault('America/Noronha') // -02:00
      const date = '2022-04-15T23:00:00Z'
      const targetTimezone = 'Asia/Bangkok' // +07:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-16T08:00:00.000Z')
    })

    it('with a (+) current timezone and (-) target timezone', () => {
      moment.tz.setDefault('Europe/Sofia') // +03:00 (in DST)
      const date = '2022-04-15T02:00:00Z'
      const targetTimezone = 'America/Cancun' // -05:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-14T18:00:00.000Z')
    })

    it('with same (-) current and target timezones', () => {
      moment.tz.setDefault('America/Cancun') // -05:00
      const date = '2022-04-15T02:00:00Z'
      const targetTimezone = 'America/Cancun' // -05:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-15T02:00:00.000Z')
    })

    it('with same (+) current and target timezones', () => {
      moment.tz.setDefault('Asia/Dubai') // +04:00
      const date = '2022-04-15T02:00:00Z'
      const targetTimezone = 'Asia/Dubai' // +04:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-15T02:00:00.000Z')
    })

    it('with same 00:00 current and target timezones', () => {
      moment.tz.setDefault('Africa/Abidjan') // +00:00
      const date = '2022-04-15T02:00:00Z'
      const targetTimezone = 'Africa/Abidjan' // +00:00
      const result = applyTimezoneOffsetToDate(date, targetTimezone)
      expect(result.toISOString()).toBe('2022-04-15T02:00:00.000Z')
    })
  })
})
