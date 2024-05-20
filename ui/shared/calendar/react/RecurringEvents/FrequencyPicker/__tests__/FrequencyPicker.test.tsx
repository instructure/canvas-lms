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
import {render, screen, waitFor} from '@testing-library/react'
import FrequencyPicker, {
  FrequencyPickerErrorBoundary,
  type FrequencyPickerProps,
} from '../FrequencyPicker'
import userEvent from '@testing-library/user-event'
import type {FrequencyOptionValue, UnknownSubset} from '../../types'

const defaultTZ = 'Asia/Tokyo'

const defaultProps = (overrides: UnknownSubset<FrequencyPickerProps> = {}) => {
  const tz = overrides.timezone || defaultTZ
  return {
    date: moment.tz('2001-04-12', tz).toDate(), // a Thursday
    interaction: 'enabled' as const,
    initialFrequency: 'weekly-day' as FrequencyOptionValue,
    locale: 'en',
    timezone: tz,
    onChange: jest.fn(),
    ...overrides,
  }
}

const selectOption = async (buttonName: RegExp, optionName: RegExp) => {
  await userEvent.click(
    screen.getByRole('combobox', {
      name: buttonName,
    })
  )
  await userEvent.click(
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
    for (const TZ of ['Asia/Tokyo', 'Europe/Budapest', 'America/New_York']) {
      // eslint-disable-next-line jest/valid-describe
      describe(`in timezone ${TZ}`, () => {
        it('with the given initial frequency', () => {
          const props = defaultProps({timezone: TZ})
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

        it('with open modal with the current selected frequency', async () => {
          const props = defaultProps({timezone: TZ})
          const {getByText, getByDisplayValue} = render(<FrequencyPicker {...props} />)
          await selectOption(/frequency/i, /weekly on thursday/i)
          await selectOption(/frequency/i, /custom/i)
          const modal = getByText('Custom Repeating Event')
          expect(modal).toBeInTheDocument()

          const thursdayCheckbox = getByDisplayValue('TH')
          expect(thursdayCheckbox).toBeInTheDocument()
          expect(thursdayCheckbox).toBeChecked()
        })

        it('the modal with the given custom rrule', async () => {
          const props = defaultProps({timezone: TZ})
          const {getByText, getByDisplayValue} = render(
            <FrequencyPicker
              {...props}
              initialFrequency="saved-custom"
              rrule="FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE;COUNT=5"
            />
          )
          expect(getByDisplayValue('Weekly on Mon, Wed, 5 times')).toBeInTheDocument()

          await selectOption(/frequency/i, /Weekly on Mon, Wed, 5 times/)
          await selectOption(/frequency/i, /custom/i)
          const modal = getByText('Custom Repeating Event')
          expect(modal).toBeInTheDocument()
          expect(getByDisplayValue('Week')).toBeInTheDocument()
          expect(getByDisplayValue('MO')).toBeChecked()
          expect(getByDisplayValue('WE')).toBeChecked()
          expect(getByDisplayValue('5')).toBeInTheDocument()
        })
      })
    }

    it('disabled when interaction is disabled', () => {
      const props = defaultProps({interaction: 'disabled'})
      const {getByDisplayValue} = render(<FrequencyPicker {...props} />)
      expect(getByDisplayValue('Weekly on Thursday')).toBeDisabled()
    })

    it('with custom frequency opens the modal', () => {
      const props = defaultProps()
      const {getByText} = render(<FrequencyPicker {...props} initialFrequency="custom" />)
      const modal = getByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
    })

    it('returns focus to the frequency picker button when the modal is closed', async () => {
      const user = userEvent.setup({delay: null})
      const props = defaultProps()
      const {getByText, getByRole, getByLabelText} = render(<FrequencyPicker {...props} />)
      await selectOption(/frequency/i, /custom/i)
      const modal = getByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
      await user.click(getByRole('button', {name: /cancel/i}))
      await waitFor(() => expect(getByLabelText('Frequency')).toHaveFocus())
    })

    it('sets width to auto', () => {
      const props = defaultProps()
      const {container} = render(<FrequencyPicker {...props} width="auto" />)
      expect(container.querySelector('label')).toHaveStyle({width: 'auto'})
    })

    it('sets width to fit', () => {
      const props = defaultProps()
      const {container} = render(<FrequencyPicker {...props} width="fit" />)
      expect(container.querySelector('label')?.getAttribute('style')).toMatch(/width: \d+px/)
    })

    it('retains auto width after selecting a custom frequency', async () => {
      const props = defaultProps({width: 'auto'})
      const {container, getByText, getByRole} = render(<FrequencyPicker {...props} />)
      await selectOption(/frequency/i, /custom/i)
      const modal = getByText('Custom Repeating Event')
      expect(modal).toBeInTheDocument()
      await userEvent.click(getByRole('button', {name: /done/i}))
      expect(container.querySelector('label')).toHaveStyle({width: 'auto'})
    })

    // it's really annoying that I can't supress the exception being logged to the console
    // even though it's being caught by the error boundary
    describe('with errors', () => {
      it('the error boundary fallback when enabled with no date', () => {
        const props = defaultProps({date: undefined})
        const {getByText} = render(
          <FrequencyPickerErrorBoundary>
            <FrequencyPicker {...props} />
          </FrequencyPickerErrorBoundary>
        )
        expect(getByText('There was an error rendering.')).toBeInTheDocument()
        expect(
          getByText('FrequencyPicker: date is required when interaction is enabled')
        ).toBeInTheDocument()
      })

      it('the error boundary fallback with no date and a recurring frequency', () => {
        const props = defaultProps({
          date: undefined,
          interaction: 'disabled',
          initialFrequency: 'weekly-day',
        })
        const {getByText} = render(
          <FrequencyPickerErrorBoundary>
            <FrequencyPicker {...props} />
          </FrequencyPickerErrorBoundary>
        )
        expect(getByText('There was an error rendering.')).toBeInTheDocument()
        expect(
          getByText('FrequencyPicker: date is required when initialFrequency is not not-repeat')
        ).toBeInTheDocument()
      })
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

    it('when user changes frequency', async () => {
      const props = defaultProps()
      render(<FrequencyPicker {...props} />)
      await selectOption(/frequency/i, /annually on april 12/i)
      expect(props.onChange).toHaveBeenCalledWith(
        'annually',
        'FREQ=YEARLY;BYMONTH=04;BYMONTHDAY=12;INTERVAL=1;COUNT=5'
      )
    })
  })
})
