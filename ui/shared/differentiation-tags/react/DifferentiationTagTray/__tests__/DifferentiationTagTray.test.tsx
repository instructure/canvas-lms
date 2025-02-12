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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DifferentiationTagTray from '../DifferentiationTagTray'
import type {DifferentiationTagTrayProps} from '../DifferentiationTagTray'

describe('DifferentiationTagTray', () => {
  const defaultProps: DifferentiationTagTrayProps = {
    isOpen: true,
    onClose: jest.fn(),
    differentiationTagCategories: [],
    isLoading: false,
    error: null,
  }

  const renderComponent = (props: Partial<DifferentiationTagTrayProps> = {}) => {
    render(<DifferentiationTagTray {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the tray when isOpen is true', () => {
    renderComponent()
    expect(screen.queryByTestId('differentiation-tag-header')).toBeInTheDocument()
  })

  it('shows loading spinner when isLoading is true', () => {
    renderComponent({isLoading: true})
    expect(screen.getByTitle('Loading...')).toBeInTheDocument()
  })

  it('shows error message when there is an error', () => {
    const error = new Error('Failed to fetch')
    renderComponent({error})
    expect(screen.getByText(/Error loading tag differentiation tag categories/)).toBeInTheDocument()
    expect(screen.getByText(/Failed to fetch/)).toBeInTheDocument()
  })

  // Skipping until next patchset since Specific mocked data is being displayed in this patchset
  it.skip('displays differentiation tag categories when data is available', () => {
    const mockCategories = [
      {id: 1, name: 'Category 1'},
      {id: 2, name: 'Category 2'},
    ]
    renderComponent({differentiationTagCategories: mockCategories})
    expect(screen.getByText('Category 1')).toBeInTheDocument()
    expect(screen.getByText('Category 2')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', async () => {
    renderComponent()
    const closeButton = screen.getByRole('button', {
      name: 'Close Differentiation Tag Tray',
      hidden: true,
    })

    await userEvent.click(closeButton)
    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  it('renders help text when there are no differentiation tags', () => {
    renderComponent({isOpen: true})
    expect(screen.getByText(/Like groups, but different!/)).toBeInTheDocument()
  })

  it('does not render tray when isOpen is false', () => {
    renderComponent({isOpen: false})
    expect(screen.queryByTestId('differentiation-tag-header')).not.toBeInTheDocument()
  })

  // Skipping in this patchset since TagCategoryCards are being rendered with specific mock data
  it.skip('renders list items with proper text content', () => {
    const mockCategories = [
      {id: 1, name: 'Advanced'},
      {id: 2, name: 'Remedial'},
    ]
    renderComponent({differentiationTagCategories: mockCategories})
    const listItems = screen.queryByTestId('differentiation-tag-categories-list')?.children
    expect(listItems).toHaveLength(2)
  })
})
