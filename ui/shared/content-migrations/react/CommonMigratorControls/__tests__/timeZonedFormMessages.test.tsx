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

import React from 'react'
import {timeZonedFormMessages} from '../timeZonedFormMessages'
import moment from 'moment-timezone'
import {configureAndRestoreLater} from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import {render} from '@testing-library/react'

interface TimeZoneMessage {
  type: 'hint'
  text: React.ReactElement
}

function isTimeZoneMessage(result: unknown): result is TimeZoneMessage {
  return (
    typeof result === 'object' &&
    result !== null &&
    'type' in result &&
    'text' in result &&
    React.isValidElement((result as any).text)
  )
}

import tz from 'timezone'
import chicago from 'timezone/America/Chicago'
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
        timeZonedFormMessages('America/New_York', 'America/New_York', '2024-11-08T08:00:00+00:00'),
      ).toStrictEqual([])
    })
  })

  describe('when the two timezones are different', () => {
    it('returns an array with two messages', () => {
      moment.tz.setDefault('America/Denver')

      configureAndRestoreLater({
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
        '2024-11-08T08:00:00+00:00',
      )

      const localResult = result[0]
      const courseResult = result[1]

      if (!isTimeZoneMessage(localResult) || !isTimeZoneMessage(courseResult)) {
        throw new Error('Invalid message format')
      }
      const {getByText: localGetByText} = render(localResult.text)
      const {getByText: courseGetByTest} = render(courseResult.text)

      expect(result).toHaveLength(2)
      expect(localResult.type).toBe('hint')
      expect(courseResult.type).toBe('hint')
      expect(localGetByText(/Local: [A-Za-z]{3} \d{1,2}(, \d{4})? at 2am/)).toBeInTheDocument()
      expect(courseGetByTest(/Course: [A-Za-z]{3} \d{1,2}(, \d{4})? at 3am/)).toBeInTheDocument()
    })
  })
})
