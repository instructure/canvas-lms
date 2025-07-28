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
import {render, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import RosterTableHeader from '../RosterTableHeader'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'
import {DEFAULT_SORT_FIELD, DEFAULT_SORT_DIRECTION} from '../../../../util/constants'

jest.mock('../../../hooks/useCoursePeopleContext')

describe('RosterTableHeader', () => {
  const user = userEvent.setup()

  const defaultProps = {
    allSelected: false,
    someSelected: false,
    sortField: DEFAULT_SORT_FIELD,
    sortDirection: DEFAULT_SORT_DIRECTION,
    handleSelectAll: jest.fn(),
    handleSort: jest.fn(),
  }

  const defaultContextValues = {
    canViewLoginIdColumn: true,
    canViewSisIdColumn: true,
    canReadReports: true,
    hideSectionsOnCourseUsersPage: false,
    canManageDifferentiationTags: true,
    allowAssignToDifferentiationTags: true,
  }

  beforeEach(() => {
    ;(useCoursePeopleContext as jest.Mock).mockReturnValue(defaultContextValues)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders all columns when user has all permissions', () => {
      const {getByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(getByTestId('header-select-all')).toBeInTheDocument()
      expect(getByTestId('header-name')).toHaveTextContent(/name/i)
      expect(getByTestId('header-sis_id')).toHaveTextContent(/sis id/i)
      expect(getByTestId('header-section_name')).toHaveTextContent(/section/i)
      expect(getByTestId('header-role')).toHaveTextContent(/role/i)
      expect(getByTestId('header-last_activity_at')).toHaveTextContent(/last activity/i)
      expect(getByTestId('header-total_activity_time')).toHaveTextContent(/total activity/i)
      expect(getByTestId('header-admin-links')).toHaveTextContent(/administrative links/i)
      const headerCells = document.querySelectorAll('[data-testid^="header-"]')
      expect(headerCells).toHaveLength(9)
    })

    it('renders select all checkbox when canManageDifferentiationTags is true', () => {
      const {getByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(getByTestId('header-select-all')).toBeInTheDocument()
    })
  })

  describe('conditional rendering based on permissions', () => {
    it('hides login ID column when canViewLoginIdColumn is false', () => {
      ;(useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canViewLoginIdColumn: false,
      })
      const {queryByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(queryByTestId('header-login_id')).not.toBeInTheDocument()
    })

    it('hides SIS ID column when canViewSisIdColumn is false', () => {
      ;(useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canViewSisIdColumn: false,
      })
      const {queryByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(queryByTestId('header-sis_id')).not.toBeInTheDocument()
    })

    it('hides sections column when hideSectionsOnCourseUsersPage is true', () => {
      ;(useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        hideSectionsOnCourseUsersPage: true,
      })
      const {queryByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(queryByTestId('header-section')).not.toBeInTheDocument()
    })

    it('hides last and total activity columns when canReadReports is false', () => {
      ;(useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canReadReports: false,
      })
      const {queryByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(queryByTestId('header-lastActivity')).not.toBeInTheDocument()
      expect(queryByTestId('header-totalActivity')).not.toBeInTheDocument()
    })

    it('hides user select/checkboxes column when allowAssignToDifferentiationTags is false', () => {
      ;(useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        allowAssignToDifferentiationTags: false,
      })
      const {queryByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(queryByTestId('header-select-all')).not.toBeInTheDocument()
    })

    it('hides user select/checkboxes column when canManageDifferentiationTags is false', () => {
      ;(useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...defaultContextValues,
        canManageDifferentiationTags: false,
      })
      const {queryByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(queryByTestId('header-select-all')).not.toBeInTheDocument()
    })
  })

  describe('sorting', () => {
    it('calls handleSort when clicking a sortable column', async () => {
      const handleSort = jest.fn()
      const {getByTestId} = render(<RosterTableHeader {...defaultProps} handleSort={handleSort} />)
      const nameHeader = getByTestId('header-name')
      await user.click(within(nameHeader).getByRole('button', {hidden: true}))
      expect(handleSort).toHaveBeenCalledWith(expect.any(Object), {id: 'name'})
    })

    it('shows correct sort direction for active column', () => {
      const {getByTestId} = render(<RosterTableHeader {...defaultProps} />)
      expect(getByTestId('header-name')).toHaveAttribute('aria-sort', 'ascending')
    })

    it('shows no sort direction for inactive columns', () => {
      const {getByRole} = render(<RosterTableHeader {...defaultProps} />)
      const roleHeader = Array.from(getByRole('row', {hidden: true}).querySelectorAll('th')).find(
        cell => cell.textContent?.includes('Role'),
      )
      expect(roleHeader).toHaveAttribute('aria-sort', 'none')
    })
  })

  describe('select all checkbox', () => {
    it('calls handleSelectAll when clicked', async () => {
      const handleSelectAll = jest.fn()
      const {getByTestId} = render(
        <RosterTableHeader {...defaultProps} handleSelectAll={handleSelectAll} />,
      )
      await user.click(getByTestId('header-select-all'))
      expect(handleSelectAll).toHaveBeenCalledWith(false)
    })

    it('shows indeterminate state when someSelected is true', () => {
      const {getByTestId} = render(<RosterTableHeader {...defaultProps} someSelected={true} />)
      const checkbox = getByTestId('header-select-all') as HTMLInputElement
      expect(checkbox.indeterminate).toBe(true)
    })

    it('shows checked state when allSelected is true', () => {
      const {getByTestId} = render(<RosterTableHeader {...defaultProps} allSelected={true} />)
      const checkbox = getByTestId('header-select-all') as HTMLInputElement
      expect(checkbox.checked).toBe(true)
    })
  })
})
