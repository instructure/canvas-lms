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

import useAllowedAttemptsState from '../useAllowedAttemptsState'
import {renderHook, act} from '@testing-library/react-hooks'

it('allows numeric value for the number of attempts', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: true, attempts: 42}))
  act(() => result.current.onAttemptsChange(3))
  expect(result.current.attempts).toBe(3)
})

it('allows attempts to be null (blank value)', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: true, attempts: 42}))
  act(() => result.current.onAttemptsChange(null))
  expect(result.current.attempts).toBe(null)
})

it('accepts -1 as an initial value', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: true, attempts: -1}))
  expect(result.current.attempts).toBe(-1)
})

it('only allows positive values for the number of attempts', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: true, attempts: 42}))
  act(() => result.current.onAttemptsChange(0))
  expect(result.current.attempts).toBe(42)
  act(() => result.current.onAttemptsChange(-3))
  expect(result.current.attempts).toBe(42)
})

it('sets limited to false and does not change attempts', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: true, attempts: 42}))
  act(() => result.current.onLimitedChange(false))
  expect(result.current.limited).toBe(false)
  expect(result.current.attempts).toBe(42)
})

it('sets limited to true and does not change attempts if attempts is positive', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: false, attempts: 42}))
  act(() => result.current.onLimitedChange(true))
  expect(result.current.limited).toBe(true)
  expect(result.current.attempts).toBe(42)
})

it('sets limited to true and sets -1 attempts to 1 ', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: false, attempts: -1}))
  act(() => result.current.onLimitedChange(true))
  expect(result.current.limited).toBe(true)
  expect(result.current.attempts).toBe(1)
})

it('sets limited to true and sets null attempts to 1', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: false, attempts: null}))
  act(() => result.current.onLimitedChange(true))
  expect(result.current.limited).toBe(true)
  expect(result.current.attempts).toBe(1)
})

it('does not set attempts when limited does not change', () => {
  const {result} = renderHook(() => useAllowedAttemptsState({limited: true, attempts: null}))
  act(() => result.current.onLimitedChange(true))
  expect(result.current.limited).toBe(true)
  expect(result.current.attempts).toBe(null)
})
