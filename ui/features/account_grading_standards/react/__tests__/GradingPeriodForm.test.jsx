/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import $ from 'jquery'
import {fireEvent, render, screen} from '@testing-library/react'
import chicago from 'timezone/America/Chicago'
import * as tz from '@instructure/moment-utils'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import GradingPeriodForm from '../GradingPeriodForm'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'

const onSave = jest.fn()
const onCancel = jest.fn()
const defaultProps = (props = {}) => {
  let period = {
    closeDate: new Date('2016-01-07T12:00:00Z'),
    endDate: new Date('2015-12-31T12:00:00Z'),
    id: '1401',
    startDate: new Date('2015-11-01T12:00:00Z'),
    title: 'Q1',
    weight: 30,
    ...props.period,
  }

  if (props.period === null) period = null

  return {
    disabled: false,
    weighted: true,
    onSave,
    onCancel,
    ...props,
    period,
  }
}
const renderGradingPeriodForm = (props = {}) => {
  const ref = React.createRef()
  const wrapper = render(<GradingPeriodForm {...defaultProps(props)} ref={ref} />)

  return {
    ...wrapper,
    ref,
  }
}
const getButton = label => screen.queryByRole('button', {name: new RegExp(`${label}`, 'i')})
const getDateTimeSuggestions = inputLabel => {
  const $input = screen.getByLabelText(inputLabel)
  let $parent = $input.parentElement

  while ($parent && !$parent.classList.contains('ic-Form-control')) {
    $parent = $parent.parentElement
  }

  return Array.from($parent.querySelectorAll('.datetime_suggest'))
}
const setDateInputValue = (label, value) => {
  const $input = screen.getByLabelText(label)

  fireEvent.change($input, {target: {value}})
}

describe('GradingPeriodForm', () => {
  beforeEach(() => {
    window.ENV = {CONTEXT_TIMEZONE: 'Etc/UTC', TIMEZONE: 'Etc/UTC'}
  })

  afterEach(() => {
    const datePickerElement = $('#ui-datepicker-div')

    datePickerElement.datepicker('destroy')
    datePickerElement.remove()
    jest.clearAllMocks()
  })

  describe('Title" input', () => {
    it('value is set to the grading period title for an existing grading period', () => {
      renderGradingPeriodForm()

      expect(screen.getByDisplayValue('Q1')).toBeInTheDocument()
    })
  })

  describe('"Start Date" input', () => {
    it('value is set to the grading period start date', () => {
      renderGradingPeriodForm()

      expect(screen.getByLabelText('Start Date')).toHaveValue('Nov 1, 2015, 12:00 PM')
    })

    it('does not alter the seconds value when emitting the new date', () => {
      const {ref} = renderGradingPeriodForm()

      setDateInputValue('Start Date', 'Dec 31, 2015 11pm')

      const startDate = tz.parse(ref.current.state.period.startDate)

      expect(tz.format(startDate, '%S')).toEqual('00')
    })

    describe('when local and server time are different', () => {
      beforeEach(() => {
        Object.assign(ENV, {CONTEXT_TIMEZONE: 'America/Chicago'})
        tzInTest.configureAndRestoreLater({
          tz: timezone('UTC'),
          tzData: {
            'America/Chicago': chicago,
          },
          formats: getI18nFormats(),
        })

        renderGradingPeriodForm()
      })

      afterEach(tzInTest.restore)

      it('shows both local and context time suggestions for start date', () => {
        expect(getDateTimeSuggestions('Start Date')).toHaveLength(2)
      })

      it('formats the start date for the local timezone', () => {
        const $suggestions = getDateTimeSuggestions('Start Date')

        // Local is GMT
        expect($suggestions[0]).toHaveTextContent('Local: Sun, Nov 1, 2015, 12:00 PM')
      })

      it('formats the start date for the context timezone', () => {
        const $suggestions = getDateTimeSuggestions('Start Date')

        // Course is in Chicago
        expect($suggestions[1]).toHaveTextContent('Account: Sun, Nov 1, 2015, 6:00 AM')
      })
    })
  })

  describe('End Date" input', () => {
    it('value is set to the grading period end date', () => {
      renderGradingPeriodForm()

      expect(screen.getByLabelText('End Date')).toHaveValue('Dec 31, 2015, 12:00 PM')
    })

    it('sets the seconds value to 59 when emitting the updated date', () => {
      const {ref} = renderGradingPeriodForm()

      setDateInputValue('End Date', 'Dec 31, 2015, 11:00 PM')

      const endDate = tz.parse(ref.current.state.period.endDate)

      expect(tz.format(endDate, '%S')).toEqual('59')
    })

    describe('when local and server time are different', () => {
      beforeEach(() => {
        Object.assign(ENV, {CONTEXT_TIMEZONE: 'America/Chicago'})
        tzInTest.configureAndRestoreLater({
          tz: timezone('UTC'),
          tzData: {
            'America/Chicago': chicago,
          },
          formats: getI18nFormats(),
        })

        renderGradingPeriodForm()
      })

      afterEach(tzInTest.restore)

      it('shows both local and context time suggestions for end date', () => {
        expect(getDateTimeSuggestions('End Date')).toHaveLength(2)
      })

      it('formats the end date for the local timezone', () => {
        const $suggestions = getDateTimeSuggestions('End Date')

        // Local is GMT
        expect($suggestions[0]).toHaveTextContent('Local: Thu, Dec 31, 2015, 12:00 PM')
      })

      it('formats the end date for the context timezone', () => {
        const $suggestions = getDateTimeSuggestions('End Date')

        // Course is in Chicago
        expect($suggestions[1]).toHaveTextContent('Account: Thu, Dec 31, 2015, 6:00 AM')
      })
    })
  })

  describe('Close Date" input', () => {
    it('value is set to the grading period close date for an existing grading period', () => {
      renderGradingPeriodForm()

      expect(screen.getByLabelText('Close Date')).toHaveValue('Jan 7, 2016, 12:00 PM')
    })

    it('updates to match "End Date" when not previously set and "End Date" changes', () => {
      renderGradingPeriodForm({
        period: null,
      })

      setDateInputValue('End Date', 'Dec 31, 2015 12pm')

      expect(screen.getByLabelText('Close Date')).toHaveValue('Dec 31, 2015, 12:00 PM')
    })

    it('updates to match "End Date" when currently matching "End Date" and "End Date" changes', () => {
      const closeDate = defaultProps().period.endDate

      renderGradingPeriodForm({
        period: {
          closeDate,
        },
      })

      setDateInputValue('End Date', 'Dec 31, 2015 12pm')

      expect(screen.getByLabelText('Close Date')).toHaveValue('Dec 31, 2015, 12:00 PM')
    })

    it('does not update when not set equal to "End Date" and "End Date" changes', () => {
      renderGradingPeriodForm()

      setDateInputValue('End Date', 'Dec 31, 2015 12pm')

      setDateInputValue('Close Date', 'Jan 7, 2016 12pm')
    })

    it('does not update when "End Date" changes to match and changes again', async () => {
      renderGradingPeriodForm()

      setDateInputValue('End Date', 'Jan 7, 2016 12pm')
      setDateInputValue('End Date', 'Dec 31, 2015 12pm')

      await new Promise(resolve => setTimeout(resolve, 0))

      expect(screen.getByLabelText('Close Date')).toHaveValue('Jan 7, 2016, 12:00 PM')
    })

    it('updates to match "End Date" after being cleared and "End Date" changes', async () => {
      renderGradingPeriodForm()

      setDateInputValue('Close Date', '')
      setDateInputValue('End Date', 'Dec 31, 2015 12:34')

      await new Promise(resolve => setTimeout(resolve, 0))

      expect(screen.getByLabelText('Close Date')).toHaveValue('Dec 31, 2015, 12:34 PM')
    })

    it('sets the seconds value to 59 when emitting the updated date', () => {
      const {ref} = renderGradingPeriodForm()

      setDateInputValue('Close Date', 'Dec 31, 2015 11pm')

      const closeDate = tz.parse(ref.current.state.period.closeDate)

      expect(tz.format(closeDate, '%S')).toEqual('59')
    })

    describe('when local and server time are different', () => {
      beforeEach(() => {
        Object.assign(ENV, {CONTEXT_TIMEZONE: 'America/Chicago'})
        tzInTest.configureAndRestoreLater({
          tz: timezone('UTC'),
          tzData: {
            'America/Chicago': chicago,
          },
          formats: getI18nFormats(),
        })

        renderGradingPeriodForm()
      })

      afterEach(tzInTest.restore)

      it('shows both local and context time suggestions for close date', () => {
        expect(getDateTimeSuggestions('Close Date')).toHaveLength(2)
      })

      it('formats the close date for the local timezone', () => {
        const $suggestions = getDateTimeSuggestions('Close Date')

        // Local is GMT
        expect($suggestions[0]).toHaveTextContent('Local: Thu, Jan 7, 2016, 12:00 PM')
      })

      it('formats the close date for the context timezone', () => {
        const $suggestions = getDateTimeSuggestions('Close Date')

        // Course is in Chicago
        expect($suggestions[1]).toHaveTextContent('Account: Thu, Jan 7, 2016, 6:00 AM')
      })
    })
  })

  describe('"Weight" input', () => {
    it('is present when the grading period set is weighted', () => {
      renderGradingPeriodForm()

      expect(screen.getByLabelText('Grading Period Weight')).toBeInTheDocument()
    })

    it('is absent when the grading period set is not weighted', () => {
      renderGradingPeriodForm({
        weighted: false,
      })

      expect(screen.queryByLabelText('Grading Period Weight')).not.toBeInTheDocument()
    })

    it('value is set to the grading period weight for an existing grading period', () => {
      renderGradingPeriodForm()

      expect(screen.getByDisplayValue('30')).toBeInTheDocument()
    })
  })

  describe('"Save" button', () => {
    const getSavedGradingPeriod = () => onSave.mock.calls[0][0]

    it('calls the onSave callback when clicked', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(onSave).toHaveBeenCalledTimes(1)
    })

    it('includes the grading period id when updating an existing grading period', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().id).toEqual('1401')
    })

    it('excludes the grading period id when creating a new grading period', () => {
      renderGradingPeriodForm({
        period: {
          id: undefined,
        },
      })

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().id).toBeUndefined()
    })

    it('includes the grading period title', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().title).toEqual('Q1')
    })

    it('includes updates to the grading period title', () => {
      renderGradingPeriodForm()

      fireEvent.change(screen.getByTitle('Grading Period Title'), {
        target: {value: 'Quarter 1'},
      })
      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().title).toEqual('Quarter 1')
    })

    it('includes the grading period start date', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().startDate).toEqual(new Date('2015-11-01T12:00:00Z'))
    })

    it('includes updates to the grading period start date', () => {
      renderGradingPeriodForm()

      setDateInputValue('Start Date', 'Nov 2, 2015 12pm')
      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().startDate).toEqual(new Date('2015-11-02T12:00:00Z'))
    })

    it('includes the grading period end date', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().endDate).toEqual(new Date('2015-12-31T12:00:00Z'))
    })

    it('includes updates to the grading period end date', () => {
      renderGradingPeriodForm()
      setDateInputValue('End Date', 'Dec 30, 2015 12pm')

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().endDate).toEqual(new Date('2015-12-30T12:00:59Z'))
    })

    it('includes the grading period close date', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().closeDate).toEqual(new Date('2016-01-07T12:00:00Z'))
    })

    it('includes updates to the grading period close date', () => {
      renderGradingPeriodForm()
      setDateInputValue('Close Date', 'Dec 31, 2015 12pm')

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().closeDate).toEqual(new Date('2015-12-31T12:00:59Z'))
    })

    it('includes the grading period weight', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().weight).toEqual(30)
    })

    it('includes updates to the grading period weight', () => {
      renderGradingPeriodForm()

      fireEvent.change(screen.getByLabelText('Grading Period Weight'), {
        target: {value: '25'},
      })
      fireEvent.click(screen.getByText('Save'))

      expect(getSavedGradingPeriod().weight).toEqual(25)
    })

    it('is disabled when the form is disabled', () => {
      renderGradingPeriodForm({
        disabled: true,
      })

      expect(getButton('Save Grading Period')).toBeDisabled()
    })

    it('is not disabled when the form is not disabled', () => {
      renderGradingPeriodForm()

      expect(getButton('Save Grading Period')).not.toBeDisabled()
    })
  })

  describe('"Cancel" button', () => {
    it('calls the onCancel callback when clicked', () => {
      renderGradingPeriodForm()

      fireEvent.click(screen.getByText('Cancel'))

      expect(onCancel).toHaveBeenCalledTimes(1)
    })

    it('is disabled when the form is disabled', () => {
      renderGradingPeriodForm({
        disabled: true,
      })

      expect(getButton('Cancel')).toBeDisabled()
    })

    it('is not disabled when the form is not disabled', () => {
      renderGradingPeriodForm()

      expect(getButton('Cancel')).not.toBeDisabled()
    })
  })
})
