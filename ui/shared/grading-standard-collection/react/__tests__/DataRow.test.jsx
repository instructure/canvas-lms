/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DataRow from '@canvas/grading-standard-collection/react/dataRow'

const renderInTable = ui => {
  return render(
    <table>
      <tbody>{ui}</tbody>
    </table>,
  )
}

describe('DataRow not being edited, without a sibling', () => {
  const defaultProps = {
    uniqueId: 0,
    row: ['A', 92.346],
    editing: false,
    round: number => Math.round(number * 100) / 100,
    onRowMinScoreChange: jest.fn(),
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders in "view" mode', () => {
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    expect(getByTestId('grading-standard-row-view')).toBeInTheDocument()
  })

  it('returns the correct name from getRowData', () => {
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    expect(getByTestId('row-name')).toHaveTextContent('A')
  })

  it('sets max score to 100 if there is no sibling row', () => {
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    expect(getByTestId('max-score')).toHaveTextContent('100%')
  })

  it('rounds the score if not in editing mode', () => {
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    expect(getByTestId('min-score')).toHaveTextContent('to 92.35%')
  })
})

describe('DataRow being edited', () => {
  const defaultProps = {
    uniqueId: 0,
    row: ['A', 92.346],
    editing: true,
    round: number => Math.round(number * 100) / 100,
    onRowMinScoreChange: jest.fn(),
    onRowNameChange: jest.fn(),
    onDeleteRow: jest.fn(),
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders in "edit" mode', () => {
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    expect(getByTestId('grading-standard-row-edit')).toBeInTheDocument()
  })

  it('accepts arbitrary input and saves to state', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    const input = getByTestId('min-score-input')

    await user.clear(input)
    await user.type(input, 'A')
    expect(input).toHaveValue('A')

    await user.clear(input)
    await user.type(input, '*&@%!')
    expect(input).toHaveValue('*&@%!')

    await user.clear(input)
    await user.type(input, '3B')
    expect(input).toHaveValue('3B')

    expect(defaultProps.onRowMinScoreChange).not.toHaveBeenCalled()
  })

  it('contains contextual screenreader text for inserting row', () => {
    const {container} = renderInTable(<DataRow key={0} {...defaultProps} />)
    const screenreaderTexts = container.getElementsByClassName('screenreader-only')
    const insertText = Array.from(screenreaderTexts).find(
      el => el.textContent === 'Insert row below A',
    )
    expect(insertText).toBeInTheDocument()
  })

  it('contains contextual screenreader text for removing row', () => {
    const {container} = renderInTable(<DataRow key={0} {...defaultProps} />)
    const screenreaderTexts = container.getElementsByClassName('screenreader-only')
    const removeText = Array.from(screenreaderTexts).find(el => el.textContent === 'Remove row A')
    expect(removeText).toBeInTheDocument()
  })

  it('does not call onRowMinScoreChange if input value is less than 0', async () => {
    const mockOnRowMinScoreChange = jest.fn()
    const props = {...defaultProps, onRowMinScoreChange: mockOnRowMinScoreChange}
    const user = userEvent.setup()
    const {getByTestId} = renderInTable(<DataRow key={0} {...props} />)
    const input = getByTestId('min-score-input')

    await user.clear(input)
    await user.type(input, '-1')
    fireEvent.blur(input)

    expect(mockOnRowMinScoreChange).not.toHaveBeenCalled()
  })

  it('does not call onRowMinScoreChange if input value is greater than 100', async () => {
    const mockOnRowMinScoreChange = jest.fn()
    const props = {...defaultProps, onRowMinScoreChange: mockOnRowMinScoreChange}
    const user = userEvent.setup()
    const {getByTestId} = renderInTable(<DataRow key={0} {...props} />)
    const input = getByTestId('min-score-input')

    await user.clear(input)
    await user.type(input, '101')
    fireEvent.blur(input)

    expect(mockOnRowMinScoreChange).not.toHaveBeenCalled()
  })

  it('calls onRowMinScoreChange when input value is between 0 and 100', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    const input = getByTestId('min-score-input')

    await user.clear(input)
    await user.type(input, '88')
    fireEvent.blur(input)

    await user.clear(input)
    await user.type(input, '100')
    fireEvent.blur(input)

    await user.clear(input)
    await user.type(input, '0')
    fireEvent.blur(input)

    expect(defaultProps.onRowMinScoreChange).toHaveBeenCalledWith(0, '88')
    expect(defaultProps.onRowMinScoreChange).toHaveBeenCalledWith(0, '100')
    expect(defaultProps.onRowMinScoreChange).toHaveBeenCalledWith(0, '0')
  })

  it('calls onRowNameChange when input changes', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderInTable(<DataRow key={0} {...defaultProps} />)
    const input = getByTestId('name-input')

    await user.type(input, 'F')

    expect(defaultProps.onRowNameChange).toHaveBeenCalledWith(0, 'AF')
  })

  it('calls onDeleteRow when the delete button is clicked', async () => {
    const user = userEvent.setup()
    const {getByRole} = renderInTable(<DataRow key={0} {...defaultProps} />)
    const deleteButton = getByRole('button', {name: 'Remove row A'})

    await user.click(deleteButton)

    expect(defaultProps.onDeleteRow).toHaveBeenCalledWith(0)
  })
})

describe('DataRow with a sibling', () => {
  const defaultProps = {
    uniqueId: 1,
    row: ['A-', 90],
    siblingRow: ['A', 92.346],
    editing: false,
    round: number => Math.round(number * 100) / 100,
    onRowMinScoreChange: jest.fn(),
  }

  it("shows the max score as the sibling's min score", () => {
    const {getByTestId} = renderInTable(<DataRow key={1} {...defaultProps} />)
    expect(getByTestId('max-score')).toHaveTextContent('< 92.35%')
  })
})
