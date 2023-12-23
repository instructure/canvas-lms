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

import detroit from 'timezone/America/Detroit'
import timezone from 'timezone'
import {configureAndRestoreLater, epoch, moonwalk, restore} from '../specHelpers'
import {isMidnight as subject} from '..'

describe('isMidnight', () => {
  afterEach(restore)

  test('is false when no argument given.', () => {
    expect(subject()).toEqual(false)
  })

  test('is false when invalid date is given.', () => {
    const date = new Date('invalid date')
    expect(subject(date)).toEqual(false)
  })

  test('is true when date given is at midnight.', () => {
    expect(subject(epoch)).toEqual(true)
  })

  test("is false when date given isn't at midnight.", () => {
    expect(subject(moonwalk)).toEqual(false)
  })

  test('is false when date is midnight in a different zone.', () => {
    configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detrot': detroit,
      },
    })

    expect(subject(epoch)).toEqual(false)
  })
})
