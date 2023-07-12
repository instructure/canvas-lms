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
import moment from 'moment'
import {render, screen} from '@testing-library/react'
import FrequencyPicker from '../FrequencyPicker'
import userEvent from '@testing-library/user-event'
import {FrequencyOptionValue} from '@canvas/calendar/react/FrequencyPicker/FrequencyPickerUtils'

const defaultProps = (overrides: object = {}) => ({
  date: moment('2001-04-12').toDate(),
  initialFrequency: 'weekly-day' as FrequencyOptionValue,
  locale: 'en',
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
  beforeEach(() => {
    jest.clearAllMocks()
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
      rerender(<FrequencyPicker {...props} {...{date: moment('1997-04-15').toDate()}} />)
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
