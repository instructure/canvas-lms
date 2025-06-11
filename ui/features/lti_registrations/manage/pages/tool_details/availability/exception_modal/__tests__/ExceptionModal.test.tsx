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
import {render, screen, fireEvent} from '@testing-library/react'
import {ExceptionModal} from '../ExceptionModal'
import {mockDeployment} from '../../__tests__/helpers'

describe('ExceptionModal', () => {
  it('does not render when open is false', () => {
    render(<ExceptionModal openState={{open: false}} onClose={jest.fn()} />)
    expect(screen.queryByText('Add Availability and Exceptions')).not.toBeInTheDocument()
  })

  it('renders when open is true', () => {
    render(
      <ExceptionModal
        openState={{open: true, deployment: mockDeployment({})}}
        onClose={jest.fn()}
      />,
    )
    expect(screen.getByText('Add Availability and Exceptions')).toBeInTheDocument()
    expect(screen.getByText('Availability and Exceptions')).toBeInTheDocument()
    expect(
      screen.queryByText(
        'You have not added any availability or exceptions. Search or browse to add one.',
      ),
    ).toBeInTheDocument()
  })

  it('calls onClose when CloseButton is clicked', () => {
    const onClose = jest.fn()
    render(
      <ExceptionModal openState={{open: true, deployment: mockDeployment({})}} onClose={onClose} />,
    )
    const closeBtn = screen.getByRole('button', {name: /close/i})
    fireEvent.click(closeBtn)
    expect(onClose).toHaveBeenCalled()
  })
})
