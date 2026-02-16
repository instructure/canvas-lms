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

import {render} from '@testing-library/react'
import React from 'react'
import NameLink from '../NameLink'

const STUDENT_ENROLLMENT = 'StudentEnrollment'
const TEACHER_ENROLLMENT = 'TeacherEnrollment'

const DEFAULT_PROPS = {
  studentId: '2',
  name: 'Test User',
  htmlUrl: 'http://test.host/courses/1/users/2',
  enrollments: [{type: TEACHER_ENROLLMENT}],
}

describe('NameLink', () => {
  const setup = (props: typeof DEFAULT_PROPS) => {
    return render(<NameLink {...props} />)
  }

  beforeEach(() => {
    window.ENV = {
      STUDENT_CONTEXT_CARDS_ENABLED: true,
      course: {
        id: '1',
        name: 'Test Course',
        start_at: '2021-01-01T00:00:00Z',
        end_at: '2021-12-31T23:59:59Z',
        created_at: '2021-01-01T00:00:00Z',
      },
      current_user: {
        id: '999',
        anonymous_id: 'anon999',
        display_name: 'Test User',
        avatar_image_url: 'http://test.host/avatar.png',
        html_url: 'http://test.host/users/999',
        pronouns: null,
        fake_student: false,
        avatar_is_fallback: false,
      },
    } as any
  })

  it('should render', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container).toBeTruthy()
  })

  it('should render the name', () => {
    const container = setup(DEFAULT_PROPS)
    const name = container.getByText(DEFAULT_PROPS.name)
    expect(name).toBeInTheDocument()
  })

  it('should link to the htmlUrl prop', () => {
    const container = setup(DEFAULT_PROPS)
    const link = container.getByRole('link', {name: DEFAULT_PROPS.name})
    expect(link).toHaveAttribute('href', DEFAULT_PROPS.htmlUrl)
  })

  it('should not display the user pronouns element if no pronouns prop is passed', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container.queryAllByTestId('user-pronouns')).toHaveLength(0)
  })

  it('should display pronouns if passed as a prop', () => {
    const container = setup(DEFAULT_PROPS)
    const pronounOptions = ['He/His', 'She/Her', 'They/Them']
    pronounOptions.forEach(pronounOption => {
      container.rerender(<NameLink {...DEFAULT_PROPS} pronouns={pronounOption} />)
      const pronounElement = container.getByTestId('user-pronouns')
      expect(pronounElement).toBeInTheDocument()
    })
  })

  it('should have the necessary attributes for the StudentContextCardTrigger component when the user is a student', () => {
    const propsWithStudentEnrollment = {...DEFAULT_PROPS, enrollments: [{type: STUDENT_ENROLLMENT}]}
    const {firstChild} = setup(propsWithStudentEnrollment).container
    expect(firstChild).toHaveAttribute('class', 'student_context_card_trigger')
    expect(firstChild).toHaveAttribute('data-student_id', DEFAULT_PROPS.studentId)
    expect(firstChild).toHaveAttribute('data-course_id', window.ENV.course!.id)
  })
})
