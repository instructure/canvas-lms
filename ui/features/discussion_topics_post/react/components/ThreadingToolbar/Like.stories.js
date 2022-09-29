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
  title: 'Examples/Discussion Posts/Components/ThreadingToolbar/Like',
  component: ThreadingToolbar.Like,
  argTypes: {},
}

const Template = args => (
  <ThreadingToolbar.Like
    isLiked={true}
    likeCount={1}
    delimiterKey="like"
    authorName="Rex"
    {...args}
  />
)

export const Liked = Template.bind({})
Liked.args = {}

export const NotLiked = Template.bind({})
NotLiked.args = {
  isLiked: false,
  likeCount: 0,
}
