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
import {render, screen, waitFor} from '@testing-library/react'
import {RCSPropsContext} from '../../../../Contexts'
import {SelectMediaModal} from '../SelectMediaModal'
import {mockTrayProps} from './fixtures/mockTrayProps'
import userEvent from '@testing-library/user-event'

const user = userEvent.setup()

describe('SelectMediaModal', () => {
  const defaultProps = {
    open: true,
    onSubmit: jest.fn(),
    onDismiss: jest.fn(),
    accept: 'video/*',
  }

  const renderComponent = (props = {}) => {
    return render(
      <RCSPropsContext.Provider value={mockTrayProps}>
        <SelectMediaModal {...defaultProps} {...props} />
      </RCSPropsContext.Provider>,
    )
  }

  it('renders with the correct tabs', () => {
    const {getByText} = renderComponent()
    expect(getByText('Upload Media')).toBeInTheDocument()
    expect(getByText('Course Media')).toBeInTheDocument()
    expect(getByText('User Media')).toBeInTheDocument()
  })

  it('calls onDismiss when the modal is dismissed', async () => {
    const mockOnDismiss = jest.fn()
    renderComponent({onDismiss: mockOnDismiss})
    await user.click(screen.getAllByText('Close')[1].closest('button') as Element)
    await waitFor(() => {
      expect(mockOnDismiss).toHaveBeenCalled()
    })
  })
})
