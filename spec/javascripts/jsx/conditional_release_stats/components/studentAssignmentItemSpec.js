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
import AssignmentItem from 'jsx/conditional_release_stats/components/student-assignment-item'

QUnit.module('Student Assignment Item')

const renderComponent = props => TestUtils.renderIntoDocument(<AssignmentItem {...props} />)

const defaultProps = () => ({
  assignment: {
    name: 'hello world',
    grading_type: 'percent',
    points_possible: 100,
    submission_types: ['online_text_entry']
  },
  trend: 0,
  score: 0.8
})

test('renders assignment item correctly', () => {
  const component = renderComponent(defaultProps())

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student-details__assignment'
  )
  equal(renderedList.length, 1, 'does not render crs-student-details__assignment')
})

test('renders bar inner-components correctly', () => {
  const component = renderComponent(defaultProps())

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student-details__assignment-icon'
  )
  equal(renderedList.length, 1, 'does not render student details assignment icon')
})

test('renders name correctly', () => {
  const component = renderComponent(defaultProps())

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student-details__assignment-name'
  )
  equal(
    renderedList[0].textContent,
    'hello world',
    'does not render student details assignment name'
  )
})

test('renders trend icon', () => {
  const component = renderComponent(defaultProps())

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon'
  )
  equal(renderedList.length, 1, 'does not render trend icon')
})

test('renders correct icon type', () => {
  const component = renderComponent(defaultProps())

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'icon-assignment')
  equal(renderedList.length, 1, 'does not render correct assignment icon type')
})

test('renders no trend correctly', () => {
  const props = defaultProps()
  props.trend = null
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon'
  )
  equal(renderedList.length, 0)
})

test('renders positive trend correctly', () => {
  const props = defaultProps()
  props.trend = 1
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon__positive'
  )
  equal(renderedList.length, 1, 'does not render positive trend icon')
})

test('renders neutral trend correctly', () => {
  const props = defaultProps()
  props.trend = 0
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon__neutral'
  )
  equal(renderedList.length, 1, 'does not render neutral trend icon')
})

test('renders negative trend correctly', () => {
  const props = defaultProps()
  props.trend = -1
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'crs-student__trend-icon__negative'
  )
  equal(renderedList.length, 1, 'does not render negative trend icon')
})
