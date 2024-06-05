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

import React from 'react'
import {act, render, waitFor} from '@testing-library/react'
import PropTypes from 'prop-types'
import useTabState from '../useTabState'
import {TAB_IDS} from '../../utils'

const TABS = [
  {id: TAB_IDS.HOME},
  {id: TAB_IDS.GRADES},
  {id: TAB_IDS.MODULES},
  {id: TAB_IDS.SCHEDULE},
  {id: TAB_IDS.RESOURCES},
]

beforeAll(() => {
  window.history.replaceState = jest.fn()
})

afterEach(() => {
  window.history.replaceState.mockClear()
  window.location.hash = ''
})

const TestComponent = ({defaultTab, tabs, getResult = () => {}}) => {
  const result = useTabState(defaultTab, tabs)

  React.useEffect(() => {
    getResult(result)
  }, [result, getResult])
  return <div className="test-wrapper">Test</div>
}

TestComponent.propTypes = {
  defaultTab: PropTypes.string,
  tabs: PropTypes.arrayOf(
    PropTypes.oneOfType([
      PropTypes.shape({
        id: PropTypes.string.isRequired,
      }),
      PropTypes.string,
    ])
  ).isRequired,
  getResult: PropTypes.func,
}

const renderHook = (defaultTab, tabs, getResult) => {
  const {container} = render(
    <TestComponent defaultTab={defaultTab} tabs={tabs} getResult={getResult} />
  )
  return container.querySelector('.test-wrapper').innerHTML
}

describe('useTabState hook', () => {
  it('sets the current tab to the passed-in default tab', () => {
    renderHook(TAB_IDS.GRADES, TABS, result => {
      expect(result.currentTab).toBe(TAB_IDS.GRADES)
    })
  })

  it('defaults the current tab to the first tab if no default is passed-in', () => {
    renderHook(undefined, TABS, result => {
      expect(result.currentTab).toBe(TAB_IDS.HOME)
    })
  })

  it('leaves the current tab unset if no default or tabs are passed-in', () => {
    renderHook(undefined, [], result => {
      expect(result.currentTab).toBe(undefined)
    })
  })

  it('updates the current tab as handleTabChange is called and keeps activeTab in sync', () => {
    renderHook(TAB_IDS.MODULES, TABS, result => {
      let {activeTab, currentTab} = result
      waitFor(() => {
        expect(currentTab).toBe(TAB_IDS.MODULES)
        expect(activeTab).toBe(TAB_IDS.MODULES)

        act(() => result.handleTabChange(TAB_IDS.RESOURCES))

        activeTab = result.activeTab
        currentTab = result.currentTab
        expect(currentTab).toBe(TAB_IDS.RESOURCES)
        expect(activeTab).toBe(TAB_IDS.RESOURCES)
      })
    })
  })

  it('does not update the current tab if the requested tab is invalid', () => {
    renderHook(TAB_IDS.SCHEDULE, [TAB_IDS.MODULES], result => {
      expect(result.currentTab).toBe(TAB_IDS.SCHEDULE)

      act(() => result.handleTabChange(TAB_IDS.MODULES))
      expect(result.currentTab).toBe(TAB_IDS.SCHEDULE)
    })
  })

  describe('stores current tab ID to URL', () => {
    afterEach(() => {
      window.location.hash = ''
    })
    it('and starts at that tab if it is valid', () => {
      window.location.hash = '#schedule'
      renderHook(TAB_IDS.GRADES, TABS, result => {
        expect(result.currentTab).toBe(TAB_IDS.SCHEDULE)
      })
    })
    it('and starts at the default tab if it is invalid', () => {
      window.location.hash = '#fake-tab'
      renderHook(TAB_IDS.GRADES, TABS, result => {
        expect(result.currentTab).toBe(TAB_IDS.GRADES)
      })
    })
    it('and updates the URL hash as tabs are changed', () => {
      renderHook(TAB_IDS.GRADES, TABS, result => {
        act(() => result.handleTabChange(TAB_IDS.RESOURCES))
        expect(window.location.href).toBe('http://localhost/#resources')
        act(() => result.handleTabChange(TAB_IDS.HOME))
        expect(window.location.href).toBe('http://localhost/#home')
      })
    })
  })
})
