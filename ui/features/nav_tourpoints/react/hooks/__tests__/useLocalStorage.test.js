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

import useLocalStorage from '../useLocalStorage'
import {renderHook} from '@testing-library/react-hooks/dom'

describe('Module: use-localstorage', () => {
  describe('useLocalStorage', () => {
    it('is callable', () => {
      const {result} = renderHook(() => useLocalStorage('foo', 'bar'))

      expect(result.current).toBeDefined()
    })

    it('can have a numeric default value', () => {
      const key = 'Number Value'
      const defaultValue = 42
      const {result} = renderHook(() => useLocalStorage(key, defaultValue))

      expect(result.current[0]).toBe(defaultValue)
    })

    it('can have a default value of 0', async () => {
      const key = 'AmountOfMoneyInMyBankAccount'
      const defaultValue = 0
      const {result} = renderHook(() => useLocalStorage(key, defaultValue))

      expect(result.current[0]).toBe(defaultValue)
    })

    describe('when existing value is false', () => {
      it('returns false value when the default value is true', () => {
        const key = 'AmIFalse'
        const defaultValue = true

        localStorage.setItem(key, 'false')

        const {result} = renderHook(() => useLocalStorage(key, defaultValue))

        expect(result.current[0]).toBe(false)
      })

      it('returns false value when default value is false', () => {
        const key = 'AmIFalse'
        const defaultValue = false

        localStorage.setItem(key, 'false')

        const {result} = renderHook(() => useLocalStorage(key, defaultValue))

        expect(result.current[0]).toBe(false)
      })
    })
  })
})
