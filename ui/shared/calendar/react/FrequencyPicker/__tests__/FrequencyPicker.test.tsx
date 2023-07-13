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
import moment from 'moment-timezone'
import {render, screen} from '@testing-library/react'
import FrequencyPicker from '../FrequencyPicker'
import userEvent from '@testing-library/user-event'
import {FrequencyOptionValue} from '@canvas/calendar/react/FrequencyPicker/FrequencyPickerUtils'

const defaultTZ = 'Asia/Tokyo'

const defaultProps = (overrides: object = {}) => ({
  date: moment.tz('2001-04-12', defaultTZ).toDate(), // a Thursday
  initialFrequency: 'weekly-day' as FrequencyOptionValue,
  locale: 'en',
  timezone: defaultTZ,
  onChange: jest.fn(),
  ...overrides,
})

const selectOption = (buttonName: RegExp, optionName: RegExp) => {
  userEvent.click(
    screen.getByRole('button', {
      name: buttonName,
    })
  )
  userEvent.click(
    screen.getByRole('option', {
      name: optionName,
    })
  )
}

describe('FrequencyPicker', () => {
  beforeAll(() => {
    moment.tz.setDefault(defaultTZ)
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('renders', () => {
    it('with default the given frequency', async () => {
      const props = defaultProps()
      const {getByDisplayValue, rerender} = render(
        <FrequencyPicker {...props} initialFrequency="daily" />
      )
      expect(getByDisplayValue('Daily')).toBeInTheDocument()

      rerender(<FrequencyPicker {...props} initialFrequency="weekly-day" />)
      expect(getByDisplayValue('Weekly on Thursday')).toBeInTheDocument()

      rerender(<FrequencyPicker {...props} initialFrequency="monthly-nth-day" />)
      expect(getByDisplayValue('Monthly on the second Thursday')).toBeInTheDocument()

      rerender(<FrequencyPicker {...props} initialFrequency="annually" />)
      expect(getByDisplayValue('Annually on April 12')).toBeInTheDocument()

      rerender(<FrequencyPicker {...props} initialFrequency="every-weekday" />)
      expect(getByDisplayValue('Every weekday (Monday to Friday)')).toBeInTheDocument()
    })

    it('with custom frequency opens the modal', () => {
      const props = defaultProps()
      const {getByText} = render(<FrequencyPicker {...props} initialFrequency="custom" />)
      const modal = getByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
    })

    it('with open modal with the current selected frequency', async () => {
      const props = defaultProps()
      const {findByText, getByRole} = render(<FrequencyPicker {...props} />)
      selectOption(/frequency:/i, /weekly on thursday/i)
      selectOption(/frequency:/i, /custom/i)
      const modal = await findByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()

      const thursdayCheckbox = getByRole('checkbox', {name: 'Thursday'})
      expect(thursdayCheckbox).toBeInTheDocument()
      expect(thursdayCheckbox).toBeChecked()
    })

    it('the modal with the given custom rrule', async () => {
      const props = defaultProps()
      const {findByText, getByDisplayValue, getByRole} = render(
        <FrequencyPicker
          {...props}
          initialFrequency="saved-custom"
          rrule="FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE;COUNT=5"
        />
      )
      expect(getByDisplayValue('Weekly on Mon, Wed, 5 times')).toBeInTheDocument()

      selectOption(/frequency:/i, /Weekly on Mon, Wed, 5 times/)
      selectOption(/frequency/i, /custom/i)
      const modal = await findByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
      expect(getByDisplayValue('Week')).toBeInTheDocument()
      expect(getByRole('checkbox', {name: 'Monday'})).toBeChecked()
      expect(getByRole('checkbox', {name: 'Wednesday'})).toBeChecked()
      expect(getByDisplayValue('5')).toBeInTheDocument()
    })

    it('returns focus to the frequency picker button when the modal is closed', async () => {
      const props = defaultProps()
      const {findByText, getByRole} = render(<FrequencyPicker {...props} />)
      selectOption(/frequency:/i, /custom/i)
      const modal = await findByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
      userEvent.click(getByRole('button', {name: /cancel/i}))
      expect(getByRole('button', {name: /frequency/i})).toHaveFocus()
    })
  })

  describe('onChange is called', () => {
    it('after was mounted', () => {
      const props = defaultProps()
      render(<FrequencyPicker {...props} />)
      expect(props.onChange).toHaveBeenCalledWith(
        'weekly-day',
        'FREQ=WEEKLY;BYDAY=TH;INTERVAL=1;COUNT=52'
      )
    })

    it('with not-default prop after was mounted', () => {
      const props = defaultProps({initialFrequency: 'annually'})
      render(<FrequencyPicker {...props} />)
      expect(props.onChange).toHaveBeenCalledWith(
        'annually',
        'FREQ=YEARLY;BYMONTH=04;BYMONTHDAY=12;INTERVAL=1;COUNT=5'
      )
    })

    it('when date prop changes', () => {
      const props = defaultProps()
      const {rerender} = render(<FrequencyPicker {...props} />)
      rerender(
        <FrequencyPicker {...props} {...{date: moment.tz('1997-04-15', defaultTZ).toDate()}} />
      )
      expect(props.onChange).toHaveBeenCalledWith(
        'weekly-day',
        'FREQ=WEEKLY;BYDAY=TU;INTERVAL=1;COUNT=52'
      )
    })

    it('when user changes frequency', () => {
      const props = defaultProps()
      render(<FrequencyPicker {...props} />)
      selectOption(/frequency:/i, /annually on april 12/i)
      expect(props.onChange).toHaveBeenCalledWith(
        'annually',
        'FREQ=YEARLY;BYMONTH=04;BYMONTHDAY=12;INTERVAL=1;COUNT=5'
      )
    })
  })
})
