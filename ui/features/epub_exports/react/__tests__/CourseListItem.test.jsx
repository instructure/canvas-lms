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
import CourseListItem from '../CourseListItem'

let props

describe('CourseListItemSpec', () => {
  beforeEach(() => {
    props = {
      course: {
        name: 'Maths 101',
        id: 1,
      },
    }
  })

  test('getDisplayState', function () {
    let CourseListItemElement = <CourseListItem {...props} />
    let component = TestUtils.renderIntoDocument(CourseListItemElement)
    // 'display state should be null without epub_export'
    expect(isNull(component.getDisplayState())).toBeTruthy()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
    props.course = {
      epub_export: {
        permissions: {},
        workflow_state: 'generating',
      },
    }
    CourseListItemElement = <CourseListItem {...props} />
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    // 'display state should not be null with epub_export'
    expect(!isNull(component.getDisplayState())).toBeTruthy()
    // 'should include workflow_state'
    expect(component.getDisplayState().match('Generating')).toBeTruthy()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })

  test('render', function () {
    const CourseListItemElement = <CourseListItem {...props} />
    const component = TestUtils.renderIntoDocument(CourseListItemElement)
    // 'should render with course'
    expect(!isNull(ReactDOM.findDOMNode(component))).toBeTruthy()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })
})
