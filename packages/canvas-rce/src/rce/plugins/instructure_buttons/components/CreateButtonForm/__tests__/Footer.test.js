/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Footer} from '../Footer'

describe('<Footer />', () => {
  const defaults = {
    onCancel: jest.fn(),
    onSubmit: jest.fn()
  }

  it('submits the buttons tray', () => {
    const onSubmit = jest.fn()
    render(<Footer {...defaults} onSubmit={onSubmit} />)
    userEvent.click(screen.getByRole('button', {name: /apply/i}))
    expect(onSubmit).toHaveBeenCalled()
  })

  it('closes the buttons tray', () => {
    const onCancel = jest.fn()
    render(<Footer {...defaults} onCancel={onCancel} />)
    userEvent.click(screen.getByRole('button', {name: /cancel/i}))
    expect(onCancel).toHaveBeenCalled()
  })

  it('renders the footer disabled', () => {
    render(<Footer {...defaults} disabled />)
    const cancelButton = screen.getByRole('button', {name: /cancel/i})
    const applyButton = screen.getByRole('button', {name: /apply/i})
    expect(cancelButton).toBeDisabled()
    expect(applyButton).toBeDisabled()
  })
})
