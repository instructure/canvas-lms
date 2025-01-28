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
import {render, fireEvent, within} from '@testing-library/react'
import RosterTable from './../RosterTable'
import {users} from '../../../../util/mocks'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'

jest.mock('../../../hooks/useCoursePeopleContext')

describe('RosterTable', () => {
  const useCoursePeopleContextMocks = {
    canReadReports: true,
    canViewLoginIdColumn: true,
    canViewSisIdColumn: true,
    canManageDifferentiationTags: true,
    hideSectionsOnCourseUsersPage: false,
    allowAssignToDifferentiationTags: true
  }

  beforeEach(() => {
    (useCoursePeopleContext as jest.Mock).mockReturnValue(useCoursePeopleContextMocks)
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
    expect(getByText(users[0].short_name)).toBeInTheDocument()
    expect(getByText(users[1].short_name)).toBeInTheDocument()
    expect(getByText(users[2].short_name)).toBeInTheDocument()
    expect(getAllByTestId(/^table-row-/)).toHaveLength(users.length)
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

  it('handles sorting when clicking on sortable headers', () => {
    const {getAllByTestId, getByTestId} = render(<RosterTable />)
    const nameHeader = getByTestId('header-name')

    let rows = getAllByTestId(/^table-row-/)
    expect(rows[0]).toHaveTextContent(users[0].short_name)
    expect(rows[1]).toHaveTextContent(users[1].short_name)
    expect(rows[2]).toHaveTextContent(users[2].short_name)

    fireEvent.click(within(nameHeader).getByRole('button', {hidden: true }))
    rows = getAllByTestId(/^table-row-/)
    expect(rows[0]).toHaveTextContent(users[2].short_name)
    expect(rows[1]).toHaveTextContent(users[1].short_name)
    expect(rows[2]).toHaveTextContent(users[0].short_name)
  })

  it('displays inactive and pending enrollment states', () => {
    const {getByText} = render(<RosterTable />)
    expect(getByText('Inactive')).toBeInTheDocument()
    expect(getByText('Pending')).toBeInTheDocument()
  })
})
