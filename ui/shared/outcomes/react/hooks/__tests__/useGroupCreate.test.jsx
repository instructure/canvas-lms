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
import {renderHook, act} from '@testing-library/react-hooks/dom'
import useGroupCreate from '../useGroupCreate'
import {createCache} from '@canvas/apollo'
import {MockedProvider} from '@apollo/react-testing'
import {createOutcomeGroupMocks} from '../../../mocks/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.useFakeTimers()

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

describe('useGroupCreate', () => {
  let cache
  const groupId = '101'
  const groupName = 'New Group'
  const parentGroupId = '100'

  beforeEach(() => {
    cache = createCache()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({children, mocks = createOutcomeGroupMocks()}) => (
    <MockedProvider cache={cache} mocks={mocks}>
      {children}
    </MockedProvider>
  )

  it('creates custom hook with proper exports', () => {
    const {result} = renderHook(() => useGroupCreate(), {
      wrapper,
    })
    expect(typeof result.current.createGroup).toBe('function')
    expect(typeof result.current.createdGroups).toBe('object')
    expect(Array.isArray(result.current.createdGroups)).toBe(true)
    expect(typeof result.current.clearCreatedGroups).toBe('function')
  })

  it('adds created group id to createdGroups if group created', async () => {
    const {result} = renderHook(() => useGroupCreate(), {
      wrapper,
    })
    act(() => {
      result.current.createGroup(groupName, parentGroupId)
    })
    await act(async () => jest.runAllTimers())
    expect(result.current.createdGroups).toEqual([groupId])
  })

  it('displays flash confirmation if group created', async () => {
    const {result} = renderHook(() => useGroupCreate(), {
      wrapper,
    })
    act(() => {
      result.current.createGroup(groupName, parentGroupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: '"New Group" was successfully created.',
      type: 'success',
    })
  })

  it('displays flash error message with details if create group fails', async () => {
    const {result} = renderHook(() => useGroupCreate(), {
      wrapper,
      initialProps: {
        mocks: createOutcomeGroupMocks({failResponse: true}),
      },
    })
    act(() => {
      result.current.createGroup(groupName, parentGroupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while creating this group. Please try again.',
      type: 'error',
    })
  })

  it('displays flash error generic message if create group fails and no error details', async () => {
    const {result} = renderHook(() => useGroupCreate(), {
      wrapper,
      initialProps: {
        mocks: createOutcomeGroupMocks({failMutationNoErrMsg: true}),
      },
    })
    act(() => {
      result.current.createGroup(groupName, parentGroupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while creating this group. Please try again.',
      type: 'error',
    })
  })

  it('clears createdGroups if clearCreatedGroups fn called', async () => {
    const {result} = renderHook(() => useGroupCreate(), {
      wrapper,
    })
    act(() => {
      result.current.createGroup(groupName, parentGroupId)
    })
    await act(async () => jest.runAllTimers())
    expect(result.current.createdGroups).toEqual([groupId])
    act(() => {
      result.current.clearCreatedGroups()
    })
    expect(result.current.createdGroups).toEqual([])
  })
})
