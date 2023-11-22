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
import {User} from '../types'

describe('<TempEnrollAvatar />', () => {
  const user: User = {
    id: '1',
    name: 'John Doe',
    avatar_url: 'http://example.com/avatar.jpg',
  }

  it('renders the user name', () => {
    render(<TempEnrollAvatar user={user} />)
    const nameElement = screen.getByText(user.name)
    expect(nameElement).toBeInTheDocument()
  })

  it('renders the avatar with correct attributes', () => {
    render(<TempEnrollAvatar user={user} />)
    const avatarElement = screen.getByAltText('Avatar for John Doe')
    expect(avatarElement).toBeInTheDocument()
    expect(avatarElement).toHaveAttribute('src', user.avatar_url)
  })

  it('renders the children instead of the user name when provided', () => {
    const childText = 'Custom child text'
    render(<TempEnrollAvatar user={user}>{childText}</TempEnrollAvatar>)
    const childElement = screen.getByText(childText)
    expect(childElement).toBeInTheDocument()
    const nameElement = screen.queryByText(user.name)
    expect(nameElement).not.toBeInTheDocument()
  })
})
