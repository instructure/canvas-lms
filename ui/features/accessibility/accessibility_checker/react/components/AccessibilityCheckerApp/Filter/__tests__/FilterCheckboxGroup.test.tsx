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

import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FilterCheckboxGroup from '../FilterCheckboxGroup'
import {FilterOption} from '../../../../../../shared/react/types'

describe('FilterCheckboxGroup', () => {
  afterEach(() => {
    cleanup()
  })

  const mockOnUpdate = vi.fn()
  const mockOptions: {value: string; label: string}[] = [
    {value: 'option1', label: 'Option 1'},
    {value: 'option2', label: 'Option 2'},
    {value: 'option3', label: 'Option 3'},
  ]

  const defaultProps = {
    options: mockOptions,
    selected: [] as FilterOption[],
    onUpdate: mockOnUpdate,
    name: 'test-checkbox-group',
    description: 'Test checkbox group',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders all options including the "All" option', () => {
    render(<FilterCheckboxGroup {...defaultProps} />)

    expect(screen.getByLabelText('All')).toBeInTheDocument()
    expect(screen.getByLabelText('Option 1')).toBeInTheDocument()
    expect(screen.getByLabelText('Option 2')).toBeInTheDocument()
    expect(screen.getByLabelText('Option 3')).toBeInTheDocument()
  })

  it('renders with correct values', () => {
    render(<FilterCheckboxGroup {...defaultProps} />)

    const allCheckbox = screen.getByLabelText('All')
    const option1Checkbox = screen.getByLabelText('Option 1')
    const option2Checkbox = screen.getByLabelText('Option 2')
    const option3Checkbox = screen.getByLabelText('Option 3')

    expect(allCheckbox).toHaveAttribute('value', 'all')
    expect(option1Checkbox).toHaveAttribute('value', 'option1')
    expect(option2Checkbox).toHaveAttribute('value', 'option2')
    expect(option3Checkbox).toHaveAttribute('value', 'option3')
  })

  it('shows selected options as checked', () => {
    const selectedOptions: FilterOption[] = [
      {value: 'option1', label: 'Option 1'},
      {value: 'option2', label: 'Option 2'},
    ]

    render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

    expect(screen.getByLabelText('Option 1')).toBeChecked()
    expect(screen.getByLabelText('Option 2')).toBeChecked()
    expect(screen.getByLabelText('Option 3')).not.toBeChecked()
    expect(screen.getByLabelText('All')).not.toBeChecked()
  })

  it('shows "All" option as checked when it is selected', () => {
    const selectedOptions: FilterOption[] = [{value: 'all', label: 'All'}]

    render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

    expect(screen.getByLabelText('All')).toBeChecked()
    expect(screen.getByLabelText('Option 1')).toBeChecked()
    expect(screen.getByLabelText('Option 2')).toBeChecked()
    expect(screen.getByLabelText('Option 3')).toBeChecked()
  })

  describe('when "All" option is selected', () => {
    it('selects all options when "All" is clicked and no other options are selected', async () => {
      render(<FilterCheckboxGroup {...defaultProps} />)

      const allCheckbox = screen.getByLabelText('All')
      await userEvent.click(allCheckbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'all', label: 'All'}])
    })

    it('selects all options when "All" is clicked and other options are already selected', async () => {
      const selectedOptions: FilterOption[] = [
        {value: 'option1', label: 'Option 1'},
        {value: 'option2', label: 'Option 2'},
      ]

      render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

      const allCheckbox = screen.getByLabelText('All')
      await userEvent.click(allCheckbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'all', label: 'All'}])
    })

    it('removes "All" and keeps other options when "All" is deselected', async () => {
      const selectedOptions: FilterOption[] = [{value: 'all', label: 'All'}]

      render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

      const allCheckbox = screen.getByLabelText('All')
      await userEvent.click(allCheckbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([])
    })

    it('automatically selects "All" when all individual options are selected', async () => {
      const selectedOptions: FilterOption[] = [
        {value: 'option1', label: 'Option 1'},
        {value: 'option2', label: 'Option 2'},
      ]

      render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

      const option3Checkbox = screen.getByLabelText('Option 3')
      await userEvent.click(option3Checkbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'all', label: 'All'}])
    })

    it('allows unchecking individual options when "All" is selected', async () => {
      const selectedOptions: FilterOption[] = [{value: 'all', label: 'All'}]

      render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

      const option1Checkbox = screen.getByLabelText('Option 1')
      await userEvent.click(option1Checkbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([
        {value: 'option2', label: 'Option 2'},
        {value: 'option3', label: 'Option 3'},
      ])
    })
  })

  describe('when individual options are selected', () => {
    it('adds option to selection when individual option is clicked', async () => {
      render(<FilterCheckboxGroup {...defaultProps} />)

      const option1Checkbox = screen.getByLabelText('Option 1')
      await userEvent.click(option1Checkbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'option1', label: 'Option 1'}])
    })

    it('adds multiple options to selection when multiple options are clicked', async () => {
      render(<FilterCheckboxGroup {...defaultProps} />)

      const option1Checkbox = screen.getByLabelText('Option 1')
      const option2Checkbox = screen.getByLabelText('Option 2')

      await userEvent.click(option1Checkbox)
      await userEvent.click(option2Checkbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'option1', label: 'Option 1'}])
      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'option2', label: 'Option 2'}])
    })

    it('removes option from selection when individual option is deselected', async () => {
      const selectedOptions: FilterOption[] = [
        {value: 'option1', label: 'Option 1'},
        {value: 'option2', label: 'Option 2'},
      ]

      render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

      const option1Checkbox = screen.getByLabelText('Option 1')
      await userEvent.click(option1Checkbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([{value: 'option2', label: 'Option 2'}])
    })

    it('handles empty selection when all options are deselected', async () => {
      const selectedOptions: FilterOption[] = [{value: 'option1', label: 'Option 1'}]

      render(<FilterCheckboxGroup {...defaultProps} selected={selectedOptions} />)

      const option1Checkbox = screen.getByLabelText('Option 1')
      await userEvent.click(option1Checkbox)

      expect(mockOnUpdate).toHaveBeenCalledWith([])
    })
  })
})
