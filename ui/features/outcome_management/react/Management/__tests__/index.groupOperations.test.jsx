/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {act, fireEvent} from '@testing-library/react'
import {within} from '@testing-library/dom'
import axios from 'axios'
import OutcomeManagementPanel from '../index'
import {setupTest, teardownTest, courseMocks, groupMocks, groupDetailMocks} from './testSetup'
import {updateOutcomeGroupMock, createOutcomeGroupMocks} from '@canvas/outcomes/mocks/Management'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()

// FOO-3827
describe('OutcomeManagementPanel - Group Operations', () => {
  let render, defaultProps, groupDetailDefaultProps

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
  })

  afterEach(() => {
    vi.clearAllMocks()
    teardownTest()
  })

  describe('Removing a group', () => {
    let mocks

    beforeEach(() => {
      mocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        ...groupDetailMocks({
          title: 'Course folder 1',
          groupDescription: 'Course folder 1 group description',
          groupId: '2',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        ...groupMocks({
          groupId: '300',
          childGroupOffset: 400,
          parentOutcomeGroupTitle: 'Course folder 0',
          parentOutcomeGroupId: '200',
        }),
        ...groupDetailMocks({
          groupId: '300',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
      ]
      axios.delete.mockResolvedValue({status: 200})
    })

    it('clears selected outcomes', async () => {
      const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        mocks,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Group 300'))
      expect(getByText('1 Outcome Selected')).toBeInTheDocument()
      fireEvent.click(getByText('Menu for group Group 200 folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Remove Group'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    }, 10000)

    it('Show parent group in the RHS', async () => {
      const {getByText, queryByText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(queryByText('Course folder 0 Outcomes')).not.toBeInTheDocument()
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Menu for group Group 200 folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
      await act(async () => vi.runOnlyPendingTimers())
      // Remove Modal
      fireEvent.click(getByText('Remove Group'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
    }, 10000)
  })

  describe('Moving a group', () => {
    let mocks

    beforeEach(() => {
      mocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        ...groupMocks({
          groupId: '300',
          childGroupOffset: 400,
          parentOutcomeGroupTitle: 'Course folder 0',
          parentOutcomeGroupId: '200',
        }),
        ...groupDetailMocks({
          groupId: '300',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        updateOutcomeGroupMock({
          id: '300',
          parentOutcomeGroupId: '2',
          title: null,
          returnTitle: 'Group 300',
          description: null,
          vendorGuid: null,
        }),
        ...createOutcomeGroupMocks({parentOutcomeGroupId: '2', title: 'new group name'}),
      ]
    })

    const moveSelectedGroup = async getByRole => {
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
    }

    it('show old parent group in the RHS when moving a group succeeds', async () => {
      const {getByRole, getByText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Menu for group Group 200 folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      // Move Modal
      await act(async () => vi.runAllTimers())
      await moveSelectedGroup(getByRole)
      expect(getByText('2 Outcomes')).toBeInTheDocument()
    })

    it('shows groups created in the modal immediately on the LHS', async () => {
      const {getByText, getByRole, getByLabelText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Menu for group Group 200 folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {
        target: {value: 'new group name'},
      })
      fireEvent.click(within(getByRole('dialog')).getByText('Create new group'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Cancel'))
      await act(async () => vi.runAllTimers())
      expect(getByText('new group name')).toBeInTheDocument()
    })

    it('shows move group modal if move option from group menu is selected', async () => {
      const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Menu for group Course folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Where would you like to move this group?')).toBeInTheDocument()
    })
  })
})
