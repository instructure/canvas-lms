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
  accountMocks,
  smallOutcomeTree,
  groupMocks,
  createOutcomeGroupMocks,
} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo'
import TargetGroupSelector from '../TargetGroupSelector'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()

describe('TargetGroupSelector', () => {
  let cache
  let setTargetGroupMock
  let showFlashAlertSpy

  const defaultProps = (props = {}) => ({
    parentGroupId: '1',
    setTargetGroup: setTargetGroupMock,
    targetGroupId: '1',
    notifyGroupCreated: () => {},
    ...props,
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
      mocks = accountMocks({childGroupsCount: 0}),
      treeBrowserRootGroupId = '1',
    } = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId, treeBrowserRootGroupId}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('loads nested groups', async () => {
    const {getByText} = render(<TargetGroupSelector {...defaultProps()} />, {
      mocks: [...smallOutcomeTree()],
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Account folder 0')).toBeInTheDocument()
  })

  it('calls setTargetGroup with the selected group object and ancestors ids', async () => {
    const {getByText} = render(<TargetGroupSelector {...defaultProps({groupId: undefined})} />, {
      mocks: [...smallOutcomeTree()],
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Root account folder'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    expect(setTargetGroupMock).toHaveBeenCalledWith({
      targetAncestorsIds: ['100', '1'],
      targetGroup: {
        collections: [],
        id: '100',
        name: 'Account folder 0',
        parentGroupId: '1',
        isRootGroup: false,
      },
    })
  })

  it('displays a screen reader error and text error on failed request for account outcome groups', async () => {
    render(<TargetGroupSelector {...defaultProps()} />, {
      mocks: [],
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      srOnly: true,
      type: 'error',
    })
  })

  it('displays a screen reader error and text error on failed request for course outcome groups', async () => {
    render(<TargetGroupSelector {...defaultProps()} />, {
      contextId: '2',
      contextType: 'Course',
      mocks: [],
    })
    await act(async () => jest.runAllTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading course learning outcome groups.',
      srOnly: true,
      type: 'error',
    })
  })

  it('displays a flash alert when a child group fails to load', async () => {
    const mocks = [
      ...accountMocks({childGroupsCount: 2}),
      ...groupMocks({groupId: '100', childGroupOffset: 400}),
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
      srOnly: false,
    })
  })

  it('renders a create new group link', async () => {
    const {getByText} = render(<TargetGroupSelector {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Create New Group')).toBeInTheDocument()
  })

  describe('passing starterGroupId', () => {
    it('calls setTargetGroup with a mock group when back button is clicked', async () => {
      const {getByText} = render(
        <TargetGroupSelector {...defaultProps({starterGroupId: '123'})} />,
        {
          mocks: [
            ...groupMocks({
              groupId: '123',
              parentOutcomeGroupId: '12',
              parentOutcomeGroupTitle: 'Group 12',
            }),
            ...groupMocks({
              groupId: '12',
            }),
          ],
        }
      )
      await act(async () => jest.runAllTimers())
      // We're in group 123
      fireEvent.click(getByText('Back'))
      await act(async () => jest.runAllTimers())
      // Now we're group 12 (parent group of 123)
      expect(getByText('Group 12')).toBeInTheDocument()
      // We should se a setTargetGroup with group 12 (parent of 123)
      expect(setTargetGroupMock.mock.calls[1][0].targetGroup.id).toBe('12')
    })
  })

  describe('create new group button', () => {
    it('focuses on the link after the AddContentItem unexpands after cancellation', async () => {
      const {getByText} = render(<TargetGroupSelector {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.click(getByText('Cancel'))
      expect(getByText('Create New Group')).toHaveFocus()
    })

    it('does not focus on link after AddContentItem unexpands after submission', async () => {
      const {getByText, getByLabelText} = render(<TargetGroupSelector {...defaultProps()} />, {
        mocks: [
          ...accountMocks({childGroupsCount: 0}),
          ...createOutcomeGroupMocks({
            parentOutcomeGroupId: '1',
            title: 'new group name',
          }),
        ],
      })
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create new group'))
      await act(async () => jest.runAllTimers())
      expect(getByText('Create New Group')).not.toHaveFocus()
    })

    it('notifyGroupCreated is called when a group is created', async () => {
      const notifyMock = jest.fn(() => {})
      const {getByText, getByLabelText} = render(
        <TargetGroupSelector {...defaultProps({notifyGroupCreated: notifyMock})} />,
        {
          mocks: [
            ...accountMocks({childGroupsCount: 0}),
            ...createOutcomeGroupMocks({
              parentOutcomeGroupId: '1',
              title: 'new group name',
            }),
          ],
        }
      )
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create new group'))
      await act(async () => jest.runAllTimers())
      expect(notifyMock).toHaveBeenCalledTimes(1)
    })

    it('displays flash confirmation if group is created', async () => {
      const {getByText, getByLabelText} = render(<TargetGroupSelector {...defaultProps()} />, {
        mocks: [
          ...accountMocks({childGroupsCount: 0}),
          ...createOutcomeGroupMocks({
            parentOutcomeGroupId: '1',
            title: 'new group name',
          }),
        ],
      })
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create new group'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        type: 'success',
        message: '"new group name" was successfully created.',
      })
    })

    it('displays an error message if group cannot be created', async () => {
      const {getByText, getByLabelText} = render(<TargetGroupSelector {...defaultProps()} />, {
        mocks: [
          ...accountMocks({childGroupsCount: 0}),
          ...createOutcomeGroupMocks({
            parentOutcomeGroupId: '1',
            title: 'new group name',
            failResponse: true,
          }),
        ],
      })
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'new group name'}})
      fireEvent.click(getByText('Create new group'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        type: 'error',
        message: 'An error occurred while creating this group. Please try again.',
      })
    })
  })
})
