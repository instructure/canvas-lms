/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import useCourseAlignments from '../useCourseAlignments'
import {createCache} from '@canvas/apollo'
import {renderHook, act, cleanup} from '@testing-library/react-hooks'
import {courseAlignmentMocks} from '../../../mocks/Management'
import {MockedProvider} from '@apollo/react-testing'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import OutcomesContext from '../../contexts/OutcomesContext'

jest.mock('@canvas/alerts/react/FlashAlert')

const outcomeTitles = result => result.current.rootGroup.outcomes.edges.map(edge => edge.node.title)

describe('useCourseAlignments', () => {
  let cache, mocks, showFlashAlertSpy
  const searchMocks = [...courseAlignmentMocks(), ...courseAlignmentMocks({searchQuery: 'TEST'})]

  beforeEach(() => {
    jest.useFakeTimers()
    cache = createCache()
    mocks = courseAlignmentMocks()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
    cleanup()
  })

  const wrapper = ({children}) => (
    <MockedProvider cache={cache} mocks={mocks}>
      <OutcomesContext.Provider
        value={{
          env: {
            contextType: 'Course',
            contextId: '1',
            rootOutcomeGroup: {
              id: '1'
            }
          }
        }}
        f
      >
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  it('should load with pagination all outcomes', async () => {
    const {result} = renderHook(() => useCourseAlignments(), {
      wrapper
    })
    expect(result.current.loading).toBe(true)
    expect(result.current.rootGroup).toBe(null)

    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(false)
    expect(result.current.rootGroup._id).toBe('1')
    expect(outcomeTitles(result)).toEqual(['Outcome 1 with alignments', 'Outcome 2'])
    expect(result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(true)

    act(() => result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(result)).toEqual([
      'Outcome 1 with alignments',
      'Outcome 2',
      'Outcome 3 with alignments',
      'Outcome 4'
    ])
    expect(result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it('should load with pagination only outcomes with alignments', async () => {
    mocks = courseAlignmentMocks({searchFilter: 'WITH_ALIGNMENTS'})
    const hook = renderHook(() => useCourseAlignments(), {
      wrapper
    })

    hook.result.current.onFilterChangeHandler('WITH_ALIGNMENTS')
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.loading).toBe(false)
    expect(hook.result.current.rootGroup._id).toBe('1')
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 with alignments'])
    expect(hook.result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(true)

    act(() => hook.result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual([
      'Outcome 1 with alignments',
      'Outcome 3 with alignments'
    ])
    expect(hook.result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it('should load with pagination only outcomes withouts alignments', async () => {
    mocks = courseAlignmentMocks({searchFilter: 'NO_ALIGNMENTS'})
    const hook = renderHook(() => useCourseAlignments(), {
      wrapper
    })

    hook.result.current.onFilterChangeHandler('NO_ALIGNMENTS')
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.loading).toBe(false)
    expect(hook.result.current.rootGroup._id).toBe('1')
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 2'])
    expect(hook.result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(true)

    act(() => hook.result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 2', 'Outcome 4'])
    expect(hook.result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(false)
  })

  it("should flash an error message and return the error when coudn't load outcomes", async () => {
    mocks = courseAlignmentMocks({groupId: '2'})
    const {result} = renderHook(() => useCourseAlignments(), {
      wrapper
    })

    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading outcome alignments.',
      type: 'error'
    })
    expect(result.current.error).not.toBe(null)
  })

  it('should load outcomes if no search string or if search string > 2', async () => {
    mocks = searchMocks
    const hook = renderHook(() => useCourseAlignments(), {
      wrapper
    })

    hook.result.current.onSearchChangeHandler({target: {value: ''}})
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 with alignments', 'Outcome 2'])

    hook.result.current.onSearchChangeHandler({target: {value: 'T'}})
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 with alignments', 'Outcome 2'])

    hook.result.current.onSearchChangeHandler({target: {value: 'TE'}})
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual(['Outcome 1 with alignments', 'Outcome 2'])

    hook.result.current.onSearchChangeHandler({target: {value: 'TEST'}})
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual([
      'Outcome 1 with alignments',
      'Outcome 2 with alignments'
    ])
  })

  it('should search for outcomes with pagination', async () => {
    mocks = searchMocks
    const hook = renderHook(() => useCourseAlignments(), {wrapper})

    hook.result.current.onSearchChangeHandler({target: {value: 'TEST'}})
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual([
      'Outcome 1 with alignments',
      'Outcome 2 with alignments'
    ])

    expect(hook.result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(true)
    act(() => hook.result.current.loadMore())
    await act(async () => jest.runAllTimers())
    expect(outcomeTitles(hook.result)).toEqual([
      'Outcome 1 with alignments',
      'Outcome 2 with alignments',
      'Outcome 3 with alignments',
      'Outcome 4 with alignments'
    ])
    expect(hook.result.current.rootGroup.outcomes.pageInfo.hasNextPage).toBe(false)
  })
})
