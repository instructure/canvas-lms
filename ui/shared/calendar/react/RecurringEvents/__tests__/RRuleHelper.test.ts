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

import RRuleHelper, {
  type RRuleHelperSpec,
  RruleValidationError,
  ISODateToIcalDate,
  icalDateToISODate,
} from '../RRuleHelper'
import moment from 'moment-timezone'

const defaultTZ = 'Asia/Tokyo'

describe('RRuleHelper', () => {
  beforeAll(() => {
    moment.tz.setDefault(defaultTZ)
  })

  describe('RRuleHelper.parseString', () => {
    it('handles an empty string', () => {
      const spec = RRuleHelper.parseString('')
      expect(spec.freq).toEqual('DAILY')
      expect(spec.interval).toEqual(1)
      expect(spec.count).toEqual(5)

      expect(spec.weekdays).toBeUndefined()
      expect(spec.month).toBeUndefined()
      expect(spec.monthdate).toBeUndefined()
      expect(spec.pos).toBeUndefined()
      expect(spec.until).toBeUndefined()
    })

    it('parses a daily rule', () => {
      const spec = RRuleHelper.parseString('FREQ=DAILY;INTERVAL=1;COUNT=10')
      expect(spec.freq).toEqual('DAILY')
      expect(spec.interval).toEqual(1)
      expect(spec.count).toEqual(10)

      expect(spec.weekdays).toBeUndefined()
      expect(spec.month).toBeUndefined()
      expect(spec.monthdate).toBeUndefined()
      expect(spec.pos).toBeUndefined()
      expect(spec.until).toBeUndefined()
    })

    it('parses a weekly rule', () => {
      const spec = RRuleHelper.parseString(
        'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;UNTIL=20201231T000000Z'
      )
      expect(spec.freq).toEqual('WEEKLY')
      expect(spec.interval).toEqual(1)
      expect(spec.weekdays).toEqual(['MO', 'WE', 'FR'])
      expect(spec.until).toEqual('2020-12-31T00:00:00Z')

      expect(spec.month).toBeUndefined()
      expect(spec.monthdate).toBeUndefined()
      expect(spec.pos).toBeUndefined()
      expect(spec.count).toBeUndefined()
    })

    it('parses a monthly by date rule', () => {
      const spec = RRuleHelper.parseString(
        'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=17;BYMONTH=12;UNTIL=20201231T000000Z'
      )
      expect(spec.freq).toEqual('MONTHLY')
      expect(spec.interval).toEqual(1)
      expect(spec.monthdate).toEqual(17)
      expect(spec.month).toEqual(12)
      expect(spec.until).toEqual('2020-12-31T00:00:00Z')

      expect(spec.weekdays).toBeUndefined()
      expect(spec.pos).toBeUndefined()
      expect(spec.count).toBeUndefined()
    })

    it('parses a monthly bypos rule', () => {
      const spec = RRuleHelper.parseString('FREQ=MONTHLY;INTERVAL=2;BYDAY=MO;BYSETPOS=1;COUNT=7')
      expect(spec.freq).toEqual('MONTHLY')
      expect(spec.interval).toEqual(2)
      expect(spec.weekdays).toEqual(['MO'])
      expect(spec.pos).toEqual(1)
      expect(spec.count).toEqual(7)

      expect(spec.month).toBeUndefined()
      expect(spec.monthdate).toBeUndefined()
      expect(spec.until).toBeUndefined()
    })

    it('parses a yearly rule', () => {
      const spec = RRuleHelper.parseString('FREQ=YEARLY;INTERVAL=1;BYMONTH=9;BYMONTHDAY=17')
      expect(spec.freq).toEqual('YEARLY')
      expect(spec.interval).toEqual(1)
      expect(spec.monthdate).toEqual(17)
      expect(spec.month).toEqual(9)
      expect(spec.count).toBeUndefined()
      expect(spec.pos).toBeUndefined()
      expect(spec.until).toBeUndefined()
    })
  })

  describe('RRuleHelper constructor', () => {
    it('creates a daily rule', () => {
      const rrh = new RRuleHelper({freq: 'DAILY', interval: 1, count: 10})
      expect(rrh.toString()).toEqual('FREQ=DAILY;INTERVAL=1;COUNT=10')
    })

    it('creates a weekly rule', () => {
      const rrh = new RRuleHelper({
        freq: 'WEEKLY',
        interval: 2,
        weekdays: ['MO', 'WE', 'FR'],
        until: '2020-12-31T00:00:00Z',
      })
      expect(rrh.toString()).toEqual('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;UNTIL=20201231T000000Z')
    })

    it('creates a monthly by date rule', () => {
      const rrh = new RRuleHelper({
        freq: 'MONTHLY',
        interval: 1,
        monthdate: 17,
        month: 12,
        until: '2020-12-31T00:00:00Z',
      })
      expect(rrh.toString()).toEqual('FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=17;UNTIL=20201231T000000Z')
    })

    it('creates a monthly bypos rule', () => {
      const spec: RRuleHelperSpec = {
        freq: 'MONTHLY',
        interval: 1,
        weekdays: ['MO', 'TU'],
        pos: 2,
        count: 7,
      }
      const rrh = new RRuleHelper(spec)
      expect(rrh.toString()).toEqual('FREQ=MONTHLY;INTERVAL=1;BYDAY=MO,TU;BYSETPOS=2;COUNT=7')
    })

    it('creates a yearly rule', () => {
      const spec: RRuleHelperSpec = {
        freq: 'YEARLY',
        interval: 1,
        monthdate: 17,
        month: 9,
        count: 5,
      }
      const rrh = new RRuleHelper(spec)
      expect(rrh.toString()).toEqual('FREQ=YEARLY;INTERVAL=1;BYMONTH=9;BYMONTHDAY=17;COUNT=5')
    })

    it('throws an exception convering an invalid spec to an RRULE', () => {
      const rrh = new RRuleHelper({
        freq: 'WEEKLY',
        interval: 2,
        weekdays: [],
        until: '2020-12-31T00:00:00Z',
      })
      expect(() => rrh.toString()).toThrow()
    })

    describe('isValid', () => {
      it('returns true for valid specs', () => {
        const spec: RRuleHelperSpec = {
          freq: 'YEARLY',
          interval: 1,
          monthdate: 17,
          month: 9,
          count: 5,
        }
        const rrh = new RRuleHelper(spec)
        expect(rrh.isValid()).toEqual(true)
      })

      it('throws for invalid specs', () => {
        const spec: RRuleHelperSpec = {
          freq: 'WEEKLY',
          interval: 1,
          weekdays: [],
          pos: 1,
          count: 7,
        }
        const rrh = new RRuleHelper(spec)
        expect(() => rrh.isValid()).toThrow(RruleValidationError)
      })
    })
  })

  describe('ISODateToIcalDate', () => {
    it('converts an ISO date to an ical date', () => {
      expect(ISODateToIcalDate('2020-12-31T00:00:00Z')).toEqual('20201231T000000Z')
    })

    it('takes timezone into account', () => {
      expect(ISODateToIcalDate('2020-12-31T00:00:00-05:00')).toEqual('20201231T050000Z')
    })
  })

  describe('icalDateToISODate', () => {
    it('converts an ical date to an ISO date', () => {
      expect(icalDateToISODate('20201231T000000Z')).toEqual('2020-12-31T00:00:00Z')
    })

    it('takes timezone into account', () => {
      expect(icalDateToISODate('20201231T000000-05:00')).toEqual('2020-12-31T05:00:00Z')
    })
  })
})
