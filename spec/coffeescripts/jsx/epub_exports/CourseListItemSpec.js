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

import {isNull} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import CourseListItem from 'jsx/epub_exports/CourseListItem'

QUnit.module('CourseListItemSpec', {
  setup() {
    this.props = {
      course: {
        name: 'Maths 101',
        id: 1
      }
    }
  }
})

test('getDisplayState', function() {
  let CourseListItemElement = <CourseListItem {...this.props} />
  let component = TestUtils.renderIntoDocument(CourseListItemElement)
  ok(isNull(component.getDisplayState()), 'display state should be null without epub_export')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  this.props.course = {
    epub_export: {
      permissions: {},
      workflow_state: 'generating'
    }
  }
  CourseListItemElement = <CourseListItem {...this.props} />
  component = TestUtils.renderIntoDocument(CourseListItemElement)
  ok(!isNull(component.getDisplayState()), 'display state should not be null with epub_export')
  ok(component.getDisplayState().match('Generating'), 'should include workflow_state')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
})

test('render', function() {
  const CourseListItemElement = <CourseListItem {...this.props} />
  const component = TestUtils.renderIntoDocument(CourseListItemElement)
  ok(!isNull(ReactDOM.findDOMNode(component)), 'should render with course')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
})
