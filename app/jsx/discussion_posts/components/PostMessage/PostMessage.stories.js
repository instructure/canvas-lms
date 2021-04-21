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

import {ThreadingToolbar} from '../ThreadingToolbar/ThreadingToolbar'
import {PostMessage} from './PostMessage'

export default {
  title: 'Examples/Discussion Posts/PostMessage',
  component: PostMessage,
  argTypes: {}
}

const Template = args => (
  <PostMessage
    authorName="Posty Postersen"
    timingDisplay="Jan 25 1:00pm"
    message="Posts are fun"
    {...args}
  />
)

export const Default = Template.bind({})
Default.args = {}

export const AuthorPost = Template.bind({})
AuthorPost.args = {
  pillText: 'Author'
}

export const LargePost = Template.bind({})
LargePost.args = {
  message: 'This is the post that never ends. It goes on and on my friends. '.repeat(10)
}

export const AvatarPost = Template.bind({})
AvatarPost.args = {
  avatarUrl: 'https://www.gravatar.com/avatar/'
}

export const UnreadPost = Template.bind({})
UnreadPost.args = {
  isUnread: true
}

export const WithChildren = Template.bind({})
WithChildren.args = {
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Reply onReply={Function.prototype} />
      <ThreadingToolbar.Like onClick={Function.prototype} likeCount={2} isLiked />
      <ThreadingToolbar.Expansion
        onExpand={Function.prototype}
        expandText="4 replies, 2 unread"
        isExpanded
      />
    </ThreadingToolbar>
  )
}
