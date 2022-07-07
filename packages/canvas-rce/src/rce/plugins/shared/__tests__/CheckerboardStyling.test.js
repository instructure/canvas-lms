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

import checkerboardStyle from '../CheckerboardStyling'

describe('checkerboardStyle', () => {
  it('creates 4px squares when passed squareSize 4', () => {
    const checkerboard = checkerboardStyle(4)
    expect(checkerboard.backgroundSize).toBe('4px 4px')
  })

  it('creates 8px squares when passed squareSize 8', () => {
    const checkerboard = checkerboardStyle(8)
    expect(checkerboard.backgroundSize).toBe('8px 8px')
  })
})
