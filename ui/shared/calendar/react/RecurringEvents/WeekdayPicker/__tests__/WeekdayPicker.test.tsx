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
import moment, {type Locale} from 'moment'
import {render, act} from '@testing-library/react'
import WeekdayPicker from '../WeekdayPicker'

const defaultProps = (overrides: object = {}) => ({
  onChange: jest.fn(),
  locale: 'en',
  ...overrides,
})

describe('WeekdayPicker', () => {
  it('renders', () => {
    const {getAllByRole, getByText} = render(<WeekdayPicker {...defaultProps()} />)
    expect(getByText('Sunday')).toBeInTheDocument()
    expect(getByText('Monday')).toBeInTheDocument()
    expect(getByText('Tuesday')).toBeInTheDocument()
    expect(getByText('Wednesday')).toBeInTheDocument()
    expect(getByText('Thursday')).toBeInTheDocument()
    expect(getByText('Friday')).toBeInTheDocument()
    expect(getByText('Saturday')).toBeInTheDocument()
    expect(getByText('Su')).toBeInTheDocument()
    expect(getByText('Mo')).toBeInTheDocument()
    expect(getByText('Tu')).toBeInTheDocument()
    expect(getByText('We')).toBeInTheDocument()
    expect(getByText('Th')).toBeInTheDocument()
    expect(getByText('Fr')).toBeInTheDocument()
    expect(getByText('Sa')).toBeInTheDocument()
    expect((getAllByRole('checkbox') as HTMLInputElement[])[0].value).toEqual('SU')
  })

  describe('in a different locale', () => {
    let origLocaleDataFunc: (...args: any) => Locale
    const mockLocaleData = {firstDayOfWeek: () => 1} as Locale
    beforeEach(() => {
      origLocaleDataFunc = moment.localeData
      moment.localeData = _locale => mockLocaleData
    })
    afterEach(() => {
      moment.localeData = origLocaleDataFunc
    })

    it("renders with the locale's first day of week", () => {
      const {getAllByRole} = render(<WeekdayPicker {...defaultProps({locale: 'en_GB'})} />)
      const checkboxes = getAllByRole('checkbox') as HTMLInputElement[]
      expect(checkboxes[0].value).toEqual('MO')
      expect(checkboxes[1].value).toEqual('TU')
      expect(checkboxes[2].value).toEqual('WE')
      expect(checkboxes[3].value).toEqual('TH')
      expect(checkboxes[4].value).toEqual('FR')
      expect(checkboxes[5].value).toEqual('SA')
      expect(checkboxes[6].value).toEqual('SU')
    })
  })

  it('renders with selected days', () => {
    const {getAllByRole} = render(<WeekdayPicker {...defaultProps({selectedDays: ['SU', 'MO']})} />)
    const checked = getAllByRole('checkbox', {checked: true}) as HTMLInputElement[]
    const unchecked = getAllByRole('checkbox', {checked: false}) as HTMLInputElement[]
    expect(checked).toHaveLength(2)
    expect(checked[0].value).toEqual('SU')
    expect(checked[1].value).toEqual('MO')
    expect(unchecked).toHaveLength(5)
  })

  it('calls onChange with the selected days', () => {
    const props = defaultProps()
    const {getByText} = render(<WeekdayPicker {...props} />)
    act(() => {
      getByText('Sunday').click()
    })
    expect(props.onChange).toHaveBeenCalledWith(['SU'])
  })

  it('calls on Change with all the selected days', () => {
    const props = defaultProps({selectedDays: ['SU', 'MO']})
    const {getByText} = render(<WeekdayPicker {...props} />)
    act(() => {
      getByText('Tuesday').click()
    })
    expect(props.onChange).toHaveBeenCalledWith(['SU', 'MO', 'TU'])
  })
})
