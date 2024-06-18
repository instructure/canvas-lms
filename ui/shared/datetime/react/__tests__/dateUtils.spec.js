/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {isPassedDelayedPostAt} from '../date-utils'
import moment from 'moment'

describe('Util helpers for shared dates', () => {
  // fails in Jest, not in QUnit
  it.skip('isPassedDelayedPostAt correctly identifies date that is after as true', () => {
    const checkDate = '2015-12-17'
    const delayedDate = '2015-12-14'
    const check = isPassedDelayedPostAt({checkDate, delayedDate})
    expect(check).toBeTruthy()
  })

  it('isPassedDelayedPostAt correctly identifies date that is before as false when using browser date', () => {
    const delayedDate = moment().add(2, 'days')
    const check = isPassedDelayedPostAt({delayedDate})
    expect(check).not.toBeTruthy()
  })

  it('isPassedDelayedPostAt correctly identifies date that is after as true when using browser date', () => {
    const delayedDate = moment().subtract(2, 'days')
    const check = isPassedDelayedPostAt({delayedDate})
    expect(check).toBeTruthy()
  })
})
