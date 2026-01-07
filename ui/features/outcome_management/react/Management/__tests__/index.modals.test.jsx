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
import OutcomeManagementPanel from '../index'
import {setupTest} from './testSetup'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()

// FOO-3827
describe('OutcomeManagementPanel - Modals', () => {
  let render, defaultProps, groupDetailDefaultProps

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  afterAll(() => {
    window.ENV = null
  })

  it('shows and closes Find Outcomes modal if Add Outcomes option from group menu is selected', async () => {
    const {getByText, queryByText, getByTestId, getByRole} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(within(getByRole('menu')).getByText('Add Outcomes'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Add Outcomes to "Course folder 0"')).toBeInTheDocument()
    fireEvent.click(within(getByTestId('find-outcomes-modal')).getByText('Done'))
    // Run all timers to remove the modal from the DOM
    await act(async () => vi.runAllTimers())
    expect(queryByText('Add Outcomes to "Course folder 0"')).not.toBeInTheDocument()
  })

  it('shows remove group modal if remove option from group menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Remove Group?')).toBeInTheDocument()
  })

  it('shows remove outcome modal if remove option from individual outcome menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Remove Outcome?')).toBeInTheDocument()
  })

  it('shows edit outcome modal if edit option from individual outcome menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('shows move outcome modal if move option from individual outcome menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-move'))
    expect(getByText('Where would you like to move this outcome?')).toBeInTheDocument()
  })

  it('clears selected outcome when remove outcome modal is closed', async () => {
    const {getByText, queryByText, getByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
  })

  it('clears selected outcome when move outcome modal is closed', async () => {
    const {getByText, queryByText, getByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-move'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Move "Outcome 1 - Course folder 0"')).not.toBeInTheDocument()
  })

  // Need to move this bellow since somehow this spec is triggering an infinite loop
  // in runAllTimers above if we put this spec before it
  it('clears selected outcome when edit outcome modal is closed', async () => {
    const {getByText, queryByText, getByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    fireEvent.click(getByText('Cancel'))
    await act(async () => vi.advanceTimersByTime(500))
    expect(queryByText('Edit Outcome')).not.toBeInTheDocument()
  })

  it('shows edit group modal if edit option from group menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Edit Group')).toBeInTheDocument()
  })

  it('shows selected group title within edit group modal', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    await act(async () => vi.runOnlyPendingTimers())
    const editModal = getByTestId('outcome-management-edit-modal')
    expect(within(editModal).getByDisplayValue('Course folder 0')).toBeInTheDocument()
  })

  it('shows selected group description within edit group modal', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    await act(async () => vi.runOnlyPendingTimers())
    const editModal = getByTestId('outcome-management-edit-modal')
    expect(within(editModal).getByTestId('group-description-input')).toBeInTheDocument()
  })
})
