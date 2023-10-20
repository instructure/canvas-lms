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
import {render} from '@testing-library/react'
import CoursesTray from '../CoursesTray'

describe('CoursesTray', () => {
  const courses = [
    {
      id: '1',
      name: 'Course1',
      wokrflow_state: 'published',
    },
    {
      id: '2',
      name: 'Course2',
      workflow_state: 'published',
    },
    {
      id: '3',
      name: 'Course3',
      workflow_state: 'unpublished',
    },
  ]

  function makeProps(overrides = {}) {
    return {
      courses,
      hasLoaded: true,
      k5User: false,
      ...overrides,
    }
  }

  it('renders loading spinner', () => {
    const {getByTitle, queryByText} = render(<CoursesTray {...makeProps({hasLoaded: false})} />)
    getByTitle('Loading')
    expect(queryByText('Course1')).toBeNull()
    expect(queryByText('Course2')).toBeNull()
  })

  it('renders the header', () => {
    const {getByText} = render(<CoursesTray {...makeProps()} />)
    expect(getByText('Courses')).toBeVisible()
  })

  it('renders a link for each course', () => {
    const {getByText} = render(<CoursesTray {...makeProps()} />)
    getByText('Course1')
    getByText('Course2')
  })

  it('renders all courses link', () => {
    const {getByText} = render(<CoursesTray {...makeProps()} />)
    getByText('All Courses')
  })

  it('does not render a split dashboard for non teachers', () => {
    const {queryByText} = render(<CoursesTray {...makeProps()} />)
    expect(queryByText('Published Courses')).not.toBeInTheDocument()
    expect(queryByText('Unpublished Courses')).not.toBeInTheDocument()
  })

  it('does render a split dashboard for teachers with appropriate headers', () => {
    window.ENV = {...window.ENV, current_user_roles: ['teacher']}
    const {getByText} = render(<CoursesTray {...makeProps()} />)
    getByText('Published Courses')
    getByText('Unpublished Courses')
  })

  it('changes `Courses` to `Subjects` if k5User is set', () => {
    const {getByText, queryByText} = render(<CoursesTray {...makeProps({k5User: true})} />)
    expect(getByText('Subjects')).toBeInTheDocument()
    expect(getByText('All Subjects')).toBeInTheDocument()
    expect(queryByText('Courses')).not.toBeInTheDocument()
  })
})
