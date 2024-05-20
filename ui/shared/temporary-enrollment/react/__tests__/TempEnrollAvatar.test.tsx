/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import '@testing-library/jest-dom'
import {TempEnrollAvatar} from '../TempEnrollAvatar'
import type {User} from '../types'

const mockUser: User = {
  id: '1',
  name: 'John Doe',
  avatar_url: 'https://example.com/avatar.jpg',
}

const props = {
  user: mockUser,
}

describe('TempEnrollAvatar', () => {
  it('renders the user name', () => {
    render(<TempEnrollAvatar {...props} />)
    const nameElement = screen.getByText(props.user.name)
    expect(nameElement).toBeInTheDocument()
  })

  it('renders the user name without an avatar url', () => {
    const newProps = {
      user: {
        ...props.user,
        avatar_url: undefined,
      },
    }
    render(<TempEnrollAvatar {...newProps} />)
    const nameElement = screen.getByText(props.user.name)
    expect(nameElement).toBeInTheDocument()
  })

  it('renders the avatar with correct attributes', () => {
    render(<TempEnrollAvatar {...props} />)
    const avatarElement = screen.getByAltText('Avatar for John Doe')
    expect(avatarElement).toBeInTheDocument()
    expect(avatarElement).toHaveAttribute('src', props.user.avatar_url)
  })

  it('renders the children instead of the user name when provided', () => {
    const childText = 'Custom child text'
    render(<TempEnrollAvatar {...props}>{childText}</TempEnrollAvatar>)
    const childElement = screen.getByText(childText)
    expect(childElement).toBeInTheDocument()
    const nameElement = screen.queryByText(props.user.name)
    expect(nameElement).not.toBeInTheDocument()
  })
})
