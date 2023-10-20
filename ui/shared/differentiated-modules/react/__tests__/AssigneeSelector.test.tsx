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
import {act, fireEvent, render} from '@testing-library/react'
import AssigneeSelector from '../AssigneeSelector'
import fetchMock from 'fetch-mock'
import {FILTERED_SECTIONS_DATA, FILTERED_STUDENTS_DATA, SECTIONS_DATA, STUDENTS_DATA} from './mocks'

const props = {
  courseId: '1',
  moduleId: '2',
  onSelect: jest.fn(),
  selectedOptionIds: [],
}

const SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections`
const STUDENTS_URL = `api/v1/courses/${props.courseId}/users?enrollment_type=student`
const FILTERED_SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections?search_term=sec`
const FILTERED_STUDENTS_URL = `api/v1/courses/${props.courseId}/users?search_term=sec&enrollment_type=student`
const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/${props.courseId}/modules/${props.moduleId}/assignment_overrides`

describe('AssigneeSelector', () => {
  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  beforeEach(() => {
    fetchMock.getOnce(SECTIONS_URL, SECTIONS_DATA)
    fetchMock.getOnce(STUDENTS_URL, STUDENTS_DATA)
    fetchMock.getOnce(FILTERED_SECTIONS_URL, FILTERED_SECTIONS_DATA)
    fetchMock.getOnce(FILTERED_STUDENTS_URL, FILTERED_STUDENTS_DATA)
    fetchMock.getOnce(ASSIGNMENT_OVERRIDES_URL, [])
  })

  afterEach(() => {
    fetchMock.restore()
  })

  const renderComponent = (overrides?: Partial<typeof props>) =>
    render(<AssigneeSelector {...props} {...overrides} />)

  it('displays sections and students as options', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const assigneeSelector = await findByTestId('assignee_selector')
    act(() => assigneeSelector.click())
    await findByText(SECTIONS_DATA[0].name)
    SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    STUDENTS_DATA.forEach(student => {
      expect(getByText(student.name)).toBeInTheDocument()
    })
  })

  it('fetches filtered results from both APIs', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const assigneeSelector = await findByTestId('assignee_selector')
    act(() => assigneeSelector.click())
    fireEvent.change(assigneeSelector, {target: {value: 'sec'}})
    await findByText(FILTERED_SECTIONS_DATA[0].name)
    FILTERED_SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    FILTERED_STUDENTS_DATA.forEach(student => {
      expect(getByText(student.name)).toBeInTheDocument()
    })
  })

  it('calls onSelect with parsed options', async () => {
    const onSelect = jest.fn()
    const {findByTestId, findByText} = renderComponent({onSelect})
    const assigneeSelector = await findByTestId('assignee_selector')
    act(() => assigneeSelector.click())
    const option1 = await findByText(SECTIONS_DATA[0].name)
    act(() => option1.click())
    expect(onSelect).toHaveBeenCalledWith([
      {group: 'Sections', id: `section-${SECTIONS_DATA[0].id}`, value: SECTIONS_DATA[0].name},
    ])
  })
})
