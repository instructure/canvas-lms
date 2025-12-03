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
import {StudentAssignmentDetailTray} from '..'
import {MOCK_OUTCOMES} from '../../../../__fixtures__/rollups'

describe('StudentAssignmentDetailTray', () => {
  const defaultProps = {
    open: true,
    onDismiss: jest.fn(),
    outcome: MOCK_OUTCOMES[0],
  }

  it('renders when open', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    expect(screen.getByTestId('student-assignment-detail-tray')).toBeInTheDocument()
  })

  it('displays the outcome title', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    expect(screen.getByText(defaultProps.outcome.title)).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', async () => {
    const user = userEvent.setup()
    const onDismiss = jest.fn()
    render(<StudentAssignmentDetailTray {...defaultProps} onDismiss={onDismiss} />)

    const closeButton = screen.getByRole('button', {name: /close/i})
    await user.click(closeButton)

    expect(onDismiss).toHaveBeenCalledTimes(1)
  })

  it('does not render when closed', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} open={false} />)
    const tray = screen.queryByTestId('student-assignment-detail-tray')
    expect(tray).not.toBeInTheDocument()
  })
})
