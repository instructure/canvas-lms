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
import {shallow} from 'enzyme'
import sinon from 'sinon'
import CoursePicker from '../CoursePicker'
import getSampleData from './getSampleData'

describe('CoursePicker component', () => {
  const defaultProps = () => ({
    courses: getSampleData().courses,
    selectedCourses: [],
    subAccounts: getSampleData().subAccounts,
    terms: getSampleData().terms,
    isLoadingCourses: false,
    loadCourses: () => {},
    onSelectedChanged: () => {},
  })

  test('renders the CoursePicker component', () => {
    const tree = shallow(<CoursePicker {...defaultProps()} />)
    const node = tree.find('.bca-course-picker')
    expect(node.exists()).toBeTruthy()
  })

  test('displays spinner when loading courses', () => {
    const props = defaultProps()
    props.isLoadingCourses = true
    const tree = shallow(<CoursePicker {...props} />)
    const node = tree.find('.bca-course-picker__loading')
    expect(node.exists()).toBeTruthy()
  })

  test('calls loadCourses when filters are updated', () => {
    const props = defaultProps()
    props.loadCourses = sinon.spy()
    const ref = React.createRef()
    const tree = render(<CoursePicker {...props} ref={ref} />)
    const picker = ref.current

    picker.onFilterChange({
      term: '',
      subAccount: '',
      search: 'one',
    })

    expect(props.loadCourses.calledOnce).toBeTruthy()
  })
})
