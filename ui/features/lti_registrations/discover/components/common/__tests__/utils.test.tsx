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

import {calculateArrowDisableIndex} from '../Carousels/utils'

describe('calculateArrowDisableIndex', () => {
  it('should return the correct index for a window size of 360 and 2 screenshots', () => {
    const screenshots = ['screenshot1', 'screenshot2']
    const windowSize = 360
    expect(calculateArrowDisableIndex(screenshots, windowSize)).toEqual({type: 1})
  })

  it('should return the correct index for a window size <= 760 but > 360 and 5 screenshots', () => {
    const screenshots = ['screenshot1', 'screenshot2', 'screenshot3', 'screenshots4', 'screenshot5']
    const windowSize = 760
    expect(calculateArrowDisableIndex(screenshots, windowSize)).toEqual({type: 3})
  })
})
