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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import TimeBlockSelectRow from '../TimeBlockSelectRow'
import tzInTest from '@instructure/moment-utils/specHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import $ from 'jquery'

// Mock jQuery functions used in the component
$.fn.data = jest.fn()
$.fn.is = jest.fn()

describe('TimeBlockSelectRow', () => {
  let props
  let originalDate

  beforeEach(() => {
    originalDate = new Date('2016-10-28T19:00:00.000Z')

    // Configure timezone with proper data
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })

    // set user profile timezone to EST (UTC-4)
    fakeENV.setup({TIMEZONE: 'America/Detroit'})

    // Reset jQuery mock functions
    $.fn.data.mockReset()
    $.fn.is.mockReset()

    // Setup jQuery mock return values
    $.fn.data.mockImplementation(key => {
      if (key === 'blank') return false
      if (key === 'date') return originalDate
      return null
    })
    $.fn.is.mockReturnValue(true) // Mock :last-child check

    props = {
      timeData: {
        date: originalDate,
        startTime: originalDate,
        endTime: new Date('2016-10-28T19:30:00.000Z'),
      },
      setData: jest.fn(),
      handleDelete: jest.fn(),
      onBlur: jest.fn(),
    }
  })

  afterEach(() => {
    tzInTest.restore()
    fakeENV.teardown()
  })

  it('sets up the date and time fields', () => {
    const {container} = render(<TimeBlockSelectRow {...props} />)
    const fields = container.querySelectorAll('.datetime_field_enabled')
    expect(fields).toHaveLength(3)
  })

  it('disables the datepicker button when readOnly prop is true', () => {
    props.readOnly = true
    const {container} = render(<TimeBlockSelectRow {...props} />)
    const datepickerButton = container.querySelector('.TimeBlockSelectorRow__Date').nextSibling
    expect(datepickerButton).toHaveAttribute('disabled')
  })

  it('does not render a delete button when readOnly prop is provided', () => {
    props.readOnly = true
    const {container} = render(<TimeBlockSelectRow {...props} />)
    const deleteButton = container.querySelector('[data-testid="delete-button"]')
    expect(deleteButton).toBeNull()
  })

  it('renders disabled inputs when readOnly prop is true', () => {
    props.readOnly = true
    const {container} = render(<TimeBlockSelectRow {...props} />)
    const inputs = container.querySelectorAll('input')
    const disabledInputs = Array.from(inputs).filter(input => input.hasAttribute('disabled'))
    expect(disabledInputs).toHaveLength(3)
  })

  it('renders fudged dates for timezones', () => {
    const {container} = render(<TimeBlockSelectRow {...props} />)
    const inputs = container.querySelectorAll('input')
    expect(inputs[1].value).toBe(' 3:00pm')
    expect(inputs[2].value).toBe(' 3:30pm')
  })

  it('calls handleDelete with slotEventId', async () => {
    props.slotEventId = '123'
    const {getByTestId} = render(<TimeBlockSelectRow {...props} />)
    const deleteButton = getByTestId('delete-button')
    await userEvent.click(deleteButton)
    expect(props.handleDelete).toHaveBeenCalledWith('123')
  })

  it('calls setData on field blur', async () => {
    props.slotEventId = '123'
    const {container} = render(<TimeBlockSelectRow {...props} />)
    const dateInput = container.querySelector('.TimeBlockSelectorRow__Date')
    await userEvent.click(dateInput)
    await userEvent.tab()
    expect(props.setData).toHaveBeenCalledWith(
      '123',
      expect.objectContaining({
        date: expect.any(Date),
        startTime: expect.any(Date),
        endTime: expect.any(Date),
      }),
    )
  })

  it('calls onBlur when non-blank and when the target row is the last', async () => {
    const firstOnBlur = jest.fn()
    const {container} = render(
      <div>
        <TimeBlockSelectRow slotEventId="1" {...props} onBlur={firstOnBlur} />
        <TimeBlockSelectRow slotEventId="2" {...props} />
      </div>,
    )
    const lastRowDateInput = container.querySelectorAll('.TimeBlockSelectorRow__Date')[1]
    await userEvent.click(lastRowDateInput)
    await userEvent.tab()
    expect(props.onBlur).toHaveBeenCalled()
    expect(firstOnBlur).not.toHaveBeenCalled()
  })
})
