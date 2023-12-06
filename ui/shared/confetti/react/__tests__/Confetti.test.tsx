// @vitest-environment jsdom
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
import {render, act, fireEvent} from '@testing-library/react'
import Confetti from '../Confetti'
import React from 'react'

jest.useFakeTimers()

describe('Confetti', () => {
  let originalEnv: any
  beforeEach(() => {
    originalEnv = JSON.parse(JSON.stringify(window.ENV))
    act(() => {
      jest.advanceTimersByTime(10000)
    })
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  it('renders confetti', () => {
    const {getByTestId} = render(<Confetti />)
    expect(getByTestId('confetti-canvas')).toBeInTheDocument()
  })

  it('clears confetti after 3 seconds', () => {
    const {queryByTestId} = render(<Confetti />)
    expect(queryByTestId('confetti-canvas')).toBeInTheDocument()
    act(() => {
      jest.advanceTimersByTime(3000)
    })
    expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
  })

  describe('screenreader content', () => {
    it('announces the text', () => {
      const {queryByText} = render(<Confetti />)
      expect(queryByText('Great work! From the Canvas developers')).toBeInTheDocument()
      act(() => {
        jest.advanceTimersByTime(10000)
      })
      expect(queryByText('Great work! From the Canvas developers')).not.toBeInTheDocument()
    })
  })

  describe('keyboard clearing', () => {
    it('clears confetti when pressing `SPACE`', () => {
      const {queryByTestId} = render(<Confetti />)
      expect(queryByTestId('confetti-canvas')).toBeInTheDocument()
      act(() => {
        fireEvent.keyDown(document.body, {key: 'Space', keyCode: 32})
      })
      expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
    })

    it('clears confetti when pressing `ESC`', () => {
      const {queryByTestId} = render(<Confetti />)
      expect(queryByTestId('confetti-canvas')).toBeInTheDocument()
      act(() => {
        fireEvent.keyDown(document.body, {key: 'Escape', keyCode: 27})
      })
      expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
    })
  })

  describe('user has disabled celebrations', () => {
    it('does not render confetti', () => {
      // @ts-expect-error
      window.ENV = {
        disable_celebrations: true,
      }
      const {queryByTestId} = render(<Confetti />)
      expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
    })
  })

  describe('user has enabled celebrations', () => {
    it('does render confetti', () => {
      // @ts-expect-error
      window.ENV = {
        disable_celebrations: false,
      }
      const {queryByTestId} = render(<Confetti />)
      expect(queryByTestId('confetti-canvas')).toBeInTheDocument()
    })
  })
})
