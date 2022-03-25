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
import {act} from '@testing-library/react'
import {renderConnected} from '../../../../__tests__/utils'
import {COURSE, PRIMARY_PACE} from '../../../../__tests__/fixtures'

import {ProjectedDates} from '../projected_dates'

const defaultProps = {
  coursePace: PRIMARY_PACE,
  assignments: 5,
  pacePublishing: false,
  paceWeeks: 8,
  projectedEndDate: '2021-12-01',
  blackoutDates: [],
  weekendsDisabled: false,
  setStartDate: () => {},
  compressDates: jest.fn(),
  uncompressDates: jest.fn(),
  onToggleHardEndDates: jest.fn(),
  showProjections: true
}

beforeEach(() => {
  window.ENV.VALID_DATE_RANGE = {
    end_at: {date: COURSE.end_at, date_context: 'course'},
    start_at: {date: COURSE.start_at, date_context: 'course'}
  }
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('ProjectedDates', () => {
  it('shows nothing when projections are hidden', () => {
    const {queryByRole} = renderConnected(
      <ProjectedDates {...defaultProps} showProjections={false} />
    )
    expect(queryByRole('combobox')).not.toBeInTheDocument()
  })

  it('shows projected start and end date when projections are shown', () => {
    const {getByRole} = renderConnected(<ProjectedDates {...defaultProps} />)
    const startDateInput = getByRole('combobox', {
      name: /^Start Date/
    }) as HTMLInputElement
    const endDateInput = getByRole('combobox', {
      name: /^End Date/
    }) as HTMLInputElement
    const specifiedEndDateCheckbox = getByRole('checkbox', {
      name: 'Require Completion by Specified End Date'
    })
    expect(startDateInput).toBeInTheDocument()
    expect(startDateInput.value).toBe('September 1, 2021')
    expect(endDateInput).toBeInTheDocument()
    expect(endDateInput.value).toBe('December 15, 2021')
    expect(specifiedEndDateCheckbox).toBeInTheDocument()
    expect(specifiedEndDateCheckbox.checked).toBeTruthy()
  })

  it('shows the number of assignments and weeks in the pace when projections are shown', () => {
    const {getByText} = renderConnected(<ProjectedDates {...defaultProps} />)
    expect(getByText('5 assignments')).toBeInTheDocument()
    expect(getByText('8 weeks')).toBeInTheDocument()
  })

  describe('start date messages', () => {
    it('shows normal help text', () => {
      const {getAllByText} = renderConnected(<ProjectedDates {...defaultProps} />)
      expect(getAllByText('Hypothetical student enrollment date').length).toBeTruthy()
    })

    it('shows error if start date is before course start date', () => {
      const pace = {...defaultProps.coursePace, start_date: '2021-08-01'}
      const {getByText} = renderConnected(<ProjectedDates {...defaultProps} coursePace={pace} />)
      expect(getByText('Date is before the course start date')).toBeInTheDocument()
    })

    it('shows error if start date is after specified end date', () => {
      const pace = {...defaultProps.coursePace, start_date: '2021-12-16'}
      const {getByText} = renderConnected(<ProjectedDates {...defaultProps} coursePace={pace} />)
      expect(getByText('Date is after the specified end date')).toBeInTheDocument()
    })

    it('copes with no course start date', () => {
      window.ENV.VALID_DATE_RANGE = {
        end_at: {date: null, date_context: 'course'},
        start_at: {date: null, date_context: 'course'}
      }
      const pace = {...defaultProps.coursePace, hard_end_dates: false}
      const {getAllByText} = renderConnected(
        <ProjectedDates {...defaultProps} coursePace={pace} projectedEndDate="2022-01-02" />
      )
      expect(getAllByText('Hypothetical student enrollment date').length).toBeTruthy()
    })
  })

  describe('end date messages', () => {
    it('shows course end date text', () => {
      const pace = {
        ...defaultProps.coursePace,
        hard_end_dates: false,
        start_sate: '2022-01-03',
        end_date: undefined
      }
      const {getAllByText, getByTestId} = renderConnected(
        <ProjectedDates {...defaultProps} coursePace={pace} />
      )
      expect(getAllByText('Required by course end date').length).toBeTruthy()
      // expect the course end date
      expect(getByTestId('coursepace-date-text').textContent).toStrictEqual('December 31, 2021')
    })

    it('shows term end date text', () => {
      window.ENV.VALID_DATE_RANGE = {
        end_at: {date: COURSE.end_at, date_context: 'term'},
        start_at: {date: COURSE.start_at, date_context: 'term'}
      }
      const pace = {
        ...defaultProps.coursePace,
        hard_end_dates: false,
        start_sate: '2022-01-03',
        end_date: undefined
      }
      const {getAllByText, getByTestId} = renderConnected(
        <ProjectedDates {...defaultProps} coursePace={pace} />
      )
      expect(getAllByText('Required by term end date').length).toBeTruthy()
      // expect the term end date
      expect(getByTestId('coursepace-date-text').textContent).toStrictEqual('December 31, 2021')
    })

    it('shows specified end date input', () => {
      const {getAllByText, getByDisplayValue} = renderConnected(
        <ProjectedDates {...defaultProps} />
      )
      expect(getAllByText('Required by specified end date').length).toBeTruthy()
      // expect the specified pace end date
      expect(getByDisplayValue('December 15, 2021')).toBeInTheDocument()
    })

    it('shows error if end date is before start date', () => {
      const pace = {...defaultProps.coursePace, start_date: '2021-08-01', end_date: '2021-07-31'}
      const {getByText} = renderConnected(<ProjectedDates {...defaultProps} coursePace={pace} />)
      expect(getByText('Date is before student enrollment date')).toBeInTheDocument()
    })

    it('shows error if end date is after course end date', () => {
      const d = new Date(ENV.VALID_DATE_RANGE.end_at.date)
      d.setDate(d.getDate() + 1)
      const pace = {...defaultProps.coursePace, end_date: d.toISOString()}
      const {getByText} = renderConnected(<ProjectedDates {...defaultProps} coursePace={pace} />)
      expect(getByText('Date is after the course end date')).toBeInTheDocument()
    })

    it('shows open-ended pace text', () => {
      window.ENV.VALID_DATE_RANGE = {
        end_at: {date: null, date_context: 'course'},
        start_at: {date: null, date_context: 'course'}
      }
      const pace = {
        ...defaultProps.coursePace,
        hard_end_dates: false,
        start_date: '2022-01-03',
        end_date: undefined
      }
      const {getAllByText, getByTestId} = renderConnected(
        <ProjectedDates {...defaultProps} coursePace={pace} />
      )
      expect(getAllByText('Hypothetical end date').length).toBeTruthy()
      // expect projectedEndDate in this case
      expect(getByTestId('coursepace-date-text').textContent).toStrictEqual('December 1, 2021')
    })
  })

  describe('date compression', () => {
    it('calls uncompressDates when start date allows enough days', () => {
      renderConnected(<ProjectedDates {...defaultProps} />)

      expect(defaultProps.uncompressDates).toHaveBeenCalled()
      expect(defaultProps.compressDates).not.toHaveBeenCalled()
    })

    it('calls compressDates if start date does not allow enough days before the specified end date', () => {
      const pp = {...defaultProps.coursePace}
      pp.end_date = '2021-09-05'
      renderConnected(<ProjectedDates {...defaultProps} coursePace={pp} />)

      expect(defaultProps.uncompressDates).not.toHaveBeenCalled()
      expect(defaultProps.compressDates).toHaveBeenCalled()
    })

    it('calls compressDates if start date does not allow enough days before the course end date', () => {
      // the course ends on 2021-12-31
      const pp = {...defaultProps.coursePace}
      pp.hard_end_dates = false
      pp.end_date = undefined
      const ped = '2022-01-01'
      renderConnected(<ProjectedDates {...defaultProps} coursePace={pp} projectedEndDate={ped} />)

      expect(defaultProps.uncompressDates).not.toHaveBeenCalled()
      expect(defaultProps.compressDates).toHaveBeenCalled()
    })

    it('calls compressDates when switching from course to student pace and squshing is necessary', () => {
      // the course ends on 2021-12-31
      const pp = {...defaultProps.pacePace}
      pp.hard_end_dates = false
      pp.end_date = undefined
      const ped = '2022-01-01'
      const {rerender} = renderConnected(
        <ProjectedDates {...defaultProps} pacePace={pp} projectedEndDate={ped} />
      )

      expect(defaultProps.compressDates).toHaveBeenCalledTimes(1)

      pp.context_id = '1'
      pp.context_type = 'Enrollment'
      rerender(<ProjectedDates {...defaultProps} pacePace={pp} projectedEndDate={ped} />)

      expect(defaultProps.compressDates).toHaveBeenCalledTimes(2)
    })
  })

  describe('specified end date checkbox', () => {
    it('toggles the setting when clicked', () => {
      const {getByRole} = renderConnected(<ProjectedDates {...defaultProps} />)
      const hardEndDatesToggle = getByRole('checkbox', {
        name: 'Require Completion by Specified End Date'
      })
      expect(hardEndDatesToggle).not.toBeDisabled()
      act(() => hardEndDatesToggle.click())
      expect(defaultProps.onToggleHardEndDates).toHaveBeenCalled()
    })

    it('is disabled while the pace is publishing', () => {
      const {getByRole} = renderConnected(<ProjectedDates {...defaultProps} pacePublishing />)
      const hardEndDatesToggle = getByRole('checkbox', {
        name: 'Require Completion by Specified End Date'
      })
      expect(hardEndDatesToggle).toBeDisabled()
    })
  })
})
