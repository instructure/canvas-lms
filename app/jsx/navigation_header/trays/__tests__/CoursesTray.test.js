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
      name: 'Course1'
    },
    {
      id: '2',
      name: 'Course2'
    }
  ]

  const props = {
    courses,
    hasLoaded: true
  }

  it('renders loading spinner', () => {
    const {getByTitle, queryByText} = render(<CoursesTray {...props} hasLoaded={false} />)
    getByTitle('Loading')
    expect(queryByText('Course1')).toBeNull()
    expect(queryByText('Course2')).toBeNull()
  })

  it('renders the header', () => {
    const {getByText} = render(<CoursesTray {...props} />)
    expect(getByText('Courses')).toBeVisible()
  })

  it('renders a link for each course', () => {
    const {getByText} = render(<CoursesTray {...props} />)
    getByText('Course1')
    getByText('Course2')
  })

  it('renders all courses link', () => {
    const {getByText} = render(<CoursesTray {...props} />)
    getByText('All Courses')
  })
})
