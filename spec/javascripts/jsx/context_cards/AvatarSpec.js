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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import Avatar from 'jsx/context_cards/Avatar'
import InstUIAvatar from '@instructure/ui-elements/lib/components/Avatar'

QUnit.module('StudentContextTray/Avatar', (hooks) => {
  let subject

  hooks.afterEach(() => {
    if (subject) {
      const componentNode = ReactDOM.findDOMNode(subject)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    subject = null
  })

  test('renders no avatars by default', () => {
    subject = TestUtils.renderIntoDocument(
      <Avatar user={{}} courseId="1" canMasquerade />
    )

    throws(() => { TestUtils.findRenderedComponentWithType(subject, InstUIAvatar) })
  })

  test('renders avatar with user object when provided', () => {
    const userName = 'wooper'
    const avatarUrl = 'http://wooper.com/avatar.png'
    const user = {
      name: userName,
      avatar_url: avatarUrl,
      _id: '17'
    }
    subject = TestUtils.renderIntoDocument(
      <Avatar user={user} courseId="1" canMasquerade />
    )

    const avatar = TestUtils.findRenderedComponentWithType(subject, InstUIAvatar)
    equal(avatar.props.name, user.name)
    equal(avatar.props.src, user.avatar_url)
    const componentNode = ReactDOM.findDOMNode(subject)
    const link = componentNode.querySelector('a')
    equal(link.getAttribute('href'), '/courses/1/users/17')
  })
})
