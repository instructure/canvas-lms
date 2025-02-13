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
import {render, fireEvent} from '@testing-library/react'
import RosterTableRow, {type RosterTableRowProps} from '../RosterTableRow'
import {users} from '../../../../util/mocks'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'
import {TEACHER_ENROLLMENT, TA_ENROLLMENT, DESIGNER_ENROLLMENT} from '../../../../util/constants'

jest.mock('../../../hooks/useCoursePeopleContext')

describe('RosterTableRow', () => {
  const mockUser = users[1]
  const mockUserStudent = users[0]

  const defaultProps = {
    user: mockUser,
    isSelected: false,
    handleSelectRow: jest.fn()
  }

  const defaultContextValues = {
    canViewLoginIdColumn: true,
    canViewSisIdColumn: true,
    canReadReports: true,
    hideSectionsOnCourseUsersPage: false,
    canManageDifferentiationTags: true,
    canAllowCourseAdminActions: true,
    allowAssignToDifferentiationTags: true,
    activeGranularEnrollmentPermissions: []
  }

  const renderRosterTableRow = (props: Partial<RosterTableRowProps> = {}) => render(<RosterTableRow {...defaultProps} {...props} />)

  beforeEach(() => {
    ;(useCoursePeopleContext as jest.Mock).mockReturnValue(defaultContextValues)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders user information correctly', () => {
    const {getByText, getByTestId} = renderRosterTableRow()
    expect(getByText(mockUser.short_name)).toBeInTheDocument()
    expect(getByText(mockUser.login_id)).toBeInTheDocument()
    expect(getByText(mockUser.sis_user_id)).toBeInTheDocument()
    expect(getByTestId(`avatar-user-${mockUser.id}`)).toHaveAttribute('src', mockUser.avatar_url)
  })

  it('renders user with pronouns', () => {
    const props = {
      user: {...mockUser, pronouns: 'he/him'}
    }
    const {getByText} = renderRosterTableRow(props)
    expect(getByText(mockUser.short_name)).toBeInTheDocument()
    expect(getByText('(he/him)')).toBeInTheDocument()
  })

  it('renders inactive status correctly', () => {
    const props = {
      user: {...mockUser, enrollments: [{...mockUser.enrollments[0], enrollment_state: 'inactive'}]}
    }
    const {getByText} = renderRosterTableRow(props)
    expect(getByText(/Inactive/)).toBeInTheDocument()
  })

  it('renders pending status correctly', () => {
    const props = {
      user: {...mockUser, enrollments: [{...mockUser.enrollments[0], enrollment_state: 'invited'}]}
    }
    const {getByText} = renderRosterTableRow(props)
    expect(getByText(/Pending/)).toBeInTheDocument()
  })

  it('renders options menu for user', () => {
    const {getByTestId} = renderRosterTableRow()
    expect(getByTestId(`options-menu-user-${mockUser.id}`)).toBeInTheDocument()
  })

  it('handles selecting checkbox for individual user', () => {
    const handleSelectRow = jest.fn()
    const {getByTestId} = renderRosterTableRow({handleSelectRow})
    const checkbox = getByTestId(`select-user-${mockUser.id}`)
    fireEvent.click(checkbox)
    expect(handleSelectRow).toHaveBeenCalledWith(false, mockUser.id)
  })

  it('hides user selection checkbox when allowAssignToDifferentiationTags is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      allowAssignToDifferentiationTags: false
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`select-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides user selection checkbox when canManageDifferentiationTags is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canManageDifferentiationTags: false
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`select-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides login ID column when canViewLoginIdColumn is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canViewLoginIdColumn: false
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`login-id-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides SIS ID column when canViewSisIdColumn is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canViewSisIdColumn: false
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`sis-id-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides sections when hideSectionsOnCourseUsersPage is true', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      hideSectionsOnCourseUsersPage: true
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`sections-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides last activity when canReadReports is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canReadReports: false
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`last-activity-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  describe('Option Menu Visibility', () => {
    it('hides menu for students when enrollments cannot be removed', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canManageStudents: false
      })
      const props = {
        user: {
          ...mockUserStudent,
          enrollments: [{
            ...mockUserStudent.enrollments[0],
            can_be_removed: false
          }]
        }
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockUser.id}`)).not.toBeInTheDocument()
    })

    it('hides menu for teachers when canAllowCourseAdminActions is false', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canAllowCourseAdminActions: false
      })
      const props = {
        user: {
          ...mockUser,
          enrollments: [{
            ...mockUser.enrollments[0],
            type: TEACHER_ENROLLMENT,
            can_be_removed: false
          }]
        }
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockUser.id}`)).not.toBeInTheDocument()
    })

    it('hides menu for teaching assistants when canAllowCourseAdminActions is false', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canAllowCourseAdminActions: false
      })
      const props = {
        user: {
          ...mockUser,
          enrollments: [{
            ...mockUser.enrollments[0],
            type: TA_ENROLLMENT,
            can_be_removed: false
          }]
        }
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockUser.id}`)).not.toBeInTheDocument()
    })

    it('hides menu for designers when canAllowCourseAdminActions is false', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canAllowCourseAdminActions: false
      })
      const props = {
        user: {
          ...mockUser,
          enrollments: [{
            ...mockUser.enrollments[0],
            type: DESIGNER_ENROLLMENT,
            can_be_removed: false
          }]
        }
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockUser.id}`)).not.toBeInTheDocument()
    })

    it('hides menu for observers when canManageStudents and canAllowCourseAdminActions are false', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canManageStudents: false,
        canAllowCourseAdminActions: false
      })
      const {queryByTestId} = renderRosterTableRow({user: mockUserStudent})
      expect(queryByTestId(`options-menu-user-${mockUser.id}`)).not.toBeInTheDocument()
    })
  })
})
