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
import {render as realRender, act, fireEvent, within} from '@testing-library/react'
import {accountMocks, smallOutcomeTree} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo'
import {addOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import MoveModal from '../MoveModal'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()
jest.mock('@canvas/outcomes/graphql/Management', () => ({
  ...jest.requireActual('@canvas/outcomes/graphql/Management'),
  addOutcomeGroup: jest.fn()
}))

describe('MoveModal', () => {
  let onCloseHandlerMock
  let cache
  let showFlashAlertSpy

  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onMoveHandler: jest.fn(),
    title: 'Account folder 0',
    type: 'group',
    groupId: '100',
    parentGroupId: 0,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    cache = createCache()
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
      mocks = accountMocks({childGroupsCount: 0})
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
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Move "Account folder 0"')).toBeInTheDocument()
  })

  it('shows modal if open prop true', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Cancel')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', async () => {
    const {queryByText} = render(<MoveModal {...defaultProps({isOpen: false})} />)
    await act(async () => jest.runAllTimers())
    expect(queryByText('Cancel')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Cancel button click', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Cancel')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Account folder 0')).toBeInTheDocument()
  })

  it('disables the move button when the selected group is equal to the group to be moved', async () => {
    // Once TreeBrowser is updated to the latest version, groupId can go back to being a string
    const {getByText, getByRole} = render(<MoveModal {...defaultProps({groupId: 100})} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(within(getByRole('dialog')).getByText('Move').closest('button')).toHaveAttribute(
      'disabled'
    )
  })

  it('disables the move button when the selected parent group is equal to the parent of the group to be moved', async () => {
    const {getByText, getByRole} = render(
      <MoveModal {...defaultProps({groupId: 400, parentGroupId: 100})} />,
      {
        mocks: [...smallOutcomeTree('Account')]
      }
    )
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(within(getByRole('dialog')).getByText('Move').closest('button')).toHaveAttribute(
      'disabled'
    )
  })

  it('enables the move button when a valid group is selected', async () => {
    const {getByText, getByRole} = render(<MoveModal {...defaultProps({groupId: 100})} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runAllTimers())
    expect(within(getByRole('dialog')).getByText('Move').closest('button')).not.toHaveAttribute(
      'disabled'
    )
  })

  it('displays an error on failed request for account outcome groups', async () => {
    render(<MoveModal {...defaultProps()} />, {
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading account outcomes.',
      type: 'error'
    })
  })

  it('displays an error on failed request for course outcome groups', async () => {
    render(<MoveModal {...defaultProps()} />, {
      contextId: '2',
      contextType: 'Course',
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading course outcomes.',
      type: 'error'
    })
  })

  it('renders a create new group link', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Create New Group')).toBeInTheDocument()
  })

  describe('when the create new group link is expanded', () => {
    it('calls the addOutcomeGroup api when the create group item is clicked', async () => {
      addOutcomeGroup.mockReturnValue(Promise.resolve({status: 200}))
      const {getByText, getByLabelText} = render(<MoveModal {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create New Group'))
      await act(async () => jest.runAllTimers())
      expect(addOutcomeGroup).toHaveBeenCalledTimes(1)
      expect(addOutcomeGroup).toHaveBeenCalledWith('Account', '1', '100', 'new group name')
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        type: 'success',
        message: '"new group name" has been created.'
      })
    })

    it('displays an error if the group could not be created', async () => {
      const {getByText, getByLabelText} = render(<MoveModal {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      addOutcomeGroup.mockReturnValue(Promise.reject(new Error('Server is busy')))
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create New Group'))
      await act(async () => jest.runAllTimers())

      expect(addOutcomeGroup).toHaveBeenCalledTimes(1)
      expect(addOutcomeGroup).toHaveBeenCalledWith('Account', '1', '100', 'new group name')
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        type: 'error',
        message: 'An error occurred adding group "new group name": Server is busy'
      })
    })
  })
})
