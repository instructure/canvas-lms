// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {within} from '@testing-library/dom'
import {renderConnected} from '../../../../__tests__/utils'
import {PRIMARY_PACE, STUDENT_PACE} from '../../../../__tests__/fixtures'

import {ProjectedDates} from '../projected_dates'

const defaultProps = {
  coursePace: PRIMARY_PACE, // 2021-09-01 -> 2021-12-15
  assignments: 5,
  paceDuration: {weeks: 2, days: 3},
  projectedEndDate: '2021-12-01',
  blackoutDates: [],
  weekendsDisabled: false,
  compression: 0,
  setStartDate: () => {},
  compressDates: jest.fn(),
  uncompressDates: jest.fn(),
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('ProjectedDates', () => {
  it('shows course start and end date when given', () => {
    const {getByText} = renderConnected(<ProjectedDates {...defaultProps} />)

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('Determined by course start date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('Determined by course end date')).toBeInTheDocument()
    expect(getByText(/\d+ assignments/)).toBeInTheDocument()
    expect(getByText(/\d+ weeks/)).toBeInTheDocument()
    expect(getByText('Dates shown in course time zone')).toBeInTheDocument()
  })

  it('shows term start and end date when given', () => {
    const cpace = {...defaultProps.coursePace, start_date_context: 'term', end_date_context: 'term'}
    const {getByText} = renderConnected(<ProjectedDates {...defaultProps} coursePace={cpace} />)

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('Determined by course start date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('Determined by course end date')).toBeInTheDocument()
    expect(getByText(/\d+ assignments/)).toBeInTheDocument()
    expect(getByText(/\d+ weeks/)).toBeInTheDocument()
    expect(getByText('Dates shown in course time zone')).toBeInTheDocument()
  })

  it('shows student enrollment dates when given', () => {
    const {getByText} = renderConnected(
      <ProjectedDates {...defaultProps} coursePace={STUDENT_PACE} />
    )

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('Student enrollment date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('Determined by course pace')).toBeInTheDocument()
    expect(getByText(/2 weeks 3 days/)).toBeInTheDocument()
    expect(getByText(/\d+ weeks/)).toBeInTheDocument()
    expect(getByText('Dates shown in course time zone')).toBeInTheDocument()
  })

  // this can't happen any more
  it('shows no dates for a course with no start and end dates', () => {
    const cpace = {...defaultProps.coursePace, start_date: null, end_date: null}
    const {queryByText} = renderConnected(<ProjectedDates {...defaultProps} coursePace={cpace} />)

    expect(queryByText('Start Date')).not.toBeInTheDocument()
    expect(queryByText('End Date')).not.toBeInTheDocument()
    expect(queryByText(/2 weeks 3 days/)).toBeInTheDocument()
    expect(queryByText(/\d+ weeks/)).toBeInTheDocument()
    expect(queryByText('Dates shown in course time zone')).toBeInTheDocument()
  })

  it("shows not specified end if start date is all that's given", () => {
    const cpace = {...defaultProps.coursePace, end_date: null}

    const {getByTestId, getByText} = renderConnected(
      <ProjectedDates {...defaultProps} coursePace={cpace} />
    )

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    const end = getByTestId('coursepace-end-date')
    expect(within(end).getByText(/Not Specified/)).toBeInTheDocument()
    expect(getByText(/2 weeks 3 days/)).toBeInTheDocument()
    expect(getByText(/\d+ weeks/)).toBeInTheDocument()
    expect(getByText('Dates shown in course time zone')).toBeInTheDocument()
  })

  it('captions the end date to match the start', () => {
    const cpace = {...defaultProps.coursePace, end_date: null, end_date_context: 'term'}

    const {getByTestId, getByText} = renderConnected(
      <ProjectedDates {...defaultProps} coursePace={cpace} />
    )

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    const end = getByTestId('coursepace-end-date')
    expect(within(end).getByText(/Not Specified/)).toBeInTheDocument()
    expect(within(end).getByText('Determined by course end date')).toBeInTheDocument()
    expect(getByText(/\d+ assignments/)).toBeInTheDocument()
    expect(getByText(/\d+ weeks/)).toBeInTheDocument()
    expect(getByText('Dates shown in course time zone')).toBeInTheDocument()
  })

  it('compresses dates if projectedEndDate is after pace end_date', () => {
    renderConnected(
      <ProjectedDates {...defaultProps} projectedEndDate="2021-12-17" compression={1000} />
    )
    expect(defaultProps.compressDates).toHaveBeenCalled()
    expect(defaultProps.uncompressDates).not.toHaveBeenCalled()
  })

  it('uncompresses dates of projectedEndDate is before pace end_date', () => {
    renderConnected(<ProjectedDates {...defaultProps} />)
    expect(defaultProps.compressDates).not.toHaveBeenCalled()
    expect(defaultProps.uncompressDates).toHaveBeenCalled()
  })
})
