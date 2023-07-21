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
import {User} from '../../../graphql/User'

export default {
  title: 'Examples/Discussion Posts/Components/PostMessage',
  component: PostMessage,
  argTypes: {},
}

const Template = args => (
  <PostMessage author={User.mock()} title="This is a title" message="Posts are fun" {...args} />
)

export const Default = Template.bind({})
Default.args = {}

export const LargePost = Template.bind({})
LargePost.args = {
  message: 'This is the post that never ends. It goes on and on my friends. '.repeat(10),
}

export const WithChildren = Template.bind({})
WithChildren.args = {
  title: '',
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Reply onReply={Function.prototype} />
      <ThreadingToolbar.Like onClick={Function.prototype} likeCount={2} isLiked={true} />
      <ThreadingToolbar.Expansion
        onExpand={Function.prototype}
        expandText="4 replies, 2 unread"
        isExpanded={true}
      />
    </ThreadingToolbar>
  ),
}
