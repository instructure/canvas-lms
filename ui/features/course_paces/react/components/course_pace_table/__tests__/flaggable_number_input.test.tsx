/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import {FlaggableNumberInput} from '../flaggable_number_input'

const onChange = jest.fn()
const onDecrement = jest.fn()
const onIncrement = jest.fn()

const defaultProps = {
  label: 'Duration for assignment 3',
  interaction: 'enabled' as const,
  value: '5',
  onChange,
  onDecrement,
  onIncrement,
  showTooltipOn: ['hover' as const],
  showFlag: false,
}

describe('FlaggableNumberInput', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders an input with provided label and value', () => {
    const {getByLabelText} = render(<FlaggableNumberInput {...defaultProps} />)
    const input = getByLabelText('Duration for assignment 3') as HTMLInputElement
    expect(input).toBeInTheDocument()
    expect(input.value).toBe('5')
  })

  it('calls onChange when the value is changed', async () => {
    const {getByLabelText} = render(<FlaggableNumberInput {...defaultProps} />)
    const input = getByLabelText('Duration for assignment 3') as HTMLInputElement
    await userEvent.type(input, '{selectall}{backspace}4')
    expect(onChange).toHaveBeenCalled()
  })

  it('renders a flag according to showFlag prop', () => {
    const {getByText, queryByText, rerender} = render(<FlaggableNumberInput {...defaultProps} />)
    const flagText = 'Unsaved change'
    expect(queryByText(flagText)).not.toBeInTheDocument()
    rerender(<FlaggableNumberInput {...defaultProps} showFlag={true} />)
    expect(getByText(flagText)).toBeInTheDocument()
  })

  it('enables the input according to the interaction prop', () => {
    const {getByLabelText, rerender} = render(<FlaggableNumberInput {...defaultProps} />)
    const input = getByLabelText('Duration for assignment 3') as HTMLInputElement
    expect(input).toBeEnabled()
    rerender(<FlaggableNumberInput {...defaultProps} interaction="disabled" />)
    expect(input).toBeDisabled()
  })
})
