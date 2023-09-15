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
}

const SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections`
const STUDENTS_URL = `api/v1/courses/${props.courseId}/users?enrollment_type=student`
const FILTERED_SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections?search_term=sec`
const FILTERED_STUDENTS_URL = `api/v1/courses/${props.courseId}/users?search_term=sec&enrollment_type=student`

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
  })
  afterEach(() => {
    fetchMock.restore()
  })

  const renderComponent = () => render(<AssigneeSelector {...props} />)

  it('displays sections and students as options', async () => {
    const {getByTestId, findByText, getByText} = renderComponent()
    act(() => getByTestId('assignee_selector').click())
    await findByText(SECTIONS_DATA[0].name)
    SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    STUDENTS_DATA.forEach(student => {
      expect(getByText(student.name)).toBeInTheDocument()
    })
  })

  it('fetches filtered results from both APIs', async () => {
    const {getByTestId, findByText, getByText} = renderComponent()
    const assigneeSelector = getByTestId('assignee_selector')
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

  it('selects multiple options', async () => {
    const {getByTestId, findByText, getAllByTestId} = renderComponent()
    act(() => getByTestId('assignee_selector').click())
    const option1 = await findByText(SECTIONS_DATA[0].name)
    act(() => option1.click())
    act(() => getByTestId('assignee_selector').click())
    const option2 = await findByText(SECTIONS_DATA[2].name)
    act(() => option2.click())
    expect(getAllByTestId('assignee_selector_option').length).toBe(2)
  })

  it('clears selection', async () => {
    const {getByTestId, queryAllByTestId, findByText} = renderComponent()
    act(() => getByTestId('assignee_selector').click())
    const option = await findByText(STUDENTS_DATA[0].name)
    act(() => option.click())
    expect(queryAllByTestId('assignee_selector_option').length).toBe(1)
    act(() => getByTestId('clear_selection_button').click())
    expect(queryAllByTestId('assignee_selector_option').length).toBe(0)
  })
})
