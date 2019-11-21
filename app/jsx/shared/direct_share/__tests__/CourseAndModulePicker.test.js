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
import {render} from '@testing-library/react'
import useManagedCourseSearchApi from 'jsx/shared/effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from 'jsx/shared/effects/useModuleCourseSearchApi'
import CourseAndModulePicker from '../CourseAndModulePicker'

jest.mock('jsx/shared/effects/useManagedCourseSearchApi')
jest.mock('jsx/shared/effects/useModuleCourseSearchApi')

describe('CourseAndModulePicker', () => {
  let ariaLive

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  it('enables the module selector when a course is selected', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
      success([{id: 'abc', name: 'abc'}, {id: 'cde', name: 'cde'}])
    })
    useModuleCourseSearchApi.mockImplementationOnce(({success}) => {
      success([{id: '1', name: 'Module 1'}, {id: '2', name: 'Module 2'}])
    })
    const {getByText} = render(<CourseAndModulePicker selectedCourseId="abc" />)
    expect(getByText(/select a course/i)).toBeInTheDocument()
    expect(getByText(/select a module/i)).toBeInTheDocument()
  })
})
