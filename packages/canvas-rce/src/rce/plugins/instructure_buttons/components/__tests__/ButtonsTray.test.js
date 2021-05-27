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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ButtonsTray} from '../ButtonsTray'

describe('RCE "Buttons and Icons" Plugin > ButtonsTray', () => {
  const defaults = {
    editor: null,
    onUnmount: jest.fn(),
    type: 'create'
  }

  it('renders the create view', () => {
    render(<ButtonsTray {...defaults} />)
    screen.getByRole('heading', {name: /buttons and icons/i})
  })

  it('renders the list view', () => {
    render(<ButtonsTray {...defaults} type="list" />)
    screen.getByRole('heading', {name: /saved buttons and icons/i})
  })

  it('closes the tray', async () => {
    const onUnmount = jest.fn()
    render(<ButtonsTray {...defaults} onUnmount={onUnmount} />)
    userEvent.click(screen.getByText(/close/i))
    await waitFor(() => expect(onUnmount).toHaveBeenCalled())
  })
})
