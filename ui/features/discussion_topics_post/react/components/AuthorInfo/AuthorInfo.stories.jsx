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

import {AuthorInfo} from './AuthorInfo'
import React from 'react'
import {User} from '../../../graphql/User'

export default {
  title: 'Examples/Discussion Posts/Components/Author Info',
  component: AuthorInfo,
  argTypes: {},
}

const Template = args => <AuthorInfo {...args} />

export const NoEditor = Template.bind({})
NoEditor.args = {
  author: User.mock({displayName: 'Harry Potter', courseRoles: ['Student', 'TA'], avatarUrl: ''}),
  isUnread: false,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
}

export const Unread = Template.bind({})
Unread.args = {
  author: User.mock({displayName: 'Hagrid', courseRoles: ['Teacher'], avatarUrl: ''}),
  isUnread: true,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
}

export const WithEditor = Template.bind({})
WithEditor.args = {
  author: User.mock({displayName: 'Hermione Granger', courseRoles: ['Student'], avatarUrl: ''}),
  editor: User.mock({_id: '1337', displayName: 'Severus Snape', courseRoles: ['Teacher']}),
  isUnread: false,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
  editedTimingDisplay: 'Feb 22 12:45pm',
}

export const WithCreatedTooltip = Template.bind({})
WithCreatedTooltip.args = {
  author: User.mock({displayName: 'Hermione Granger', courseRoles: ['Student'], avatarUrl: ''}),
  editor: User.mock({_id: '1337', displayName: 'Severus Snape', courseRoles: ['Teacher']}),
  isUnread: false,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
  editedTimingDisplay: 'Feb 22 12:45pm',
  showCreatedAsTooltip: true,
}

export const WithCreatedTooltipAndNoEdit = Template.bind({})
WithCreatedTooltipAndNoEdit.args = {
  author: User.mock({displayName: 'Hermione Granger', courseRoles: ['Student'], avatarUrl: ''}),
  isUnread: false,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
  showCreatedAsTooltip: true,
}

export const WithLastReplyAt = Template.bind({})
WithLastReplyAt.args = {
  author: User.mock({displayName: 'Hermione Granger', courseRoles: ['Student'], avatarUrl: ''}),
  editor: User.mock({
    _id: '1337',
    displayName: 'Severus Super Duper Crazy Long Name Snape',
    courseRoles: ['Teacher'],
  }),
  isUnread: false,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
  editedTimingDisplay: 'Feb 22 12:45pm',
  lastReplyAtDisplay: 'Mar 14 10:20am',
  showCreatedAsTooltip: false,
}

export const WithNoAuthor = Template.bind({})
WithNoAuthor.args = {
  isUnread: true,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
}

export const WithNoRoles = Template.bind({})
WithNoRoles.args = {
  author: User.mock({displayName: 'Harry Potter', avatarUrl: ''}),
  isUnread: true,
  isForcedRead: false,
  timingDisplay: 'Jan 21 1:58pm',
  lastReplyAtDisplay: 'Mar 14 10:20am',
}
