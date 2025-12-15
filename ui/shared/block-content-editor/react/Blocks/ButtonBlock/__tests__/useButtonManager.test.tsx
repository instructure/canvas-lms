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

import {renderHook, act} from '@testing-library/react-hooks'
import {useButtonManager} from '../useButtonManager'
import {ButtonData} from '../../BlockItems/Button/types'

const createButton = (id: number, text: string = ''): ButtonData => ({
  id,
  text,
  url: '',
  linkOpenMode: 'new-tab',
  primaryColor: '#000000',
  secondaryColor: '#FFFFFF',
  style: 'filled',
})

const MAX_BUTTONS = 5
const MIN_BUTTONS = 1

describe('useButtonManager', () => {
  const mockOnChange = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('initialization', () => {
    it('initializes with given buttons', () => {
      const {result} = renderHook(() => useButtonManager([createButton(1, 'A')], mockOnChange))
      expect(result.current.buttons).toHaveLength(1)
      expect(result.current.buttons[0].text).toBe('A')
      expect(result.current.buttons[0].id).toBe(1)
    })

    it('initializes without given buttons', () => {
      const {result} = renderHook(() => useButtonManager([], mockOnChange))
      expect(result.current.buttons).toHaveLength(0)
    })
  })

  describe('addButton', () => {
    it('adds a button', () => {
      const {result} = renderHook(() => useButtonManager([createButton(1)], mockOnChange))
      act(() => {
        result.current.addButton()
      })
      expect(result.current.buttons).toHaveLength(2)
      expect(mockOnChange).toHaveBeenCalledWith(result.current.buttons)
    })

    it('adds a button up to MAX_BUTTONS', () => {
      const {result} = renderHook(() => useButtonManager([createButton(1)], mockOnChange))
      for (let i = 0; i < MAX_BUTTONS + 1; i++) {
        act(() => {
          result.current.addButton()
        })
      }
      expect(result.current.buttons).toHaveLength(MAX_BUTTONS)
      expect(result.current.canAddButton).toBe(false)
    })
  })

  describe('removeButton', () => {
    it('removes a button', () => {
      const {result} = renderHook(() =>
        useButtonManager([createButton(1), createButton(2)], mockOnChange),
      )
      expect(result.current.buttons).toHaveLength(2)
      act(() => {
        result.current.removeButton(1)
      })
      expect(result.current.buttons).toHaveLength(1)
      expect(mockOnChange).toHaveBeenCalledWith(result.current.buttons)
    })

    it('doesn not remove below MIN_BUTTONS', () => {
      const {result} = renderHook(() =>
        useButtonManager([createButton(1), createButton(2)], mockOnChange),
      )

      act(() => {
        result.current.removeButton(1)
      })
      act(() => {
        result.current.removeButton(2)
      })

      expect(result.current.buttons).toHaveLength(MIN_BUTTONS)
      expect(result.current.canDeleteButton).toBe(false)
    })
  })

  describe('updateButton', () => {
    it('updates a button', () => {
      const {result} = renderHook(() => useButtonManager([createButton(1)], mockOnChange))
      act(() => {
        result.current.updateButton(1, {text: 'Updated'})
      })
      expect(result.current.buttons[0].text).toBe('Updated')
      expect(mockOnChange).toHaveBeenCalledWith(result.current.buttons)
    })

    it('does not update non-existent button', () => {
      const {result} = renderHook(() => useButtonManager([createButton(1)], mockOnChange))
      act(() => {
        result.current.updateButton(2, {text: 'Does not exist'})
      })
      expect(result.current.buttons[0].text).toBe('')
    })
  })
})
