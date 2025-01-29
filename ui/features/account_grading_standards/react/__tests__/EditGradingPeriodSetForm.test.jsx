/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradingPeriodSetForm from '../EditGradingPeriodSetForm'

// Mock jQuery
jest.mock('jquery', () => ({
  __esModule: true,
  default: {
    flashError: jest.fn(),
  },
}))

// Mock flash notifications
jest.mock('@canvas/rails-flash-notifications', () => ({
  __esModule: true,
  default: {
    flashError: jest.fn(),
  },
}))

const exampleSet = {
  id: '1',
  title: 'Fall 2015',
  weighted: true,
  displayTotalsForAllGradingPeriods: false,
}

const defaultProps = {
  set: exampleSet,
  enrollmentTerms: [
    {id: '1', gradingPeriodGroupId: '1'},
    {id: '2', gradingPeriodGroupId: '2'},
    {id: '3', gradingPeriodGroupId: '1'},
  ],
  disabled: false,
  onSave: jest.fn(),
  onCancel: jest.fn(),
}

describe('EditGradingPeriodSetForm', () => {
  beforeEach(() => {
    defaultProps.onSave.mockClear()
    defaultProps.onCancel.mockClear()
  })

  it('renders with enabled save and cancel buttons by default', () => {
    render(<GradingPeriodSetForm {...defaultProps} />)

    const saveButton = screen.getByRole('button', {name: /save grading period set/i})
    const cancelButton = screen.getByRole('button', {name: /cancel/i})

    expect(saveButton).toBeEnabled()
    expect(cancelButton).toBeEnabled()
  })

  it('renders with disabled save and cancel buttons when disabled prop is true', () => {
    render(<GradingPeriodSetForm {...defaultProps} disabled={true} />)

    const saveButton = screen.getByRole('button', {name: /save grading period set/i})
    const cancelButton = screen.getByRole('button', {name: /cancel/i})

    expect(saveButton).toBeDisabled()
    expect(cancelButton).toBeDisabled()
  })

  it('displays the set title in the input field', () => {
    render(<GradingPeriodSetForm {...defaultProps} />)

    const titleInput = screen.getByRole('textbox', {name: /set name/i})
    expect(titleInput).toHaveValue('Fall 2015')
  })

  it('updates weighted state when checkbox is clicked', async () => {
    const user = userEvent.setup()
    render(<GradingPeriodSetForm {...defaultProps} />)

    const weightedCheckbox = screen.getByRole('checkbox', {name: /weighted grading periods/i})
    expect(weightedCheckbox).toBeChecked()

    await user.click(weightedCheckbox)
    expect(weightedCheckbox).not.toBeChecked()
  })

  it('defaults to unchecked for the "Display totals" checkbox when value is null', () => {
    const setWithNullDisplay = {
      ...exampleSet,
      displayTotalsForAllGradingPeriods: null,
    }
    render(<GradingPeriodSetForm {...defaultProps} set={setWithNullDisplay} />)

    const displayTotalsCheckbox = screen.getByRole('checkbox', {
      name: /display totals for all grading periods option/i,
    })
    expect(displayTotalsCheckbox).not.toBeChecked()
  })

  it('initializes checked for the "Display totals" checkbox when true', () => {
    const setWithDisplayTrue = {
      ...exampleSet,
      displayTotalsForAllGradingPeriods: true,
    }
    render(<GradingPeriodSetForm {...defaultProps} set={setWithDisplayTrue} />)

    const displayTotalsCheckbox = screen.getByRole('checkbox', {
      name: /display totals for all grading periods option/i,
    })
    expect(displayTotalsCheckbox).toBeChecked()
  })

  it('updates display totals state when checkbox is clicked', async () => {
    const user = userEvent.setup()
    render(<GradingPeriodSetForm {...defaultProps} />)

    const displayTotalsCheckbox = screen.getByRole('checkbox', {
      name: /display totals for all grading periods option/i,
    })
    expect(displayTotalsCheckbox).not.toBeChecked()

    await user.click(displayTotalsCheckbox)
    expect(displayTotalsCheckbox).toBeChecked()
  })

  it('calls onSave with updated set when save button is clicked', async () => {
    const user = userEvent.setup()
    render(<GradingPeriodSetForm {...defaultProps} />)

    const saveButton = screen.getByRole('button', {name: /save grading period set/i})
    await user.click(saveButton)

    expect(defaultProps.onSave).toHaveBeenCalledWith(
      expect.objectContaining({
        id: '1',
        title: 'Fall 2015',
        weighted: true,
        displayTotalsForAllGradingPeriods: false,
        enrollmentTermIDs: ['1', '3'],
      }),
    )
  })

  it('calls onCancel when cancel button is clicked', async () => {
    const user = userEvent.setup()
    render(<GradingPeriodSetForm {...defaultProps} />)

    const cancelButton = screen.getByRole('button', {name: /cancel/i})
    await user.click(cancelButton)

    expect(defaultProps.onCancel).toHaveBeenCalled()
  })

  it('does not call onSave when the set has no title', async () => {
    const user = userEvent.setup()
    const setWithNoTitle = {...exampleSet, title: ''}
    render(<GradingPeriodSetForm {...defaultProps} set={setWithNoTitle} />)

    const saveButton = screen.getByRole('button', {name: /save grading period set/i})
    await user.click(saveButton)

    expect(defaultProps.onSave).not.toHaveBeenCalled()
  })
})
