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
  'jsx/conditional_release_stats/components/student-range',
], (React, TestUtils, StudentRange) => {

  QUnit.module('Student Range')

  const defaultProps = () => ({
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
          user: { name: 'Foo Bar' },
        },
        {
          user: { name: 'Bar Foo' },
        },
      ],
    },
    loadStudent: () => {},
    onStudentSelect: () => {},
  })

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <StudentRange {...props} />
    )
  }

  test('renders items correctly', () => {
    const props = defaultProps()
    const component = renderComponent(props)

    const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'crs-student-range__item')
    equal(renderedList.length, props.range.students.length, 'renders full component')
  })
})
