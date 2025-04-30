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
import {fireEvent, render, within} from '@testing-library/react'
import {CopyCourseForm} from '../CopyCourseForm'
import type {Course} from '../../../../../../api'
import moment from 'moment-timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import type {default as Timezone} from 'timezone'
import type {default as ChicagoTz} from 'timezone/America/Chicago'
import type {default as DetroitTz} from 'timezone/America/Detroit'
import fakeENV from '@canvas/test-utils/fakeENV'

const tz = require('timezone') as typeof Timezone
const chicago = require('timezone/America/Chicago') as typeof ChicagoTz
const detroit = require('timezone/America/Detroit') as typeof DetroitTz

describe('CourseCopyForm', () => {
  const currentYear = new Date().getFullYear()
  const courseName = 'Course name'
  const courseCode = 'Course code'
  const startAt = `${currentYear}-01-01`
  const termStartAt = `${currentYear}-02-01`
  const endAt = `${currentYear}-01-02`
  const termEndAt = `${currentYear}-02-02`

  const course: Course = {
    blueprint: false,
    enrollment_term_id: 2,
    homeroom_course: false,
    sections: [{id: '', name: ''}],
    sis_course_id: null,
    term: {
      name: 'Option 2',
    },
    time_zone: 'America/Detroit',
    workflow_state: '',
    id: '1',
    name: courseName,
    course_code: courseCode,
    start_at: startAt,
    end_at: endAt,
    restrict_enrollments_to_course_dates: true,
    horizon_course: false,
  }

  const terms = [
    {id: '1', name: 'Option 1'},
    {id: '2', name: 'Option 2', startAt: termStartAt, endAt: termEndAt},
    {id: '3', name: 'Option 3'},
  ]

  const defaultProps = {
    course,
    terms,
    isSubmitting: false,
    onSubmit: jest.fn(),
    onCancel: jest.fn(),
    canImportAsNewQuizzes: true,
  }

  const defaultExpectedOnSubmitCall = {
    courseName: course.name,
    courseCode: course.course_code,
    newCourseStartDate: new Date(startAt),
    newCourseEndDate: new Date(endAt),
    selectedTerm: {id: '1', name: 'Option 1'},
    settings: {import_quizzes_next: false},
    selective_import: false,
    adjust_dates: {enabled: 1, operation: 'shift_dates'},
    errored: false,
    date_shift_options: {
      old_start_date: new Date(startAt).toISOString(),
      new_start_date: new Date(startAt).toISOString(),
      old_end_date: new Date(endAt).toISOString(),
      new_end_date: new Date(endAt).toISOString(),
      day_substitutions: [],
    },
    restrictEnrollmentsToCourseDates: course.restrict_enrollments_to_course_dates,
    courseTimeZone: course.time_zone,
  }

  beforeEach(() => {
    // Set timezone and mock current date
    const timezone = 'America/Denver'
    moment.tz.setDefault(timezone)

    // Use fakeENV instead of directly setting window.ENV
    fakeENV.setup({
      TIMEZONE: timezone,
    })

    // Mock the current date to be January 1st of the current year at noon
    jest.useFakeTimers()
    jest.setSystemTime(new Date(`${currentYear}-01-01T12:00:00.000Z`))
  })

  afterEach(() => {
    jest.useRealTimers()
    fakeENV.teardown()
  })

  const renderCopyCourseForm = (props = {}) =>
    render(<CopyCourseForm {...defaultProps} {...props} />)

  describe('initial values', () => {
    it('renders the course name', () => {
      const {getByDisplayValue} = renderCopyCourseForm()

      expect(getByDisplayValue(courseName)).toBeInTheDocument()
    })

    it('renders the course code', () => {
      const {getByDisplayValue} = renderCopyCourseForm()

      expect(getByDisplayValue(courseCode)).toBeInTheDocument()
    })

    it('renders the start date', () => {
      const {getByTestId} = renderCopyCourseForm()

      const startDateField = getByTestId('course-start-date')
      expect(startDateField).toBeInTheDocument()
    })

    it('renders the end date', () => {
      const {getByTestId} = renderCopyCourseForm()

      const endDateField = getByTestId('course-end-date')
      expect(endDateField).toBeInTheDocument()
    })

    it('renders the terms', () => {
      const {getByText, getAllByRole} = renderCopyCourseForm()

      fireEvent.click(getByText('Term'))
      const options = getAllByRole('option')
      const optionTexts = options.map(option => option.textContent)
      expect(optionTexts).toContain('Option 1')
      expect(optionTexts).toContain('Option 2')
      expect(optionTexts).toContain('Option 3')
    })
  })

  describe('dates', () => {
    describe('availability', () => {
      describe('when restrictEnrollmentsToCourseDates is false', () => {
        it('should disable start date input fields', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          expect(getByDisplayValue('Feb 1 at 12am')).toBeDisabled()
        })

        it('should disable end date input fields', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          expect(getByDisplayValue('Feb 2 at 12am')).toBeDisabled()
        })

        it('should render disable state explanation', () => {
          const {getAllByText} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          expect(
            getAllByText(
              'Term start and end dates cannot be modified here, only on the Term Details page under Admin.',
            ),
          ).toHaveLength(2)
        })
      })

      describe('when restrictEnrollmentsToCourseDates is true', () => {
        it('should enable start date input fields', () => {
          const {getByTestId} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          const startDateField = getByTestId('course-start-date')
          expect(startDateField).toBeEnabled()
        })

        it('should enable end date input fields', () => {
          const {getByTestId} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          const endDateField = getByTestId('course-end-date')
          expect(endDateField).toBeEnabled()
        })

        it('should not render disable state explanation', () => {
          const {queryByText} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          expect(
            queryByText(
              'Term start and end dates cannot be modified here, only on the Term Details page under Admin.',
            ),
          ).not.toBeInTheDocument()
        })
      })
    })

    describe('default date', () => {
      describe('when restrictEnrollmentsToCourseDates is false', () => {
        it('should use terms start date', () => {
          const {getByTestId} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          const startDateField = getByTestId('course-start-date')
          expect(startDateField).toBeInTheDocument()
        })

        it('should use terms end date', () => {
          const {getByTestId} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          const endDateField = getByTestId('course-end-date')
          expect(endDateField).toBeInTheDocument()
        })
      })

      describe('when restrictEnrollmentsToCourseDates is true', () => {
        it('should use course start date', () => {
          const {getByTestId} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          const startDateField = getByTestId('course-start-date')
          expect(startDateField).toBeInTheDocument()
        })

        it('should use course end date', () => {
          const {getByTestId} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          const endDateField = getByTestId('course-end-date')
          expect(endDateField).toBeInTheDocument()
        })
      })
    })

    describe('timezone', () => {
      beforeEach(() => {
        moment.tz.setDefault('America/Denver')

        tzInTest.configureAndRestoreLater({
          tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
          tzData: {
            'America/Chicago': chicago,
            'America/Detroit': detroit,
          },
          formats: getI18nFormats(),
        })
      })

      const courseTimeZone = 'America/Detroit'
      const userTimeZone = 'America/Chicago'
      const startDate = `${currentYear}-02-03T00:00:00.000Z`
      const expectedStartDateCourseDateString = 'Local: Feb 2 at 6pm'
      const expectedStartDateUserDateString = 'Course: Feb 2 at 7pm'
      const endDate = `${currentYear}-03-03T00:00:00.000Z`
      const expectedEndDateCourseDateString = 'Local: Mar 2 at 6pm'
      const expectedEndDateUserDateString = 'Course: Mar 2 at 7pm'

      it('renders time zone data on different timezones', () => {
        const {getByText} = renderCopyCourseForm({
          course: {...course, start_at: startDate, end_at: endDate},
          courseTimeZone,
          userTimeZone,
        })
        expect(getByText(expectedStartDateCourseDateString)).toBeInTheDocument()
        expect(getByText(expectedStartDateUserDateString)).toBeInTheDocument()
        expect(getByText(expectedEndDateCourseDateString)).toBeInTheDocument()
        expect(getByText(expectedEndDateUserDateString)).toBeInTheDocument()
      })
    })
  })
})
