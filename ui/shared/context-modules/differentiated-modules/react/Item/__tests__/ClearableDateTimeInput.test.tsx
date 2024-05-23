/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ClearableDateTimeInput, {type ClearableDateTimeInputProps} from '../ClearableDateTimeInput'

describe('ClearableDateTimeInput', () => {
  const props: ClearableDateTimeInputProps = {
    description: 'Pick a date',
    dateRenderLabel: 'Date',
    value: null,
    messages: [],
    onChange: jest.fn(),
    onClear: jest.fn(),
    breakpoints: {},
    clearButtonAltLabel: 'Clear input for 2 students',
  }

  const renderComponent = (overrides = {}) =>
    render(<ClearableDateTimeInput {...props} {...overrides} />)

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Pick a date')).toBeInTheDocument()
    expect(getByText('Clear')).toBeInTheDocument()
  })

  it('renders accessible label for clear button', () => {
    const {getByText} = renderComponent()
    expect(getByText('Clear input for 2 students')).toBeInTheDocument()
  })

  it('disables clear button if blueprint-locked', () => {
    const {getByText} = renderComponent({disabled: true})
    expect(getByText('Clear').closest('button')).toBeDisabled()
  })

  it('calls onChange when date is changed', () => {
    const {getByLabelText, getByRole} = renderComponent()
    const dateInput = getByLabelText('Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(props.onChange).toHaveBeenCalled()
  })

  it('calls onClear when clear button is clicked', () => {
    const {getByText} = renderComponent()
    getByText('Clear').click()
    expect(props.onClear).toHaveBeenCalled()
  })
})
