/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {addZeroWidthSpace} from '../addZeroWidthSpace'

describe('addZeroWidthSpace', () => {
  const input = 'Test.1A. 2B.3C. 4.D.E.'

  it('returns text with zero width space added properly', () => {
    const result = addZeroWidthSpace(input)
    expect(result.length).toEqual(input.length + 5)
  })

  it('returns empty string if arg is empty', () => {
    const result = addZeroWidthSpace('')
    expect(result).toEqual('')
  })

  it('returns empty string if no arg provided', () => {
    const result = addZeroWidthSpace()
    expect(result).toEqual('')
  })
})
