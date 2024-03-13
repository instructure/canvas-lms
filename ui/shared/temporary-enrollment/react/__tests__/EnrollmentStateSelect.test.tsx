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
import EnrollmentStateSelect, {enrollmentStates, getLabelForState} from '../EnrollmentStateSelect'

describe('EnrollmentStateSelect', () => {
  it('renders with default value', () => {
    const defaultValue = 'deleted'
    render(<EnrollmentStateSelect value={defaultValue} label="Select State" />)
    const comboboxElement = screen.getByRole('combobox')
    const defaultLabel = enrollmentStates.find(state => state.value === defaultValue)?.label
    expect(comboboxElement).toHaveValue(defaultLabel)
  })

  it('defaults to the first option when no initial value is provided', () => {
    render(<EnrollmentStateSelect label="Select State" />)
    const comboboxElement = screen.getByRole('combobox')
    const firstOptionLabel = 'Deleted'
    expect(comboboxElement).toHaveValue(firstOptionLabel)
  })

  it('calls onChange when an option is selected', async () => {
    const handleChange = jest.fn()
    render(<EnrollmentStateSelect onChange={handleChange} label="Select State" />)
    const comboboxElement = screen.getByRole('combobox')
    await userEvent.click(comboboxElement)
    const optionLabel = enrollmentStates.find(state => state.value === 'inactive')?.label
    const option = screen.getByRole('option', {name: optionLabel})
    await userEvent.click(option)
    expect(handleChange).toHaveBeenCalledWith('inactive')
  })

  it('displays all the options', async () => {
    render(<EnrollmentStateSelect label="Select State" />)
    const comboboxElement = screen.getByRole('combobox')
    await userEvent.click(comboboxElement)
    enrollmentStates.forEach(state => {
      expect(screen.getByRole('option', {name: state.label})).toBeInTheDocument()
    })
  })

  it('updates the displayed value when an option is selected', async () => {
    render(<EnrollmentStateSelect label="Select State" />)
    const comboboxElement = screen.getByRole('combobox')
    expect(comboboxElement).toHaveValue('Deleted')
    await userEvent.click(comboboxElement)
    const optionLabel = 'Completed'
    const option = screen.getByRole('option', {name: optionLabel})
    await userEvent.click(option)
    expect(comboboxElement).toHaveValue(optionLabel)
  })

  describe('getLabelForState()', () => {
    it('returns correct label for each valid state', () => {
      enrollmentStates.forEach(state => {
        expect(getLabelForState(state.value)).toBe(state.label)
      })
    })
  })
})
