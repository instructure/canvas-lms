/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {timeZonedFormMessages} from '../timeZonedFormMessages'
import moment from 'moment-timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import {render} from '@testing-library/react'
// @ts-ignore
import tz from 'timezone'
// @ts-ignore
import chicago from 'timezone/America/Chicago'
// @ts-ignore
import detroit from 'timezone/America/Detroit'

describe('timeZonedFormMessages', () => {
  describe('when date parameter is missing', () => {
    it('returns an empty array', () => {
      expect(timeZonedFormMessages('America/New_York', 'America/New_York')).toStrictEqual([])
    })
  })

  describe('when the two timezones are the same', () => {
    it('returns an empty array', () => {
      expect(
        timeZonedFormMessages('America/New_York', 'America/New_York', '2024-11-08T08:00:00+00:00')
      ).toStrictEqual([])
    })
  })

  describe('when the two timezones are different', () => {
    it('returns an array with two messages', () => {
      moment.tz.setDefault('America/Denver')

      tzInTest.configureAndRestoreLater({
        tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
        tzData: {
          'America/Chicago': chicago,
          'America/Detroit': detroit,
        },
        formats: getI18nFormats(),
      })

      const result = timeZonedFormMessages(
        'America/Detroit',
        'America/Chicago',
        '2024-11-08T08:00:00+00:00'
      )

      const localResult = result[0]
      const courseResult = result[1]
      const {getByText: localGetByText} = render(localResult.text as JSX.Element)
      const {getByText: courseGetByTest} = render(courseResult.text as JSX.Element)

      expect(result.length).toBe(2)
      expect(localResult.type).toBe('hint')
      expect(courseResult.type).toBe('hint')
      expect(localGetByText('Local: Nov 8 at 2am')).toBeInTheDocument()
      expect(courseGetByTest('Course: Nov 8 at 3am')).toBeInTheDocument()
    })
  })
})
