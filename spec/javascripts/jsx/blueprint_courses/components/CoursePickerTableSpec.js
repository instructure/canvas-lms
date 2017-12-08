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
import CoursePickerTable from 'jsx/blueprint_courses/components/CoursePickerTable'
import getSampleData from '../getSampleData'

QUnit.module('CoursePickerTable component')

const defaultProps = () => ({
  courses: getSampleData().courses,
  selectedCourses: [],
  onSelectedChanged: () => {},
})

test('renders the CoursePickerTable component', () => {
  const tree = enzyme.shallow(<CoursePickerTable {...defaultProps()} />)
  const node = tree.find('.bca-table__wrapper')
  ok(node.exists())
})

test('show no results if no courses passed in', () => {
  const props = defaultProps()
  props.courses = []
  const tree = enzyme.shallow(<CoursePickerTable {...props} />)
  const node = tree.find('.bca-table__no-results')
  ok(node.exists())
})

test('displays correct table data', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<CoursePickerTable {...props} />)
  const rows = tree.find('.bca-table__course-row')

  equal(rows.length, props.courses.length)
  equal(rows.at(0).find('td').at(1).text(), props.courses[0].name)
  equal(rows.at(1).find('td').at(1).text(), props.courses[1].name)
})

test('calls onSelectedChanged when courses are selected', () => {
  const props = defaultProps()
  props.onSelectedChanged = sinon.spy()
  const tree = enzyme.mount(<CoursePickerTable {...props} />)
  const checkbox = tree.find('.bca-table__course-row input[type="checkbox"]')
  checkbox.at(0).simulate('change', { target: { checked: true, value: '1' } })

  equal(props.onSelectedChanged.callCount, 1)
  deepEqual(props.onSelectedChanged.getCall(0).args[0], { added: ['1'], removed: [] })
})

test('calls onSelectedChanged when courses are unselected', () => {
  const props = defaultProps()
  props.selectedCourses = ['1']
  props.onSelectedChanged = sinon.spy()
  const tree = enzyme.mount(<CoursePickerTable {...props} />)
  const checkbox = tree.find('.bca-table__course-row input[type="checkbox"]')
  checkbox.at(0).simulate('change', { target: { checked: false, value: '1' } })

  equal(props.onSelectedChanged.callCount, 1)
  deepEqual(props.onSelectedChanged.getCall(0).args[0], { removed: ['1'], added: [] })
})

test('calls onSelectedChanged with correct data when "Select All" is selected', () => {
  const props = defaultProps()
  props.onSelectedChanged = sinon.spy()
  const tree = enzyme.mount(<CoursePickerTable {...props} />)

  const checkbox = tree.find('.btps-table__header-wrapper input[type="checkbox"]')
  checkbox.at(0).simulate('change', { target: { checked: true, value: 'all' } })

  equal(props.onSelectedChanged.callCount, 1)
  deepEqual(props.onSelectedChanged.getCall(0).args[0], { added: ['1', '2'], removed: [] })
})

test('handleFocusLoss focuses the next item', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<CoursePickerTable {...props} />)
  const instance = tree.instance()

  const check = tree.find('.bca-table__course-row input[type="checkbox"]').at(0).instance()
  check.focus = sinon.spy()

  instance.handleFocusLoss(0)
  equal(check.focus.callCount, 1)
})

test('handleFocusLoss focuses the previous item if called on the last item', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<CoursePickerTable {...props} />)
  const instance = tree.instance()

  const check = tree.find('.bca-table__course-row input[type="checkbox"]').at(1).instance()
  check.focus = sinon.spy()

  instance.handleFocusLoss(2)
  equal(check.focus.callCount, 1)
})

test('handleFocusLoss focuses on select all if no items left', () => {
  const props = defaultProps()
  props.courses = []
  const tree = enzyme.mount(<CoursePickerTable {...props} />)
  const instance = tree.instance()

  const check = tree.find('.bca-table__select-all input[type="checkbox"]').at(0).instance()
  check.focus = sinon.spy()

  instance.handleFocusLoss(1)
  equal(check.focus.callCount, 1)
})
