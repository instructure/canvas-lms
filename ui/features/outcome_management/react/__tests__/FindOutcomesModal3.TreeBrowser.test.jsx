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
import {render as rtlRender, fireEvent, waitFor} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import OutcomesContext, {
  ACCOUNT_GROUP_ID,
  ROOT_GROUP_ID,
} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {groupMocks} from '@canvas/outcomes/mocks/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

describe('FindOutcomesModal - Tree Browser Tests', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock

  const defaultProps = (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  beforeAll(() => {
    window.ENV = {}
  })

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    cache = createCache()
  })

  afterEach(() => {
    vi.clearAllMocks()
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
            isMobileView: false,
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

  it('clears selected outcome group for the outcomes view after closing and reopening', async () => {
    const {getByText, queryByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)

    await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())

    fireEvent.click(getByText('Account Standards'))
    await waitFor(() => expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument())

    fireEvent.click(getByText('Root Account Outcome Group 0'))
    await waitFor(() =>
      expect(getByText('All Root Account Outcome Group 0 Outcomes')).toBeInTheDocument(),
    )

    fireEvent.click(getByText('Done'))

    render(<FindOutcomesModal {...defaultProps({open: false})} />, {renderer: rerender})
    render(<FindOutcomesModal {...defaultProps()} />, {renderer: rerender})

    await waitFor(() =>
      expect(queryByText('All Root Account Outcome Group 0 Outcomes')).not.toBeInTheDocument(),
    )
  })

  describe('account context', () => {
    it('renders Account Standards groups for non-root accounts', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)

      await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())

      fireEvent.click(getByText('Account Standards'))
      await waitFor(() => expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument())
    })

    it('does not render Account Standards groups for root accounts', async () => {
      const {queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        mocks: findModalMocks({parentAccountChildren: 0}),
      })

      // Wait for modal to fully load, then check Account Standards doesn't exist
      await waitFor(() => expect(queryByText('Account Standards')).not.toBeInTheDocument(), {
        timeout: 3000,
      })
    })
  })

  it('displays a flash alert when a child group fails to load', async () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
    })

    await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())

    fireEvent.click(getByText('Account Standards'))
    await waitFor(() => expect(getByText('Course Account Outcome Group')).toBeInTheDocument())

    fireEvent.click(getByText('Course Account Outcome Group'))

    await waitFor(() =>
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while loading course learning outcome groups.',
        type: 'error',
        srOnly: false,
      }),
    )
  })

  describe('global standards', () => {
    it('renders State Standards group with valid globalRootId', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        mocks: findModalMocks({includeGlobalRootGroup: true}),
        globalRootId: '1',
      })

      await waitFor(() => expect(getByText('State Standards')).toBeInTheDocument())

      fireEvent.click(getByText('State Standards'))
      // Just verify it renders without error
    })

    it('does not render State Standards without globalRootId', async () => {
      const {queryByText, getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        mocks: findModalMocks({includeGlobalRootGroup: true}),
      })

      await waitFor(() =>
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument(),
      )

      expect(queryByText('State Standards')).not.toBeInTheDocument()
    })

    it('does not list outcomes within State Standard group', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        mocks: [...findModalMocks({includeGlobalRootGroup: true}), ...groupMocks({groupId: '1'})],
        globalRootId: '1',
      })

      await waitFor(() => expect(getByText('State Standards')).toBeInTheDocument())

      fireEvent.click(getByText('State Standards'))

      await waitFor(() =>
        expect(getByText('Select a group to reveal outcomes here.')).toBeInTheDocument(),
      )
    })
  })
})
