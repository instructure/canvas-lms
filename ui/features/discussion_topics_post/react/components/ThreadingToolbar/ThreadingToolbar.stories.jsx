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

import {ThreadingToolbar} from './ThreadingToolbar'

export default {
  title: 'Examples/Discussion Posts/Components/ThreadingToolbar',
  component: ThreadingToolbar,
  argTypes: {},
}

export const Default = () => (
  <ThreadingToolbar>
    <ThreadingToolbar.Reply onReply={Function.prototype} delimiterKey="reply" />
    <ThreadingToolbar.Like
      onClick={Function.prototype}
      likeCount={2}
      isLiked={true}
      delimiterKey="like"
    />
    <ThreadingToolbar.Expansion
      onExpand={Function.prototype}
      expandText="4 replies, 2 unread"
      isExpanded={true}
      delimiterKey="expansion"
    />
  </ThreadingToolbar>
)

export const WithoutLiking = () => (
  <ThreadingToolbar>
    <ThreadingToolbar.Reply onReply={Function.prototype} delimiterKey="reply" />
    <ThreadingToolbar.Expansion
      onExpand={Function.prototype}
      expandText="4 replies, 2 unread"
      isExpanded={true}
      delimiterKey="expansion"
    />
  </ThreadingToolbar>
)

export const WithoutExpansion = () => (
  <ThreadingToolbar>
    <ThreadingToolbar.Reply onReply={Function.prototype} delimiterKey="reply" />
    <ThreadingToolbar.Like
      onClick={Function.prototype}
      likeCount={2}
      isLiked={true}
      delimiterKey="like"
    />
  </ThreadingToolbar>
)

export const OnlyReply = () => (
  <ThreadingToolbar>
    <ThreadingToolbar.Reply onReply={Function.prototype} delimiterKey="reply" />
  </ThreadingToolbar>
)
