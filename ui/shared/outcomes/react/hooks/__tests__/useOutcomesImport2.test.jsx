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
  IMPORT_COMPLETED,
} from '../useOutcomesImport'
import {createCache} from '@canvas/apollo-v3'
import {MockedProvider} from '@apollo/client/testing'
import OutcomesContext from '../../contexts/OutcomesContext'
import {importGroupMocks, importOutcomeMocks} from '../../../mocks/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import resolveProgress from '@canvas/progress/resolve_progress'
import {waitFor} from '@testing-library/react'

jest.mock('@canvas/progress/resolve_progress')

jest.useFakeTimers()

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

describe('useOutcomesImport', () => {
  let cache
  const outcomeId = '200'
  beforeEach(() => {
    cache = createCache()
    resolveProgress.mockImplementation(() => Promise.resolve())
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const wrapper = ({
    children,
    mocks = importGroupMocks(),
    contextType = 'Account',
    contextId = '1',
  }) => (
    <MockedProvider cache={cache} mocks={mocks}>
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    </MockedProvider>
  )

  const sharedResolverSpecs = () => {
    it('calls for resolveProgress', async () => {
      renderHook(() => useOutcomesImport(), {
        wrapper,
      })

      await waitFor(() => {
        expect(resolveProgress).toHaveBeenCalledTimes(1)
      })
    })
  }

  describe('Outcome import', () => {
    it('adds imported outcome id with pending status to importOutcomesStatus before starting outcome import', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks(),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})
    })

    it('sets status of imported outcome to failed if import fails', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({failResponse: true}),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_FAILED})
    })

    it('calls progress tracker after outcome import mutation is triggered', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks(),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })
      await act(async () => jest.runAllTimers())
      expect(resolveProgress).toHaveBeenCalled()
      expect(resolveProgress).toHaveBeenCalledWith(
        {
          url: '/api/v1/progress/211',
          workflow_state: 'queued',
        },
        {
          interval: 1000,
        },
      )
    })

    it('changes import outcome status from pending to completed when progress tracker resolves', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks(),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_COMPLETED})
    })

    it('changes import outcome status from pending to failed if progress tracker throws error', async () => {
      // Save the original implementation to restore later
      const originalImplementation = resolveProgress.mockImplementation

      // Clear all previous mock implementations and set a new one that rejects
      resolveProgress.mockReset()
      resolveProgress.mockImplementation(() => Promise.reject(new Error()))

      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks(),
        },
      })

      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })

      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})

      await act(async () => jest.runAllTimers())

      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while importing this outcome.',
        type: 'error',
      })

      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_FAILED})

      // Restore the original mock implementation for subsequent tests
      resolveProgress.mockImplementation(originalImplementation)
    })

    it('displays flash error message with details if cannot import outcome', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({failResponse: true}),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while importing this outcome: Network error.',
        type: 'error',
      })
    })

    it('displays flash error generic message if cannot import outcome and no error details', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({failMutationNoErrMsg: true}),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
      })
      await act(async () => jest.runAllTimers())
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while importing this outcome.',
        type: 'error',
      })
    })

    it('clears importOutcomesStatus if clearOutcomesStatus called', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks(),
        },
      })
      act(() => {
        result.current.importOutcomes({outcomeOrGroupId: outcomeId, isGroup: false})
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
          mocks: importOutcomeMocks({sourceContextId: 300, sourceContextType: 'Account'}),
        },
      })
      act(() => {
        result.current.importOutcomes({
          outcomeOrGroupId: outcomeId,
          isGroup: false,
          sourceContextId: 300,
          sourceContextType: 'Account',
        })
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_COMPLETED})
    })

    it('imports outcomes correctly with targetGroupId', async () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
        initialProps: {
          mocks: importOutcomeMocks({targetGroupId: 123}),
        },
      })
      act(() => {
        result.current.importOutcomes({
          outcomeOrGroupId: outcomeId,
          isGroup: false,
          targetGroupId: 123,
        })
      })
      await act(async () => jest.runAllTimers())
      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_COMPLETED})
    })
  })

  describe('when has outcome in the localStorage', () => {
    beforeEach(() => {
      localStorage.activeImports = JSON.stringify([
        {
          outcomeOrGroupId: outcomeId,
          isGroup: false,
          progress: {_id: '111', state: 'queued', __typename: 'Progress'},
        },
      ])
    })

    afterEach(() => {
      delete localStorage.activeImports
    })

    it('returns outcome with import pending status', () => {
      const {result} = renderHook(() => useOutcomesImport(), {
        wrapper,
      })

      expect(result.current.importOutcomesStatus).toEqual({[outcomeId]: IMPORT_PENDING})
    })

    sharedResolverSpecs()
  })
})
