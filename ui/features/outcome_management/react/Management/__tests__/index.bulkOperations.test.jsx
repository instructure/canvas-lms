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
import * as useGroupDetail from '@canvas/outcomes/react/hooks/useGroupDetail'
import OutcomeManagementPanel from '../index'
import {
  setupTest,
  teardownTest,
  courseMocks,
  groupMocks,
  groupDetailMocks,
  clickWithPending,
} from './testSetup'
import {moveOutcomeMock} from '@canvas/outcomes/mocks/Management'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()
vi.mock('@canvas/outcomes/react/hooks/useGroupDetail', async () => {
  return {
    __esModule: true,
    ...(await vi.importActual('@canvas/outcomes/react/hooks/useGroupDetail')),
  }
})

// FOO-3827
describe('OutcomeManagementPanel - Bulk Operations', () => {
  let render, defaultProps, groupDetailDefaultProps, defaultMocks

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
    defaultMocks = setup.defaultMocks
  })

  afterEach(() => {
    vi.clearAllMocks()
    teardownTest()
  })

  describe('Bulk remove outcomes', () => {
    it('shows bulk remove outcomes modal if outcomes are selected and remove button is clicked', async () => {
      const {findByText, getByText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(await findByText('Remove Outcomes?')).toBeInTheDocument()
    })

    it('outcome names are passed to the remove modal when using bulk remove', async () => {
      const {getByText, getByTestId, getAllByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      const itemOneTitle = getAllByTestId('outcome-management-item-title')[0].textContent
      const itemTwoTitle = getAllByTestId('outcome-management-item-title')[1].textContent
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      const removeModal = getByTestId('outcome-management-remove-modal')
      expect(await within(removeModal).findByText('Remove Outcomes?')).toBeInTheDocument()
      expect(await within(removeModal).findByText(itemOneTitle)).toBeInTheDocument()
      expect(await within(removeModal).findByText(itemTwoTitle)).toBeInTheDocument()
    })

    it('spinners show in the document when a bulk remove is pending', async () => {
      const {getByText, getByTestId, getAllByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Remove Outcomes'))
      const spinners = getAllByTestId('outcome-spinner')
      expect(spinners).toHaveLength(2)
    })

    it('updated group names are passed to the remove modal if a selected outcome is moved', async () => {
      const {findByText, getByTestId, findByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks: [
            ...defaultMocks,
            ...groupMocks({
              title: 'Course 101',
              groupId: '101',
              parentOutcomeGroupTitle: 'Root course folder',
              parentOutcomeGroupId: '2',
            }),
            moveOutcomeMock({
              groupId: '2',
              parentGroupTitle: 'Root course folder',
              outcomeLinkIds: ['1'],
            }),
          ],
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(await findByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(await findByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(await findByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(await findByText('Menu for outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(await findByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByTestId('outcome-management-move-modal-move-button'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(await findByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      const removeModal = await findByTestId('outcome-management-remove-modal')
      expect(within(removeModal).getByText('From Root course folder')).toBeInTheDocument()
    }, 10000)
  })

  describe('Bulk move outcomes', () => {
    it('shows bulk move outcomes modal if outcomes are selected and move button is clicked', async () => {
      const {getByText, getAllByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Move 2 Outcomes?')).toBeInTheDocument()
    })

    it('closes modal and clears selected outcomes when destination group for move is selected and "Move" button is clicked', async () => {
      const {getByText, getByRole, getAllByText, queryByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => vi.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
      expect(queryByText('Move 2 Outcomes?')).not.toBeInTheDocument()
    })

    it('refetch rhs when moving outcomes', async () => {
      const detailSpy = vi.spyOn(useGroupDetail, 'default')
      const {getByText, getByRole, getAllByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks: [
            ...defaultMocks,
            moveOutcomeMock({
              groupId: '201',
            }),
          ],
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => vi.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(detailSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          rhsGroupIdsToRefetch: ['2', '200', '201', '300'],
        }),
      )
    })
  })

  describe('With manage_outcomes permission / canManage true', () => {
    it('enables users to bulk select and move outcomes', async () => {
      const customMocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupDescription: 'Course folder 0 group description',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
          removeOnRefetch: true,
        }),
      ]
      const {getByText, getByRole, getAllByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks: [
            ...customMocks,
            moveOutcomeMock({
              groupId: '201',
            }),
          ],
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      expect(getByText('2 Outcomes Selected')).toBeInTheDocument()
      await clickWithPending(getAllByText('Move')[getAllByText('Move').length - 1])
      // Move Outcomes Modal
      await clickWithPending(within(getByRole('dialog')).getByText('Back'))
      await clickWithPending(within(getByRole('dialog')).getByText('Course folder 1'))
      await clickWithPending(within(getByRole('dialog')).getByText('Move'))
      await clickWithPending(getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    })
  })
})
