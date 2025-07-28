/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import DeleteConfirmation from '../DeleteConfirmation'

const defaultProps = {
  collaboration: {
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
  },
  onDelete: jest.fn(),
  onCancel: jest.fn(),
}

describe('DeleteConfirmation', () => {
  it('renders the message and action buttons', () => {
    const {getByTestId} = render(<DeleteConfirmation {...defaultProps} />)

    expect(getByTestId('delete-message')).toHaveTextContent('Remove "Hello there"?')
    expect(getByTestId('confirm-delete-button')).toHaveTextContent('Yes, remove')
    expect(getByTestId('cancel-delete-button')).toHaveTextContent('Cancel')
  })

  it('calls onDelete when clicking confirm button', () => {
    const {getByTestId} = render(<DeleteConfirmation {...defaultProps} />)

    fireEvent.click(getByTestId('confirm-delete-button'))
    expect(defaultProps.onDelete).toHaveBeenCalled()
  })

  it('calls onCancel when clicking cancel button', () => {
    const {getByTestId} = render(<DeleteConfirmation {...defaultProps} />)

    fireEvent.click(getByTestId('cancel-delete-button'))
    expect(defaultProps.onCancel).toHaveBeenCalled()
  })

  it('focuses the dialog on mount', () => {
    const {getByTestId} = render(<DeleteConfirmation {...defaultProps} />)

    expect(getByTestId('delete-confirmation')).toHaveFocus()
  })
})
