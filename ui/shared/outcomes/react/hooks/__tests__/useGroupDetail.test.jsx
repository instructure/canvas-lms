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
import {groupDetailMocks, groupDetailMocksFetchMore} from '../../../mocks/Management'
import {MockedProvider} from '@apollo/react-testing'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import OutcomesContext, {ACCOUNT_GROUP_ID} from '../../contexts/OutcomesContext'
import {FIND_GROUP_OUTCOMES} from '../../../graphql/Management'

jest.mock('@canvas/alerts/react/FlashAlert')

const flushAllTimersAndPromises = async () => {
  while (jest.getTimerCount() > 0) {
    // eslint-disable-next-line no-await-in-loop
    await act(async () => {
      jest.runAllTimers()
    })
  }
}

const outcomeTitles = result => result.current.group.outcomes.edges.map(edge => edge.node.title)
const outcomeFriendlyDescriptions = result =>
  result.current.group.outcomes.edges.map(edge => edge.node.friendlyDescription?.description || '')

describe('groupDetailHook', () => {
  let cache, mocks, showFlashAlertSpy
  const searchMocks = [
    ...groupDetailMocks(),
    ...groupDetailMocks({
      groupId: '1',
      searchQuery: 'search',
    }),
  ]

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
      <OutcomesContext.Provider
        value={{
          env: {
            contextType: 'Account',
            contextId: '1',
            rootIds: [ACCOUNT_GROUP_ID],
          },
        }}
        f={true}
      >
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  it('should load group info correctly with pagination', async () => {
    const {result} = renderHook(() => useGroupDetail({id: '1'}), {
      wrapper,
    })
    expect(result.current.loading).toBe(true)
    expect(result.current.group).toBe(null)
    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(false)
    expect(result.current.group.title).toBe('Group 1')
    expect(outcomeTitles(result)).toEqual(['Outcome 1 - Group 1', 'Outcome 2 - Group 1'])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(true)
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(result)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1',
      'Outcome 3 - Group 1',
      'Outcome 4 - Group 1',
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it('should move the outcomes to correct order when loading the same outcome', async () => {
    mocks = groupDetailMocksFetchMore()
    const {result} = renderHook(() => useGroupDetail({id: '1'}), {
      wrapper,
    })
    await act(async () => jest.runAllTimers())
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 2 - Group 1',
    ])
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(result.current.group.outcomes.edges.map(edge => edge.node.title)).toEqual([
      'Outcome 2 - Group 1',
      'New Outcome 1 - Group 1',
      'Outcome 3 - Group 1',
    ])
  })

  it("should flash an error message and return the error when coudn't load by default", async () => {
    const {result} = renderHook(() => useGroupDetail({id: '2'}), {
      wrapper,
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading selected group.',
      type: 'error',
    })
    expect(result.current.error).not.toBe(null)
  })

  describe('should flash a screenreader message when group has finshed loading', () => {
    it('shows pluralized info message when a group has more than 1 outcome', async () => {
      const {result} = renderHook(id => useGroupDetail({id}), {wrapper, initialProps: '1'})
      await act(async () => jest.runAllTimers())
      expect(result.current.group.title).toBe('Group 1')
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Showing 2 outcomes for Group 1.',
        srOnly: true,
      })
    })

    it('shows singularized info message when a group has only 1 outcome', async () => {
      mocks = [...groupDetailMocks({numOfOutcomes: 1})]
      const {result} = renderHook(id => useGroupDetail({id}), {wrapper, initialProps: '1'})
      await act(async () => jest.runAllTimers())
      expect(result.current.group.title).toBe('Group 1')
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Showing 1 outcome for Group 1.',
        srOnly: true,
      })
    })
  })

  it('resets and loads correctly when change the id', async () => {
    mocks = [...groupDetailMocks(), ...groupDetailMocks({groupId: '2'})]
    const {result, rerender} = renderHook(id => useGroupDetail({id}), {wrapper, initialProps: '1'})
    await act(async () => jest.runAllTimers())
    expect(result.current.group.title).toBe('Group 1')
    act(() => rerender('2'))
    await act(async () => jest.runAllTimers())
    expect(result.current.group.title).toBe('Group 2')
    expect(outcomeTitles(result)).toEqual(['Outcome 1 - Group 2', 'Outcome 2 - Group 2'])
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(result)).toEqual([
      'Outcome 1 - Group 2',
      'Outcome 2 - Group 2',
      'Outcome 3 - Group 2',
      'Outcome 4 - Group 2',
    ])
  })

  it('refetches when id is in rhsGroupIdsToRefetch', async () => {
    mocks = [...groupDetailMocks(), ...groupDetailMocks({groupId: '200'})]
    const {result, rerender} = renderHook(
      id => useGroupDetail({id, rhsGroupIdsToRefetch: ['200']}),
      {wrapper, initialProps: '1'}
    )
    await act(async () => jest.runAllTimers())
    expect(result.current.group.title).toBe('Group 1')
    expect(outcomeTitles(result)).toEqual(['Outcome 1 - Group 1', 'Outcome 2 - Group 1'])
    expect(outcomeFriendlyDescriptions(result)).toEqual(['', ''])
    act(() => rerender('200'))
    await flushAllTimersAndPromises()
    expect(result.current.group.title).toBe('Refetched Group 200')
    expect(outcomeTitles(result)).toEqual([
      'Refetched Outcome 1 - Group 200',
      'Refetched Outcome 2 - Group 200',
      'Newly Created Outcome - Group 200',
    ])
    expect(outcomeFriendlyDescriptions(result)).toEqual(['friendly', '', ''])
  })

  it('should not load group info if ACCOUNT_GROUP_ID passed as id', async () => {
    const {result} = renderHook(() => useGroupDetail({id: ACCOUNT_GROUP_ID}), {wrapper})
    expect(result.current.loading).toBe(false)
    expect(result.current.group).toBe(null)
    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(false)
    expect(result.current.group).toBe(null)
  })

  it('should load group info if search length is equal to 0 or greater than 2', async () => {
    mocks = searchMocks
    const hook = renderHook(
      search =>
        useGroupDetail({
          id: '1',
          query: FIND_GROUP_OUTCOMES,
          loadOutcomesIsImported: false,
          searchString: search,
        }),
      {wrapper}
    )
    hook.rerender('')
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 - Group 1', 'Outcome 2 - Group 1'])

    hook.rerender('s')
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 - Group 1', 'Outcome 2 - Group 1'])

    hook.rerender('se')
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 - Group 1', 'Outcome 2 - Group 1'])

    hook.rerender('search')
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 - Group 1', 'Outcome 3 - Group 1'])
  })

  it('should search for group outcomes correctly with pagination', async () => {
    mocks = searchMocks
    const {result} = renderHook(
      () =>
        useGroupDetail({
          id: '1',
          query: FIND_GROUP_OUTCOMES,
          loadOutcomesIsImported: false,
          searchString: 'search',
        }),
      {wrapper}
    )
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(result)).toEqual(['Outcome 1 - Group 1', 'Outcome 3 - Group 1'])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(true)
    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(result)).toEqual([
      'Outcome 1 - Group 1',
      'Outcome 3 - Group 1',
      'Outcome 5 - Group 1',
      'Outcome 6 - Group 1',
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it('Remove outcomes correctly', async () => {
    const {result} = renderHook(() => useGroupDetail({id: '1'}), {
      wrapper,
    })

    await act(async () => jest.runAllTimers())
    let contentTags = result.current.group.outcomes.edges
    expect(contentTags.length).toBe(2)
    expect(result.current.group.outcomesCount).toBe(2)

    act(() => result.current.removeLearningOutcomes(['1']))
    contentTags = result.current.group.outcomes.edges

    expect(result.current.group.outcomesCount).toBe(1)
    expect(contentTags.length).toBe(1)
    expect(contentTags[0]._id).toBe('2')
  })

  it('if searching, should remove outcomes from not searching cache', async () => {
    mocks = searchMocks
    const hook = renderHook(
      search =>
        useGroupDetail({
          id: '1',
          query: FIND_GROUP_OUTCOMES,
          loadOutcomesIsImported: false,
          searchString: search,
        }),
      {wrapper}
    )

    // load without search
    // it'll cache this result in graphql cache
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 - Group 1', 'Outcome 2 - Group 1'])

    // load with search
    hook.rerender('search')
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 - Group 1', 'Outcome 3 - Group 1'])

    // remove outcome 1
    act(() => hook.result.current.removeLearningOutcomes(['1']))

    // should remove outcome 1 from query with search
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 3 - Group 1'])

    // clear search
    hook.rerender('')
    await act(async () => jest.runAllTimers())

    // should remove outcome 1 from query without search
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 2 - Group 1'])
  })
})
