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

define(
  ['react', 'react-addons-test-utils', 'jsx/shared/load-more'],
  (React, TestUtils, LoadMore) => {
    QUnit.module('LoadMore')

    function defaultProps() {
      return {
        hasMore: false,
        loadMore: () => {},
        isLoading: false
      }
    }

    test('renders the load more component', () => {
      let component = TestUtils.renderIntoDocument(<LoadMore {...defaultProps()} />)
      let loadMore = TestUtils.findRenderedDOMComponentWithClass(component, 'LoadMore')
      ok(loadMore)
    })

    test('function is called on load more link click', () => {
      let onItemClicked = false
      let props = defaultProps()
      props.hasMore = true
      props.loadMore = () => {
        onItemClicked = true
      }
      let component = TestUtils.renderIntoDocument(<LoadMore {...props} />)
      let loadMore = TestUtils.findRenderedDOMComponentWithClass(component, 'LoadMore')
      let button = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'Button--link'
      ).getDOMNode()
      TestUtils.Simulate.click(button)
      ok(onItemClicked)
    })
  }
)
