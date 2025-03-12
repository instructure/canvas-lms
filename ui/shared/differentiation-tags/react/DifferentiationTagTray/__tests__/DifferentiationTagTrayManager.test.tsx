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
import DifferentiationTagTrayManager from '../DifferentiationTagTrayManager'
import {useDifferentiationTagCategoriesIndex} from '../../hooks/useDifferentiationTagCategoriesIndex'

jest.mock('../../hooks/useDifferentiationTagCategoriesIndex')

const mockUseDifferentiationTagCategoriesIndex = useDifferentiationTagCategoriesIndex as jest.Mock

describe('DifferentiationTagTrayManager', () => {
  const defaultProps = {
    isOpen: true,
    onClose: jest.fn(),
    courseID: 123,
  }

  let user: ReturnType<typeof userEvent.setup>
  const renderComponent = (mockReturn = {}, props = {}) => {
    const defaultMock = {
      data: [],
      isLoading: false,
      error: null,
    }
    mockUseDifferentiationTagCategoriesIndex.mockReturnValue({...defaultMock, ...mockReturn})
    render(<DifferentiationTagTrayManager {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the tray when isOpen is true', () => {
    renderComponent()
    expect(screen.queryByTestId('differentiation-tag-header')).toBeInTheDocument()
  })

  it('shows loading spinner when data is being fetched', () => {
    renderComponent({isLoading: true})
    expect(screen.getByTitle('Loading...')).toBeInTheDocument()
  })

  it('shows error message when there is an error', () => {
    const error = new Error('Failed to fetch')
    renderComponent({error})
    expect(screen.getByText(/Error loading categories:/)).toBeInTheDocument()
    expect(screen.getByText(/Failed to fetch/)).toBeInTheDocument()
  })
  it('shows error message when course id is not provided', () => {
    const error = new Error('A valid course ID is required')
    renderComponent({error}, {courseID: undefined})
    expect(screen.getByText(/Error loading categories:/)).toBeInTheDocument()
    expect(screen.getByText(/A valid course ID is required./)).toBeInTheDocument()
  })

  it('displays differentiation tag categories when data is retrieved from the hook', () => {
    const mockCategories = [
      {id: 1, name: 'Category 1'},
      {id: 2, name: 'Category 2'},
    ]
    renderComponent({data: mockCategories})
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

  it('calls useDifferentiationTagCategoriesIndex with correct courseID', () => {
    renderComponent()
    expect(mockUseDifferentiationTagCategoriesIndex).toHaveBeenCalledWith(123, {
      enabled: true,
      includeDifferentiationTags: true,
    })
  })

  it('renders help text when there are no differentiation tags', () => {
    renderComponent()
    expect(screen.getByText(/Like groups, but different!/)).toBeInTheDocument()
  })
})
