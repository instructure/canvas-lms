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
import {render} from '@testing-library/react'
import Avatar from '../Avatar'

describe('StudentContextTray/Avatar', () => {
  test('renders no avatars by default', () => {
    const wrapper = render(<Avatar name="" user={{}} courseId="1" canMasquerade={true} />)
    expect(wrapper.container.querySelector('.StudentContextTray__Avatar')).toBeFalsy()
  })

  test('renders avatar with user object when provided', () => {
    const userName = 'wooper'
    const avatarUrl = 'http://wooper.com/avatar.png'
    const user = {
      name: userName,
      avatar_url: avatarUrl,
      _id: '17',
    }

    const wrapper = render(<Avatar name="" user={user} courseId="1" canMasquerade={true} />)
    const avatar = wrapper.container.querySelector('.StudentContextTray__Avatar span')
    expect(avatar.getAttribute('name')).toEqual(user.name)
    expect(avatar.getAttribute('src')).toEqual(user.avatar_url)

    const link = wrapper.container.querySelector('a')
    expect(link.getAttribute('href')).toEqual('/courses/1/users/17')
  })
})
