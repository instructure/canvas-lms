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
import ModuleAssignments, {type ModuleAssignmentsProps} from '../ModuleAssignments'
import fetchMock from 'fetch-mock'
import {FILTERED_SECTIONS_DATA, FILTERED_STUDENTS_DATA, SECTIONS_DATA, STUDENTS_DATA} from './mocks'

const props: ModuleAssignmentsProps = {
  courseId: '1',
  onSelect: jest.fn(),
  defaultValues: [],
}

const SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections`
const STUDENTS_URL = `api/v1/courses/${props.courseId}/users?enrollment_type=student`
const FILTERED_SECTIONS_URL = /\/api\/v1\/courses\/.+\/sections\?search_term=.+/
const FILTERED_STUDENTS_URL =
  /\/api\/v1\/courses\/.+\/users\?search_term=.+&enrollment_type=student/

describe('ModuleAssignments', () => {
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

  const renderComponent = (overrides?: Partial<typeof props>) =>
    render(<ModuleAssignments {...props} {...overrides} />)

  it('displays sections and students as options', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    await findByText(SECTIONS_DATA[0].name)
    SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    STUDENTS_DATA.forEach(student => {
      expect(getByText(student.name)).toBeInTheDocument()
    })
  })

  it('shows sis id in list', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    await findByText(STUDENTS_DATA[0].name)
    STUDENTS_DATA.forEach(student => {
      expect(getByText(student.sis_user_id)).toBeInTheDocument()
    })
  })

  it('fetches filtered results from both APIs', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    fireEvent.change(moduleAssignments, {target: {value: 'sec'}})
    await findByText(FILTERED_SECTIONS_DATA[0].name)
    FILTERED_SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    FILTERED_STUDENTS_DATA.forEach(student => {
      expect(getByText(student.name)).toBeInTheDocument()
    })
  })

  it('allows filtering by SIS ID', async () => {
    const {findByTestId, findByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    fireEvent.change(moduleAssignments, {target: {value: 'raNDoM_iD_8'}})
    expect(await findByText('Secilia')).toBeInTheDocument()
  })

  it('shows SIS ID on existing options', async () => {
    const {findByTestId, findByText, getByTitle} = renderComponent({
      defaultValues: [{id: 'student-2', group: 'Students', overrideId: '1234', value: 'Peter'}],
    })
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    act(() => getByTitle('Remove Peter').click())
    expect(await findByText('peter002')).toBeInTheDocument()
  })

  it('calls onSelect with parsed options', async () => {
    const onSelect = jest.fn()
    const {findByTestId, findByText} = renderComponent({onSelect})
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    const option1 = await findByText(SECTIONS_DATA[0].name)
    act(() => option1.click())
    expect(onSelect).toHaveBeenCalledWith([
      {group: 'Sections', id: `section-${SECTIONS_DATA[0].id}`, value: SECTIONS_DATA[0].name},
    ])
  })

  it('shows defaultValues as default selection', async () => {
    const defaultValues = [
      {id: '1', value: 'section A'},
      {id: '2', value: 'section B'},
    ]
    const {getAllByTestId, getByText} = renderComponent({defaultValues})
    expect(getByText(defaultValues[0].value)).toBeInTheDocument()
    expect(getByText(defaultValues[1].value)).toBeInTheDocument()
    expect(getAllByTestId('assignee_selector_selected_option').length).toBe(defaultValues.length)
  })
})
