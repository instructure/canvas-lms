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
import UploadArea from 'jsx/course_settings/components/UploadArea'

QUnit.module('UploadArea Component')

test('it renders', () => {
  const component = TestUtils.renderIntoDocument(<UploadArea />)

  ok(component)
})

test('calls the handleFileUpload prop when change occurs on the file input', () => {
  let called = false
  const handleFileUploadFunc = () => (called = true)
  const component = TestUtils.renderIntoDocument(
    <UploadArea courseId="101" handleFileUpload={handleFileUploadFunc} />
  )

  const input = TestUtils.findRenderedDOMComponentWithClass(component, 'FileUpload__Input')
  TestUtils.Simulate.change(input)
  ok(called, 'handleFileUpload was called')
})
