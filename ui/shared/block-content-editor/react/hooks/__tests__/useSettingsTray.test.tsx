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
import {useSettingsTray} from '../useSettingsTray'

describe('useSettingsTray', () => {
  it('should be initialized with closed settings tray', () => {
    const {result} = renderHook(() => useSettingsTray())
    expect(result.current.isOpen).toBe(false)
    expect(result.current).not.toHaveProperty('blockId')
  })

  describe('open', () => {
    it('should set isOpen to true and blockId to the correct value', () => {
      const {result} = renderHook(() => useSettingsTray())

      act(() => {
        result.current.open('block-123')
      })

      expect(result.current.isOpen).toBe(true)
      result.current.isOpen && expect(result.current.blockId).toBe('block-123')
    })
  })

  describe('close', () => {
    it('should set isOpen to false and blockId to undefined', () => {
      const {result} = renderHook(() => useSettingsTray())

      act(() => {
        result.current.open('block-123')
      })

      act(() => {
        result.current.close()
      })

      expect(result.current.isOpen).toBe(false)
      expect(result.current).not.toHaveProperty('blockId')
    })
  })
})
