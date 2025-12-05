/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {screen, fireEvent} from '@testing-library/react'
import {renderConnected} from '../../../__tests__/utils'
import '@testing-library/jest-dom'
import TimeSelection from '../TimeSelection'
import {PRIMARY_PACE, STUDENT_PACE} from '../../../__tests__/fixtures'
import {CoursePace, Pace} from 'features/course_paces/react/types'
import keycode from 'keycode'
import fakeENV from '@canvas/test-utils/fakeENV'

const responsiveSize = 'small'

const appliedPace: Pace = {
  name: 'LS3432',
  type: 'Course',
  duration: 6,
  last_modified: '2022-10-17T23:12:24Z',
}

const coursePace: CoursePace = {
  ...PRIMARY_PACE,
  start_date: '2021-09-01',
  time_to_complete_calendar_days: 90,
  end_date_context: 'hypothetical',
}

describe('Pace Modal TimeSelection', () => {
  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        course_pace_time_selection: true,
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('displays the correct start date', () => {
    renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    expect(screen.getByLabelText('Start Date')).toHaveValue('September 1, 2021')
  })

  it('displays the correct end date from PRIMARY_PACE.end_date', () => {
    renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    expect(screen.getByLabelText('End Date')).toHaveValue('November 30, 2021')
  })

  it('updates the end date when incrementing weeks', () => {
    const {getByTestId} = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    const weeksInput = getByTestId('weeks-number-input')
    fireEvent.keyDown(weeksInput, {keyCode: keycode.codes.up})

    expect(screen.getByLabelText('End Date')).toHaveValue('December 7, 2021')
  })

  it('updates the end date when decrementing weeks', () => {
    const {getByTestId} = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    const weeksInput = getByTestId('weeks-number-input')
    fireEvent.keyDown(weeksInput, {keyCode: keycode.codes.down})

    expect(screen.getByLabelText('End Date')).toHaveValue('November 23, 2021')
  })

  it('updates the end date when incrementing days', () => {
    const {getByTestId} = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    const weeksInput = getByTestId('days-number-input')
    fireEvent.keyDown(weeksInput, {keyCode: keycode.codes.up})

    expect(screen.getByLabelText('End Date')).toHaveValue('December 1, 2021')
  })

  it('updates the end date when decrementing days', () => {
    const {getByTestId} = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    const weeksInput = getByTestId('days-number-input')
    fireEvent.keyDown(weeksInput, {keyCode: keycode.codes.down})

    expect(screen.getByLabelText('End Date')).toHaveValue('November 29, 2021')
  })

  it('updates time to complete when start date is changed', () => {
    const {getByTestId} = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    const dateText = '2021-09-16'
    const startDateInput = getByTestId('start-date-input')

    fireEvent.change(startDateInput, {target: {value: dateText}})
    fireEvent.blur(startDateInput)

    const weeksInput = getByTestId('weeks-number-input')

    expect(weeksInput).toHaveValue(10)
  })

  it('updates time to complete when end date is changed', () => {
    const {getByTestId} = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )
    const dateText = '2021-12-23'
    const endDateInput = getByTestId('end-date-input')

    fireEvent.change(endDateInput, {target: {value: dateText}})
    fireEvent.blur(endDateInput)

    const weeksInput = getByTestId('weeks-number-input')

    expect(weeksInput).toHaveValue(16)
  })

  it('Start date input is not available for Student Pace', () => {
    const {queryByTestId} = renderConnected(
      <TimeSelection
        coursePace={STUDENT_PACE}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )

    const startDateInput = queryByTestId('start-date-input')

    expect(startDateInput).not.toBeInTheDocument()
  })

  it('Start date Label is shown for Student Pace', () => {
    const {queryByTestId} = renderConnected(
      <TimeSelection
        coursePace={STUDENT_PACE}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />,
    )

    const startDateLabel = queryByTestId('start-date-label')

    expect(startDateLabel).not.toBeInTheDocument()
  })

  describe('End Date Behavior', () => {
    it('displays end date from course/section for enrollment pace', () => {
      const enrollmentPaceWithCourseEnd: CoursePace = {
        ...STUDENT_PACE,
        end_date: '2021-11-15',
        end_date_context: 'course',
      }

      renderConnected(
        <TimeSelection
          coursePace={enrollmentPaceWithCourseEnd}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      expect(screen.getByTestId('end-date-readonly')).toHaveTextContent('November 15, 2021')
    })

    it('displays end date caption "Determined by course end date" for enrollment pace with course end date', () => {
      const enrollmentPaceWithCourseEnd: CoursePace = {
        ...STUDENT_PACE,
        end_date: '2021-11-15',
        end_date_context: 'course',
      }
      const appliedCourse = {...appliedPace, type: 'Course'}

      const {container} = renderConnected(
        <TimeSelection
          coursePace={enrollmentPaceWithCourseEnd}
          appliedPace={appliedCourse as Pace}
          responsiveSize={responsiveSize}
        />,
      )

      expect(container).toHaveTextContent('Determined by course end date')
    })

    it('displays end date caption "Determined by section end date" for enrollment pace with section end date', () => {
      const enrollmentPaceWithSectionEnd: CoursePace = {
        ...STUDENT_PACE,
        end_date: '2021-11-15',
        end_date_context: 'term',
      }
      const appliedSection = {...appliedPace, type: 'Section'}

      const {container} = renderConnected(
        <TimeSelection
          coursePace={enrollmentPaceWithSectionEnd}
          appliedPace={appliedSection as Pace}
          responsiveSize={responsiveSize}
        />,
      )

      expect(container).toHaveTextContent('Determined by section end date')
    })

    it('shows warning caption for course pace with course end date', () => {
      const coursePaceWithEnd: CoursePace = {
        ...PRIMARY_PACE,
        end_date: '2021-12-15',
        end_date_context: 'course',
      }

      const {container} = renderConnected(
        <TimeSelection
          coursePace={coursePaceWithEnd}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      expect(container).toHaveTextContent(
        'Determined by course end date. Changing this date will not save, but you can view the effects of a new end date by changing the date here.',
      )
    })

    it('shows warning caption for section pace with section end date', () => {
      const sectionPaceWithEnd: CoursePace = {
        ...PRIMARY_PACE,
        context_type: 'Section',
        end_date: '2021-12-15',
        end_date_context: 'term',
      }

      const {container} = renderConnected(
        <TimeSelection
          coursePace={sectionPaceWithEnd}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      expect(container).toHaveTextContent(
        'Determined by section end date. Changing this date will not save, but you can view the effects of a new end date by changing the date here.',
      )
    })

    it('End date input is not available for Student Pace', () => {
      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={STUDENT_PACE}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const endDateInput = queryByTestId('end-date-input')

      expect(endDateInput).not.toBeInTheDocument()
    })

    it('End date readonly label is shown for Student Pace', () => {
      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={STUDENT_PACE}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const endDateReadonly = queryByTestId('end-date-readonly')

      expect(endDateReadonly).toBeInTheDocument()
    })

    it('displays editable end date for course/section paces', () => {
      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={coursePace}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const endDateInput = queryByTestId('end-date-input')

      expect(endDateInput).toBeInTheDocument()
    })
  })

  describe('Time to Complete Behavior', () => {
    it('displays read-only time to complete for enrollment pace with course end date', () => {
      const enrollmentPaceWithCourseEnd: CoursePace = {
        ...STUDENT_PACE,
        end_date: '2021-11-15',
        end_date_context: 'course',
      }

      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={enrollmentPaceWithCourseEnd}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const timeToCompleteReadonly = queryByTestId('time-to-complete-readonly')
      const weeksInput = queryByTestId('weeks-number-input')

      expect(timeToCompleteReadonly).toBeInTheDocument()
      expect(weeksInput).not.toBeInTheDocument()
    })

    it('displays read-only time to complete for enrollment pace with section end date', () => {
      const enrollmentPaceWithSectionEnd: CoursePace = {
        ...STUDENT_PACE,
        end_date: '2021-11-15',
        end_date_context: 'term',
      }

      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={enrollmentPaceWithSectionEnd}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const timeToCompleteReadonly = queryByTestId('time-to-complete-readonly')
      const weeksInput = queryByTestId('weeks-number-input')

      expect(timeToCompleteReadonly).toBeInTheDocument()
      expect(weeksInput).not.toBeInTheDocument()
    })

    it('displays editable time to complete for enrollment pace with hypothetical end date', () => {
      const enrollmentPaceHypothetical: CoursePace = {
        ...STUDENT_PACE,
        end_date: '2021-11-15',
        end_date_context: 'hypothetical',
      }

      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={enrollmentPaceHypothetical}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const timeToCompleteReadonly = queryByTestId('time-to-complete-readonly')
      const weeksInput = queryByTestId('weeks-number-input')

      expect(timeToCompleteReadonly).not.toBeInTheDocument()
      expect(weeksInput).toBeInTheDocument()
    })

    it('displays editable time to complete for course/section paces', () => {
      const {queryByTestId} = renderConnected(
        <TimeSelection
          coursePace={coursePace}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const weeksInput = queryByTestId('weeks-number-input')
      const daysInput = queryByTestId('days-number-input')

      expect(weeksInput).toBeInTheDocument()
      expect(daysInput).toBeInTheDocument()
    })

    it('calculates compressed time to complete when course end date is earlier than projected end', () => {
      // Set up a pace where assignments would project past the course end date
      const compressedPace: CoursePace = {
        ...coursePace,
        start_date: '2021-09-01',
        end_date: '2021-10-15', // Course ends earlier
        end_date_context: 'course',
        time_to_complete_calendar_days: 90, // Would extend to ~November 30 without compression
      }

      const {getByTestId} = renderConnected(
        <TimeSelection
          coursePace={compressedPace}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const weeksInput = getByTestId('weeks-number-input')
      const daysInput = getByTestId('days-number-input')

      // Should show compressed time (Sept 1 to Oct 15 = ~6 weeks, 2 days)
      expect(weeksInput).toHaveValue(6)
      expect(daysInput).toHaveValue(2)
    })

    it('calculates uncompressed time to complete when course end date is later than projected end', () => {
      const uncompressedPace: CoursePace = {
        ...coursePace,
        start_date: '2021-09-01',
        end_date: '2021-12-31', // Course ends later
        end_date_context: 'course',
        time_to_complete_calendar_days: 30, // Would end ~October 1
      }

      const {getByTestId} = renderConnected(
        <TimeSelection
          coursePace={uncompressedPace}
          appliedPace={appliedPace}
          responsiveSize={responsiveSize}
        />,
      )

      const weeksInput = getByTestId('weeks-number-input')
      const daysInput = getByTestId('days-number-input')

      // Should show uncompressed time based on assignments (30 days = 4 weeks, 2 days)
      expect(weeksInput).toHaveValue(4)
      expect(daysInput).toHaveValue(2)
    })
  })
})
