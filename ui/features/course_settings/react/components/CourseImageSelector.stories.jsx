/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import CourseImageSelector from './CourseImageSelector'

const initialState = {
  courseImage: 'abc',
  imageUrl: 'http://placekitten.com/1000/100',
  showModal: false,
  gettingImage: false,
  uploadingImage: false,
  removingImage: false,
}

export default {
  title: 'Examples/Course Settings/CourseImageSelector',
  component: CourseImageSelector,
}

const Template = args => (
  <CourseImageSelector
    courseId="1"
    setting="foo"
    store={{
      getState: () => initialState,
      subscribe: cb => setTimeout(cb),
      dispatch: Function.prototype,
    }}
    {...args}
  />
)

export const WithImage = Template.bind({})
