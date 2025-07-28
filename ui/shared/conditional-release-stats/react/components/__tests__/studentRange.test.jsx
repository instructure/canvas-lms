/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import StudentRange from '../student-range'

describe('StudentRange', () => {
  const defaultProps = (overrides = {}) => ({
    range: {
      scoring_range: {
        id: 1,
        rule_id: 1,
        lower_bound: 0.7,
        upper_bound: 1.0,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [
        {
          user: {name: 'Foo Bar', id: 1},
        },
        {
          user: {name: 'Bar Foo', id: 2},
        },
      ],
    },
    onStudentSelect: jest.fn(),
    ...overrides,
  })

  it('renders all students in the range', () => {
    const props = defaultProps()
    const {getAllByRole} = render(<StudentRange {...props} />)

    const studentButtons = getAllByRole('button')
    expect(studentButtons).toHaveLength(props.range.students.length)
    expect(studentButtons[0]).toHaveTextContent('Foo Bar')
    expect(studentButtons[1]).toHaveTextContent('Bar Foo')
  })

  it('renders nothing when there are no students', () => {
    const props = defaultProps({
      range: {
        ...defaultProps().range,
        students: [],
      },
    })
    const {container} = render(<StudentRange {...props} />)
    expect(container.firstChild).toBeEmptyDOMElement()
  })

  it('calls onStudentSelect with correct index when student is clicked', () => {
    const props = defaultProps()
    const {getByRole} = render(<StudentRange {...props} />)

    const firstStudent = getByRole('button', {name: /select student foo bar/i})
    fireEvent.click(firstStudent)
    expect(props.onStudentSelect).toHaveBeenCalledWith(0)

    const secondStudent = getByRole('button', {name: /select student bar foo/i})
    fireEvent.click(secondStudent)
    expect(props.onStudentSelect).toHaveBeenCalledWith(1)
  })

  it('renders students in correct order', () => {
    const props = defaultProps()
    const {getAllByRole} = render(<StudentRange {...props} />)

    const studentButtons = getAllByRole('button')
    studentButtons.forEach((button, index) => {
      expect(button).toHaveTextContent(props.range.students[index].user.name)
    })
  })

  it('renders with correct structure', () => {
    const props = defaultProps()
    const {container} = render(<StudentRange {...props} />)

    expect(container.firstChild).toHaveClass('crs-student-range')
    const items = container.getElementsByClassName('crs-student-range__item')
    expect(items).toHaveLength(props.range.students.length)
  })
})
