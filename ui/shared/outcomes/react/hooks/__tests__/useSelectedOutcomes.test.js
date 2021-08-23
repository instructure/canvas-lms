/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import useSelectedOutcomes from '../useSelectedOutcomes'

describe('useSelectedOutcomes', () => {
  const generateOutcomes = num =>
    new Array(num).fill(0).reduce(
      (acc, _val, ind) => ({
        ...acc,
        [`${ind + 1}`]: {
          _id: `${10 + ind}`,
          linkId: `${ind + 1}`,
          title: `Outcome ${10 + ind}`,
          canUnlink: true,
          parentGroupId: `${100 + ind}`,
          parentGroupTitle: `Outcome Group ${100 + ind}`
        }
      }),
      {}
    )
  const initialState = generateOutcomes(2)

  test('should create custom hook with initial state', () => {
    const {result} = renderHook(() => useSelectedOutcomes(initialState))
    expect(result.current.selectedOutcomes).toBe(initialState)
  })

  test('should create custom hook with state equal to an empty object if no initial state provided', () => {
    const {result} = renderHook(() => useSelectedOutcomes())
    expect(result.current.selectedOutcomes).toEqual({})
  })

  test('should calculate number of outcomes stored in the hook', () => {
    const {result} = renderHook(() => useSelectedOutcomes(initialState))
    expect(result.current.selectedOutcomesCount).toBe(2)
  })

  test('should clear state if clearSelectedOutcomes is called', () => {
    const {result} = renderHook(() => useSelectedOutcomes(initialState))
    act(() => result.current.clearSelectedOutcomes())
    expect(result.current.selectedOutcomes).toEqual({})
  })

  test('should toggle selected outcome in state if toggleSelectedOutcome is called', () => {
    const outcome = generateOutcomes(1)[1]
    const {result} = renderHook(() => useSelectedOutcomes(initialState))
    act(() => result.current.toggleSelectedOutcomes(outcome))
    expect(result.current.selectedOutcomesCount).toBe(1)
    act(() => result.current.toggleSelectedOutcomes(outcome))
    expect(result.current.selectedOutcomesCount).toBe(2)
  })

  test('should not change state if action type is missing or not defined', () => {
    const {result} = renderHook(() => useSelectedOutcomes(initialState))
    act(() => result.current.dispatchSelectedOutcomes({}))
    expect(result.current.selectedOutcomes).toBe(initialState)
    act(() => result.current.dispatchSelectedOutcomes({type: 'not_defined_action_type'}))
    expect(result.current.selectedOutcomes).toBe(initialState)
  })
})
