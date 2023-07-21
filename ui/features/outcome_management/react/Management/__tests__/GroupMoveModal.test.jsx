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
import {MockedProvider} from '@apollo/react-testing'
import {render as realRender, act, fireEvent} from '@testing-library/react'
import {
  smallOutcomeTree,
  updateOutcomeGroupMock,
  createOutcomeGroupMocks,
} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo'
import GroupMoveModal from '../GroupMoveModal'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()

describe('GroupMoveModal', () => {
  let cache
  let onCloseHandlerMock
  let showFlashAlertSpy
  let mocks

  const defaultProps = (props = {}) => ({
    isOpen: true,
    groupId: '400',
    groupTitle: 'Group 100 folder 0',
    onCloseHandler: onCloseHandlerMock,
    parentGroup: {
      id: '100',
      title: 'Account folder 0',
    },
    ...props,
  })

  beforeEach(() => {
    mocks = smallOutcomeTree({
      group100childCounts: 2,
    })
    cache = createCache()
    onCloseHandlerMock = jest.fn()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      rootOutcomeGroup = {id: '100'},
      treeBrowserRootGroupId = '1',
    } = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider
        value={{env: {contextType, contextId, rootOutcomeGroup, treeBrowserRootGroupId}}}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders component with Group title', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Move "Group 100 folder 0"')).toBeInTheDocument()
  })

  it('shows modal if open prop true', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Cancel')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', async () => {
    const {queryByText} = render(<GroupMoveModal {...defaultProps({isOpen: false})} />)
    await act(async () => jest.runAllTimers())
    expect(queryByText('Cancel')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Cancel button click', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Cancel')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('enables the move button when a valid group is selected', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Group 100 folder 1'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Move').closest('button')).toBeEnabled()
  })

  it('by default, select parent group and disables move button', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Group 100 folder 1')).toBeInTheDocument()
    expect(getByText('Move').closest('button')).toBeDisabled()
  })

  it('shows successful flash message when moving a group succeeds', async () => {
    mocks = [
      ...mocks,
      updateOutcomeGroupMock({
        id: '400',
        parentOutcomeGroupId: '401',
        title: null,
        description: null,
        vendorGuid: null,
      }),
    ]
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Group 100 folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: '"Group 100 folder 0" was moved to "Group 100 folder 1".',
      type: 'success',
    })
  })

  it('shows custom error flash message when moving a group fails', async () => {
    mocks = [
      ...mocks,
      updateOutcomeGroupMock({
        id: '400',
        parentOutcomeGroupId: '401',
        title: null,
        description: null,
        vendorGuid: null,
        failResponse: true,
      }),
    ]
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Group 100 folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving this group. Please try again.',
      type: 'error',
    })
  })

  it('shows flash error message when move group mutation fails', async () => {
    mocks = [
      ...mocks,
      updateOutcomeGroupMock({
        id: '400',
        parentOutcomeGroupId: '401',
        title: null,
        description: null,
        vendorGuid: null,
        failMutation: true,
      }),
    ]

    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Group 100 folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving this group. Please try again.',
      type: 'error',
    })
  })

  it('shows default error flash message when moving a group fails without any message', async () => {
    mocks = [
      ...mocks,
      updateOutcomeGroupMock({
        id: '400',
        parentOutcomeGroupId: '401',
        title: null,
        description: null,
        vendorGuid: null,
        failMutationNoErrMsg: true,
      }),
    ]

    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Group 100 folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving this group. Please try again.',
      type: 'error',
    })
  })

  it('filters out groupId from the options', async () => {
    const {queryByText} = render(<GroupMoveModal {...defaultProps({groupId: '100'})} />)
    expect(queryByText('Group 100 folder 0')).not.toBeInTheDocument()
  })

  it('calls onSuccess after move', async () => {
    mocks = [
      ...mocks,
      updateOutcomeGroupMock({
        id: '400',
        parentOutcomeGroupId: '401',
        title: null,
        description: null,
        vendorGuid: null,
      }),
    ]

    const onSuccess = jest.fn()
    const {getByText} = render(<GroupMoveModal {...defaultProps({onSuccess})} />)
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Group 100 folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onSuccess).toHaveBeenCalled()
  })

  describe('for a newly created group', () => {
    it('becomes selected and can be moved into', async () => {
      mocks = [
        ...mocks,
        updateOutcomeGroupMock({
          id: '400',
          parentOutcomeGroupId: '200',
          title: null,
          description: null,
          vendorGuid: null,
        }),
        ...createOutcomeGroupMocks({
          id: '200',
          parentOutcomeGroupId: '100',
          title: 'new group',
        }),
      ]
      const {getByText, getByLabelText} = render(<GroupMoveModal {...defaultProps()} />)
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {
        target: {value: 'new group'},
      })
      fireEvent.click(getByText('Create new group'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"new group" was successfully created.',
        type: 'success',
      })
      expect(getByText('Move').closest('button')).toBeEnabled()
      fireEvent.click(getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Group 100 folder 0" was moved to "new group".',
        type: 'success',
      })
    })
  })
})
