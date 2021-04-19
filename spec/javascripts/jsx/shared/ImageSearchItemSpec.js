/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ImageSearchItem from 'ui/features/course_settings/react/components/ImageSearchItem.js'

QUnit.module('ImageSearchItem View')

test('it renders', () => {
  const image = TestUtils.renderIntoDocument(<ImageSearchItem />)
  ok(image)
})

test('it calls selectImage when clicked', () => {
  let called = false
  const selectImage = imageUrl => (called = true)

  const imageItem = TestUtils.renderIntoDocument(
    <ImageSearchItem url="http://imageUrl" selectImage={selectImage} />
  )

  TestUtils.Simulate.click(
    TestUtils.findRenderedDOMComponentWithClass(imageItem, 'ImageSearch__item')
  )

  ok(called, 'selectImage was called')
})
