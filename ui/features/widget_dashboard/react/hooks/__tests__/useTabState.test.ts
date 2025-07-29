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
import {useTabState} from '../useTabState'
import {TAB_IDS} from '../../constants'
import type {TabId} from '../../types'

type HookArgs = {
  defaultTab?: TabId
}

const setUp = (args: HookArgs = {}) => {
  return renderHook(() => useTabState(args.defaultTab))
}

const buildDefaultArgs = (overrides: Partial<HookArgs> = {}): HookArgs => {
  const defaultArgs: HookArgs = {
    defaultTab: undefined, // Let hook use its own default
  }

  return {...defaultArgs, ...overrides}
}

describe('useTabState', () => {
  it('should initialize with default tab (DASHBOARD)', () => {
    const {result} = setUp(buildDefaultArgs())

    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should initialize with provided default tab', () => {
    const {result} = setUp(buildDefaultArgs({defaultTab: TAB_IDS.COURSES}))

    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)
  })

  it('should change tab when handleTabChange is called', () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })

    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)
  })

  it('should change tab back to dashboard', () => {
    const {result} = setUp(buildDefaultArgs({defaultTab: TAB_IDS.COURSES}))

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })

    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should maintain stable handleTabChange reference across renders', () => {
    const {result, rerender} = setUp(buildDefaultArgs())
    const firstHandleTabChange = result.current.handleTabChange

    rerender()

    expect(result.current.handleTabChange).toBe(firstHandleTabChange)
  })

  it('should handle multiple tab changes correctly', () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })
    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })
    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should handle setting the same tab multiple times', () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })

    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should work with different initial configurations', () => {
    const {result: resultDefault} = setUp(buildDefaultArgs())
    const {result: resultCourses} = setUp(buildDefaultArgs({defaultTab: TAB_IDS.COURSES}))

    expect(resultDefault.current.currentTab).toBe(TAB_IDS.DASHBOARD)
    expect(resultCourses.current.currentTab).toBe(TAB_IDS.COURSES)
  })
})
