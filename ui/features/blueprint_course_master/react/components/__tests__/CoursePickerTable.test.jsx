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
import {render} from '@testing-library/react'
import CoursePickerTable from '../CoursePickerTable'
import getSampleData from './getSampleData'
import userEvent from '@testing-library/user-event'

describe('CoursePickerTable component', () => {
  const defaultProps = () => ({
    courses: getSampleData().courses,
    selectedCourses: [],
    onSelectedChanged: () => {},
  })

  test('renders the CoursePickerTable component', () => {
    const {container} = render(<CoursePickerTable {...defaultProps()} />)
    const node = container.querySelector('.bca-table__wrapper')
    expect(node).toBeTruthy()
  })

  test('show no results if no courses passed in', () => {
    const props = defaultProps()
    props.courses = []
    const {getByTestId} = render(<CoursePickerTable {...props} />)
    const node = getByTestId('bca-table__no-results')
    expect(node).toBeTruthy()
  })

  test('displays correct table data', () => {
    const props = defaultProps()
    const {container} = render(<CoursePickerTable {...props} />)
    const rows = container.querySelectorAll('tr[data-testid="bca-table__course-row"]')

    expect(rows).toHaveLength(props.courses.length)
    expect(rows[0].querySelectorAll('td')[0].textContent).toEqual(
      `Toggle select course ${props.courses[0].name}`,
    )
    expect(rows[1].querySelectorAll('td')[0].textContent).toEqual(
      `Toggle select course ${props.courses[1].name}`,
    )
  })

  test('calls onSelectedChanged when courses are selected', async () => {
    const props = defaultProps()
    props.onSelectedChanged = vi.fn()
    const {container} = render(<CoursePickerTable {...props} />)
    const checkbox = container.querySelectorAll(
      '[data-testid="bca-table__course-row"] input[type="checkbox"]',
    )[0]
    await userEvent.click(checkbox)

    expect(props.onSelectedChanged).toHaveBeenCalledTimes(1)
    expect(props.onSelectedChanged).toHaveBeenCalledWith({added: ['1'], removed: []})
  })

  test('calls onSelectedChanged when courses are unselected', async () => {
    const props = defaultProps()
    props.selectedCourses = ['1']
    props.onSelectedChanged = vi.fn()
    const {container} = render(<CoursePickerTable {...props} />)
    const checkbox = container.querySelectorAll(
      '[data-testid="bca-table__course-row"] input[type="checkbox"]',
    )[0]
    await userEvent.click(checkbox)

    expect(props.onSelectedChanged).toHaveBeenCalledTimes(1)
    expect(props.onSelectedChanged).toHaveBeenCalledWith({removed: ['1'], added: []})
  })

  test('calls onSelectedChanged with correct data when "Select All" is selected', async () => {
    const props = defaultProps()
    props.onSelectedChanged = vi.fn()
    const {container} = render(<CoursePickerTable {...props} />)

    const checkbox = container.querySelectorAll(
      '.btps-table__header-wrapper input[type="checkbox"]',
    )[0]
    await userEvent.click(checkbox)

    expect(props.onSelectedChanged).toHaveBeenCalledTimes(1)
    expect(props.onSelectedChanged).toHaveBeenCalledWith({added: ['1', '2'], removed: []})
  })

  test('handleFocusLoss focuses the next item', () => {
    const props = defaultProps()
    const ref = React.createRef()
    const {container} = render(<CoursePickerTable {...props} ref={ref} />)
    const instance = ref.current

    const check = container.querySelectorAll(
      '[data-testid="bca-table__course-row"] input[type="checkbox"]',
    )[0]
    check.focus = vi.fn()

    instance.handleFocusLoss(0)
    expect(check.focus).toHaveBeenCalledTimes(1)
  })

  test('handleFocusLoss focuses the previous item if called on the last item', () => {
    const props = defaultProps()
    const ref = React.createRef()
    const {container} = render(<CoursePickerTable {...props} ref={ref} />)
    const instance = ref.current

    const check = container.querySelectorAll(
      '[data-testid="bca-table__course-row"] input[type="checkbox"]',
    )[1]
    check.focus = vi.fn()

    instance.handleFocusLoss(2)
    expect(check.focus).toHaveBeenCalledTimes(1)
  })

  test('handleFocusLoss focuses on select all if no items left', () => {
    const props = defaultProps()
    props.courses = []
    const ref = React.createRef()
    const {container} = render(<CoursePickerTable {...props} ref={ref} />)
    const instance = ref.current

    const check = container.querySelectorAll('.bca-table__select-all input[type="checkbox"]')[0]
    check.focus = vi.fn()

    instance.handleFocusLoss(1)
    expect(check.focus).toHaveBeenCalledTimes(1)
  })

  test('renders concluded pill when course is concluded', () => {
    window.ENV = {FEATURES: {ux_list_concluded_courses_in_bp: true}}

    const props = defaultProps()
    props.courses = [
      {
        id: '1',
        name: 'Concluded Course',
        course_code: 'CONCLUDED101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher One'}],
        sis_course_id: '1001',
        concluded: true,
      },
    ]

    const {getByText} = render(<CoursePickerTable {...props} />)
    const pill = getByText('Concluded')
    expect(pill).toBeInTheDocument()
  })

  test('does not render pill when course is not concluded', () => {
    const props = defaultProps()
    props.courses = [
      {
        id: '1',
        name: 'Active Course',
        course_code: 'ACTIVE101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher One'}],
        sis_course_id: '1001',
        concluded: false,
      },
    ]

    const {queryByText} = render(<CoursePickerTable {...props} />)
    const pill = queryByText('Concluded')
    expect(pill).not.toBeInTheDocument()
  })

  test('does not render pill when concluded property is missing', () => {
    const props = defaultProps()
    props.courses = [
      {
        id: '1',
        name: 'Course Without Concluded Property',
        course_code: 'NORMAL101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher One'}],
        sis_course_id: '1001',
      },
    ]

    const {queryByText} = render(<CoursePickerTable {...props} />)
    const pill = queryByText('Concluded')
    expect(pill).not.toBeInTheDocument()
  })
})
