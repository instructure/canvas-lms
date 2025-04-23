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
import RosterTable from '../RosterTable'
import {
  DEFAULT_SORT_DIRECTION,
  DEFAULT_SORT_FIELD,
  INACTIVE_ENROLLMENT,
  PENDING_ENROLLMENT
} from '../../../../util/constants'
import useCoursePeopleQuery from '../../../hooks/useCoursePeopleQuery'
import {mockUser, mockEnrollment} from '../../../../graphql/Mocks'

jest.mock('../../../hooks/useCoursePeopleQuery')
jest.mock('../../../hooks/useCoursePeopleContext')

const mockUsers = [
  mockUser({
    userId: '1',
    userName: 'Student One'
  }),
  mockUser({
    userId: '2',
    userName: 'Student Two',
    firstEnrollment: mockEnrollment({enrollmentState: INACTIVE_ENROLLMENT})
  }),
  mockUser({
    userId: '3',
    userName: 'Student Three',
    firstEnrollment: mockEnrollment({enrollmentState: PENDING_ENROLLMENT})
  }),
]

const useCoursePeopleContextMocks = {
  courseId: '1',
  currentUserId: '1',
  canReadReports: true,
  canViewLoginIdColumn: true,
  canViewSisIdColumn: true,
  canManageDifferentiationTags: true,
  hideSectionsOnCourseUsersPage: false,
  allowAssignToDifferentiationTags: true,
  activeGranularEnrollmentPermissions: [],
}

const defaultProps = {
  users: mockUsers,
  handleSort: () => {},
  sortField: DEFAULT_SORT_FIELD,
  sortDirection: DEFAULT_SORT_DIRECTION
}

describe('RosterTable', () => {
  const user = userEvent.setup()
  const renderComponent = () => render(<RosterTable {...defaultProps} />)

  beforeEach(() => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: mockUsers,
      isLoading: false,
      error: null
    })
    require('../../../hooks/useCoursePeopleContext').default.mockReturnValue(useCoursePeopleContextMocks)
    renderComponent()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the table with correct caption', () => {
    expect(screen.getByTestId('roster-table')).toBeInTheDocument()
    expect(screen.getByText('Course Roster')).toBeInTheDocument()
  })

  it('renders the table with correct headers', () => {
    expect(screen.getByText('Select all')).toBeInTheDocument()
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByText('SIS ID')).toBeInTheDocument()
    expect(screen.getByText('Login ID')).toBeInTheDocument()
    expect(screen.getByText('Section')).toBeInTheDocument()
    expect(screen.getByText('Role')).toBeInTheDocument()
    expect(screen.getByText('Last Activity')).toBeInTheDocument()
    expect(screen.getByText('Total Activity')).toBeInTheDocument()
    expect(screen.getByText('Administrative Links')).toBeInTheDocument()
  })

  it('renders table rows with user data', () => {
    expect(screen.getByText(mockUsers[0].name)).toBeInTheDocument()
    expect(screen.getByText(mockUsers[1].name)).toBeInTheDocument()
    expect(screen.getByText(mockUsers[2].name)).toBeInTheDocument()
    expect(screen.getAllByTestId(/^table-row-/)).toHaveLength(mockUsers.length)
  })

  it('handles selecting a single row', async () => {
    const checkboxes = screen.getAllByTestId(/^select-user-/)
    const firstRowCheckbox = checkboxes[0]
    await user.click(firstRowCheckbox)
    expect(firstRowCheckbox).toBeChecked()
    await user.click(firstRowCheckbox)
    expect(firstRowCheckbox).not.toBeChecked()
  })

  it('handles select all rows', async () => {
    const selectAllCheckbox = screen.getByTestId('header-select-all')
    await user.click(selectAllCheckbox)

    const checkboxes = screen.getAllByTestId(/^select-user-/)
    checkboxes.forEach(checkbox => {
      expect(checkbox).toBeChecked()
    })

    await user.click(selectAllCheckbox)
    checkboxes.forEach(checkbox => {
      expect(checkbox).not.toBeChecked()
    })
  })

  it('displays inactive and pending enrollment states', () => {
    expect(screen.getByText('Inactive')).toBeInTheDocument()
    expect(screen.getByText('Pending')).toBeInTheDocument()
  })
})
