/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render as testingLibraryRender} from '@testing-library/react'
import CoursesTray from '../CoursesTray'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const window: Window & {ENV: GlobalEnv}

const render = (children: unknown) =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

describe('CoursesTray', () => {
  const courses = [
    {
      id: '1',
      name: 'Course1',
      wokrflow_state: 'published',
      enrollment_term_id: '1',
      sis_course_id: 'sis1',
      term: {
        id: '1',
        name: 'Term1',
      },
      sections: [
        {
          id: '1',
          name: 'Section1',
        },
      ],
    },
    {
      id: '2',
      name: 'Course2',
      workflow_state: 'published',
      enrollment_term_id: '2',
      term: {
        id: '2',
        name: 'Term2',
      },
      sections: [
        {
          id: '2',
          name: 'Section2',
        },
      ],
    },
    {
      id: '3',
      name: 'Course3',
      workflow_state: 'unpublished',
      enrollment_term_id: '3',
      sis_course_id: 'sis3',
      term: {
        id: '3',
        name: 'Term3',
      },
      sections: [
        {
          id: '5',
          name: 'Section5',
        },
        {
          id: '3',
          name: 'Section3',
        },
        {
          id: '4',
          name: 'Section4',
        },
      ],
    },
    {
      id: '4',
      name: 'Course4',
      workflow_state: 'published',
      enrollment_term_id: '4',
      sis_course_id: 'sis4',
      term: {
        id: '4',
        name: 'Term4',
      },
      sections: [
        {
          id: '6',
          name: 'Section6',
        },
      ],
    },
  ]

  beforeEach(() => {
    queryClient.setQueryData(['courses'], courses)
    window.ENV.K5_USER = false
    window.ENV.FEATURES.courses_popout_sisid = true
    window.ENV.current_user_roles = []
    // @ts-expect-error
    window.ENV.SETTINGS = {show_sections_in_course_tray: true}
  })

  afterEach(() => {
    queryClient.removeQueries()
  })

  it('renders the header', () => {
    const {getByText} = render(<CoursesTray />)
    expect(getByText('Courses')).toBeVisible()
  })

  it('renders a link for each course', () => {
    const {getByText} = render(<CoursesTray />)
    getByText('Course1')
    getByText('Course2')
  })

  it('renders all courses link', () => {
    const {getByText} = render(<CoursesTray />)
    getByText('All Courses')
  })

  it('does not render a split dashboard for non teachers', () => {
    const {queryByText} = render(<CoursesTray />)
    expect(queryByText('Published Courses')).not.toBeInTheDocument()
    expect(queryByText('Unpublished Courses')).not.toBeInTheDocument()
  })

  it('does render a split dashboard for teachers with appropriate headers', () => {
    window.ENV = {...window.ENV, current_user_roles: ['teacher']}
    const {getByText} = render(<CoursesTray />)
    getByText('Published Courses')
    getByText('Unpublished Courses')
  })

  it('changes `Courses` to `Subjects` if k5User is set', () => {
    window.ENV.K5_USER = true
    const {getByText, queryByText} = render(<CoursesTray />)
    expect(getByText('Subjects')).toBeInTheDocument()
    expect(getByText('All Subjects')).toBeInTheDocument()
    expect(queryByText('Courses')).not.toBeInTheDocument()
  })

  it('renders term name', () => {
    const {getByText} = render(<CoursesTray />)
    expect(getByText('Term: Term2')).toBeInTheDocument()
  })

  it('renders sis id if present', () => {
    const {getByText} = render(<CoursesTray />)
    expect(getByText('SIS ID: sis1')).toBeInTheDocument()
  })

  it('renders term name and sis id if both are present', () => {
    const {getByText} = render(<CoursesTray />)
    expect(getByText('SIS ID: sis3 | Term: Term3')).toBeInTheDocument()
  })

  it('does not render term name if term id is 1 (default term for account)', () => {
    const {queryByText} = render(<CoursesTray />)
    expect(queryByText('Term1')).not.toBeInTheDocument()
  })

  it('renders section name if present', () => {
    const {getByText} = render(<CoursesTray />)
    expect(getByText('Section2')).toBeInTheDocument()
  })

  it('sorts section names in alphabetical and ascending order', () => {
    const {getByText} = render(<CoursesTray />)
    expect(getByText('Section3, Section4, Section5')).toBeInTheDocument()
  })

  it('does not render sections if setting show_sections_in_course_tray is disabled', () => {
    // @ts-expect-error
    window.ENV.SETTINGS.show_sections_in_course_tray = false
    const {queryByText} = render(<CoursesTray />)
    expect(queryByText('Section3, Section4, Section5')).not.toBeInTheDocument()
  })

  it('renders the correct URL for each course', () => {
    const {getByText} = render(<CoursesTray />)
    const courses = [
      {name: 'Course1', url: '/courses/1'},
      {name: 'Course2', url: '/courses/2'},
      {name: 'Course3', url: '/courses/3'},
      {name: 'Course4', url: '/courses/4'},
    ]
    courses.forEach(({name, url}) => {
      const courseLink = getByText(name).closest('a')
      expect(courseLink).toBeInTheDocument()
      expect(courseLink).toHaveAttribute('href', url)
    })
  })
})
