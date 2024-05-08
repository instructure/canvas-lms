/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ConfirmationForm from '../ConfirmationForm'

function newProps() {
  return {
    onCancel: jest.fn(),
    onConfirm: jest.fn(),
    message: 'Are you sure you want to install the tool?',
    confirmLabel: 'Yes, please',
    cancelLabel: 'Nope!',
  }
}

describe('ConfirmationForm', () => {
  it('uses the specified fields', () => {
    render(<ConfirmationForm {...newProps()} />)
    expect(screen.queryByRole('button', {name: 'Nope!'})).toBeInTheDocument()
    expect(screen.queryByRole('button', {name: 'Yes, please'})).toBeInTheDocument()
    expect(screen.queryByText(/Are you sure you want to install the tool?/i)).toBeInTheDocument()
  })

  it('calls the passed in callbacks when the buttons are clicked', async () => {
    const props = newProps()
    const {onCancel, onConfirm, confirmLabel, cancelLabel} = props
    render(<ConfirmationForm {...props} />)

    await userEvent.click(screen.getByRole('button', {name: cancelLabel}))
    expect(onCancel).toHaveBeenCalled()
    await userEvent.click(screen.getByRole('button', {name: confirmLabel}))
    expect(onConfirm).toHaveBeenCalled()
  })
})
