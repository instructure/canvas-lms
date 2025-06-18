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
import DateAdjustments from '../DateAdjustments'
import {timeZonedFormMessages} from '../timeZonedFormMessages'
import type {DateAdjustmentConfig, DateShifts} from '../types'
import userEvent from '@testing-library/user-event'
import moment from 'moment-timezone'
import {configureAndRestoreLater} from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import tz from 'timezone'

import chicago from 'timezone/America/Chicago'
import detroit from 'timezone/America/Detroit'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock jQuery.flashError to fix the test failure
jest.mock('jquery', () => {
  const mockJQuery = jest.requireActual('jquery')
  mockJQuery.flashError = jest.fn()
  return mockJQuery
})

declare module 'timezone' {
  interface Timezone {
    (timezoneData: unknown, ...args: string[]): string
  }
}

const dateAdjustments: DateAdjustmentConfig = {
  adjust_dates: {
    enabled: false,
    operation: 'shift_dates',
  },
  date_shift_options: {
    old_start_date: '',
    new_start_date: '',
    old_end_date: '',
    new_end_date: '',
    day_substitutions: [],
  },
}

const dateAdjustmentsWithSub: DateAdjustmentConfig = {
  adjust_dates: {
    enabled: false,
    operation: 'shift_dates',
  },
  date_shift_options: {
    old_start_date: '',
    new_start_date: '',
    old_end_date: '',
    new_end_date: '',
    day_substitutions: [{from: 0, id: 1, to: 0}],
  },
}

const setDateAdjustments: (cfg: DateAdjustmentConfig) => void = jest.fn()

describe('DateAdjustment', () => {
  afterEach(() => jest.clearAllMocks())

  it('Fill in with empty values the start and end date fileds', () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />,
    )
    expect(screen.getByLabelText('Select new beginning date').closest('input')?.value).toBe('')
    expect(screen.getByLabelText('Select new end date').closest('input')?.value).toBe('')
  })

  it('Renders proper date operation radio buttons', () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />,
    )
    expect(screen.getByRole('radio', {name: 'Shift dates', hidden: false})).toBeInTheDocument()
    expect(screen.getByRole('radio', {name: 'Remove dates', hidden: false})).toBeInTheDocument()
  })

  describe('Date fill in on initial data', () => {
    beforeEach(() => {
      fakeENV.setup({
        TIMEZONE: 'America/Detroit',
        CONTEXT_TIMEZONE: 'America/Detroit',
        LOCALE: 'en',
        FEATURES: {},
        MOMENT_LOCALE: 'en',
      })
      moment.tz.setDefault('UTC')
      configureAndRestoreLater({
        tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
        tzData: {
          'America/Detroit': detroit,
          'America/Chicago': chicago,
        },
        formats: getI18nFormats(),
        momentLocale: 'en',
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    const dateObject = '2024-08-08T08:00:00+00:00'
    const expectedDate = 'Aug 8, 2024 at 4am'
    const getComponent = (dateShiftOptionVariant: Partial<DateShifts>) => {
      return (
        <DateAdjustments
          dateAdjustmentConfig={{
            ...dateAdjustments,
            date_shift_options: {
              ...dateAdjustments.date_shift_options,
              ...dateShiftOptionVariant,
            },
          }}
          setDateAdjustments={setDateAdjustments}
        />
      )
    }

    const expectDateField = (dataCid: string, value: string) => {
      expect((screen.getByTestId(dataCid) as HTMLInputElement).value).toBe(value)
    }

    it('Fill in original beginning date with old_start_date', () => {
      render(getComponent({old_start_date: dateObject}))
      expectDateField('old_start_date', expectedDate)
    })

    it('Fill in original end date with old_end_date', () => {
      render(getComponent({old_end_date: dateObject}))
      expectDateField('old_end_date', expectedDate)
    })

    it('Fill in new beginning date with new_start_date', () => {
      render(getComponent({new_start_date: dateObject}))
      expectDateField('new_start_date', expectedDate)
    })

    it('Fill in new end date with new_end_date', () => {
      render(getComponent({new_end_date: dateObject}))
      expectDateField('new_end_date', expectedDate)
    })
  })

  it('Renders/hides date shifting UI when appropriate', async () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />,
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    expect(screen.getByLabelText('Select original beginning date')).toBeInTheDocument()
    expect(screen.getByLabelText('Select new beginning date')).toBeInTheDocument()
    expect(screen.getByLabelText('Select original end date')).toBeInTheDocument()
    expect(screen.getByLabelText('Select new end date')).toBeInTheDocument()
    await userEvent.click(screen.getByRole('radio', {name: 'Remove dates', hidden: false}))
    expect(screen.queryByLabelText('Select original beginning date')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Select new beginning date')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Select original end date')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Select new end date')).not.toBeInTheDocument()
  })

  it('Allows adding multiple weekday substitutions', async () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />,
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    await userEvent.click(screen.getByRole('button', {name: 'Add substitution', hidden: false}))
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustmentsWithSub)
  })

  it('Allows removing multiple weekday substitutions', async () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustmentsWithSub}
        setDateAdjustments={setDateAdjustments}
      />,
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    const remove_sub_button = screen.getByRole('button', {
      name: "Remove 'Sunday' to 'Sunday' from substitutes",
      hidden: false,
    })
    expect(remove_sub_button).toBeInTheDocument()
    await userEvent.click(remove_sub_button)
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustments)
  })

  describe('timeZoneFormMessages', () => {
    it('returns the correct localised date messages', () => {
      moment.tz.setDefault('America/Denver')

      configureAndRestoreLater({
        tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
        tzData: {
          'America/Chicago': chicago,
          'America/Detroit': detroit,
        },
        formats: getI18nFormats(),
      })

      const messages = timeZonedFormMessages(
        'America/Detroit',
        'America/Chicago',
        '2024-11-08T08:00:00+00:00',
      )

      render(
        <CanvasDateInput
          selectedDate="2024-11-08T08:00:00+00:00"
          onSelectedDateChange={() => {}}
          formatDate={jest.fn(date => date.toISOString())}
          interaction="enabled"
          messages={messages}
        />,
      )

      expect(screen.queryByText('Local: Nov 8, 2024 at 2am')).toBeInTheDocument()
      expect(screen.queryByText('Course: Nov 8, 2024 at 3am')).toBeInTheDocument()
    })
  })
})
