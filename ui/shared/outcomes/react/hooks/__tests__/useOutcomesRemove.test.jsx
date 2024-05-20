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
import useOutcomesRemove, {
  REMOVE_FAILED,
  REMOVE_COMPLETED,
  REMOVE_NOT_STARTED,
  REMOVE_PENDING,
} from '../useOutcomesRemove'
import {createCache} from '@canvas/apollo'
import OutcomesContext from '../../contexts/OutcomesContext'
import {deleteOutcomeMocks} from '../../../mocks/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {MockedProvider} from '@apollo/react-testing'

jest.useFakeTimers()

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

const outcomesGenerator = (startId, count, canUnlink = true, sameGroup = false, title = '') =>
  new Array(count).fill(0).reduce(
    (acc, _curr, idx) => ({
      ...acc,
      [`${startId + idx}`]: {
        _id: `${idx + 100}`,
        linkId: `${startId + idx}`,
        title: title || `Learning Outcome ${startId + idx}`,
        canUnlink,
        parentGroupId: sameGroup ? 1001 : `${1001 + idx}`,
        parentGroupTitle: `Outcome Group ${sameGroup ? 1001 : 1001 + idx}`,
      },
    }),
    {}
  )

describe('useOutcomesRemove', () => {
  let cache
  beforeEach(() => {
    cache = createCache()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({
    children,
    mocks = deleteOutcomeMocks(),
    contextType = 'Account',
    contextId = '1',
  }) => (
    <MockedProvider cache={cache} mocks={mocks}>
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  it('creates custom hook with proper exports', () => {
    const {result} = renderHook(() => useOutcomesRemove(), {
      wrapper,
    })
    expect(typeof result.current.removeOutcomes).toBe('function')
    expect(typeof result.current.setRemoveOutcomesStatus).toBe('function')
    expect(typeof result.current.removeOutcomesStatus).toBe('object')
  })

  describe('Remove outcomes', () => {
    it('displays flash confirmation with proper message if delete request succeeds', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks(),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'This outcome was successfully removed.',
        type: 'success',
      })
    })

    it('displays flash error with proper message if delete request fails', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks({failResponse: true}),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing this outcome. Please try again.',
        type: 'error',
      })
    })

    it('displays flash error with proper message if delete request fails because it is aligned with content', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks({failAlignedContentMutation: true}),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing this outcome. Please try again.',
        type: 'error',
      })
    })

    it('displays flash confirmation with proper message if delete mutation fails', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks({failMutation: true}),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing this outcome. Please try again.',
        type: 'error',
      })
    })

    it('displays flash confirmation with proper message if delete request fails with no error message', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks({failMutationNoErrMsg: true}),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing this outcome. Please try again.',
        type: 'error',
      })
    })

    it('sets status of deleted outcome to complete if delete succeeds', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks(),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      expect(result.current.removeOutcomesStatus).toEqual({1: REMOVE_PENDING})
      await act(async () => jest.runAllTimers())
      expect(result.current.removeOutcomesStatus).toEqual({1: REMOVE_COMPLETED})
    })

    it('sets status of deleted outcome to failed if delete fails', async () => {
      const outcomes = outcomesGenerator(1, 1)
      const {result} = renderHook(() => useOutcomesRemove(), {
        wrapper,
        initialProps: {
          mocks: deleteOutcomeMocks({failResponse: true}),
        },
      })
      act(() => {
        result.current.removeOutcomes(outcomes)
      })
      expect(result.current.removeOutcomesStatus).toEqual({1: REMOVE_PENDING})
      await act(async () => jest.runAllTimers())
      expect(result.current.removeOutcomesStatus).toEqual({1: REMOVE_FAILED})
    })

    describe('Bulk Remove Outcomes', () => {
      it('displays flash confirmation with proper message if delete request succeeds', async () => {
        const outcomes = outcomesGenerator(1, 4)
        const {result} = renderHook(() => useOutcomesRemove(), {
          wrapper,
          initialProps: {
            mocks: deleteOutcomeMocks({ids: ['1', '2', '3', '4']}),
          },
        })
        act(() => {
          result.current.removeOutcomes(outcomes)
        })
        await act(async () => jest.runAllTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: '4 outcomes were successfully removed.',
          type: 'success',
        })
      })

      it('displays flash error with proper message if delete request fails', async () => {
        const outcomes = outcomesGenerator(1, 4)
        const {result} = renderHook(() => useOutcomesRemove(), {
          wrapper,
          initialProps: {
            mocks: deleteOutcomeMocks({ids: ['1', '2', '3', '4'], failResponse: true}),
          },
        })
        act(() => {
          result.current.removeOutcomes(outcomes)
        })
        await act(async () => jest.runAllTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while removing these outcomes. Please try again.',
          type: 'error',
        })
      })

      it('displays flash confirmation with proper message if delete mutation fails', async () => {
        const outcomes = outcomesGenerator(1, 4)
        const {result} = renderHook(() => useOutcomesRemove(), {
          wrapper,
          initialProps: {
            mocks: deleteOutcomeMocks({ids: ['1', '2', '3', '4'], failMutation: true}),
          },
        })
        act(() => {
          result.current.removeOutcomes(outcomes)
        })
        await act(async () => jest.runAllTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while removing these outcomes. Please try again.',
          type: 'error',
        })
      })

      it('displays flash confirmation with proper message if delete request fails with no error message', async () => {
        const outcomes = outcomesGenerator(1, 4)
        const {result} = renderHook(() => useOutcomesRemove(), {
          wrapper,
          initialProps: {
            mocks: deleteOutcomeMocks({ids: ['1', '2', '3', '4'], failMutationNoErrMsg: true}),
          },
        })
        act(() => {
          result.current.removeOutcomes(outcomes)
        })
        await act(async () => jest.runAllTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while removing these outcomes. Please try again.',
          type: 'error',
        })
      })

      it('displays flash generic error if remove outcomes mutation partially succeeds', async () => {
        const outcomes = outcomesGenerator(1, 4)
        const {result} = renderHook(() => useOutcomesRemove(), {
          wrapper,
          initialProps: {
            mocks: deleteOutcomeMocks({ids: ['1', '2', '3', '4'], partialSuccess: true}),
          },
        })
        act(() => {
          result.current.removeOutcomes(outcomes)
        })
        await act(async () => jest.runAllTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while removing these outcomes. Please try again.',
          type: 'error',
        })
      })

      it('sets status of outcomes being removed to pending and others are not started', async () => {
        const outcomes = outcomesGenerator(1, 4)
        const {result} = renderHook(() => useOutcomesRemove(), {
          wrapper,
          initialProps: {
            mocks: deleteOutcomeMocks({ids: ['1', '3']}),
          },
        })
        result.current.setRemoveOutcomesStatus({
          1: REMOVE_NOT_STARTED,
          2: REMOVE_NOT_STARTED,
          3: REMOVE_NOT_STARTED,
          4: REMOVE_NOT_STARTED,
        })
        act(() => {
          result.current.removeOutcomes({1: outcomes['1'], 3: outcomes['3']})
        })
        expect(result.current.removeOutcomesStatus).toEqual({
          1: REMOVE_PENDING,
          2: REMOVE_NOT_STARTED,
          3: REMOVE_PENDING,
          4: REMOVE_NOT_STARTED,
        })
        await act(async () => jest.runAllTimers())
        expect(result.current.removeOutcomesStatus).toEqual({
          1: REMOVE_COMPLETED,
          2: REMOVE_NOT_STARTED,
          3: REMOVE_COMPLETED,
          4: REMOVE_NOT_STARTED,
        })
      })
    })
  })
})
