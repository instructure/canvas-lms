//
// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {isoDateFromInput} from '../DateUtils'
import moment from 'moment'

describe('DateUtils', () => {
  beforeAll(() => {
    moment.tz.setDefault('Etc/UTC')
  })

  afterAll(() => {
    moment.tz.setDefault() // reset default back to local time
  })

  describe('isoDateFromInput', () => {
    describe('timezones', () => {
      it('handles timezone input', () => {
        const result = isoDateFromInput(
          'start-date',
          new Date('2022-02-05T10:18:34'),
          'Europe/Budapest'
        )
        expect(result).toEqual('2022-02-04T23:00:00.000Z')
      })
    })
    describe('start dates', () => {
      it('returns an ISO string representing the beginning of the day', () => {
        const result = isoDateFromInput('start-date', new Date('2022-02-05T10:18:34'))
        expect(result).toEqual('2022-02-05T00:00:00.000Z')
      })

      it('accepts a string', () => {
        const result = isoDateFromInput('start-date', '2022-02-05T10:18:34')
        expect(result).toEqual('2022-02-05T00:00:00.000Z')
      })

      it('returns undefined if input is null', () => {
        const result = isoDateFromInput('start-date', null)
        expect(result).toBeUndefined()
      })

      it('returns undefined if input is undefined', () => {
        const result = isoDateFromInput('start-date', undefined)
        expect(result).toBeUndefined()
      })
    })

    describe('end dates', () => {
      it('returns an ISO string representing the end of the day', () => {
        const result = isoDateFromInput('end-date', new Date('2022-02-05T10:18:34'))
        expect(result).toEqual('2022-02-05T23:59:59.999Z')
      })

      it('accepts a string', () => {
        const result = isoDateFromInput('end-date', '2022-02-05T10:18:34')
        expect(result).toEqual('2022-02-05T23:59:59.999Z')
      })

      it('returns undefined if input is null', () => {
        const result = isoDateFromInput('end-date', null)
        expect(result).toBeUndefined()
      })

      it('returns undefined if input is undefined', () => {
        const result = isoDateFromInput('end-date', undefined)
        expect(result).toBeUndefined()
      })
    })
  })
})
