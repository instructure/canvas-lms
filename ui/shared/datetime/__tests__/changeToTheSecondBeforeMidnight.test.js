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

import {changeToTheSecondBeforeMidnight as subject} from '..'
import {epoch} from '../specHelpers'

describe('changeToTheSecondBeforeMidnight', () => {
  it('returns null when no argument given.', () => {
    expect(subject()).toEqual(null)
  })

  it('returns null when invalid date is given.', () => {
    const date = new Date('invalid date')
    expect(subject(date)).toEqual(null)
  })

  it('returns fancy midnight when a valid date is given.', () => {
    const fancyMidnight = subject(epoch)
    expect(fancyMidnight.toGMTString()).toEqual('Thu, 01 Jan 1970 23:59:59 GMT')
  })
})
