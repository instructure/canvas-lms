/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import Avatar from '@canvas/context-cards/react/Avatar'
import {Avatar as InstUIAvatar} from '@instructure/ui-avatar'

QUnit.module('StudentContextTray/Avatar', _ => {
  test('renders no avatars by default', () => {
    const wrapper = mount(<Avatar name="" user={{}} courseId="1" canMasquerade={true} />)
    equal(wrapper.find(InstUIAvatar).first().length, 0)
  })

  test('renders avatar with user object when provided', () => {
    const userName = 'wooper'
    const avatarUrl = 'http://wooper.com/avatar.png'
    const user = {
      name: userName,
      avatar_url: avatarUrl,
      _id: '17',
    }

    const wrapper = mount(<Avatar name="" user={user} courseId="1" canMasquerade={true} />)

    const avatar = wrapper.find(InstUIAvatar).first()

    equal(avatar.prop('name'), user.name)
    equal(avatar.prop('src'), user.avatar_url)

    const link = wrapper.find('a').first()
    equal(link.prop('href'), '/courses/1/users/17')
  })
})
