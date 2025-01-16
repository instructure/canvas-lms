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

import SectionFilter from '@canvas/gradebook-content-filters/react/SectionFilter'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'

describe('Gradebook > Default Gradebook > Components > Content Filters > SectionFilter', () => {
  const defaultProps = {
    disabled: false,
    sections: [
      {id: '2002', name: 'Section 2'},
      {id: '2001', name: 'Section 1'},
    ],
    onSelect: jest.fn(),
    selectedSectionId: '0',
  }

  const renderSectionFilter = (props = {}) => {
    return render(<SectionFilter {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('labels the filter with "Section Filter"', () => {
    renderSectionFilter()
    expect(screen.getByLabelText('Section Filter')).toBeInTheDocument()
  })

  it('displays the name of the selected section as the value', () => {
    renderSectionFilter({selectedSectionId: '2002'})
    expect(screen.getByDisplayValue('Section 2')).toBeInTheDocument()
  })

  it('displays "All Sections" as the value when selected', () => {
    renderSectionFilter()
    expect(screen.getByDisplayValue('All Sections')).toBeInTheDocument()
  })

  describe('sections list', () => {
    it('labels the "all items" option with "All Sections"', async () => {
      renderSectionFilter()
      await userEvent.click(screen.getByRole('combobox'))
      expect(screen.getByText('All Sections')).toBeInTheDocument()
    })

    it('labels each option using the related section name in alphabetical order', async () => {
      renderSectionFilter()
      await userEvent.click(screen.getByRole('combobox'))
      const options = screen.getAllByRole('option')
      expect(options[1]).toHaveTextContent('Section 1')
      expect(options[2]).toHaveTextContent('Section 2')
    })

    it('disables non-selected options when the filter is disabled', async () => {
      renderSectionFilter({disabled: true})
      await userEvent.click(screen.getByRole('combobox'))
      const option = screen.getByText('Section 2')
      expect(option).toHaveAttribute('aria-disabled', 'true')
    })
  })

  describe('selecting an option', () => {
    it('calls the onSelect callback', async () => {
      renderSectionFilter()
      await userEvent.click(screen.getByRole('combobox'))
      await userEvent.click(screen.getByText('Section 1'))
      expect(defaultProps.onSelect).toHaveBeenCalledTimes(1)
    })

    it('includes the section id when calling the onSelect callback', async () => {
      renderSectionFilter()
      await userEvent.click(screen.getByRole('combobox'))
      await userEvent.click(screen.getByText('Section 1'))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('2001')
    })

    it('includes "0" when "All Sections" is clicked', async () => {
      renderSectionFilter({selectedSectionId: '2001'})
      await userEvent.click(screen.getByRole('combobox'))
      await userEvent.click(screen.getByText('All Sections'))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('0')
    })
  })
})
