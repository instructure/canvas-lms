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

import {render} from '@testing-library/react'
import {PageEditor} from '../PageEditor'

describe('PageEditor', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('calls onInit with PageEditorHandler on mount', () => {
    const mockOnInit = jest.fn()
    render(<PageEditor data={null} onInit={mockOnInit} />)

    expect(mockOnInit).toHaveBeenCalledWith({
      getContent: expect.any(Function),
    })
  })

  it('does not break when onInit is null', () => {
    expect(() => {
      render(<PageEditor data={null} onInit={null} />)
    }).not.toThrow()
  })
})
