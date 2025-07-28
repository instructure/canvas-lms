/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import StudentGroupFilter from '../StudentGroupFilter'

describe('StudentGroupFilter', () => {
  const defaultProps = {
    disabled: false,
    studentGroupSets: [
      {
        groups: [
          {id: '2103', name: 'Group B1'},
          {id: '2104', name: 'Group B2'},
        ],
        id: '2152',
        name: 'Group Set B',
      },
      {
        groups: [
          {id: '2101', name: 'Group A2'},
          {id: '2102', name: 'Group A1'},
        ],
        id: '2151',
        name: 'Group Set A',
      },
    ],
    onSelect: jest.fn(),
    selectedStudentGroupId: '0',
  }

  const renderFilter = (props = {}) => {
    return render(<StudentGroupFilter {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('labels the filter with "Student Group Filter"', () => {
    renderFilter()
    expect(screen.getByRole('combobox', {name: 'Student Group Filter'})).toBeInTheDocument()
  })

  it('displays the name of the selected student group as the value', () => {
    renderFilter({selectedStudentGroupId: '2101'})
    const combobox = screen.getByRole('combobox', {name: 'Student Group Filter'})
    expect(combobox).toHaveValue('Group A2')
  })

  it('displays "All Student Groups" as the value when selected', () => {
    renderFilter()
    const combobox = screen.getByRole('combobox', {name: 'Student Group Filter'})
    expect(combobox).toHaveValue('All Student Groups')
  })

  describe('student group sets', () => {
    it('labels each group set option group using the related name in alphabetical order', async () => {
      const user = userEvent.setup()
      renderFilter()
      await user.click(screen.getByRole('combobox', {name: 'Student Group Filter'}))

      const groupSetA = screen.getByText('Group Set A')
      const groupSetB = screen.getByText('Group Set B')
      expect(groupSetA).toBeInTheDocument()
      expect(groupSetB).toBeInTheDocument()
      expect(groupSetA.compareDocumentPosition(groupSetB)).toBe(Node.DOCUMENT_POSITION_FOLLOWING)
    })
  })

  describe('student groups list', () => {
    it('labels the "all items" option with "All Student Groups"', async () => {
      const user = userEvent.setup()
      renderFilter()
      await user.click(screen.getByRole('combobox', {name: 'Student Group Filter'}))

      expect(screen.getByRole('option', {name: 'All Student Groups'})).toBeInTheDocument()
    })

    it('labels each option using the related student group name in alphabetical order', async () => {
      const user = userEvent.setup()
      renderFilter()
      await user.click(screen.getByRole('combobox', {name: 'Student Group Filter'}))

      const options = screen
        .getAllByRole('option')
        .slice(1) // Skip "All Student Groups" option
        .map(option => option.textContent.trim())
      expect(options).toEqual(['Group A1', 'Group A2', 'Group B1', 'Group B2'])
    })

    it('disables non-selected options when the filter is disabled', async () => {
      const user = userEvent.setup()
      renderFilter({disabled: true})
      await user.click(screen.getByRole('combobox', {name: 'Student Group Filter'}))

      const option = screen.getByRole('option', {name: 'Group A2'})
      expect(option).toHaveAttribute('aria-disabled', 'true')
    })
  })

  describe('selecting an option', () => {
    it('calls the onSelect callback when selecting a group', async () => {
      const user = userEvent.setup()
      renderFilter()
      await user.click(screen.getByRole('combobox', {name: 'Student Group Filter'}))
      await user.click(screen.getByRole('option', {name: 'Group A1'}))

      expect(defaultProps.onSelect).toHaveBeenCalledWith('2102')
    })

    it('calls onSelect with "0" when selecting "All Student Groups"', async () => {
      const user = userEvent.setup()
      renderFilter({selectedStudentGroupId: '2101'})
      await user.click(screen.getByRole('combobox', {name: 'Student Group Filter'}))
      await user.click(screen.getByRole('option', {name: 'All Student Groups'}))

      expect(defaultProps.onSelect).toHaveBeenCalledWith('0')
    })
  })
})
