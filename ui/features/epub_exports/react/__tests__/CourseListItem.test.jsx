/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import CourseListItem from '../CourseListItem'

describe('CourseListItem', () => {
  let props

  beforeEach(() => {
    props = {
      course: {
        name: 'Maths 101',
        id: 1,
      },
    }
  })

  it('renders without epub_export', () => {
    const {container} = render(<CourseListItem {...props} />)
    expect(container.firstChild).toBeInTheDocument()
    expect(container.querySelector('.epub-export-status')).toBeNull()
  })

  it('shows generating state when epub_export is generating', () => {
    props.course = {
      epub_export: {
        permissions: {},
        workflow_state: 'generating',
      },
    }
    const {getByText} = render(<CourseListItem {...props} />)
    expect(getByText(/generating/i)).toBeInTheDocument()
  })

  it('renders with course information', () => {
    const {container} = render(<CourseListItem {...props} />)
    expect(container.firstChild).toBeInTheDocument()
  })
})
