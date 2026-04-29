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
import {Table} from '@instructure/ui-table'
import RosterTableRow, {type RosterTableRowProps} from '../RosterTableRow'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'
import {
  TEACHER_ENROLLMENT,
  TA_ENROLLMENT,
  DESIGNER_ENROLLMENT,
  OBSERVER_ENROLLMENT,
  PENDING_ENROLLMENT,
  INACTIVE_ENROLLMENT,
} from '../../../../util/constants'
import {mockUser, mockEnrollment} from '../../../../graphql/Mocks'

vi.mock('../../../hooks/useCoursePeopleContext')

describe('RosterTableRow', () => {
  const mockedUser = mockUser()

  const defaultProps = {
    user: mockedUser,
    isSelected: false,
    handleSelectRow: vi.fn(),
  }

  const defaultContextValues = {
    canViewLoginIdColumn: true,
    canViewSisIdColumn: true,
    canReadReports: true,
    hideSectionsOnCourseUsersPage: false,
    canManageDifferentiationTags: true,
    canAllowCourseAdminActions: true,
    allowAssignToDifferentiationTags: true,
    activeGranularEnrollmentPermissions: [],
  }

  const renderRosterTableRow = (props: Partial<RosterTableRowProps> = {}) =>
    render(
      <Table caption="Test table">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="select">Select</Table.ColHeader>
            <Table.ColHeader id="name">Name</Table.ColHeader>
            <Table.ColHeader id="login">Login ID</Table.ColHeader>
            <Table.ColHeader id="sis">SIS ID</Table.ColHeader>
            <Table.ColHeader id="section">Section</Table.ColHeader>
            <Table.ColHeader id="role">Role</Table.ColHeader>
            <Table.ColHeader id="activity">Last Activity</Table.ColHeader>
            <Table.ColHeader id="total">Total Activity</Table.ColHeader>
            <Table.ColHeader id="options">Options</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          <RosterTableRow {...defaultProps} {...props} />
        </Table.Body>
      </Table>,
    )

  beforeEach(() => {
    ;(useCoursePeopleContext as any).mockReturnValue(defaultContextValues)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders user information correctly', () => {
    const {getByText, getByTestId} = renderRosterTableRow()
    expect(getByText(mockedUser.name)).toBeInTheDocument()
    expect(getByText(mockedUser.loginId)).toBeInTheDocument()
    expect(getByText(mockedUser.sisId)).toBeInTheDocument()
    expect(getByTestId(`avatar-user-${mockedUser._id}`)).toHaveAttribute(
      'src',
      mockedUser.avatarUrl,
    )
  })

  it('renders user with pronouns', () => {
    const props = {
      user: {...mockedUser, pronouns: 'he/him'},
    }
    const {getByText} = renderRosterTableRow(props)
    expect(getByText(mockedUser.name)).toBeInTheDocument()
    expect(getByText('(he/him)')).toBeInTheDocument()
  })

  it('renders inactive status correctly', () => {
    const props = {
      user: mockUser({firstEnrollment: mockEnrollment({enrollmentState: INACTIVE_ENROLLMENT})}),
    }
    const {getByText} = renderRosterTableRow(props)
    expect(getByText(/Inactive/)).toBeInTheDocument()
  })

  it('renders pending status correctly', () => {
    const props = {
      user: mockUser({firstEnrollment: mockEnrollment({enrollmentState: PENDING_ENROLLMENT})}),
    }
    const {getByText} = renderRosterTableRow(props)
    expect(getByText(/Pending/)).toBeInTheDocument()
  })

  it('renders options menu for user', () => {
    const {getByTestId} = renderRosterTableRow()
    expect(getByTestId(`options-menu-user-${mockedUser._id}`)).toBeInTheDocument()
  })

  it('handles selecting checkbox for individual user', () => {
    const handleSelectRow = vi.fn()
    const {getByTestId} = renderRosterTableRow({handleSelectRow})
    const checkbox = getByTestId(`select-user-${mockedUser._id}`)
    fireEvent.click(checkbox)
    expect(handleSelectRow).toHaveBeenCalledWith(false, mockedUser._id)
  })

  it('hides user selection checkbox when allowAssignToDifferentiationTags is false', () => {
    ;(useCoursePeopleContext as any).mockReturnValue({
      ...defaultContextValues,
      allowAssignToDifferentiationTags: false,
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`select-user-${mockedUser._id}`)).not.toBeInTheDocument()
  })

  it('hides user selection checkbox when canManageDifferentiationTags is false', () => {
    ;(useCoursePeopleContext as any).mockReturnValue({
      ...defaultContextValues,
      canManageDifferentiationTags: false,
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`select-user-${mockedUser._id}`)).not.toBeInTheDocument()
  })

  it('hides login ID column when canViewLoginIdColumn is false', () => {
    ;(useCoursePeopleContext as any).mockReturnValue({
      ...defaultContextValues,
      canViewLoginIdColumn: false,
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`login-id-user-${mockedUser._id}`)).not.toBeInTheDocument()
  })

  it('hides SIS ID column when canViewSisIdColumn is false', () => {
    ;(useCoursePeopleContext as any).mockReturnValue({
      ...defaultContextValues,
      canViewSisIdColumn: false,
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`sis-id-user-${mockedUser._id}`)).not.toBeInTheDocument()
  })

  it('hides sections when hideSectionsOnCourseUsersPage is true', () => {
    ;(useCoursePeopleContext as any).mockReturnValue({
      ...defaultContextValues,
      hideSectionsOnCourseUsersPage: true,
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`section-name-user-${mockedUser._id}`)).not.toBeInTheDocument()
  })

  it('hides last activity when canReadReports is false', () => {
    ;(useCoursePeopleContext as any).mockReturnValue({
      ...defaultContextValues,
      canReadReports: false,
    })
    const {queryByTestId} = renderRosterTableRow()
    expect(queryByTestId(`last-activity-user-${mockedUser._id}`)).not.toBeInTheDocument()
  })

  describe('Option Menu Visibility', () => {
    it('hides menu for students when enrollments cannot be removed', () => {
      ;(useCoursePeopleContext as any).mockReturnValue({
        ...defaultContextValues,
        canManageStudents: false,
      })
      const props = {
        user: mockUser({firstEnrollment: mockEnrollment({canBeRemoved: false})}),
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockedUser._id}`)).not.toBeInTheDocument()
    })

    it('hides menu for teachers when canAllowCourseAdminActions is false', () => {
      ;(useCoursePeopleContext as any).mockReturnValue({
        ...defaultContextValues,
        canAllowCourseAdminActions: false,
      })
      const props = {
        user: mockUser({
          firstEnrollment: mockEnrollment({
            enrollmentType: TEACHER_ENROLLMENT,
            canBeRemoved: false,
          }),
        }),
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockedUser._id}`)).not.toBeInTheDocument()
    })

    it('hides menu for teaching assistants when canAllowCourseAdminActions is false', () => {
      ;(useCoursePeopleContext as any).mockReturnValue({
        ...defaultContextValues,
        canAllowCourseAdminActions: false,
      })
      const props = {
        user: mockUser({
          firstEnrollment: mockEnrollment({enrollmentType: TA_ENROLLMENT, canBeRemoved: false}),
        }),
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockedUser._id}`)).not.toBeInTheDocument()
    })

    it('hides menu for designers when canAllowCourseAdminActions is false', () => {
      ;(useCoursePeopleContext as any).mockReturnValue({
        ...defaultContextValues,
        canAllowCourseAdminActions: false,
      })
      const props = {
        user: mockUser({
          firstEnrollment: mockEnrollment({
            enrollmentType: DESIGNER_ENROLLMENT,
            canBeRemoved: false,
          }),
        }),
      }
      const {queryByTestId} = renderRosterTableRow(props)

      expect(queryByTestId(`options-menu-user-${mockedUser._id}`)).not.toBeInTheDocument()
    })

    it('hides menu for observers when canManageStudents and canAllowCourseAdminActions are false', () => {
      ;(useCoursePeopleContext as any).mockReturnValue({
        ...defaultContextValues,
        canManageStudents: false,
        canAllowCourseAdminActions: false,
      })
      const props = {
        user: mockUser({
          firstEnrollment: mockEnrollment({
            enrollmentType: OBSERVER_ENROLLMENT,
            canBeRemoved: false,
          }),
        }),
      }
      const {queryByTestId} = renderRosterTableRow(props)
      expect(queryByTestId(`options-menu-user-${mockedUser._id}`)).not.toBeInTheDocument()
    })
  })
})
