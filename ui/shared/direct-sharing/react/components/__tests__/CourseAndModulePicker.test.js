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
import {render, fireEvent} from '@testing-library/react'
import useManagedCourseSearchApi from '../../effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi, {
  useCourseModuleItemApi,
} from '../../effects/useModuleCourseSearchApi'
import CourseAndModulePicker from '../CourseAndModulePicker'

jest.mock('../../effects/useManagedCourseSearchApi')
jest.mock('../../effects/useModuleCourseSearchApi')

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

  it('shows course selector by default', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    const setCourse = jest.fn()
    const {getByText} = render(<CourseAndModulePicker setSelectedCourse={setCourse} />)
    const selector = getByText(/select a course/i)
    fireEvent.click(selector)
    fireEvent.click(getByText('abc'))
    expect(setCourse).toHaveBeenLastCalledWith({id: 'abc', name: 'abc'})
  })

  it('shows the course and module selector when a course is given', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    useModuleCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    const setModule = jest.fn()
    const {getByText} = render(
      <CourseAndModulePicker selectedCourseId="abc" setSelectedModule={setModule} />
    )
    const selector = getByText(/select a module/i)
    fireEvent.click(selector)
    fireEvent.click(getByText('Module 1'))
    expect(setModule).toHaveBeenLastCalledWith({id: '1', name: 'Module 1'})
  })

  it('shows the position selector when a module is given', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    useModuleCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    useCourseModuleItemApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'a', title: 'Item 1', position: '5'},
        {id: 'b', title: 'Item 2', position: '6'},
      ])
    })
    const setPosition = jest.fn()
    const {getByTestId} = render(
      <CourseAndModulePicker
        selectedCourseId="abc"
        selectedModuleId="1"
        setModuleItemPosition={setPosition}
      />
    )
    const selector = getByTestId('select-position')
    fireEvent.change(selector, {target: {value: 'top'}})
    expect(setPosition).toHaveBeenLastCalledWith(1)
  })

  it('hides the module selector if requested', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    useModuleCourseSearchApi.mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    const setModule = jest.fn()
    const {queryByText} = render(
      <CourseAndModulePicker
        selectedCourseId="abc"
        setSelectedModule={setModule}
        disableModuleInsertion={true}
      />
    )
    const selector = queryByText(/select a module/i)
    expect(selector).not.toBeInTheDocument()
  })
})
