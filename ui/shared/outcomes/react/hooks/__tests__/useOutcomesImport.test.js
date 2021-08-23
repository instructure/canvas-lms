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
import useOutcomesImport, {
  IMPORT_PENDING,
  IMPORT_FAILED,
  IMPORT_COMPLETED
} from '../useOutcomesImport'
import {createCache} from '@canvas/apollo'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '../../contexts/OutcomesContext'
import {importGroupMocks, importOutcomeMocks} from '../../../mocks/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import resolveProgress from '@canvas/progress/resolve_progress'

jest.mock('@canvas/progress/resolve_progress')
jest.useFakeTimers()

describe('useOutcomesImport', () => {
  let cache, showFlashAlertSpy
  const groupId = '100'
  const outcomeId = '200'
  beforeEach(() => {
    cache = createCache()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    resolveProgress.mockImplementation(() => Promise.resolve())
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({
    children,
    mocks = importGroupMocks(),
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
    const {result} = renderHook(() => useOutcomesImport(), {
      wrapper
    })
    expect(typeof result.current.importOutcomes).toBe('function')
    expect(typeof result.current.clearGroupsStatus).toBe('function')
    expect(typeof result.current.clearOutcomesStatus).toBe('function')
    expect(typeof result.current.importGroupsStatus).toBe('object')
    expect(typeof result.current.importOutcomesStatus).toBe('object')
  })

  describe('Group import', () => {
    it('adds imported group id with pending status to importGroupsStatus before starting group import', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_PENDING})
    })

    it('sets status of imported group to failed if import fails', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importGroupMocks({failResponse: true})
        }
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_FAILED})
    })

    it('calls progress tracker after group import mutation is triggered', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      await act(async () => jest.runAllTimers())
      expect(resolveProgress).toHaveBeenCalled()
      expect(resolveProgress).toHaveBeenCalledWith(
        {
          url: '/api/v1/progress/111',
          workflow_state: 'queued'
        },
        {
          interval: 5000
        }
      )
    })

    it('changes import group status from pending to completed when progress tracker resolves', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_PENDING})
      await act(async () => jest.runAllTimers())
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_COMPLETED})
    })

    it('changes import group status from pending to failed if progress tracker throws error', async () => {
      resolveProgress.mockImplementationOnce(() => Promise.reject(new Error()))
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_PENDING})
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while importing this group.',
        type: 'error'
      })
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_FAILED})
    })

    it('imports group in Account context and displays flash confirmation', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'The outcome group was successfully imported into this account.',
        type: 'success'
      })
    })

    it('imports group in Course context and displays flash confirmation', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importGroupMocks({
            targetContextId: '2',
            targetContextType: 'Course'
          }),
          contextType: 'Course',
          contextId: '2'
        }
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'The outcome group was successfully imported into this course.',
        type: 'success'
      })
    })

    it('displays flash error message with details if cannot import group', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importGroupMocks({failResponse: true})
        }
      })
      act(() => {
        result.current.importOutcomes('100')
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while importing this group: GraphQL error: Network error.',
        type: 'error'
      })
    })

    it('displays flash error generic message if cannot import group and no error details', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importGroupMocks({failMutationNoErrMsg: true})
        }
      })
      act(() => {
        result.current.importOutcomes('100')
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while importing this group.',
        type: 'error'
      })
    })

    it('clears importGroupsStatus if clearGroupsStatus called', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper
      })
      act(() => {
        result.current.importOutcomes(groupId)
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importGroupsStatus).toEqual({[groupId]: IMPORT_COMPLETED})
      act(() => {
        result.current.clearGroupsStatus()
      })
      expect(result.current.importGroupsStatus).toEqual({})
    })
  })

  describe('Outcome import', () => {
    it('adds imported outcome id with pending status to importOutcomesStatus before starting outcome import', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks()
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})
    })

    it('sets status of imported outcome to failed if import fails', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({failResponse: true})
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_FAILED})
    })

    it('calls progress tracker after outcome import mutation is triggered', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks()
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      await act(async () => jest.runAllTimers())
      expect(resolveProgress).toHaveBeenCalled()
      expect(resolveProgress).toHaveBeenCalledWith(
        {
          url: '/api/v1/progress/211',
          workflow_state: 'queued'
        },
        {
          interval: 1000
        }
      )
    })

    it('changes import outcome status from pending to completed when progress tracker resolves', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks()
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_COMPLETED})
    })

    it('changes import outcome status from pending to failed if progress tracker throws error', async () => {
      resolveProgress.mockImplementationOnce(() => Promise.reject(new Error()))
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks()
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while importing this outcome.',
        type: 'error'
      })
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_FAILED})
    })

    it('displays flash error message with details if cannot import outcome', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({failResponse: true})
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while importing this outcome: GraphQL error: Network error.',
        type: 'error'
      })
    })

    it('displays flash error generic message if cannot import outcome and no error details', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({failMutationNoErrMsg: true})
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while importing this outcome.',
        type: 'error'
      })
    })

    it('clears importOutcomesStatus if clearOutcomesStatus called', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks()
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false)
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_COMPLETED})
      act(() => {
        result.current.clearOutcomesStatus()
      })
      expect(result.current.importOutcomesStatus).toEqual({})
    })

    it('passes sourceContextId and sourceContexType to outcome import mutation if provided', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({sourceContextId: 300, sourceContextType: 'Account'})
        }
      })
      act(() => {
        result.current.importOutcomes(outcomeId, false, 300, 'Account')
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_COMPLETED})
    })
  })
})
