/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import useManagedCourseSearchApi from '@canvas/direct-sharing/react/effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi, {
  useCourseModuleItemApi,
} from '@canvas/direct-sharing/react/effects/useModuleCourseSearchApi'
import DirectShareCoursePanel from '../DirectShareCoursePanel'

jest.mock('@canvas/direct-sharing/react/effects/useManagedCourseSearchApi')
jest.mock('@canvas/direct-sharing/react/effects/useModuleCourseSearchApi')

const defaultProps = {
  selectedCourseId: null,
  onSelectCourse: jest.fn(),
  selectedModuleId: null,
  onSelectModule: jest.fn(),
  onSelectPosition: jest.fn(),
}

const renderComponent = (props = {}) =>
  render(<DirectShareCoursePanel {...defaultProps} {...props} />)

describe('DirectShareCoursePanel', () => {
  let ariaLive: HTMLElement

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  it('shows course selector by default', async () => {
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc', course_code: '1', term: 'default term'},
        {id: 'cde', name: 'cde', course_code: '2', term: 'default term'},
      ])
    })
    renderComponent()

    const input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, 'abc')
    await userEvent.click(screen.getByText('abc'))
    expect(defaultProps.onSelectCourse).toHaveBeenLastCalledWith({
      id: 'abc',
      name: 'abc',
      course_code: '1',
      term: 'default term',
    })
  })

  it('shows the course and module selector when a course is given', async () => {
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    ;(useModuleCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    renderComponent({selectedCourseId: 'abc'})
    const input = await screen.getByLabelText(/select a module/i)
    await userEvent.click(input)
    await userEvent.type(input, 'abc')
    await userEvent.click(screen.getByText('Module 1'))
    expect(defaultProps.onSelectModule).toHaveBeenLastCalledWith({id: '1', name: 'Module 1'})
  })

  it('shows the position selector when a module is given', async () => {
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    ;(useModuleCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    ;(useCourseModuleItemApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'a', title: 'Item 1', position: '5'},
        {id: 'b', title: 'Item 2', position: '6'},
      ])
    })
    renderComponent({selectedCourseId: 'abc', selectedModuleId: '1'})
    await userEvent.type(screen.getByTestId('select-position'), 'At the Top')
    await userEvent.click(screen.getByText(/At the Top/i))
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(1)
  })

  it('hides the assignments selector when a course is given but assignments are not shown', () => {
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
    renderComponent({selectedCourseId: 'abc'})
    expect(screen.queryByText(/select an assignment/i)).not.toBeInTheDocument()
  })
})
