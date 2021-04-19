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

import {act, renderHook} from '@testing-library/react-hooks'
import useTabState from '../useTabState'
import {TAB_IDS} from '../../utils'

beforeAll(() => {
  window.history.replaceState = jest.fn()
})

afterEach(() => {
  window.history.replaceState.mockClear()
  window.location.hash = ''
})

describe('useTabState hook', () => {
  it('sets the current tab to the passed-in default tab', () => {
    const {result} = renderHook(() => useTabState(TAB_IDS.GRADES))
    expect(result.current.currentTab).toBe(TAB_IDS.GRADES)
  })

  it('updates the current tab as handleTabChange is called and keeps activeTab in sync', () => {
    const {result} = renderHook(() => useTabState(TAB_IDS.MODULES))
    let {activeTab, currentTab} = result.current
    expect(currentTab).toBe(TAB_IDS.MODULES)
    expect(activeTab.current).toBe(TAB_IDS.MODULES)

    act(() => result.current.handleTabChange(TAB_IDS.RESOURCES))

    activeTab = result.current.activeTab
    currentTab = result.current.currentTab
    expect(currentTab).toBe(TAB_IDS.RESOURCES)
    expect(activeTab.current).toBe(TAB_IDS.RESOURCES)
  })

  describe('stores current tab ID to URL', () => {
    afterEach(() => {
      window.location.hash = ''
    })

    it('and starts at that tab if it is valid', () => {
      window.location.hash = '#schedule'
      const {result} = renderHook(() => useTabState(TAB_IDS.GRADES))
      expect(result.current.currentTab).toBe(TAB_IDS.SCHEDULE)
    })

    it('and starts at the default tab if it is invalid', () => {
      window.location.hash = '#fake-tab'
      const {result} = renderHook(() => useTabState(TAB_IDS.GRADES))
      expect(result.current.currentTab).toBe(TAB_IDS.GRADES)
    })

    it('and updates the URL hash as tabs are changed', () => {
      const {result} = renderHook(() => useTabState(TAB_IDS.GRADES))

      act(() => result.current.handleTabChange(TAB_IDS.RESOURCES))

      expect(window.history.replaceState).toHaveBeenCalled()
      expect(window.history.replaceState.mock.calls[0][0].id).toBe(TAB_IDS.RESOURCES)
      expect(window.history.replaceState.mock.calls[0][2]).toBe('http://localhost/#resources')

      act(() => result.current.handleTabChange(TAB_IDS.HOME))

      expect(window.history.replaceState.mock.calls[1][0].id).toBe(TAB_IDS.HOME)
      expect(window.history.replaceState.mock.calls[1][2]).toBe('http://localhost/#home')
    })
  })
})
