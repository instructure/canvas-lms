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
import {MockedProvider} from '@apollo/client/testing'
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import OutcomesContext, {
  ACCOUNT_GROUP_ID,
  ROOT_GROUP_ID,
} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import resolveProgress from '@canvas/progress/resolve_progress'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.mock('@canvas/progress/resolve_progress')
vi.useFakeTimers()

const clickEl = async el => {
  fireEvent.click(el)
  await act(async () => vi.runOnlyPendingTimers())
}

describe('FindOutcomesModal - Mobile View Basic', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  const isMobileView = true

  const defaultProps = (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    cache = createCache()
    window.ENV = {}
  })

  afterEach(() => {
    vi.clearAllMocks()
    resolveProgress.mockReset()
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      mocks = findModalMocks(),
      renderer = rtlRender,
      globalRootId = '',
      rootOutcomeGroup = {id: '0'},
      rootIds = [ACCOUNT_GROUP_ID, ROOT_GROUP_ID, globalRootId],
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            isMobileView,
            globalRootId,
            rootIds,
            rootOutcomeGroup,
            treeBrowserRootGroupId: ROOT_GROUP_ID,
            treeBrowserAccountGroupId: ACCOUNT_GROUP_ID,
          },
        }}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>,
    )
  }

  it('renders component with "Add Outcomes to Account" title when contextType is Account', async () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
  })

  it('renders component with "Add Outcomes to Course" title when contextType is Course', async () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Add Outcomes to Course')).toBeInTheDocument()
  })

  it('shows modal if open prop true', async () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', async () => {
    const {queryByText} = render(<FindOutcomesModal {...defaultProps({open: false})} />)
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Close')).not.toBeInTheDocument()
  })

  it('renders the action drilldown', async () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Groups')).toBeInTheDocument()
  })

  it('does not render the TreeBrowser', async () => {
    const {queryByTestId} = render(<FindOutcomesModal {...defaultProps()} />)
    await act(async () => vi.runOnlyPendingTimers())
    const treeBrowser = queryByTestId('groupsColumnRef')
    expect(treeBrowser).not.toBeInTheDocument()
  })

  describe('error handling', () => {
    describe('within an account', () => {
      it('displays a screen reader error and text error on failed request', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {mocks: []})
        await act(async () => vi.runOnlyPendingTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while loading account learning outcome groups.',
          srOnly: true,
          type: 'error',
        })
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
      })
    })

    describe('within a course', () => {
      it('displays a screen reader error and text error on failed request', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [],
        })
        await act(async () => vi.runOnlyPendingTimers())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while loading course learning outcome groups.',
          srOnly: true,
          type: 'error',
        })
        expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
      })
    })
  })
})
