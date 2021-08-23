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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import {getByText} from '@testing-library/dom'
import CourseImagePicker from 'ui/features/course_settings/react/components/CourseImagePicker.js'

const wrapper = document.getElementById('fixtures')
const reset_env = window.ENV

QUnit.module('CourseImagePicker Component', {
  renderComponent(props = {}) {
    let courseImagePicker
    const element = React.createElement(CourseImagePicker, {
      ref: node => {
        courseImagePicker = node
      },
      courseId: 0,
      ...props
    })
    ReactDOM.render(element, wrapper)
    return courseImagePicker
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
    window.ENV = reset_env
  }
})

test('calls the handleFileUpload prop when drop occurs', function() {
  let called = false
  const handleFileUploadFunc = () => {
    called = true
  }
  const component = this.renderComponent({courseId: '101', handleFileUpload: handleFileUploadFunc})

  const area = TestUtils.findRenderedDOMComponentWithTag(component, 'label') // FileDrop's wrapped in a label

  TestUtils.Simulate.drop(area, {
    dataTransfer: {
      files: [{type: 'image/jpg', name: 'image.jpg', size: 10}]
    }
  })

  ok(called, 'handleFileUpload was called')
})

test('Unsplash tab can be selected', function() {
  window.ENV.use_unsplash_image_search = true
  const component = this.renderComponent({courseId: '101'})
  const imageSearchTab = getByText(wrapper, 'Unsplash')

  TestUtils.Simulate.click(imageSearchTab)

  strictEqual(
    TestUtils.scryRenderedDOMComponentsWithClass(component, 'Unsplash__logo').length,
    1,
    'the Unsplash tab content should appear'
  )
})
