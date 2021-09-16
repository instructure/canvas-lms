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
import {smallOutcomeTree, updateOutcomeGroupMock} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo'
import GroupMoveModal from '../GroupMoveModal'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import * as api from '@canvas/outcomes/graphql/Management'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()

describe('GroupMoveModal', () => {
  let cache
  let onCloseHandlerMock
  let showFlashAlertSpy

  const defaultProps = (props = {}) => ({
    isOpen: true,
    groupId: '100',
    groupTitle: 'Account folder 0',
    parentGroupId: '0',
    onCloseHandler: onCloseHandlerMock,
    rootGroup: {
      id: '0',
      title: 'Root account folder'
    },
    ...props
  })

  beforeEach(() => {
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
      mocks = smallOutcomeTree()
    } = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId, rootOutcomeGroup}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders component with Group title', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Move "Account folder 0"')).toBeInTheDocument()
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

  it('disables the move button when the selected parent group is equal to the parent of the group to be moved', async () => {
    const {getByText} = render(
      <GroupMoveModal {...defaultProps({parentGroupId: '100', groupId: '400'})} />
    )
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Move').closest('button')).toBeDisabled()
  })

  it('enables the move button when a valid group is selected', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps({groupId: '100'})} />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Move').closest('button')).toBeEnabled()
  })

  it('selects the rootGroup by default and enables the submit button if the group can be moved', async () => {
    const {getByText} = render(
      <GroupMoveModal {...defaultProps({parentGroupId: '100', groupId: '400'})} />
    )
    await act(async () => jest.runAllTimers())
    expect(getByText('Move').closest('button')).toBeEnabled()
  })

  it('shows successful flash message when moving a group succeeds', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />, {
      mocks: [
        ...smallOutcomeTree(),
        updateOutcomeGroupMock({
          title: null,
          description: null,
          vendorGuid: null
        })
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: '"Account folder 0" has been moved to "Account folder 1".',
      type: 'success'
    })
  })

  it('shows custom error flash message when moving a group fails', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />, {
      mocks: [
        ...smallOutcomeTree(),
        updateOutcomeGroupMock({
          title: null,
          description: null,
          vendorGuid: null,
          failResponse: true
        })
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred moving group "Account folder 0": GraphQL error: Network error.',
      type: 'error'
    })
  })

  it('shows flash error message when move group mutation fails', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />, {
      mocks: [
        ...smallOutcomeTree(),
        updateOutcomeGroupMock({
          title: null,
          description: null,
          vendorGuid: null,
          failMutation: true
        })
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred moving group "Account folder 0": Mutation failed.',
      type: 'error'
    })
  })

  it('shows default error flash message when moving a group fails and error message is empty', async () => {
    const {getByText} = render(<GroupMoveModal {...defaultProps()} />, {
      mocks: [
        ...smallOutcomeTree(),
        updateOutcomeGroupMock({
          title: null,
          description: null,
          vendorGuid: null,
          failMutationNoErrMsg: true
        })
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred moving group "Account folder 0".',
      type: 'error'
    })
  })

  it('filters out groupId from the options', async () => {
    const {queryByText} = render(<GroupMoveModal {...defaultProps({groupId: '100'})} />, {
      mocks: [...smallOutcomeTree()]
    })
    expect(queryByText('Account folder 0')).not.toBeInTheDocument()
  })

  it('calls onSuccess after move', async () => {
    const onSuccess = jest.fn()
    const {getByText} = render(<GroupMoveModal {...defaultProps({onSuccess})} />, {
      mocks: [
        ...smallOutcomeTree(),
        updateOutcomeGroupMock({
          title: null,
          description: null,
          vendorGuid: null
        })
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onSuccess).toHaveBeenCalled()
  })

  describe('for a newly created group', () => {
    const newGroup = {
      id: '200',
      title: 'new group',
      description: '',
      isRootGroup: false,
      parent_outcome_group: {id: '100'}
    }
    const mocks = [
      ...smallOutcomeTree(),
      updateOutcomeGroupMock({
        id: '400',
        parentOutcomeGroupId: '200',
        title: null,
        description: null,
        vendorGuid: null
      })
    ]

    it('becomes selected and can be moved into', async () => {
      jest
        .spyOn(api, 'addOutcomeGroup')
        .mockImplementation(() => Promise.resolve({status: 200, data: newGroup}))
      const {getByText, getByLabelText} = render(
        <GroupMoveModal {...defaultProps({parentGroupId: '100', groupId: '400'})} />,
        {
          mocks
        }
      )
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Account folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {
        target: {value: 'new group'}
      })
      fireEvent.click(getByText('Create new group'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"new group" has been created.',
        type: 'success'
      })
      expect(getByText('Move').closest('button')).toBeEnabled()
      fireEvent.click(getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Account folder 0" has been moved to "new group".',
        type: 'success'
      })
    })
  })
})
