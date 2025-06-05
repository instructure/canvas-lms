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
import {render, screen, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'

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
    const {container, getByRole, getByText, getByLabelText, getByDisplayValue} = render(
      <SectionFilter {...defaultProps} {...props} />,
    )
    return {container, getByRole, getByText, getByLabelText, getByDisplayValue}
  }

  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    cleanup()
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  it('labels the filter with "Section Filter"', () => {
    const {getByLabelText} = renderSectionFilter()
    expect(getByLabelText('Section Filter')).toBeInTheDocument()
  })

  it('displays the name of the selected section as the value', () => {
    const {getByDisplayValue} = renderSectionFilter({selectedSectionId: '2002'})
    expect(getByDisplayValue('Section 2')).toBeInTheDocument()
  })

  it('displays "All Sections" as the value when selected', () => {
    const {getByDisplayValue} = renderSectionFilter()
    expect(getByDisplayValue('All Sections')).toBeInTheDocument()
  })

  describe('sections list', () => {
    it('labels the "all items" option with "All Sections"', async () => {
      const user = userEvent.setup()
      const {getByRole, getByText} = renderSectionFilter()
      const combobox = getByRole('combobox')
      await user.click(combobox)
      expect(getByText('All Sections')).toBeInTheDocument()
    })

    it('labels each option using the related section name in alphabetical order', async () => {
      const user = userEvent.setup()
      const {getByRole} = renderSectionFilter()
      const combobox = getByRole('combobox')
      await user.click(combobox)
      const options = screen.getAllByRole('option')
      expect(options[1]).toHaveTextContent('Section 1')
      expect(options[2]).toHaveTextContent('Section 2')
    })

    it('disables non-selected options when the filter is disabled', async () => {
      const user = userEvent.setup()
      const {getByRole, getByText} = renderSectionFilter({disabled: true})
      const combobox = getByRole('combobox')
      await user.click(combobox)
      const option = getByText('Section 2')
      expect(option).toHaveAttribute('aria-disabled', 'true')
    })
  })

  describe('selecting an option', () => {
    it('calls the onSelect callback', async () => {
      const user = userEvent.setup()
      const {getByRole, getByText} = renderSectionFilter()
      const combobox = getByRole('combobox')
      await user.click(combobox)
      await user.click(getByText('Section 1'))
      expect(defaultProps.onSelect).toHaveBeenCalledTimes(1)
    })

    it('includes the section id when calling the onSelect callback', async () => {
      const user = userEvent.setup()
      const {getByRole, getByText} = renderSectionFilter()
      const combobox = getByRole('combobox')
      await user.click(combobox)
      await user.click(getByText('Section 1'))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('2001')
    })

    it('includes "0" when "All Sections" is clicked', async () => {
      const user = userEvent.setup()
      const {getByRole, getByText} = renderSectionFilter({selectedSectionId: '2001'})
      const combobox = getByRole('combobox')
      await user.click(combobox)
      await user.click(getByText('All Sections'))
      expect(defaultProps.onSelect).toHaveBeenCalledWith('0')
    })
  })
})
