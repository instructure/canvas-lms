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
import useCourseAlignmentStats from '../useCourseAlignmentStats'
import {createCache} from '@canvas/apollo'
import {renderHook, act} from '@testing-library/react-hooks'
import {courseAlignmentStatsMocks} from '../../../mocks/Management'
import {MockedProvider} from '@apollo/react-testing'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import OutcomesContext from '../../contexts/OutcomesContext'

jest.mock('@canvas/alerts/react/FlashAlert')

describe('useCourseAlignmentStats', () => {
  let cache, showFlashAlertSpy
  const refetchMocks = [...courseAlignmentStatsMocks(), ...courseAlignmentStatsMocks({id: '2'})]
  const getStats = result => {
    const {
      totalOutcomes,
      alignedOutcomes,
      totalAlignments,
      totalArtifacts,
      alignedArtifacts,
      artifactAlignments,
    } = result.current.data.course.outcomeAlignmentStats
    return [
      totalOutcomes,
      alignedOutcomes,
      totalAlignments,
      totalArtifacts,
      alignedArtifacts,
      artifactAlignments,
    ]
  }

  beforeEach(() => {
    jest.useFakeTimers()
    cache = createCache()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({
    children,
    mocks = courseAlignmentStatsMocks(),
    contextId = '1',
    contextType = 'Course',
  }) => (
    <MockedProvider cache={cache} mocks={mocks}>
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  it('loads properly course alignments stats', async () => {
    const {result} = renderHook(() => useCourseAlignmentStats(), {
      wrapper,
    })
    expect(result.current.loading).toBe(true)
    expect(result.current.data).toEqual({})
    await act(async () => jest.runAllTimers())
    expect(result.current.loading).toBe(false)
    expect(getStats(result)).toEqual([2, 1, 4, 5, 3, 3])
  })

  it('displays flash error message when stats fail to load', async () => {
    const {result} = renderHook(() => useCourseAlignmentStats(), {
      wrapper,
      initialProps: {
        mocks: [],
      },
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading course alignment statistics.',
      type: 'error',
    })
    expect(result.current.error).not.toBe(null)
  })

  it('should refetch data if query for the same course id is run a second time', async () => {
    const hook = renderHook(() => useCourseAlignmentStats(), {
      wrapper,
      initialProps: {
        mocks: refetchMocks,
      },
    })
    expect(hook.result.current.loading).toBe(true)
    expect(hook.result.current.data).toEqual({})
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.loading).toBe(false)
    expect(getStats(hook.result)).toEqual([2, 1, 4, 5, 3, 3])

    // fetch a different course to force hook rerender
    // then refetch the original course to test refetch
    hook.rerender({contextId: '2'})
    hook.rerender({contextId: '1'})
    expect(hook.result.current.loading).toBe(true)
    await act(async () => jest.runAllTimers())
    expect(hook.result.current.loading).toBe(false)
    expect(getStats(hook.result)).toEqual([12, 11, 14, 15, 13, 13])
  })
})
