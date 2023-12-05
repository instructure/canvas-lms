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
import {
  PRIMARY_PACE,
  STUDENT_PACE,
  PACE_CONTEXTS_DEFAULT_STATE,
  PACE_CONTEXTS_STUDENTS_RESPONSE,
} from '../../../__tests__/fixtures'

import PaceModalStats from '../stats'
import type {CoursePace, ResponsiveSizes} from 'features/course_paces/react/types'
import {render} from '@testing-library/react'

const defaultProps = {
  coursePace: PRIMARY_PACE,
  assignments: 5,
  paceDuration: {weeks: 2, days: 3},
  projectedEndDate: '2021-12-01',
  plannedEndDate: '2022-06-01',
  blackoutDates: [],
  weekendsDisabled: false,
  compression: 0,
  setStartDate: () => {},
  compressDates: jest.fn(),
  uncompressDates: jest.fn(),
  responsiveSize: 'large' as ResponsiveSizes,
  appliedPace: PACE_CONTEXTS_DEFAULT_STATE.selectedContext?.applied_pace!,
}

describe('pace modal stats', () => {
  it('shows course start and end date when given', () => {
    const {getByText, getByTestId} = render(<PaceModalStats {...defaultProps} />)

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('Determined by course start date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('Determined by course end date')).toBeInTheDocument()

    expect(getByTestId('colored-assignments-section').textContent).toBe(
      `Assignments${defaultProps.assignments}`
    )
    expect(getByTestId('colored-duration-section').textContent).toBe(
      `Time to complete${defaultProps.paceDuration.weeks} weeks, ${defaultProps.paceDuration.days} days`
    )
  })

  it('shows term start and end date when given', () => {
    const cpace: CoursePace = {
      ...defaultProps.coursePace,
      start_date_context: 'term',
      end_date_context: 'term',
    }
    const {getByText, getByTestId} = render(<PaceModalStats {...defaultProps} coursePace={cpace} />)

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('Determined by course start date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('Determined by course end date')).toBeInTheDocument()

    expect(getByTestId('colored-assignments-section').textContent).toBe(
      `Assignments${defaultProps.assignments}`
    )
    expect(getByTestId('colored-duration-section').textContent).toBe(
      `Time to complete${defaultProps.paceDuration.weeks} weeks, ${defaultProps.paceDuration.days} days`
    )
  })

  it('shows student enrollment dates when given', () => {
    const {getByText, getByTestId} = render(
      <PaceModalStats
        {...defaultProps}
        coursePace={STUDENT_PACE}
        appliedPace={PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[0]?.applied_pace!}
      />
    )

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('Student enrollment date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('Student enrollment date')).toBeInTheDocument()

    expect(getByTestId('colored-assignments-section').textContent).toBe(
      `Assignments${defaultProps.assignments}`
    )
    expect(getByTestId('colored-duration-section').textContent).toBe(
      `Time to complete${defaultProps.paceDuration.weeks} weeks, ${defaultProps.paceDuration.days} days`
    )
  })

  it("shows not specified end if start date is all that's given", () => {
    const cpace = {...defaultProps.coursePace, end_date: null}

    const {getByTestId, getByText} = render(<PaceModalStats {...defaultProps} coursePace={cpace} />)

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    const end = getByTestId('coursepace-end-date')
    expect(within(end).getByText(/Not Specified/)).toBeInTheDocument()
    expect(getByTestId('colored-assignments-section').textContent).toBe(
      `Assignments${defaultProps.assignments}`
    )
    expect(getByTestId('colored-duration-section').textContent).toBe(
      `Time to complete${defaultProps.paceDuration.weeks} weeks, ${defaultProps.paceDuration.days} days`
    )
  })

  it('captions the end date to match the start', () => {
    const cpace: CoursePace = {...defaultProps.coursePace, end_date: null, end_date_context: 'term'}

    const {getByTestId, getByText} = render(<PaceModalStats {...defaultProps} coursePace={cpace} />)

    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('End Date')).toBeInTheDocument()
    const end = getByTestId('coursepace-end-date')
    expect(within(end).getByText(/Not Specified/)).toBeInTheDocument()
    expect(within(end).getByText('Determined by course pace')).toBeInTheDocument()

    expect(getByTestId('colored-assignments-section').textContent).toBe(
      `Assignments${defaultProps.assignments}`
    )
    expect(getByTestId('colored-duration-section').textContent).toBe(
      `Time to complete${defaultProps.paceDuration.weeks} weeks, ${defaultProps.paceDuration.days} days`
    )
  })

  it('uncompresses dates of projectedEndDate is before pace end_date', () => {
    render(<PaceModalStats {...defaultProps} />)
    expect(defaultProps.compressDates).not.toHaveBeenCalled()
    expect(defaultProps.uncompressDates).toHaveBeenCalled()
  })

  describe('with course_paces_for_students enabled', () => {
    beforeAll(() => {
      window.ENV.FEATURES = {course_paces_for_students: true}
    })

    it("shows course end date for student if start date is all that's given", () => {
      const cpace = {...STUDENT_PACE, end_date: null}
      const {getByTestId, getByText} = render(
        <PaceModalStats {...defaultProps} coursePace={cpace} />
      )

      expect(getByText('Start Date')).toBeInTheDocument()
      expect(getByText('End Date')).toBeInTheDocument()
      const end = getByTestId('coursepace-end-date')
      expect(within(end).getByText('Wed, Jun 1, 2022')).toBeInTheDocument()
    })
  })
})
