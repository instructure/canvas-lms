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
import {SingleButton} from '../SingleButton'
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
  button: defaultButtonData,
  isFullWidth: false,
}

describe('SingleButton tooltip', () => {
  it('shows tooltip for new-tab links with URL', async () => {
    const user = userEvent.setup()
    render(<SingleButton {...defaultProps} />)

    const button = screen.getByRole('link')
    await user.hover(button)
    expect(screen.getByText('Opens in new window')).toBeInTheDocument()
  })

  it('does not show tooltip when URL is empty', () => {
    const buttonWithoutUrl = {...defaultButtonData, url: ''}
    render(<SingleButton {...defaultProps} button={buttonWithoutUrl} />)
    expect(screen.queryByText('Opens in new window')).not.toBeInTheDocument()
  })

  it('does not show tooltip for same-tab links', () => {
    const sameTabButton = {...defaultButtonData, linkOpenMode: 'same-tab' as const}
    render(<SingleButton {...defaultProps} button={sameTabButton} />)
    expect(screen.queryByText('Opens in new window')).not.toBeInTheDocument()
  })

  it('does not show tooltip when onButtonClick is provided', () => {
    const onButtonClick = jest.fn()
    render(<SingleButton {...defaultProps} onButtonClick={onButtonClick} />)
    expect(screen.queryByText('Opens in new window')).not.toBeInTheDocument()
  })
})
