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
import {accountMocks, smallOutcomeTree, groupMocks} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo'
import {addOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import TargetGroupSelector from '../TargetGroupSelector'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()
jest.mock('@canvas/outcomes/graphql/Management', () => ({
  ...jest.requireActual('@canvas/outcomes/graphql/Management'),
  addOutcomeGroup: jest.fn()
}))

describe('TargetGroupSelector', () => {
  let cache
  let setTargetGroupMock
  let showFlashAlertSpy

  const defaultProps = (props = {}) => ({
    groupId: '100',
    parentGroupId: '1',
    setTargetGroup: setTargetGroupMock,
    ...props
  })

  beforeEach(() => {
    cache = createCache()
    setTargetGroupMock = jest.fn()
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

  it('loads nested groups', async () => {
    const {getByText} = render(<TargetGroupSelector {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Account folder 0')).toBeInTheDocument()
  })

  it('calls setTargetGroup with the selected group object', async () => {
    const {getByText} = render(<TargetGroupSelector {...defaultProps({groupId: undefined})} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    expect(setTargetGroupMock).toHaveBeenCalledWith({
      canEdit: true,
      collections: [],
      descriptor: '2 Groups | 2 Outcomes',
      id: '100',
      name: 'Account folder 0',
      outcomesCount: 2,
      parentGroupId: '1'
    })
  })

  it('displays a screen reader error and text error on failed request for account outcome groups', async () => {
    render(<TargetGroupSelector {...defaultProps()} />, {
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      srOnly: true,
      type: 'error'
    })
  })

  it('displays a screen reader error and text error on failed request for course outcome groups', async () => {
    render(<TargetGroupSelector {...defaultProps()} />, {
      contextId: '2',
      contextType: 'Course',
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading course learning outcome groups.',
      srOnly: true,
      type: 'error'
    })
  })

  it('displays a flash alert when a child group fails to load', async () => {
    const mocks = [
      ...accountMocks({childGroupsCount: 2}),
      ...groupMocks({groupId: 100, childGroupOffset: 400})
    ]
    const {getByText} = render(<TargetGroupSelector {...defaultProps()} />, {mocks})
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      type: 'error',
      srOnly: false
    })
  })

  it('renders a create new group link', async () => {
    const {getByText} = render(<TargetGroupSelector {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Create New Group')).toBeInTheDocument()
  })

  describe('when the create new group link is expanded', () => {
    it('calls the addOutcomeGroup api when the create group item is clicked', async () => {
      addOutcomeGroup.mockReturnValue(Promise.resolve({status: 200}))
      const {getByText, getByLabelText} = render(<TargetGroupSelector {...defaultProps()} />)
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

    it('displays custom error message if group cannot be created', async () => {
      const {getByText, getByLabelText} = render(<TargetGroupSelector {...defaultProps()} />)
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

    it('displays default error message if group cannot be created and no error message is returned', async () => {
      const {getByText, getByLabelText} = render(<TargetGroupSelector {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      addOutcomeGroup.mockReturnValue(Promise.reject(new Error()))
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create New Group'))
      await act(async () => jest.runAllTimers())
      expect(addOutcomeGroup).toHaveBeenCalledTimes(1)
      expect(addOutcomeGroup).toHaveBeenCalledWith('Account', '1', '100', 'new group name')
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        type: 'error',
        message: 'An error occurred adding group "new group name"'
      })
    })
  })
})
