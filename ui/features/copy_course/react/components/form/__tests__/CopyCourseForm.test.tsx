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
import {fireEvent, render} from '@testing-library/react'
import {CopyCourseForm} from '../CopyCourseForm'
import type {Course} from '../../../../../../api'

describe('CourseCopyForm', () => {
  const courseName = 'Course name'
  const courseCode = 'Course code'
  const startAt = '2024-01-01'
  const termStartAt = '2024-02-01'
  const endAt = '2024-01-02'
  const termEndAt = '2024-02-02'

  const course: Course = {
    blueprint: false,
    enrollment_term_id: 2,
    homeroom_course: false,
    sections: [{id: '', name: ''}],
    sis_course_id: null,
    term: {
      name: 'Option 2',
    },
    time_zone: '',
    workflow_state: '',
    id: '1',
    name: courseName,
    course_code: courseCode,
    start_at: startAt,
    end_at: endAt,
    restrict_enrollments_to_course_dates: true,
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

  const renderCopyCourseForm = (props = {}) =>
    render(<CopyCourseForm {...defaultProps} {...props} />)

  it('renders the component with all the form fields', () => {
    const {getByText, getByRole} = renderCopyCourseForm()

    expect(getByText('Name')).toBeInTheDocument()
    expect(getByText('Course code')).toBeInTheDocument()
    expect(getByText('Start date')).toBeInTheDocument()
    expect(getByText('End date')).toBeInTheDocument()
    expect(getByText('Term')).toBeInTheDocument()
    expect(getByRole('group', {name: 'Content *'})).toBeInTheDocument()
    expect(getByRole('group', {name: 'Options'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Clear'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Create course'})).toBeInTheDocument()
  })

  it('calls onSubmit with the correct arguments when the form is submitted', () => {
    const onSubmit = jest.fn()
    const {getByRole, getByLabelText, getByText} = renderCopyCourseForm({onSubmit})

    fireEvent.click(getByLabelText('Term'))
    fireEvent.click(getByText('Option 1'))
    fireEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))
    fireEvent.click(getByRole('button', {name: 'Create course'}))

    expect(onSubmit).toHaveBeenCalledWith({
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
    })
  })

  describe('validation', () => {
    it('should not call onSubmit on date validation error', () => {
      const onSubmit = jest.fn()
      const courseWithWrongDates = {
        ...course,
        start_at: endAt,
        end_at: startAt,
      }
      const {getByText, getByRole} = renderCopyCourseForm({
        onSubmit,
        course: courseWithWrongDates,
      })

      fireEvent.click(getByRole('button', {name: 'Create course'}))

      expect(onSubmit).not.toHaveBeenCalled()
      expect(getByText('Start date must be before end date')).toBeInTheDocument()
      expect(getByText('End date must be after start date')).toBeInTheDocument()
    })

    it('should not call onSubmit on courseName validation error', () => {
      const onSubmit = jest.fn()
      const courseWithWrongDates = {
        ...course,
        name: 'a'.repeat(256),
      }
      const {getByText, getByRole} = renderCopyCourseForm({
        onSubmit,
        course: courseWithWrongDates,
      })

      fireEvent.click(getByRole('button', {name: 'Create course'}))

      expect(onSubmit).not.toHaveBeenCalled()
      expect(getByText('Course name must be 255 characters or less')).toBeInTheDocument()
    })

    it('should not call onSubmit on courseCode validation error', () => {
      const onSubmit = jest.fn()
      const courseWithWrongDates = {
        ...course,
        course_code: 'a'.repeat(256),
      }
      const {getByText, getByRole} = renderCopyCourseForm({
        onSubmit,
        course: courseWithWrongDates,
      })

      fireEvent.click(getByRole('button', {name: 'Create course'}))

      expect(onSubmit).not.toHaveBeenCalled()
      expect(getByText('Course code must be 255 characters or less')).toBeInTheDocument()
    })
  })

  it('renders all the fields as disabled on submit', () => {
    const {getByRole, getByDisplayValue} = renderCopyCourseForm({isSubmitting: true})

    expect(getByDisplayValue(courseName)).toBeDisabled()
    expect(getByDisplayValue(courseCode)).toBeDisabled()
    expect(getByDisplayValue('Jan 1 at 12am')).toBeDisabled()
    expect(getByDisplayValue('Jan 2 at 12am')).toBeInTheDocument()
    expect(getByRole('button', {name: /Creating/})).toBeDisabled()
  })

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
      const {getByDisplayValue} = renderCopyCourseForm()

      expect(getByDisplayValue('Jan 1 at 12am')).toBeInTheDocument()
    })

    it('renders the end date', () => {
      const {getByDisplayValue} = renderCopyCourseForm()

      expect(getByDisplayValue('Jan 2 at 12am')).toBeInTheDocument()
    })

    it('renders the terms', () => {
      const {getByText, getByLabelText} = renderCopyCourseForm()

      fireEvent.click(getByLabelText('Term'))
      terms.forEach(option => {
        expect(getByText(option.name)).toBeInTheDocument()
      })
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
      })

      describe('when restrictEnrollmentsToCourseDates is true', () => {
        it('should enable start date input fields', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          expect(getByDisplayValue('Jan 1 at 12am')).toBeEnabled()
        })

        it('should enable end date input fields', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          expect(getByDisplayValue('Jan 2 at 12am')).toBeEnabled()
        })
      })
    })

    describe('default date', () => {
      describe('when restrictEnrollmentsToCourseDates is false', () => {
        it('should use terms start date', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          expect(getByDisplayValue('Feb 1 at 12am')).toBeInTheDocument()
        })

        it('should use terms end date', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: false},
          })

          expect(getByDisplayValue('Feb 2 at 12am')).toBeInTheDocument()
        })
      })

      describe('when restrictEnrollmentsToCourseDates is true', () => {
        it('should use course start date', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          expect(getByDisplayValue('Jan 1 at 12am')).toBeInTheDocument()
        })

        it('should use course end date', () => {
          const {getByDisplayValue} = renderCopyCourseForm({
            course: {...course, restrict_enrollments_to_course_dates: true},
          })

          expect(getByDisplayValue('Jan 2 at 12am')).toBeInTheDocument()
        })
      })
    })
  })
})
