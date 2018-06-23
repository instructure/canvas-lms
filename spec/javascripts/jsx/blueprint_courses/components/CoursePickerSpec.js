/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import * as enzyme from 'enzyme'
import CoursePicker from 'jsx/blueprint_courses/components/CoursePicker'
import getSampleData from '../getSampleData'

QUnit.module('CoursePicker component')

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
  const tree = enzyme.shallow(<CoursePicker {...defaultProps()} />)
  const node = tree.find('.bca-course-picker')
  ok(node.exists())
})

test('displays spinner when loading courses', () => {
  const props = defaultProps()
  props.isLoadingCourses = true
  const tree = enzyme.shallow(<CoursePicker {...props} />)
  const node = tree.find('.bca-course-picker__loading')
  ok(node.exists())
})

test('calls loadCourses when filters are updated', () => {
  const props = defaultProps()
  props.loadCourses = sinon.spy()
  const tree = enzyme.mount(<CoursePicker {...props} />)
  const picker = tree.instance()

  picker.onFilterChange({
    term: '',
    subAccount: '',
    search: 'one',
  })

  ok(props.loadCourses.calledOnce)
})
