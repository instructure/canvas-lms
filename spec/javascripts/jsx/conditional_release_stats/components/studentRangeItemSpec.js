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

import TestUtils from 'react-dom/test-utils'
import StudentRangeItem from 'jsx/conditional_release_stats/components/student-range-item'

QUnit.module('Student Range Item')

const defaultProps = () => ({
  studentIndex: 0,
  student: {
    user: {name: 'Foo Bar'},
    trend: 0
  },
  selectStudent: () => {}
})

const renderComponent = props => TestUtils.renderIntoDocument(<StudentRangeItem {...props} />)

test('renders name correctly', () => {
  const component = renderComponent(defaultProps())

  const renderedList = TestUtils.findRenderedDOMComponentWithClass(component, 'crs-student__name')
  equal(renderedList.textContent, 'Foo Bar', 'renders student name')
})

test('renders no trend correctly', () => {
  const props = defaultProps()
  props.student.trend = null
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon'
  )
  equal(renderedList.length, 0, 'renders component')
})

test('renders positive trend correctly', () => {
  const props = defaultProps()
  props.student.trend = 1
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon__positive'
  )
  equal(renderedList.length, 1, 'renders component')
})

test('renders neutral trend correctly', () => {
  const props = defaultProps()
  props.student.trend = 0
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon__neutral'
  )
  equal(renderedList.length, 1, 'renders component')
})

test('renders negative trend correctly', () => {
  const props = defaultProps()
  props.student.trend = -1
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon__negative'
  )
  equal(renderedList.length, 1, 'renders component')
})
