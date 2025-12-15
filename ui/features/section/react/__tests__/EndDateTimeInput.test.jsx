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
import {render, screen, fireEvent} from '@testing-library/react'
import EndDateTimeInput from '../EndDateTimeInput'

// Store original handlers to call them in mock
let mockOnBlur = null

vi.mock('@instructure/ui-date-time-input', () => ({
  DateTimeInput: ({onChange, onBlur, dateInputRef, timeInputRef, messages}) => {
    mockOnBlur = onBlur
    return (
      <div data-testid="mocked-date-time-input">
        <input
          data-testid="section-end-date"
          ref={dateInputRef}
        />
        <input data-testid="section-end-time" ref={timeInputRef} />
        {messages && messages.length > 0 && (
          <div data-testid="messages">
            {messages.map((msg, idx) => (
              <div key={idx}>{msg.text}</div>
            ))}
          </div>
        )}
      </div>
    )
  },
}))

const mockENV = {
  CONTEXT_TIMEZONE: 'America/New_York',
  TIMEZONE: 'America/Los_Angeles',
  context_asset_string: 'course_123',
  LOCALE: 'en',
}

beforeEach(() => {
  vi.clearAllMocks()
  mockOnBlur = null
  global.ENV = mockENV
})

describe('EndDateTimeInput', () => {
  const initialValue = '2023-05-15T12:00:00Z'

  it('renders', () => {
    render(<EndDateTimeInput initialValue={initialValue} handleDateTimeChange={() => {}} />)
    expect(screen.getByTestId('section-end-date')).toBeInTheDocument()
    expect(screen.getByTestId('section-end-time')).toBeInTheDocument()
  })

  it('shows hints when context and local timezones differ', () => {
    render(<EndDateTimeInput initialValue={initialValue} handleDateTimeChange={() => {}} />)
    expect(screen.getByText('Local: Mon, May 15, 2023, 5:00 AM')).toBeInTheDocument()
    expect(screen.getByText('Course: Mon, May 15, 2023, 8:00 AM')).toBeInTheDocument()
  })

  it('does not show hints when context and local timezones match', () => {
    const newMockENV = {
      CONTEXT_TIMEZONE: 'America/New_York',
      TIMEZONE: 'America/New_York',
      context_asset_string: 'course_123',
      LOCALE: 'en',
    }
    global.ENV = newMockENV
    render(<EndDateTimeInput initialValue={initialValue} handleDateTimeChange={() => {}} />)
    expect(screen.queryByText('Local: Mon, May 15, 2023, 5:00 AM')).not.toBeInTheDocument()
    expect(screen.queryByText('Course: Mon, May 15, 2023, 8:00 AM')).not.toBeInTheDocument()
  })

  it('shows error if date is invalid', () => {
    render(<EndDateTimeInput initialValue={initialValue} handleDateTimeChange={() => {}} />)
    const input = screen.getByTestId('section-end-date')

    // Set invalid value directly on the input element (not via event)
    // This is needed because the component reads from the ref's value property
    input.value = 'invalid'

    // Trigger blur to run validation
    mockOnBlur()

    expect(screen.getByText('Please enter a valid format for a date')).toBeInTheDocument()
  })
})
