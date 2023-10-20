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

import {PostToolbar} from './PostToolbar'

export default {
  title: 'Examples/Discussion Posts/Components/PostToolbar',
  component: PostToolbar,
  argTypes: {
    onReadAll: {action: 'Read All'},
    onDelete: {action: 'Delete'},
    onToggleComments: {action: 'Toggle Comments'},
    onSend: {action: 'Send'},
    onCopy: {action: 'Copy'},
    onEdit: {action: 'Edit'},
    onTogglePublish: {action: 'Toggle Publish'},
    onToggleSubscription: {action: 'Toggle Subscription'},
    onPeerReviews: {action: 'Peer Reviews'},
  },
}

const Template = args => <PostToolbar {...args} />

export const Default = Template.bind({})
Default.args = {
  isPublished: true,
  isSubscribed: true,
  repliesCount: 24,
  unreadCount: 4,
}

export const StudentView = Template.bind({})
StudentView.args = {
  onDelete: null,
  onToggleComments: null,
  onSend: null,
  onCopy: null,
  onEdit: null,
  onTogglePublish: null,
  onToggleSubscription: null,
  onOpenSpeedgrader: null,
  onShareToCommons: null,
}

export const NoReplies = Template.bind({})
NoReplies.args = {
  isPublished: true,
  isSubscribed: true,
}
