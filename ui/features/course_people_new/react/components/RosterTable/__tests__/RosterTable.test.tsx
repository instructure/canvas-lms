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
import RosterTable from '../RosterTable'
import {
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

describe('RosterTable', () => {
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

  beforeEach(() => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: mockUsers,
      isLoading: false,
      isSuccess: true,
      error: null
    })
    require('../../../hooks/useCoursePeopleContext').default.mockReturnValue(useCoursePeopleContextMocks)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the table with correct caption', () => {
    const {getByTestId, getByText} = render(<RosterTable />)
    expect(getByTestId('roster-table')).toBeInTheDocument()
    expect(getByText('Course Roster')).toBeInTheDocument()
  })

  it('renders the table with correct headers', () => {
    const {getByTestId} = render(<RosterTable />)
    expect(getByTestId('header-select-all')).toBeInTheDocument()
    expect(getByTestId('header-name')).toHaveTextContent(/name/i)
    expect(getByTestId('header-sisID')).toHaveTextContent(/sis id/i)
    expect(getByTestId('header-section')).toHaveTextContent(/section/i)
    expect(getByTestId('header-role')).toHaveTextContent(/role/i)
    expect(getByTestId('header-lastActivity')).toHaveTextContent(/last activity/i)
    expect(getByTestId('header-totalActivity')).toHaveTextContent(/total activity/i)
    expect(getByTestId('header-admin-links')).toHaveTextContent(/administrative links/i)
  })

  it('renders table rows with user data', () => {
    const {getByText, getAllByTestId} = render(<RosterTable />)
    expect(getByText(mockUsers[0].name)).toBeInTheDocument()
    expect(getByText(mockUsers[1].name)).toBeInTheDocument()
    expect(getByText(mockUsers[2].name)).toBeInTheDocument()
    expect(getAllByTestId(/^table-row-/)).toHaveLength(mockUsers.length)
  })

  it('handles selecting a single row', () => {
    const {getAllByTestId} = render(<RosterTable />)
    const checkboxes = getAllByTestId(/^select-user-/)
    const firstRowCheckbox = checkboxes[0]
    fireEvent.click(firstRowCheckbox)
    expect(firstRowCheckbox).toBeChecked()
    fireEvent.click(firstRowCheckbox)
    expect(firstRowCheckbox).not.toBeChecked()
  })

  it('handles select all rows', async () => {
    const {getByTestId, getAllByTestId} = render(<RosterTable />)
    const selectAllCheckbox = getByTestId('header-select-all')
    fireEvent.click(selectAllCheckbox)

    const checkboxes = getAllByTestId(/^select-user-/)
    checkboxes.forEach(checkbox => {
      expect(checkbox).toBeChecked()
    })

    fireEvent.click(selectAllCheckbox)
    checkboxes.forEach(checkbox => {
      expect(checkbox).not.toBeChecked()
    })
  })

  it('displays inactive and pending enrollment states', () => {
    const {getByText} = render(<RosterTable />)
    expect(getByText('Inactive')).toBeInTheDocument()
    expect(getByText('Pending')).toBeInTheDocument()
  })

  it('displays loading state', () => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: null,
      isLoading: true,
      isSuccess: false,
      error: null
    })
    const {getByText} = render(<RosterTable />)
    expect(getByText('Loading')).toBeInTheDocument()
  })
})
