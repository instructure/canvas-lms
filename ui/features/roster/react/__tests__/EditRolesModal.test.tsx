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

import {fireEvent, render, waitFor} from '@testing-library/react'
import EditRolesModal from '../EditRolesModal'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import {AVAILABLE_ROLES, GENERIC_ENROLLMENT, mockDelete, mockPost, USER_ID} from './testUtils'

const currentEnrollments = [
  {
    course_id: '11',
    course_section_id: '111',
    id: '1',
    limit_privileges_to_course_section: true,
    role_id: '1',
    ...GENERIC_ENROLLMENT,
  },
]

const defaultProps = {
  currentEnrollments,
  availableRoles: AVAILABLE_ROLES,
  userId: USER_ID,
  onClose: vi.fn(),
  onSubmit: vi.fn(),
}

describe('EditRolesModal', () => {
  beforeEach(() => {
    fetchMock.restore()
    vi.clearAllMocks()
  })

  it("renders modal with user's current role", async () => {
    const {getByText, getByTestId} = render(<EditRolesModal {...defaultProps} />)
    expect(getByText('Edit Roles')).toBeInTheDocument()

    const roleSelect = getByTestId('edit-roles-select') as HTMLInputElement
    expect(roleSelect.value).toBe('Student')
    fireEvent.click(roleSelect)
    expect(getByText('TA')).toBeInTheDocument()
  })

  it('calls onSubmit when submitting', async () => {
    const user = userEvent.setup()
    const {deletedEnrollments, deletedPaths} = mockDelete(currentEnrollments, '3')
    const {newEnrollments, postPaths} = mockPost(currentEnrollments, '3')
    const {getByTestId, getByText} = render(<EditRolesModal {...defaultProps} />)

    fireEvent.click(getByTestId('edit-roles-select'))
    fireEvent.click(getByText('TA'))
    // verify dropdown value changed
    const roleSelect = getByTestId('edit-roles-select') as HTMLInputElement
    expect(roleSelect.value).toBe('TA')

    await user.click(getByTestId('update-roles'))
    await waitFor(() => {
      expect(defaultProps.onSubmit).toHaveBeenCalledWith(newEnrollments, deletedEnrollments)
      expect(defaultProps.onClose).toHaveBeenCalled()
      expect(fetchMock.called(deletedPaths[0], 'DELETE')).toBe(true)
      expect(fetchMock.called(postPaths[0], 'POST')).toBe(true)
    })
  })

  it('calls onClose when cancelling', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<EditRolesModal {...defaultProps} />)
    await user.click(getByTestId('cancel-modal'))
    await waitFor(() => {
      expect(defaultProps.onClose).toHaveBeenCalled()
    })
  })

  it("skips onSubmit if role hasn't changed", async () => {
    const user = userEvent.setup()
    const deleted = mockDelete(currentEnrollments, '1')
    const created = mockPost(currentEnrollments, '1') // 1 is student; existing enrollment is for student
    const {getByTestId} = render(<EditRolesModal {...defaultProps} />)
    await user.click(getByTestId('update-roles'))
    await waitFor(() => {
      expect(defaultProps.onSubmit).not.toHaveBeenCalled()
      expect(defaultProps.onClose).toHaveBeenCalled()
      expect(fetchMock.called(deleted.deletedPaths[0], 'DELETE')).toBe(false)
      expect(fetchMock.called(created.postPaths[0], 'POST')).toBe(false)
    })
  })

  it('flashes error message if role failed to change', async () => {
    const user = userEvent.setup()
    fetchMock.delete(`/unenroll/${currentEnrollments[0].id}`, {status: 500})
    fetchMock.post(`/api/v1/sections/${currentEnrollments[0].course_section_id}/enrollments`, {
      status: 500,
    })
    const {getByTestId, getByText, getAllByText} = render(<EditRolesModal {...defaultProps} />)

    fireEvent.click(getByTestId('edit-roles-select'))
    fireEvent.click(getByText('TA'))
    // verify dropdown value changed
    const roleSelect = getByTestId('edit-roles-select') as HTMLInputElement
    expect(roleSelect.value).toBe('TA')

    await user.click(getByTestId('update-roles'))
    await waitFor(() => {
      expect(getAllByText('Failed to update roles').length).toBeGreaterThan(0)
    })
    expect(defaultProps.onSubmit).not.toHaveBeenCalled()
    expect(defaultProps.onClose).not.toHaveBeenCalled()
  })

  it('updates all roles when enrolled in multiple sections with multiple roles', async () => {
    const user = userEvent.setup()
    const multipleEnrollments = [
      ...currentEnrollments,
      {
        course_id: '11',
        course_section_id: '111', // first section
        id: '2',
        limit_privileges_to_course_section: true,
        role_id: '3', // TA
        ...GENERIC_ENROLLMENT,
      },
      {
        course_id: '11',
        course_section_id: '112', // second section
        id: '3',
        limit_privileges_to_course_section: true,
        role_id: '1', // student
        ...GENERIC_ENROLLMENT,
      },
    ]
    const props = {
      ...defaultProps,
      currentEnrollments: multipleEnrollments,
    }
    const {deletedEnrollments, deletedPaths} = mockDelete(multipleEnrollments, '3')
    const {newEnrollments, postPaths} = mockPost(multipleEnrollments, '3') // set all enrollments to TA
    const {getByTestId, getByText} = render(<EditRolesModal {...props} />)

    expect(getByText(/multiple roles in the course/)).toBeInTheDocument()
    fireEvent.click(getByTestId('edit-roles-select'))
    fireEvent.click(getByText('TA'))
    await user.click(getByTestId('update-roles'))

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith(newEnrollments, deletedEnrollments)
      expect(props.onClose).toHaveBeenCalled()
    })
    expect(fetchMock.called(deletedPaths[0], 'DELETE')).toBe(true)
    expect(fetchMock.called(deletedPaths[1], 'DELETE')).toBe(true)
    expect(fetchMock.called(postPaths[0], 'POST')).toBe(true)
    expect(fetchMock.called(postPaths[1], 'POST')).toBe(true)
  })
})
