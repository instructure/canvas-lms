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
import {render, fireEvent} from '@testing-library/react'
import {TempEnrollAssign} from '../TempEnrollAssign'
import fetchMock from 'fetch-mock'

const backCall = jest.fn()

const falsePermissions = {
  teacher: true,
  ta: true,
  student: false,
  observer: true,
  designer: true,
}

const truePermissions = {
  teacher: true,
  ta: true,
  student: true,
  observer: true,
  designer: true,
}

const props = {
  enrollment: {login_id: 'mel123', email: 'mel@email.com', name: 'Melvin', sis_user_id: '5'},
  user: {
    name: 'John Smith',
    avatar_url: '',
    id: '1',
  },
  permissions: truePermissions,
  roles: [{id: '91', label: 'Student', base_role_name: 'StudentEnrollment'}],
  goBack: backCall,
}

const johnEnrollments = [
  // student enrollment
  {course_id: '1', course_section_id: '11', id: '1', role_id: '91'},
]

describe('TempEnrollAssign', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  beforeEach(() => {
    fetchMock.get(
      `/api/v1/users/1/enrollments?state%5B%5D=active&state%5B%5D=completed&state%5B%5D=invited`,
      johnEnrollments
    )
    fetchMock.get(`/api/v1/courses/1`, {name: 'coures1', workflow_state: 'available'})
    fetchMock.get('/api/v1/courses/1/sections/11', {name: 'section1'})
  })

  it('triggers goBack when back is clicked', async () => {
    const {findByText} = render(<TempEnrollAssign {...props} />)
    const backButton = await findByText('Back')
    fireEvent.click(backButton)
    expect(backCall).toHaveBeenCalled()
  })

  it('changes summary when role is selected', async () => {
    const screen = render(<TempEnrollAssign {...props} />)
    const roleSelect = await screen.findByPlaceholderText('Select a Role')
    expect(screen.getByText(/Canvas will enroll Melvin as a ROLE/)).toBeInTheDocument()
    fireEvent.click(roleSelect)
    const option = screen.getByRole('option')
    fireEvent.click(option)

    // Format: Canvas will enroll %{recipient} as a %{role} in %{source}'s selected courses from %{start} - %{end}
    expect(await screen.findByText(/Canvas will enroll Melvin as a Student/)).toBeInTheDocument()
  })

  it('changes summary when date and time changes', async () => {
    const {findByLabelText, findByTestId} = render(<TempEnrollAssign {...props} />)
    const startDate = await findByLabelText('Begins On')
    const endDate = await findByLabelText('Until')
    fireEvent.input(startDate, {target: {value: 'Apr 10 2022'}})
    fireEvent.blur(startDate)
    fireEvent.input(endDate, {target: {value: 'Apr 12 2022'}})
    fireEvent.blur(endDate)
    expect((await findByTestId('temp-enroll-summary')).textContent).toBe(
      "Canvas will enroll Melvin as a ROLE in John Smith's selected courses from 4/10/2022, 12:00 AM - 4/12/2022, 12:00 AM"
    )
  })

  it('shows error when start date is after end date', async () => {
    const screen = render(<TempEnrollAssign {...props} />)
    const endDate = await screen.findByLabelText('Until')
    fireEvent.input(endDate, {target: {value: 'Apr 10 2022'}})
    fireEvent.blur(endDate)
    expect(await screen.findByText('The end date must be after the start date')).toBeInTheDocument()
  })

  it('hides roles the user does not have permission to enroll', async () => {
    const {queryByText} = render(<TempEnrollAssign {...props} permissions={falsePermissions} />)
    expect(queryByText('No roles available')).not.toBeInTheDocument()
  })
})
