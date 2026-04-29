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
import {ButtonEditView} from '../ButtonEditView'
import {ButtonData} from '../types'

const defaultButtonData: ButtonData = {
  id: 1,
  text: 'Test Button',
  url: 'https://example.com',
  linkOpenMode: 'new-tab',
  primaryColor: '#000000',
  secondaryColor: '#FFFFFF',
  style: 'filled',
}

const defaultProps = {
  ...defaultButtonData,
  isFullWidth: false,
}

describe('ButtonEditView', () => {
  it('shows "Opens edit mode" tooltip', async () => {
    const user = userEvent.setup()
    render(<ButtonEditView {...defaultProps} />)

    const button = screen.getByRole('button')
    await user.hover(button)
    expect(screen.getByText('Opens edit mode')).toBeInTheDocument()
  })

  it('renders as a button without click handler', () => {
    render(<ButtonEditView {...defaultProps} />)
    const button = screen.getByRole('button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('Test Button')
  })
})
