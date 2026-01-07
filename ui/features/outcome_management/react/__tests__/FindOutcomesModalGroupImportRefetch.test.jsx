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
import {importGroupMocks} from '@canvas/outcomes/mocks/Management'
import {clickEl} from '@canvas/outcomes/react/helpers/testHelpers'
import resolveProgress from '@canvas/progress/resolve_progress'
import {
  createDefaultProps,
  renderWithContext,
  delayImportOutcomesProgress,
  defaultTreeGroupMocks,
} from './FindOutcomesModalTestUtils'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.mock('@canvas/progress/resolve_progress')
vi.useFakeTimers()

describe('FindOutcomesModal - Group Import Refetch Tests', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  let defaultProps

  beforeEach(() => {
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
    resolveProgress.mockReset()
  })

  const render = (children, options = {}) => {
    return renderWithContext(children, {...options, cache})
  }

  it('refetches outcomes if parent/ancestor group is selected after group import', async () => {
    const doResolveProgress = delayImportOutcomesProgress()

    const {getByText, getAllByText, queryByText} = render(
      <FindOutcomesModal {...defaultProps()} />,
      {
        contextType: 'Course',
        mocks: [
          ...findModalMocks({parentAccountChildren: 1}),
          ...defaultTreeGroupMocks(),
          ...importGroupMocks({
            groupId: '300',
            targetContextType: 'Course',
          }),
        ],
      },
    )
    await act(async () => vi.runAllTimers())
    await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))

    await clickEl(getByText('Group 200'))
    await clickEl(getByText('Group 300'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    expect(getAllByText('Loading')).toHaveLength(3)

    await act(async () => {
      doResolveProgress()
      await vi.runAllTimersAsync()
    })
    await waitFor(() => expect(queryByText('Loading')).not.toBeInTheDocument())
    expect(getAllByText('Added')).toHaveLength(3)

    await clickEl(getByText('Group 200'))
    expect(getByText('All Refetched Group 200 Outcomes')).toBeInTheDocument()
  })

  it('does not refetch outcomes if no group is selected after group import', async () => {
    const doResolveProgress = delayImportOutcomesProgress()

    const {getByText, getAllByText, queryByText} = render(
      <FindOutcomesModal {...defaultProps()} />,
      {
        contextType: 'Course',
        mocks: [
          ...findModalMocks({parentAccountChildren: 1}),
          ...defaultTreeGroupMocks(),
          ...importGroupMocks({
            groupId: '300',
            targetContextType: 'Course',
          }),
        ],
      },
    )
    await act(async () => vi.runAllTimers())
    await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())
    await clickEl(getByText('Account Standards'))
    await clickEl(getByText('Root Account Outcome Group 0'))

    await clickEl(getByText('Group 200'))
    await clickEl(getByText('Group 300'))
    await clickEl(getByText('Add All Outcomes').closest('button'))
    expect(getAllByText('Loading')).toHaveLength(3)

    await act(async () => {
      doResolveProgress()
      await vi.runAllTimersAsync()
    })
    await waitFor(() => expect(queryByText('Loading')).not.toBeInTheDocument())
    expect(getAllByText('Added')).toHaveLength(3)
    expect(queryByText('All Refetched Group 200 Outcomes')).not.toBeInTheDocument()
  })
})
