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
import AddWidgetModal from '../AddWidgetModal'

describe('AddWidgetModal', () => {
  const defaultProps = {
    open: true,
    onClose: jest.fn(),
    targetColumn: 1,
    targetRow: 2,
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders when open is true', () => {
    render(<AddWidgetModal {...defaultProps} />)
    expect(screen.getByTestId('add-widget-modal')).toBeInTheDocument()
  })

  it('does not render when open is false', () => {
    render(<AddWidgetModal {...defaultProps} open={false} />)
    expect(screen.queryByTestId('add-widget-modal')).not.toBeInTheDocument()
  })

  it('displays the correct heading', () => {
    render(<AddWidgetModal {...defaultProps} />)
    expect(screen.getByTestId('modal-heading')).toHaveTextContent('Add widget')
  })

  it('displays placeholder content', () => {
    render(<AddWidgetModal {...defaultProps} />)
    expect(screen.getByText('Modal content coming soon...')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', async () => {
    const user = userEvent.setup()
    render(<AddWidgetModal {...defaultProps} />)

    const closeButton = screen.getByTestId('close-button').querySelector('button')
    if (!closeButton) throw new Error('Close button not found')
    await user.click(closeButton)

    expect(defaultProps.onClose).toHaveBeenCalledTimes(1)
  })

  it('has correct accessibility attributes', () => {
    render(<AddWidgetModal {...defaultProps} />)
    const modal = screen.getByTestId('add-widget-modal')
    expect(modal).toHaveAttribute('aria-label', 'Add widget')
  })
})
