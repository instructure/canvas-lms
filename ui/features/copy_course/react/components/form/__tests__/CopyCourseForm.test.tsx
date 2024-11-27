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
  const endAt = '2024-01-02'

  const course: Course = {
    blueprint: false,
    enrollment_term_id: 0,
    homeroom_course: false,
    sections: [{id: '', name: ''}],
    sis_course_id: null,
    term: {name: ''},
    time_zone: '',
    workflow_state: '',
    id: '1',
    name: courseName,
    course_code: courseCode,
    start_at: startAt,
    end_at: endAt,
  }

  it('renders the component with all the form fields', () => {
    const {getByText, getByRole} = render(
      <CopyCourseForm canImportAsNewQuizzes={true} course={course} terms={[]} />
    )

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

  describe('intial values', () => {
    it('renders the course name', () => {
      const {getByDisplayValue} = render(
        <CopyCourseForm canImportAsNewQuizzes={true} course={course} terms={[]} />
      )

      expect(getByDisplayValue(courseName)).toBeInTheDocument()
    })

    it('renders the course code', () => {
      const {getByDisplayValue} = render(
        <CopyCourseForm canImportAsNewQuizzes={true} course={course} terms={[]} />
      )

      expect(getByDisplayValue(courseCode)).toBeInTheDocument()
    })

    it('renders the start date', () => {
      const {getByDisplayValue} = render(
        <CopyCourseForm canImportAsNewQuizzes={true} course={course} terms={[]} />
      )

      expect(getByDisplayValue('Jan 1 at 12am')).toBeInTheDocument()
    })

    it('renders the end date', () => {
      const {getByDisplayValue} = render(
        <CopyCourseForm canImportAsNewQuizzes={true} course={course} terms={[]} />
      )

      expect(getByDisplayValue('Jan 2 at 12am')).toBeInTheDocument()
    })

    it('renders the terms', () => {
      const terms = [
        {id: '1', name: 'Option 1'},
        {id: '2', name: 'Option 2'},
        {id: '3', name: 'Option 3'},
      ]
      const {getByText, getByLabelText} = render(
        <CopyCourseForm canImportAsNewQuizzes={true} course={course} terms={terms} />
      )
      fireEvent.click(getByLabelText('Term'))
      terms.forEach(option => {
        expect(getByText(option.name)).toBeInTheDocument()
      })
    })
  })
})
