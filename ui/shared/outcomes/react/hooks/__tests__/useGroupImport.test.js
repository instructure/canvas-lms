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
import useGroupImport from '../useGroupImport'
import {createCache} from '@canvas/apollo'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '../../contexts/OutcomesContext'
import {importGroupMocks} from '../../../mocks/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()

describe('useGroupImport', () => {
  let cache, showFlashAlertSpy
  const groupId = '100'
  beforeEach(() => {
    cache = createCache()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({
    children,
    mocks = importGroupMocks({groupId}),
    contextType = 'Account',
    contextId = '1'
  }) => (
    <MockedProvider cache={cache} mocks={mocks}>
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  it('creates custom hook with proper exports', () => {
    const {result} = renderHook(() => useGroupImport(), {
      wrapper
    })
    expect(typeof result.current.importGroup).toBe('function')
    expect(typeof result.current.importGroupsStatus).toBe('object')
  })

  it('imports group in Account context and displays flash confirmation', async () => {
    const {result} = renderHook(() => useGroupImport(), {
      wrapper
    })
    act(() => {
      result.current.importGroup(groupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'The outcome group was successfully imported into this account',
      type: 'success'
    })
  })

  it('imports group in Course context and displays flash confirmation', async () => {
    const {result} = renderHook(() => useGroupImport(), {
      wrapper,
      initialProps: {
        mocks: importGroupMocks({
          groupId,
          targetContextId: '2',
          targetContextType: 'Course'
        }),
        contextType: 'Course',
        contextId: '2'
      }
    })
    act(() => {
      result.current.importGroup(groupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'The outcome group was successfully imported into this course',
      type: 'success'
    })
  })

  it('displays flash error message with details if cannot import group', async () => {
    const {result} = renderHook(() => useGroupImport(), {
      wrapper,
      initialProps: {
        mocks: importGroupMocks({groupId, failResponse: true})
      }
    })
    act(() => {
      result.current.importGroup(groupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while importing this group: GraphQL error: Network error.',
      type: 'error'
    })
  })

  it('displays flash error generic message if cannot import group and no error details', async () => {
    const {result} = renderHook(() => useGroupImport(), {
      wrapper,
      initialProps: {
        mocks: importGroupMocks({groupId, failMutationNoErrMsg: true})
      }
    })
    act(() => {
      result.current.importGroup(groupId)
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while importing this group.',
      type: 'error'
    })
  })

  it('adds id of imported group to importGroupStatus', async () => {
    const {result} = renderHook(() => useGroupImport(), {
      wrapper
    })
    act(() => {
      result.current.importGroup(groupId)
    })
    await act(async () => jest.runAllTimers())
    expect(result.current.importGroupsStatus[groupId]).toBe(true)
  })
})
