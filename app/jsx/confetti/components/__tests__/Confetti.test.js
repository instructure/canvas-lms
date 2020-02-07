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
import {render, fireEvent} from '@testing-library/react'
import Confetti from '../Confetti'
import React from 'react'
import {mockRender, mockClear} from 'confetti-js'

jest.genMockFromModule('confetti-js')
jest.useFakeTimers()

describe('Confetti', () => {
  beforeEach(() => {
    mockRender.mockClear()
    mockClear.mockClear()
  })

  it('renders confetti-js', () => {
    render(<Confetti />)
    expect(mockRender).toHaveBeenCalled()
  })

  it('clears confetti after 3 seconds', () => {
    render(<Confetti />)
    expect(mockClear).not.toHaveBeenCalled()
    jest.advanceTimersByTime(3000)
    expect(mockClear).toHaveBeenCalled()
  })

  describe('keyboard clearing', () => {
    it('clears confetti when pressing `SPACE`', () => {
      render(<Confetti />)
      expect(mockClear).not.toHaveBeenCalled()
      fireEvent.keyDown(document.body, {key: 'Space', keyCode: 32})
      expect(mockClear).toHaveBeenCalled()
    })

    it('clears confetti when pressing `ESC`', () => {
      render(<Confetti />)
      expect(mockClear).not.toHaveBeenCalled()
      fireEvent.keyDown(document.body, {key: 'Escape', keyCode: 27})
      expect(mockClear).toHaveBeenCalled()
    })
  })
})
