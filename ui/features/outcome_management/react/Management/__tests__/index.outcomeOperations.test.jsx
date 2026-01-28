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
import OutcomeManagementPanel from '../index'
import {setupTest, teardownTest, createDefaultCourseMocks} from './testSetup'
import {deleteOutcomeMock} from '@canvas/outcomes/mocks/Management'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()

// FOO-3827
describe('OutcomeManagementPanel - Outcome Operations', () => {
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

  it('selects/unselects outcome via checkbox', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    const outcome = getByText('Select outcome Outcome 1 - Course folder 0')
    fireEvent.click(outcome)
    expect(getByText('1 Outcome Selected')).toBeInTheDocument()
    fireEvent.click(outcome)
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
  })

  it('Removes outcome from the list', async () => {
    const {queryByText, getByText, getByTestId, getAllByText} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
        mocks: [...defaultMocks, deleteOutcomeMock({ids: ['1']})],
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    expect(queryByText('2 Outcomes')).toBeInTheDocument()
    fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('bulk-remove-outcomes'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Outcome 1 - Course folder 0')).not.toBeInTheDocument()
    expect(queryByText('1 Outcome')).toBeInTheDocument()
  })

  it('Removes selected outcome from the selected outcomes popover', async () => {
    const {queryByText, getByText, getByTestId, getAllByText} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
        mocks: [...defaultMocks, deleteOutcomeMock({ids: ['1']})],
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
    expect(queryByText('1 Outcome Selected')).toBeInTheDocument()
    fireEvent.click(getByTestId('bulk-remove-outcomes'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Outcome 1 - Course folder 0')).not.toBeInTheDocument()
    expect(queryByText('0 Outcomes Selected')).toBeInTheDocument()
  })

  it('Displays spinner in document when a single outcome is removed', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    expect(getByTestId('outcome-spinner')).toBeInTheDocument()
  })

  describe('Selected outcomes popover', () => {
    it('shows selected outcomes popover if outcomes are selected and Outcomes Selected link is clicked', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      const selectedOutcomesLink = getByText('2 Outcomes Selected').closest('button')
      fireEvent.click(selectedOutcomesLink)
      expect(selectedOutcomesLink).toBeEnabled()
      expect(selectedOutcomesLink).toHaveAttribute('aria-expanded')
    })

    it('closes popover and clears selected outcomes when Clear all link in popover is clicked', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      const selectedOutcomesLink = getByText('2 Outcomes Selected').closest('button')
      fireEvent.click(selectedOutcomesLink)
      fireEvent.click(getByText('Clear all'))
      expect(selectedOutcomesLink.getAttribute('aria-disabled')).toBe('true')
      expect(selectedOutcomesLink.getAttribute('aria-expanded')).toBe('false')
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    })
  })

  describe('After an outcome is added', () => {
    it('it does not trigger a refetch if an outcome is created but not in the currently selected group', async () => {
      const {getByText, queryByText, rerender} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      render(<OutcomeManagementPanel {...defaultProps({createdOutcomeGroupIds: ['2']})} />, {
        ...groupDetailDefaultProps,
        renderer: rerender,
      })
      await act(async () => vi.runOnlyPendingTimers())
      expect(queryByText(/Newly Created Outcome/)).not.toBeInTheDocument()
    })

    it('it does trigger a refetch if an outcome is created is in currently selected group in RHS', async () => {
      const {getByText, getAllByText, rerender} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())

      render(<OutcomeManagementPanel {...defaultProps({createdOutcomeGroupIds: ['200']})} />, {
        ...groupDetailDefaultProps,
        renderer: rerender,
      })
      await act(async () => vi.runOnlyPendingTimers())
      expect(getAllByText('Newly Created Outcome - Course folder 0')).toHaveLength(2)
    })
  })

  describe('After outcomes import', () => {
    it('resets targetGroupIdsToRefetch', () => {
      const setup = setupTest()
      const {setTargetGroupIdsToRefetchMock} = setup
      setup.render(
        <OutcomeManagementPanel {...setup.defaultProps({targetGroupIdsToRefetch: ['200']})} />,
      )
      expect(setTargetGroupIdsToRefetchMock).toHaveBeenCalledTimes(1)
      expect(setTargetGroupIdsToRefetchMock).toHaveBeenCalledWith([])
    })
  })
})
