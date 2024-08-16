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

import {getAspectRatio} from '../size'

describe('getAspectRatio', () => {
  it('should return the aspect ratio of the width and height', () => {
    expect(getAspectRatio(100, 100)).toEqual(1)
    expect(getAspectRatio(200, 100)).toEqual(2)
    expect(getAspectRatio(100, 200)).toEqual(0.5)
  })

  it('should return 1 if the aspect ratio is not a number or not finite', () => {
    expect(getAspectRatio(100, 0)).toEqual(1)
    expect(getAspectRatio(Number.NaN, 100)).toEqual(1)
    expect(getAspectRatio(0, 0)).toEqual(1)
  })
})
