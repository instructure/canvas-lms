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
import {render as rtlRender, waitFor} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

describe('FindOutcomesModal - Basic Tests', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  const mocks = findModalMocks()

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
      mocks: customMocks = mocks,
      renderer = rtlRender,
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            isMobileView: false,
          },
        }}
      >
        <MockedProvider cache={cache} mocks={customMocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>,
    )
  }

  it('renders component with correct title based on contextType', async () => {
    // Test Account
    const {getByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)
    await waitFor(() => expect(getByText('Add Outcomes to Account')).toBeInTheDocument())

    // Test Course
    render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      renderer: rerender,
    })
    await waitFor(() => expect(getByText('Add Outcomes to Course')).toBeInTheDocument())
  })

  it('renders component with custom group title when targetGroup is passed', async () => {
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
        contextType: 'Course',
      },
    )
    await waitFor(() =>
      expect(getByText('Add Outcomes to "The Group Title"')).toBeInTheDocument(),
    )
  })

  it('shows modal when open prop is true and hides when false', async () => {
    const {getByText, queryByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)
    await waitFor(() => expect(getByText('Close')).toBeInTheDocument())

    // Test closed state
    render(<FindOutcomesModal {...defaultProps({open: false})} />, {renderer: rerender})
    await waitFor(() => expect(queryByText('Close')).not.toBeInTheDocument())
  })

  describe('error handling', () => {
    it('displays appropriate error messages for account context', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {mocks: []})

      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while loading account learning outcome groups.',
          srOnly: true,
          type: 'error',
        })
      })

      expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
    })

    it('displays appropriate error messages for course context', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
        mocks: [],
      })

      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while loading course learning outcome groups.',
          srOnly: true,
          type: 'error',
        })
      })

      expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
    })
  })
})
