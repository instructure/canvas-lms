/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'

import {BLACKOUT_DATES, PRIMARY_PLAN, STUDENT_PLAN} from '../../../../__tests__/fixtures'

import {PacePlanDateSelector, PacePlanDateSelectorProps} from '../date_selector'
import moment from 'moment'

const setStartDate = jest.fn()
const setEndDate = jest.fn()

afterEach(() => {
  jest.clearAllMocks()
})

describe('PacePlansDateSelector', () => {
  describe('of start type', () => {
    const defaultProps: PacePlanDateSelectorProps = {
      type: 'start',
      blackoutDates: BLACKOUT_DATES,
      setStartDate,
      setEndDate,
      pacePlan: PRIMARY_PLAN,
      planPublishing: false
    }

    it('renders an editable "Projected Start Date" selector for primary pace plans', () => {
      const {getByLabelText} = render(<PacePlanDateSelector {...defaultProps} />)
      const startDateInput = getByLabelText('Projected Start Date') as HTMLInputElement
      expect(startDateInput).toBeInTheDocument()
      expect(startDateInput.value).toBe('September 1, 2021')

      fireEvent.change(startDateInput, {target: {value: 'September 3, 2021'}})
      fireEvent.blur(startDateInput)
      expect(setStartDate).toHaveBeenCalledWith('2021-09-03')
    })

    it('renders read-only "Start Date" text for student pace plans', () => {
      const {getByText, queryByRole} = render(
        <PacePlanDateSelector {...defaultProps} pacePlan={STUDENT_PLAN} />
      )
      expect(getByText('Start Date')).toBeInTheDocument()
      expect(getByText('October 1, 2021')).toBeInTheDocument()
      expect(queryByRole('combobox')).not.toBeInTheDocument()
    })

    it('displays an error when weekends are disallowed and the date is on a weekend', () => {
      const pacePlan = {...defaultProps.pacePlan, start_date: 'September 4, 2021'}
      const {getByText} = render(
        <PacePlanDateSelector {...defaultProps} pacePlan={pacePlan} weekendsDisabled />
      )

      expect(
        getByText('The selected date is on a weekend. This pace plan skips weekends.')
      ).toBeInTheDocument()
    })

    it('displays an error when the date is on a blackout date', () => {
      const pacePlan = {...defaultProps.pacePlan, start_date: 'September 4, 2021'}
      const blackoutDates = [
        {
          event_title: 'Student Break',
          start_date: moment('September 2, 2021'),
          end_date: moment('September 10, 2021')
        }
      ]
      const {getByText} = render(
        <PacePlanDateSelector {...defaultProps} pacePlan={pacePlan} blackoutDates={blackoutDates} />
      )

      expect(getByText('The selected date is on a blackout day.')).toBeInTheDocument()
    })

    it('displays an error when the date is after the end date', () => {
      const pacePlan = {
        ...defaultProps.pacePlan,
        start_date: 'September 4, 2021',
        end_date: 'September 2, 2021'
      }
      const {getByText} = render(<PacePlanDateSelector {...defaultProps} pacePlan={pacePlan} />)

      expect(
        getByText('The start date for the pace plan must be after the end date.')
      ).toBeInTheDocument()
    })

    it('renders as disabled while publishing', () => {
      const {getByLabelText} = render(<PacePlanDateSelector {...defaultProps} planPublishing />)
      const startDateInput = getByLabelText('Projected Start Date') as HTMLInputElement

      expect(startDateInput).toBeDisabled()
    })
  })

  describe('of end type', () => {
    const defaultProps: PacePlanDateSelectorProps = {
      type: 'end',
      blackoutDates: BLACKOUT_DATES,
      pacePlan: PRIMARY_PLAN,
      planPublishing: false,
      projectedEndDate: '2021-11-03',
      setStartDate,
      setEndDate
    }

    it('renders read-only "Projected End Date" text for primary pace plans', () => {
      const {getByText, queryByRole} = render(<PacePlanDateSelector {...defaultProps} />)
      expect(getByText('Projected End Date')).toBeInTheDocument()
      expect(getByText('November 3, 2021')).toBeInTheDocument()
      expect(queryByRole('combobox')).not.toBeInTheDocument()
    })

    it('renders read-only "End Date" text for student pace plans', () => {
      const {getByText, queryByRole} = render(
        <PacePlanDateSelector
          {...defaultProps}
          projectedEndDate="2021-10-15"
          pacePlan={STUDENT_PLAN}
        />
      )
      expect(getByText('End Date')).toBeInTheDocument()
      expect(getByText('October 15, 2021')).toBeInTheDocument()
      expect(queryByRole('combobox')).not.toBeInTheDocument()
    })
  })
})
