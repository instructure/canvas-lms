/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import CourseDefaultDueTime from '../CourseDefaultDueTime'

function createFormField(wrapper: HTMLElement, id: string, value: string): void {
  const field = document.createElement('input')
  field.setAttribute('type', 'hidden')
  field.setAttribute('id', id)
  field.setAttribute('name', id)
  field.setAttribute('value', value)
  wrapper.appendChild(field)
}

function renderComponent(wrapper: HTMLElement) {
  createFormField(wrapper, 'course_default_due_time', '05:00:00')

  return render(<CourseDefaultDueTime />, {container: wrapper})
}

describe('CourseDefaultDueTime', () => {
  let wrapper: HTMLElement

  beforeEach(() => {
    wrapper = document.createElement('div')
    document.body.appendChild(wrapper)
  })

  afterEach(() => {
    if (wrapper && wrapper.parentNode) {
      wrapper.parentNode.removeChild(wrapper)
    }
  })

  describe('can render', () => {
    it('renders course default due time', () => {
      const {getByLabelText} = renderComponent(wrapper)
      expect(getByLabelText('Choose a time')).toBeInTheDocument()
    })
  })
})
