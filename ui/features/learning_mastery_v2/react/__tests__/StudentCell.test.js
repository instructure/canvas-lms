/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import StudentCell from '../StudentCell'

describe('StudentCell', () => {
  const defaultProps = (props = {}) => {
    return {
      student: {
        name: 'Student Test',
        display_name: 'Student Test',
        sortable_name: 'Test, Student',
        avatar_url: '/avatar-url',
        id: '1'
      },
      courseId: '100',
      ...props
    }
  }

  it("renders the student's name", () => {
    const {getByText} = render(<StudentCell {...defaultProps()} />)
    expect(getByText('Student Test')).toBeInTheDocument()
  })

  it("renders an image with the student's avatar_url", () => {
    const {getByAltText} = render(<StudentCell {...defaultProps()} />)
    expect(getByAltText('Student Test').src).toMatch(/avatar-url/)
  })

  it('renders a link to the student learning mastery gradebook', () => {
    const props = defaultProps()
    const {getByText} = render(<StudentCell {...props} />)
    expect(getByText('Student Test').href).toMatch(
      `/courses/${props.courseId}/grades/${props.student.id}#tab-outcomes`
    )
  })
})
