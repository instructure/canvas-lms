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
import {render, screen as rtlScreen} from '@testing-library/react'
import CoursePicker from '../CoursePicker'
import getSampleData from './getSampleData'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('CoursePicker component', () => {
  let originalENV

  beforeEach(() => {
    originalENV = window.ENV
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    window.ENV = originalENV
  })

  const defaultProps = () => ({
    courses: getSampleData().courses,
    selectedCourses: [],
    subAccounts: getSampleData().subAccounts,
    terms: getSampleData().terms,
    isLoadingCourses: false,
    loadCourses: jest.fn(),
    onSelectedChanged: jest.fn(),
  })

  test('renders the CoursePicker component', () => {
    render(<CoursePicker {...defaultProps()} />)
    expect(document.querySelector('.bca-course-picker')).toBeInTheDocument()
  })

  test('displays courses text label', () => {
    render(<CoursePicker {...defaultProps()} />)
    expect(rtlScreen.getByText('Courses')).toBeInTheDocument()
  })

  test('displays spinner when loading courses', () => {
    const props = defaultProps()
    props.isLoadingCourses = true
    render(<CoursePicker {...props} />)
    expect(rtlScreen.getByTitle('Loading Courses')).toBeInTheDocument()
    expect(document.querySelector('.bca-course-picker__loading')).toBeInTheDocument()
  })

  test('does not display spinner when not loading courses', () => {
    const props = defaultProps()
    props.isLoadingCourses = false
    render(<CoursePicker {...props} />)
    expect(rtlScreen.queryByTitle('Loading Courses')).not.toBeInTheDocument()
    expect(document.querySelector('.bca-course-picker__loading')).not.toBeInTheDocument()
  })

  test('calls loadCourses when filters are updated', () => {
    const props = defaultProps()
    const ref = React.createRef()
    render(<CoursePicker {...props} ref={ref} />)
    const picker = ref.current

    picker.onFilterChange({
      term: '',
      subAccount: '',
      search: 'one',
    })

    expect(props.loadCourses).toHaveBeenCalledTimes(1)
    expect(props.loadCourses).toHaveBeenCalledWith({
      term: '',
      subAccount: '',
      search: 'one',
    })
  })

  test('calls onSelectedChanged when course selection changes', () => {
    const props = defaultProps()
    const ref = React.createRef()
    render(<CoursePicker {...props} ref={ref} />)
    const picker = ref.current

    picker.onSelectedChanged(['1', '2'])

    expect(props.onSelectedChanged).toHaveBeenCalledTimes(1)
    expect(props.onSelectedChanged).toHaveBeenCalledWith(['1', '2'])
  })
})
