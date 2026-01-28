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
import {act, waitFor} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {findOutcomesMocks, groupMocks, importGroupMocks} from '@canvas/outcomes/mocks/Management'
import {clickEl} from '@canvas/outcomes/react/helpers/testHelpers'
import resolveProgress from '@canvas/progress/resolve_progress'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {
  createDefaultProps,
  renderWithContext,
  delayImportOutcomesProgress,
  defaultTreeGroupMocks,
  courseImportMocks,
  WITH_FIND_GROUP_REFETCH,
} from './FindOutcomesModalTestUtils'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.mock('@canvas/progress/resolve_progress')

describe('FindOutcomesModal - Group Import Tests Part 2', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  let defaultProps

  beforeEach(() => {
    vi.useFakeTimers({shouldAdvanceTime: true})
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    defaultProps = createDefaultProps(
      onCloseHandlerMock,
      setTargetGroupIdsToRefetchMock,
      setImportsTargetGroupMock,
    )
    cache = createCache()
    window.ENV = {}
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
    resolveProgress.mockReset()
  })

  const render = (children, options = {}) => {
    return renderWithContext(children, {...options, cache})
  }

  it('loads localstorage.activeImports if present', async () => {
    const doResolveProgress = delayImportOutcomesProgress()

    localStorage.activeImports = JSON.stringify([
      {
        outcomeOrGroupId: '300',
        isGroup: true,
        groupTitle: 'Group 300',
        progress: {_id: '111', state: 'queued', __typename: 'Progress'},
      },
    ])

    const {getByText, getAllByText, queryByText} = render(
      <FindOutcomesModal {...defaultProps()} />,
      {
        contextType: 'Course',
        mocks: [...findModalMocks({parentAccountChildren: 1}), ...defaultTreeGroupMocks()],
      },
    )
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 200'))

    // No loading since we've imported group 300
    expect(queryByText('Loading')).not.toBeInTheDocument()

    await clickEl(getByText('Group 300'))
    // group 300 is loading. length 3 means outcome 1, 2, 3
    expect(getAllByText('Loading')).toHaveLength(3)
    await act(async () => {
      doResolveProgress()
      await vi.runAllTimersAsync()
    })
    await waitFor(() => expect(queryByText('Loading')).not.toBeInTheDocument())
    expect(getAllByText('Added')).toHaveLength(3)
    // resets latestImport after progress is resolved
    expect(localStorage.latestImport).toBeUndefined()
  })

  it('changes button text of individual outcomes from Add to Added after group import completes', async () => {
    resolveProgress.mockImplementation(() => Promise.resolve())
    const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [
        ...courseImportMocks,
        ...importGroupMocks({
          groupId: '300',
          targetContextType: 'Course',
        }),
      ],
    })
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 100 folder 0'))
    expect(getAllByText('Add')).toHaveLength(2)
    await clickEl(getByText('Add All Outcomes').closest('button'))
    await clickEl(getByText('Import Anyway'))
    await act(async () => {
      vi.runAllTimers()
      await Promise.resolve()
    })
    expect(getAllByText('Added')).toHaveLength(2)
  })

  it('displays flash confirmation with proper message if group import to Course succeeds', async () => {
    resolveProgress.mockImplementation(() => Promise.resolve())
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [
        ...courseImportMocks,
        ...importGroupMocks({
          groupId: '300',
          targetContextType: 'Course',
        }),
      ],
    })
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 100 folder 0'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    await clickEl(getByText('Import Anyway'))
    await act(async () => {
      vi.runAllTimers()
      await Promise.resolve()
    })
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'All outcomes from Group 300 have been successfully added to this course.',
      type: 'success',
    })
  })

  it('displays flash confirmation with proper message if group import to Account succeeds', async () => {
    resolveProgress.mockImplementation(() => Promise.resolve())
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Account',
      mocks: [
        ...findModalMocks(),
        ...groupMocks({groupId: '100'}),
        ...findOutcomesMocks({groupId: '300', withFindGroupRefetch: WITH_FIND_GROUP_REFETCH}),
        ...importGroupMocks({groupId: '300'}),
      ],
    })
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 100 folder 0'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    await act(async () => {
      vi.runAllTimers()
      await Promise.resolve()
    })
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'All outcomes from Group 300 have been successfully added to this account.',
      type: 'success',
    })
  })

  it('displays flash confirmation with proper message if group import to targetGroup succeeds', async () => {
    resolveProgress.mockImplementation(() => Promise.resolve())
    const {getByText} = render(
      <FindOutcomesModal
        {...defaultProps({
          targetGroup: {
            _id: '1',
            title: 'The Group Title',
          },
        })}
      />,
      {
        contextType: 'Account',
        mocks: [
          ...findModalMocks(),
          ...groupMocks({groupId: '100'}),
          ...findOutcomesMocks({groupId: '300', withFindGroupRefetch: WITH_FIND_GROUP_REFETCH}),
          ...importGroupMocks({groupId: '300', targetGroupId: '1'}),
        ],
      },
    )
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 100 folder 0'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    await act(async () => {
      vi.runAllTimers()
      await Promise.resolve()
    })
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'All outcomes from Group 300 have been successfully added to The Group Title.',
      type: 'success',
    })
  })

  it('displays flash alert with custom error message if group import fails', async () => {
    resolveProgress.mockImplementation(() => Promise.reject(new Error('Network error.')))
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [
        ...courseImportMocks,
        ...importGroupMocks({
          groupId: '300',
          targetContextType: 'Course',
          failResponse: true,
        }),
      ],
    })
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 100 folder 0'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    await clickEl(getByText('Import Anyway'))
    await act(async () => {
      vi.runAllTimers()
      await Promise.resolve()
    })
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while importing these outcomes: Network error.',
      type: 'error',
    })
  })

  it('displays flash alert with generic error message if group import fails and no error message', async () => {
    resolveProgress.mockImplementation(() => Promise.reject(new Error()))
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [
        ...courseImportMocks,
        ...importGroupMocks({
          groupId: '300',
          targetContextType: 'Course',
          failMutationNoErrMsg: true,
        }),
      ],
    })
    await act(async () => vi.runAllTimers())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))
    await clickEl(getByText('Group 100 folder 0'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    await clickEl(getByText('Import Anyway'))
    await act(async () => {
      vi.runAllTimers()
      await Promise.resolve()
    })
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while importing these outcomes.',
      type: 'error',
    })
  })
})
