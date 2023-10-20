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
import {DiscussionTopicContainer} from './DiscussionTopicContainer'
import React from 'react'

export default {
  title: 'Examples/Discussion Posts/Containers/Discussion Topic Contaner',
  component: DiscussionTopicContainer,
}

const Template = args => <DiscussionTopicContainer {...args} />

export const Default = Template.bind({})
Default.args = {
  isGraded: false,
  discussionTopic: {
    title: 'This is an Example Discussion',
    author: {
      displayName: 'Gunnar Gunderson Gunn',
      avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
    },
    message: 'Please introduce yourselves.',
  },
}

export const TeacherViewGraded = Template.bind({})
TeacherViewGraded.args = {
  isGraded: true,
  onReply: {acton: 'Reply'},
  discussionTopic: {
    _id: '1',
    id: 'VXNlci0x',
    title: 'Graded Teacher View Discussion',
    author: {
      displayName: 'Mister Teacher',
      avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
    },
    message: '<p> This is the Discussion Topic. It will be graded.</p>',
    postedAt: '2021-04-05T13:40:50Z',
    subscribed: true,
    entryCounts: {
      repliesCount: 24,
      unreadCount: 4,
    },
    assignment: {
      dueAt: '2021-04-05T13:40:50Z',
      pointsPossible: 5,
    },
    permissions: {
      readAsAdmin: true,
    },
  },
}
