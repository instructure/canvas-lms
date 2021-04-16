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
import $ from 'jquery'
import {MockedProvider} from '@apollo/react-testing'
import {ACCOUNT_FOLDER_ID} from '../../treeBrowser'

describe('groupDetailHook', () => {
  let cache, mocks

  beforeEach(() => {
    jest.useFakeTimers()
    cache = createCache()
    mocks = groupDetailMocks()
  })

  const wrapper = ({children}) => (
    <MockedProvider cache={cache} mocks={mocks}>
      {children}
    </MockedProvider>
  )

  it('should load group info correctly with pagination', async () => {
    const {result} = renderHook(() => useGroupDetail('1'), {wrapper})
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
      'Outcome 3 - Group 1'
    ])
    expect(result.current.group.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it("should flash an error message and return the error when coudn't load", async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {result} = renderHook(() => useGroupDetail('2'), {wrapper})
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading selected group.')
    expect(result.current.error).not.toBe(null)
  })

  it('resets and loads correctly when change the id', async () => {
    mocks = [...groupDetailMocks(), ...groupDetailMocks({groupId: '2'})]
    const {result, rerender} = renderHook(id => useGroupDetail(id), {wrapper, initialProps: '1'})
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
      'Outcome 3 - Group 2'
    ])
  })

  it('should not load group info if ACCOUNT_FOLDER_ID passed as id', async () => {
    const {result} = renderHook(() => useGroupDetail(ACCOUNT_FOLDER_ID), {wrapper})
    expect(result.current.loading).toBe(true)
    expect(result.current.group).toBe(null)
    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(true)
    expect(result.current.group).toBe(null)
  })
})
