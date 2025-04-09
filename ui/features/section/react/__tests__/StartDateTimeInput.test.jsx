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
import {render, screen} from '@testing-library/react'
import StartDateTimeInput from '../StartDateTimeInput'
import userEvent from '@testing-library/user-event'

const mockENV = {
  CONTEXT_TIMEZONE: 'America/New_York',
  TIMEZONE: 'America/Los_Angeles',
  context_asset_string: 'course_123',
  LOCALE: 'en',
}

beforeEach(() => {
  jest.clearAllMocks()
  global.ENV = mockENV
})

describe('StartDateTimeInput', () => {
  const initialValue = '2023-05-15T12:00:00Z'

  it('renders', () => {
    render(<StartDateTimeInput initialValue={initialValue}></StartDateTimeInput>)
    expect(screen.getByTestId('section-start-date')).toBeInTheDocument()
    expect(screen.getByTestId('section-start-time')).toBeInTheDocument()
  })

  it('shows hints when context and local timezones differ', () => {
    render(<StartDateTimeInput initialValue={initialValue}></StartDateTimeInput>)
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
    render(<StartDateTimeInput initialValue={initialValue}></StartDateTimeInput>)
    expect(screen.queryByText('Local: Mon, May 15, 2023, 5:00 AM')).not.toBeInTheDocument()
    expect(screen.queryByText('Course: Mon, May 15, 2023, 8:00 AM')).not.toBeInTheDocument()
  })

  it('shows error if date is invalid', async () => {
    render(<StartDateTimeInput initialValue={initialValue}></StartDateTimeInput>)
    const input = screen.getByTestId('section-start-date')
    await userEvent.clear(input)
    await userEvent.type(input, 'invalid')
    await userEvent.tab()
    expect(screen.getByText('Please enter a valid format for a date')).toBeInTheDocument()
  })
})
