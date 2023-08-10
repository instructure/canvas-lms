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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {EnrollmentTree} from '../EnrollmentTree'
import fetchMock from 'fetch-mock'

const simpleProps = {
  roles: [
    {id: '92', base_role_name: 'StudentEnrollment', label: 'StudentRole'},
    {id: '93', base_role_name: 'TeacherEnrollment', label: 'SubTeacherRole'},
  ],
  selectRoleId: '',
  list: [
    {id: '1', course_id: '11', course_section_id: '111', role_id: '93'},
    {id: '2', course_id: '11', course_section_id: '111', role_id: '92'},
    {id: '3', course_id: '11', course_section_id: '112', role_id: '93'},
  ],
}

const complexProps = {
  roles: [
    {id: '92', base_role_name: 'StudentEnrollment', label: 'StudentRole'},
    {id: '93', base_role_name: 'TeacherEnrollment', label: 'SubTeacherRole'},
    {id: '94', base_role_name: 'DesignerEnrollment', label: 'DesignRole'},
  ],
  selectRoleId: '',
  list: [
    {id: '1', course_id: '11', course_section_id: '111', role_id: '93'},
    {id: '2', course_id: '11', course_section_id: '111', role_id: '92'},
    {id: '3', course_id: '11', course_section_id: '112', role_id: '92'},
    {id: '4', course_id: '11', course_section_id: '112', role_id: '94'},
  ],
}

describe('EnrollmentTree', () => {
  beforeEach(() => {
    fetchMock.get(`/api/v1/courses/11`, {name: 'course1', workflow_state: 'available'})
    fetchMock.get('/api/v1/courses/11/sections/111', {name: 'section1'})
    fetchMock.get('/api/v1/courses/11/sections/112', {name: 'section2'})
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders role groups', async () => {
    const {getByText} = render(<EnrollmentTree {...simpleProps} />)
    await waitFor(() => expect(getByText('StudentRole')).toBeInTheDocument())
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
  })

  it('renders children after clicking toggle', async () => {
    const screen = render(<EnrollmentTree {...simpleProps} />)
    await waitFor(() => {
      expect(screen.getByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    })
    const roleGroup = screen.getByText('Toggle group StudentRole')
    fireEvent.click(roleGroup)
    expect(await screen.findByText('course1 - section1')).toBeInTheDocument()
  })

  it('hides children after clicking toggle', async () => {
    const screen = render(<EnrollmentTree {...simpleProps} />)
    await waitFor(() => {
      expect(screen.getByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    })
    const roleGroup = screen.getByText('Toggle group StudentRole')
    fireEvent.click(roleGroup)
    expect(await screen.findByText('course1 - section1')).toBeInTheDocument()

    fireEvent.click(roleGroup)
    expect(await screen.queryByText('course1 - section1')).not.toBeInTheDocument()
  })

  it('renders enrollments in order of base role', async () => {
    const {getByText} = render(<EnrollmentTree {...complexProps} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
    const student = getByText('StudentRole')
    const sub = getByText('SubTeacherRole')
    const designer = getByText('DesignRole')
    // SubTeacher is above Designer in list
    expect(sub.compareDocumentPosition(designer)).toBe(4)
    // Designer is above Student in List
    expect(designer.compareDocumentPosition(student)).toBe(4)
  })

  it('selects teacher base roles by default', async () => {
    const {getByText, getByRole} = render(<EnrollmentTree {...complexProps} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())

    const checkedBox = getByRole('checkbox', {checked: true})
    expect(checkedBox.getAttribute('data-testid')).toMatch('check r93')
  })

  it('shows enrollments in one section with different roles under respective role groups', async () => {
    const screen = render(<EnrollmentTree {...complexProps} />)
    await waitFor(() => {
      expect(screen.getByText('Toggle group StudentRole')).toBeInTheDocument()
    })
    const stuGroup = screen.getByText('Toggle group StudentRole')
    fireEvent.click(stuGroup)
    expect(await screen.findByText('course1')).toBeInTheDocument()

    const desGroup = screen.getByText('Toggle group DesignRole')
    fireEvent.click(desGroup)
    expect(await screen.findByText('course1 - section2')).toBeInTheDocument()
  })

  it('checks children when group is checked', async () => {
    const {getByText, getAllByRole, getByTestId} = render(<EnrollmentTree {...complexProps} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
    const parentBox = getByTestId('check r92')
    fireEvent.click(parentBox)

    // includes default teacher check
    await waitFor(() => expect(getAllByRole('checkbox', {checked: true}).length).toBe(2))
    fireEvent.click(getByText('Toggle group StudentRole'))
    const allChecked = getAllByRole('checkbox', {checked: true})
    // parent + child + default
    expect(allChecked.length).toBe(3)
  })
})
