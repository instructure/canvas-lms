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
import RosterTableRow from '../RosterTableRow'
import {users} from '../../../../util/mocks'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'

jest.mock('../../../hooks/useCoursePeopleContext')

describe('RosterTableRow', () => {
  const mockUser = users[1]

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
    allowAssignToDifferentiationTags: true
  }

  beforeEach(() => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue(defaultContextValues)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders user information correctly', () => {
    const {getByText, getByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(getByText(mockUser.short_name)).toBeInTheDocument()
    expect(getByText(mockUser.login_id)).toBeInTheDocument()
    expect(getByText(mockUser.sis_user_id)).toBeInTheDocument()
    expect(getByTestId(`avatar-user-${mockUser.id}`)).toHaveAttribute('src', mockUser.avatar_url)
  })

  it('renders user with pronouns', () => {
    const {getByText} = render(<RosterTableRow {...defaultProps} user={{...mockUser, pronouns: 'he/him'}} />)
    expect(getByText(mockUser.short_name)).toBeInTheDocument()
    expect(getByText('(he/him)')).toBeInTheDocument()
  })

  it('renders inactive status correctly', () => {
    const {getByText} = render(<RosterTableRow
      {...defaultProps}
      user={{...mockUser, enrollments: [{...mockUser.enrollments[0], enrollment_state: 'inactive'}]}}
    />)
    expect(getByText(/Inactive/)).toBeInTheDocument()
  })

  it('renders pending status correctly', () => {
    const {getByText} = render(<RosterTableRow
      {...defaultProps}
      user={{...mockUser, enrollments: [{...mockUser.enrollments[0], enrollment_state: 'invited'}]}}
    />)
    expect(getByText(/Pending/)).toBeInTheDocument()
  })

  it('renders options menu for user', () => {
    const {getByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(getByTestId(`options-menu-user-${mockUser.id}`)).toBeInTheDocument()
  })

  it('handles selecting checkbox for individual user', () => {
    const handleSelectRow = jest.fn()
    const {getByTestId} = render(<RosterTableRow {...defaultProps} handleSelectRow={handleSelectRow} />)
    const checkbox = getByTestId(`select-user-${mockUser.id}`)
    fireEvent.click(checkbox)
    expect(handleSelectRow).toHaveBeenCalledWith(false, mockUser.id)
  })

  it('hides user selection checkbox when allowAssignToDifferentiationTags is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      allowAssignToDifferentiationTags: false
    })
    const {queryByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(queryByTestId(`select-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides user selection checkbox when canManageDifferentiationTags is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canManageDifferentiationTags: false
    })
    const {queryByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(queryByTestId(`select-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides login ID column when canViewLoginIdColumn is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canViewLoginIdColumn: false
    })
    const {queryByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(queryByTestId(`login-id-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides SIS ID column when canViewSisIdColumn is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canViewSisIdColumn: false
    })
    const {queryByTestId, debug} = render(<RosterTableRow {...defaultProps} />)
    debug()
    expect(queryByTestId(`sis-id-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides sections when hideSectionsOnCourseUsersPage is true', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      hideSectionsOnCourseUsersPage: true
    })
    const {queryByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(queryByTestId(`sections-user-${mockUser.id}`)).not.toBeInTheDocument()
  })

  it('hides last activity when canReadReports is false', () => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue({
      ...defaultContextValues,
      canReadReports: false
    })
    const {queryByTestId} = render(<RosterTableRow {...defaultProps} />)
    expect(queryByTestId(`last-activity-user-${mockUser.id}`)).not.toBeInTheDocument()
  })
})
