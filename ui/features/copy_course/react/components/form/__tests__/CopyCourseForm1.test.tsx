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
import moment from 'moment-timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'
import type {default as Timezone} from 'timezone'
import type {default as ChicagoTz} from 'timezone/America/Chicago'
import type {default as DetroitTz} from 'timezone/America/Detroit'

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
    window.ENV = window.ENV || {}
    window.ENV.TIMEZONE = timezone

    // Mock the current date to be January 1st of the current year at noon
    jest.useFakeTimers()
    jest.setSystemTime(new Date(`${currentYear}-01-01T12:00:00.000Z`))
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  const renderCopyCourseForm = (props = {}) =>
    render(<CopyCourseForm {...defaultProps} {...props} />)

  it('renders the component with all the form fields', () => {
    const {getByText, getByRole} = renderCopyCourseForm()

    expect(getByText('Name')).toBeInTheDocument()
    expect(getByText('Course code')).toBeInTheDocument()
    expect(getByText('Start date')).toBeInTheDocument()
    expect(getByText('End date')).toBeInTheDocument()
    expect(getByText('Term')).toBeInTheDocument()
    expect(getByRole('radiogroup', {name: 'Content'})).toBeInTheDocument()
    expect(getByRole('group', {name: 'Options'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Create course'})).toBeInTheDocument()
  })

  it('calls onSubmit with the correct arguments when the form is submitted', () => {
    const onSubmit = jest.fn()
    const {getByRole, getByText} = renderCopyCourseForm({onSubmit})

    fireEvent.click(getByText('Term'))
    fireEvent.click(getByRole('option', {name: 'Option 1'}))
    fireEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))
    fireEvent.click(getByRole('button', {name: 'Create course'}))

    expect(onSubmit).toHaveBeenCalledWith(defaultExpectedOnSubmitCall)
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
    const {getByRole, getByDisplayValue, getByTestId} = renderCopyCourseForm({isSubmitting: true})

    expect(getByDisplayValue(courseName)).toBeDisabled()
    expect(getByDisplayValue(courseCode)).toBeDisabled()
    expect(getByTestId('course-start-date').querySelector('input')).toBeDisabled()
    expect(getByTestId('course-end-date').querySelector('input')).toBeDisabled()
    expect(getByRole('button', {name: /Creating/})).toBeDisabled()
  })
})
