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

import {isEmpty} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import App from 'jsx/epub_exports/App'
import CourseEpubExportStore from 'jsx/epub_exports/CourseStore'

QUnit.module('AppSpec', {
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
    return sinon.stub(CourseEpubExportStore, 'getAll').returns(true)
  },
  teardown() {
    return CourseEpubExportStore.getAll.restore()
  }
})

test('handeCourseStoreChange', function() {
  const AppElement = <App />
  const component = TestUtils.renderIntoDocument(AppElement)
  ok(isEmpty(component.state), 'precondition')
  CourseEpubExportStore.setState(this.props)
  deepEqual(
    component.state,
    CourseEpubExportStore.getState(),
    'CourseEpubExportStore.setState should trigger component setState'
  )
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
})
