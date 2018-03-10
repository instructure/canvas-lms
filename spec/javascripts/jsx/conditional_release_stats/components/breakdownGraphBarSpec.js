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

define([
  'react',
  'react-addons-test-utils',
  'jsx/conditional_release_stats/components/breakdown-graph-bar',
], (React, TestUtils, BreakdownBarComponent) => {

  QUnit.module('Breakdown Stats Graph Bar')

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <BreakdownBarComponent {...props} />
    )
  }

  const defaultProps = () => {
    return {
      upperBound: '100',
      lowerBound: '70',
      rangeStudents: 50,
      totalStudents: 100,
      rangeIndex: 0,
      selectRange: () => {},
      openSidebar: () => {}
    }
  }

  test('renders bar component correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__container')
    equal(renderedList.length, 1, 'renders full component')
  })

  test('renders bar inner-components correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-link-button')
    equal(renderedList.length, 1, 'renders full component')
  })

  test('renders bounds correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-bar__info')
    equal(renderedList[0].textContent, '70+ to 100', 'renders full component')
  })

  test('renders students in range correctly', () => {
    const component = renderComponent(defaultProps())

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-link-button')
    equal(renderedList[0].textContent, '50 out of 100 students', 'renders correct amount of students')
  })
})
