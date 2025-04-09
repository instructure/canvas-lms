/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import { render, screen, fireEvent } from '@testing-library/react'
import GroupWeightInput from '../GroupWeightInput'

const setup = (props = {}) => {
  const defaultProps = {
    groupId: 1,
    name: 'test',
    canChangeWeights: true,
    initialValue: '5'
  }
  return render(<GroupWeightInput {...defaultProps} {...props} />)
}

test('renders the input field with the correct initial value', () => {
  setup()
  const input = screen.getByTestId('ag_1_weight_input')
  expect(input).toBeInTheDocument()
  expect(input).toHaveValue('5')
})

test('allows changing input value', () => {
  setup()
  const input = screen.getByTestId('ag_1_weight_input')
  fireEvent.change(input, { target: { value: '10' } })
  expect(input).toHaveValue('10')
})

test('shows an error when entering an invalid number', () => {
  setup()
  const input = screen.getByTestId('ag_1_weight_input')
  fireEvent.change(input, { target: { value: 'abc' } })
  fireEvent.blur(input)
  expect(screen.getByText('Must be a valid number')).toBeInTheDocument()
})

test('rounds the number on blur', () => {
  setup()
  const input = screen.getByTestId('ag_1_weight_input')
  fireEvent.change(input, { target: { value: '5.678' } })
  fireEvent.blur(input)
  expect(input).toHaveValue('5.68')
})

test('disables interaction when canChangeWeights is false', () => {
  setup({ canChangeWeights: false })
  const input = screen.getByTestId('ag_1_weight_input')
  expect(input).toHaveAttribute('readonly')
})
