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

import {calculateScaleRatio} from '../utils'

describe('calculateScaleRatio()', () => {
  it('when ratio exceeds maximum ratio', () => {
    const result = calculateScaleRatio(2.5)
    expect(result).toEqual(2)
  })

  it('when ratio exceeds minimum ratio', () => {
    const result = calculateScaleRatio(0.5)
    expect(result).toEqual(1)
  })

  it('when ratio is between thresholds', () => {
    const result = calculateScaleRatio(1.5)
    expect(result).toEqual(1.5)
  })
})
