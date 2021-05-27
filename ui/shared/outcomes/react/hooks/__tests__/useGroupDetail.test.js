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
import useGroupDetail from '../useGroupDetail'
import {createCache} from '@canvas/apollo'
import {renderHook, act} from '@testing-library/react-hooks'
import {groupDetailMocks} from '../../../mocks/Management'
import {MockedProvider} from '@apollo/react-testing'
import {ACCOUNT_FOLDER_ID} from '../../treeBrowser'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import OutcomesContext from '../../contexts/OutcomesContext'
import {FIND_GROUP_OUTCOMES} from '@canvas/outcomes/graphql/Management'

jest.mock('@canvas/alerts/react/FlashAlert')

describe('groupDetailHook', () => {
  let cache, mocks, showFlashAlertSpy

  beforeEach(() => {
    jest.useFakeTimers()
    cache = createCache()
    mocks = groupDetailMocks()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({children}) => (
    <MockedProvider cache={cache} mocks={mocks}>
      <OutcomesContext.Provider value={{env: {contextType: 'Account', contextId: '1'}}}>
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  it('should load group info correctly with pagination', async () => {
    const {result} = renderHook(() => useGroupDetail({id: '1'}), {
      wrapper
    })
    expect(result.current.loading).toBe(true)
    expect(result.current.group).toBe(null)
    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(false)
    expect(result.current.group.title).toBe('Group 1')
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1'
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(true)
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1',
      'Outcome 3 - Group 1',
      'Outcome 4 - Group 1'
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it("should flash an error message and return the error when coudn't load", async () => {
    const {result} = renderHook(() => useGroupDetail({id: '2'}), {
      wrapper
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading selected group.',
      type: 'error'
    })
    expect(result.current.error).not.toBe(null)
  })

  it('resets and loads correctly when change the id', async () => {
    mocks = [...groupDetailMocks(), ...groupDetailMocks({groupId: '2'})]
    const {result, rerender} = renderHook(id => useGroupDetail({id}), {wrapper, initialProps: '1'})
    await act(async () => jest.runAllTimers())
    expect(result.current.group.title).toBe('Group 1')
    act(() => rerender('2'))
    await act(async () => jest.runAllTimers())
    expect(result.current.group.title).toBe('Group 2')
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 2',
      'Outcome 2 - Group 2'
    ])
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 2',
      'Outcome 2 - Group 2',
      'Outcome 3 - Group 2',
      'Outcome 4 - Group 2'
    ])
  })

  it('should not load group info if ACCOUNT_FOLDER_ID passed as id', async () => {
    const {result} = renderHook(() => useGroupDetail({id: ACCOUNT_FOLDER_ID}), {wrapper})
    expect(result.current.loading).toBe(true)
    expect(result.current.group).toBe(null)
    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(true)
    expect(result.current.group).toBe(null)
  })

  it('should load group info if search length is equal to 0 or greater than 2', async () => {
    mocks = [...groupDetailMocks(), ...groupDetailMocks({groupId: '1', searchQuery: 'search'})]

    const hook = renderHook(
      search =>
        useGroupDetail({
          id: '1',
          query: FIND_GROUP_OUTCOMES,
          loadOutcomesIsImported: false,
          searchString: search
        }),
      {wrapper}
    )
    hook.rerender('')
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1'
    ])

    hook.rerender('s')
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1'
    ])

    hook.rerender('se')
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1'
    ])

    hook.rerender('search')
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 3 - Group 1'
    ])
  })

  it('should search for group outcomes correctly with pagination', async () => {
    mocks = [...groupDetailMocks(), ...groupDetailMocks({groupId: '1', searchQuery: 'search'})]
    const {result} = renderHook(
      () =>
        useGroupDetail({
          id: '1',
          query: FIND_GROUP_OUTCOMES,
          loadOutcomesIsImported: false,
          searchString: 'search'
        }),
      {wrapper}
    )
    await act(async () => jest.runAllTimers())
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 3 - Group 1'
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(true)
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 3 - Group 1',
      'Outcome 5 - Group 1',
      'Outcome 6 - Group 1'
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(false)
  })
})
