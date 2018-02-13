/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import CourseList from 'jsx/epub_exports/CourseList'

QUnit.module('CourseListSpec', {
  setup() {
    this.props = {
      1: {
        name: 'Maths 101',
        id: 1
      },
      2: {
        name: 'Physics 101',
        id: 2
      }
    }
  }
})

test('render', function() {
  let CourseListElement = <CourseList courses={{}} />
  let component = TestUtils.renderIntoDocument(CourseListElement)
  let node = component.getDOMNode()
  equal(node.querySelectorAll('li').length, 0, 'should not render list items')
  ReactDOM.unmountComponentAtNode(node.parentNode)
  CourseListElement = <CourseList courses={this.props} />
  component = TestUtils.renderIntoDocument(CourseListElement)
  node = component.getDOMNode()
  equal(
    node.querySelectorAll('li').length,
    Object.keys(this.props).length,
    'should have an li element per course in @props'
  )
  ReactDOM.unmountComponentAtNode(node.parentNode)
})
