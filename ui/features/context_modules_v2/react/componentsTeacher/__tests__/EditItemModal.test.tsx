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
import {render, fireEvent, screen} from '@testing-library/react'
import EditItemModal from '../EditItemModal'

jest.mock('@canvas/query')

describe('EditItemModal', () => {
  const defaultProps = {
    isOpen: true,
    onRequestClose: jest.fn(),
    itemName: 'Test Item',
    itemIndent: 1,
    itemId: '123',
    courseId: '1',
    moduleId: '1',
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders with initial values', () => {
    render(<EditItemModal {...defaultProps} />)

    expect(screen.getByLabelText('Title')).toHaveValue('Test Item')
    expect(screen.getByLabelText('Indent')).toHaveValue('Indent 1 level')
  })

  it('updates title when typing', () => {
    render(<EditItemModal {...defaultProps} />)
    const titleInput = screen.getByTestId('edit-modal-title')
    fireEvent.change(titleInput, {target: {value: 'New Title'}})
    expect(titleInput).toHaveValue('New Title')
  })

  it('updates indent when changed', () => {
    render(<EditItemModal {...defaultProps} />)

    const indentSelect = screen.getByRole('combobox', {name: 'Indent'})
    fireEvent.click(indentSelect)
    fireEvent.click(screen.getByText('Indent 2 levels'))
    expect(indentSelect).toHaveValue('Indent 2 levels')
  })

  it('calls onRequestClose when Cancel is clicked', () => {
    render(<EditItemModal {...defaultProps} />)
    fireEvent.click(screen.getByText('Cancel'))
    expect(defaultProps.onRequestClose).toHaveBeenCalled()
  })
})
