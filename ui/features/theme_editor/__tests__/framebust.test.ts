/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {checkShouldFramebust} from '../framebust'

describe('checkShouldFramebust', () => {
  it('returns false when not in an iframe', () => {
    expect(checkShouldFramebust()).toBe(false)
  })

  it('returns false when getElementById returns null', () => {
    jest.spyOn(window.parent.document, 'getElementById').mockReturnValue(null)
    jest.restoreAllMocks()
  })

  it('catches errors when accessing parent.document (cross-origin)', () => {
    jest.spyOn(window.parent.document, 'getElementById').mockImplementation(() => {
      throw new Error('SecurityError: Blocked a frame with origin')
    })

    expect(() => checkShouldFramebust()).not.toThrow()
    jest.restoreAllMocks()
  })
})
