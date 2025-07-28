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

import ModuleFilter from '../ModuleFilter'

describe('ModuleFilter', () => {
  const defaultProps = {
    disabled: false,
    modules: [
      {id: '2002', name: 'Module 2'},
      {id: '2001', name: 'Module 1'},
    ],
    onSelect: jest.fn(),
    selectedModuleId: '0',
  }

  const renderModuleFilter = (props = {}) => {
    return render(<ModuleFilter {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('labels the filter with "Module Filter"', () => {
    renderModuleFilter()
    expect(screen.getByRole('combobox', {name: 'Module Filter'})).toBeInTheDocument()
  })

  it('displays the name of the selected module as the value', () => {
    renderModuleFilter({selectedModuleId: '2002'})
    const combobox = screen.getByRole('combobox', {name: 'Module Filter'})
    expect(combobox).toHaveDisplayValue('Module 2')
  })

  it('displays "All Modules" as the value when selected', () => {
    renderModuleFilter()
    const combobox = screen.getByRole('combobox', {name: 'Module Filter'})
    expect(combobox).toHaveDisplayValue('All Modules')
  })

  describe('modules list', () => {
    it('labels the "all items" option with "All Modules"', async () => {
      const user = userEvent.setup()
      renderModuleFilter()
      await user.click(screen.getByRole('combobox', {name: 'Module Filter'}))
      expect(screen.getByRole('option', {name: 'All Modules'})).toBeInTheDocument()
    })

    it('labels each option using the related module name in alphabetical order', async () => {
      const user = userEvent.setup()
      renderModuleFilter()
      await user.click(screen.getByRole('combobox', {name: 'Module Filter'}))
      const options = screen.getAllByRole('option')
      expect(options[1]).toHaveTextContent('Module 1')
      expect(options[2]).toHaveTextContent('Module 2')
    })

    it('disables non-selected options when the filter is disabled', async () => {
      const user = userEvent.setup()
      renderModuleFilter({disabled: true})
      await user.click(screen.getByRole('combobox', {name: 'Module Filter'}))
      expect(screen.getByRole('option', {name: 'Module 2'})).toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })
  })

  describe('selecting an option', () => {
    it('calls the onSelect callback with module id when selecting a module', async () => {
      const user = userEvent.setup()
      renderModuleFilter()
      await user.click(screen.getByRole('combobox', {name: 'Module Filter'}))
      await user.click(screen.getByRole('option', {name: 'Module 1'}))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('2001')
    })

    it('calls onSelect with "0" when selecting "All Modules"', async () => {
      const user = userEvent.setup()
      renderModuleFilter({selectedModuleId: '2001'})
      await user.click(screen.getByRole('combobox', {name: 'Module Filter'}))
      await user.click(screen.getByRole('option', {name: 'All Modules'}))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('0')
    })
  })
})
