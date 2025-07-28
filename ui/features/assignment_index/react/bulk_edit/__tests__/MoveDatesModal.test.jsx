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

import { render, screen, waitFor } from '@testing-library/react'
import React from 'react'
import userEvent, { PointerEventsCheckLevel } from '@testing-library/user-event'
import MoveDatesModal, { SHIFT_DAYS_MAX, SHIFT_DAYS_MIN } from '../MoveDatesModal'

describe('MoveDatesModal', () => {
  const props = (overrides = {}) => ({
    onShiftDays: jest.fn(),
    onRemoveDates: jest.fn(),
    onCancel: jest.fn(),
    open: true,
    ...overrides,
  })

  const user = userEvent.setup({ pointerEventsCheck: PointerEventsCheckLevel.Never })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderModal = () => {
    render(<MoveDatesModal {...props()} />)
    const numberInput = screen.getByLabelText('Days')
    const confirmButton = screen.getByText('Confirm')
    return { numberInput, confirmButton }
  }

  it('shows error if days is empty', async () => {
    const { numberInput, confirmButton } = renderModal()
    await user.clear(numberInput)
    await user.click(confirmButton)
    const errorMessage = await screen.findByText('Number of days is required')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows error if days is non-numeric value', async () => {
    const { numberInput, confirmButton } = renderModal()
    await user.clear(numberInput)
    await user.type(numberInput, 'abcde')
    await user.click(confirmButton)
    const errorMessage = await screen.findByText('You must use a number')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows error if days is decimal', async () => {
    const { numberInput, confirmButton } = renderModal()
    await user.clear(numberInput)
    await user.type(numberInput, '5.9')
    await user.click(confirmButton)
    const errorMessage = await screen.findByText('You must use an integer')
    expect(errorMessage).toBeInTheDocument()
  })

  it('shows error if days is out of range', async () => {
    const { numberInput, confirmButton } = renderModal()
    await user.clear(numberInput)
    await user.type(numberInput, '0')
    await user.click(confirmButton)
    const errorMessage = await screen.findByText(`Must be between ${SHIFT_DAYS_MIN} and ${SHIFT_DAYS_MAX}`)
    expect(errorMessage).toBeInTheDocument()
  })

  it('clears days error when input value changes', async () => {
    const { numberInput, confirmButton } = renderModal()
    await user.clear(numberInput)
    await user.click(confirmButton)
    const errorMessage = await screen.findByText('Number of days is required')
    expect(errorMessage).toBeInTheDocument()

    await user.type(numberInput, '998')
    await waitFor(() => {
      expect(screen.queryByText('Number of days is required')).not.toBeInTheDocument()
    })
  })

  it('clears days error when radio selection changes', async () => {
    const { numberInput, confirmButton } = renderModal()
    await user.clear(numberInput)
    await user.click(confirmButton)
    const errorMessage = await screen.findByText('Number of days is required')
    expect(errorMessage).toBeInTheDocument()

    await user.click(screen.getByLabelText('Remove Dates'))
    await waitFor(() => {
      expect(screen.queryByText('Number of days is required')).not.toBeInTheDocument()
    })
  })
})
