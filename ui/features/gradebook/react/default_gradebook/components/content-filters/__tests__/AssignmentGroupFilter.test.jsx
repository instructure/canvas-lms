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

import AssignmentGroupFilter from '../AssignmentGroupFilter'

describe('AssignmentGroupFilter', () => {
  const defaultProps = {
    disabled: false,
    assignmentGroups: [
      {id: '2201', name: 'In-Class'},
      {id: '2202', name: 'Homework'},
    ],
    onSelect: jest.fn(),
    selectedAssignmentGroupId: '0',
  }

  const renderAssignmentGroupFilter = (props = {}) => {
    return render(<AssignmentGroupFilter {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('labels the filter with "Assignment Group Filter"', () => {
    renderAssignmentGroupFilter()
    expect(screen.getByRole('combobox', {name: 'Assignment Group Filter'})).toBeInTheDocument()
  })

  it('displays the name of the selected assignment group as the value', () => {
    renderAssignmentGroupFilter({selectedAssignmentGroupId: '2202'})
    const combobox = screen.getByRole('combobox', {name: 'Assignment Group Filter'})
    expect(combobox).toHaveDisplayValue('Homework')
  })

  it('displays "All Assignment Groups" as the value when selected', () => {
    renderAssignmentGroupFilter()
    const combobox = screen.getByRole('combobox', {name: 'Assignment Group Filter'})
    expect(combobox).toHaveDisplayValue('All Assignment Groups')
  })

  describe('assignment groups list', () => {
    it('labels the "all items" option with "All Assignment Groups"', async () => {
      const user = userEvent.setup()
      renderAssignmentGroupFilter()
      await user.click(screen.getByRole('combobox', {name: 'Assignment Group Filter'}))
      expect(screen.getByRole('option', {name: 'All Assignment Groups'})).toBeInTheDocument()
    })

    it('labels each option using the related assignment group name in alphabetical order', async () => {
      const user = userEvent.setup()
      renderAssignmentGroupFilter()
      await user.click(screen.getByRole('combobox', {name: 'Assignment Group Filter'}))
      const options = screen.getAllByRole('option')
      expect(options[1]).toHaveTextContent('Homework')
      expect(options[2]).toHaveTextContent('In-Class')
    })

    it('disables non-selected options when the filter is disabled', async () => {
      const user = userEvent.setup()
      renderAssignmentGroupFilter({disabled: true})
      await user.click(screen.getByRole('combobox', {name: 'Assignment Group Filter'}))
      expect(screen.getByRole('option', {name: 'Homework'})).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })
  })

  describe('selecting an option', () => {
    it('calls onSelect with assignment group id when selecting a group', async () => {
      const user = userEvent.setup()
      renderAssignmentGroupFilter()
      await user.click(screen.getByRole('combobox', {name: 'Assignment Group Filter'}))
      await user.click(screen.getByRole('option', {name: 'In-Class'}))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('2201')
    })

    it('calls onSelect with "0" when selecting "All Assignment Groups"', async () => {
      const user = userEvent.setup()
      renderAssignmentGroupFilter({selectedAssignmentGroupId: '2201'})
      await user.click(screen.getByRole('combobox', {name: 'Assignment Group Filter'}))
      await user.click(screen.getByRole('option', {name: 'All Assignment Groups'}))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('0')
    })
  })
})
