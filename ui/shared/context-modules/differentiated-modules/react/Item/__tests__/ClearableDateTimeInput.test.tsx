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
import {render, fireEvent, waitFor} from '@testing-library/react'
import ClearableDateTimeInput, {type ClearableDateTimeInputProps} from '../ClearableDateTimeInput'

// Mock the DateTimeInput component to make testing easier
// We'll assume that the functionality of DateTimeInput is tested elsewhere,
// so since these unit tests are focused on the behavior of this wrapper,
// just mocking it out seems safe.
jest.mock('@instructure/ui-date-time-input', () => ({
  DateTimeInput: ({onChange, messages, description}: any) => {
    return (
      <div data-testid="mocked-date-time-input">
        {description}
        <button
          data-testid="simulate-date-change"
          onClick={e => {
            // Simulate selecting a date - this will be controlled by tests
            const date = (e.target as HTMLButtonElement).getAttribute('data-date')
            if (date && onChange) {
              onChange(e, date)
            }
          }}
        >
          Change Date
        </button>
        {messages && messages.length > 0 && (
          <div data-testid="error-messages">
            {messages.map((msg: any, idx: number) => (
              <div key={idx}>{msg.text}</div>
            ))}
          </div>
        )}
      </div>
    )
  },
}))

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

  it('calls onChange when date is changed', async () => {
    const onChange = jest.fn()
    const {getByTestId} = renderComponent({onChange})
    const changeDateButton = getByTestId('simulate-date-change')

    changeDateButton.setAttribute('data-date', '2020-11-09T12:00:00.000Z')
    fireEvent.click(changeDateButton)

    await waitFor(() => {
      expect(onChange).toHaveBeenCalledWith(expect.anything(), '2020-11-09T12:00:00.000Z')
    })
  })

  it('calls onClear when clear button is clicked', () => {
    const {getByText} = renderComponent()
    getByText('Clear').click()
    expect(props.onClear).toHaveBeenCalled()
  })

  describe('validation of "reasonable" dates', () => {
    it('prevents dates before 1980 and shows error message', async () => {
      const onChange = jest.fn()
      const {getByTestId, getByText} = renderComponent({onChange})

      const changeDateButton = getByTestId('simulate-date-change')

      // Simulate selecting a date before 1980 (January 15, 1975)
      changeDateButton.setAttribute('data-date', '1975-01-15T12:00:00.000Z')
      fireEvent.click(changeDateButton)

      await waitFor(() => {
        expect(getByText('Please select a date in the year 1980 or later')).toBeInTheDocument()
      })

      // Verify that the parent onChange was NOT called
      expect(onChange).not.toHaveBeenCalled()
    })

    it('allows dates after 1980', async () => {
      const onChange = jest.fn()
      const {getByTestId, queryByText} = renderComponent({onChange})

      const changeDateButton = getByTestId('simulate-date-change')

      // Simulate selecting a date well after 1980 (November 9, 2024)
      changeDateButton.setAttribute('data-date', '2024-11-09T12:00:00.000Z')
      fireEvent.click(changeDateButton)

      await waitFor(() => {
        // Verify that no error message is displayed
        expect(queryByText('Please select a date in the year 1980 or later')).toBeNull()
        // Verify that the parent onChange WAS called
        expect(onChange).toHaveBeenCalledWith(expect.anything(), '2024-11-09T12:00:00.000Z')
      })
    })

    it('clears validation error when clear button is clicked', async () => {
      const onChange = jest.fn()
      const onClear = jest.fn()
      const {getByTestId, getByText, queryByText} = renderComponent({onChange, onClear})

      const changeDateButton = getByTestId('simulate-date-change')

      // First, trigger a validation error with a date before 1980
      changeDateButton.setAttribute('data-date', '1975-01-15T12:00:00.000Z')
      fireEvent.click(changeDateButton)

      await waitFor(() => {
        expect(getByText('Please select a date in the year 1980 or later')).toBeInTheDocument()
      })

      // Now click the clear button
      getByText('Clear').click()

      // Verify the error message is cleared
      await waitFor(() => {
        expect(onClear).toHaveBeenCalled()
        expect(queryByText('Please select a date in the year 1980 or later')).toBeNull()
      })
    })

    it('clears validation error when a valid date is selected after an invalid one', async () => {
      const onChange = jest.fn()
      const {getByTestId, getByText, queryByText} = renderComponent({onChange})

      const changeDateButton = getByTestId('simulate-date-change')

      // First, trigger a validation error with a date before 1980
      changeDateButton.setAttribute('data-date', '1975-01-15T12:00:00.000Z')
      fireEvent.click(changeDateButton)

      await waitFor(() => {
        expect(getByText('Please select a date in the year 1980 or later')).toBeInTheDocument()
      })

      // Now select a valid date
      changeDateButton.setAttribute('data-date', '2020-01-15T12:00:00.000Z')
      fireEvent.click(changeDateButton)

      await waitFor(() => {
        // Verify the error message is cleared
        expect(queryByText('Please select a date in the year 1980 or later')).toBeNull()
        // Verify that onChange was called with the valid date
        expect(onChange).toHaveBeenCalledWith(expect.anything(), '2020-01-15T12:00:00.000Z')
      })
    })
  })
})
