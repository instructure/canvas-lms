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
import {render} from '@testing-library/react'
import CourseList from '../CourseList'

let props

describe('CourseListSpec', () => {
  beforeEach(() => {
    props = {
      1: {
        name: 'Maths 101',
        id: 1,
      },
      2: {
        name: 'Physics 101',
        id: 2,
      },
    }
  })

  it('render', function () {
    let component = render(<CourseList courses={{}} />)
    // 'should not render list items'
    expect(component.container.querySelectorAll('li').length).toBe(0)
    component.unmount()

    component = render(<CourseList courses={props} />)
    // 'should have an li element per course in @props'
    expect(component.container.querySelectorAll('li').length).toEqual(
      Object.keys(props).length
    )
    component.unmount()
  })
})
