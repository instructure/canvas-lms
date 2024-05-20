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

import {DiscussionEntryContainer} from './DiscussionEntryContainer'
import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import React from 'react'
import {ReplyInfo} from '../../components/ReplyInfo/ReplyInfo'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {User} from '../../../graphql/User'

export default {
  title: 'Examples/Discussion Posts/Containers/Post Container',
  component: DiscussionEntryContainer,
  argTypes: {
    onSave: {action: 'On Save'},
    onCancel: {action: 'On Cancel'},
  },
}

const Template = args => <DiscussionEntryContainer {...args} />

export const DiscussionTopic = Template.bind({})
DiscussionTopic.args = {
  isTopic: true,
  postUtilities: (
    <PostToolbar
      isPublished={true}
      isSubscribed={true}
      repliesCount={24}
      unreadCount={4}
      onTogglePublish={() => {}}
      onToggleSubscription={() => {}}
      onReadAll={() => {}}
    />
  ),
  author: User.mock({
    displayName: 'Harry Potter',
    courseRoles: ['Author', 'Student', 'TA'],
    avatarUrl: '',
  }),
  title: 'Gryffindor Quidditch Team',
  message: 'The only role that really matters is seaker',
  isEditing: false,
  isSplitView: false,
  editor: User.mock({_id: '5', displayName: 'George Weasley'}),
  timingDisplay: 'Jan 1 4:20pm',
  editedTimingDisplay: 'Apr 20 4:20pm',
}

export const DiscussionTopicNoAuthor = Template.bind({})
DiscussionTopicNoAuthor.args = {
  isTopic: true,
  postUtilities: (
    <PostToolbar
      isPublished={true}
      isSubscribed={true}
      repliesCount={24}
      unreadCount={4}
      onTogglePublish={() => {}}
      onToggleSubscription={() => {}}
      onReadAll={() => {}}
    />
  ),
  title: 'What original starter is your favorite?',
  message: 'I have always thought Blastoise was the coolest personally.',
  isEditing: false,
  isSplitView: false,
  timingDisplay: 'Feb 22 3:30pm',
}

export const DiscussionTopicLargePost = Template.bind({})
DiscussionTopicLargePost.args = {
  isTopic: true,
  postUtilities: (
    <PostToolbar
      isPublished={true}
      isSubscribed={true}
      repliesCount={24}
      unreadCount={4}
      onTogglePublish={() => {}}
      onToggleSubscription={() => {}}
      onReadAll={() => {}}
    />
  ),
  author: User.mock({displayName: 'Harry Potter', avatarUrl: ''}),
  title: 'Lets make it real big!',
  message: 'This is the post that never ends. It goes on and on my friends. '.repeat(10),
  isEditing: false,
  isSplitView: false,
  editor: User.mock({_id: '5', displayName: 'George Weasley'}),
  timingDisplay: 'Jan 1 4:20pm',
  editedTimingDisplay: 'Apr 20 4:20pm',
}

export const DiscussionEntry = Template.bind({})
DiscussionEntry.args = {
  isTopic: false,
  postUtilities: (
    <ThreadActions
      goToTopic={() => {}}
      onEdit={() => {}}
      onDelete={() => {}}
      onMarkAllAsUnread={() => {}}
      onToggleUnread={() => {}}
      onOpenInSpeedGrader={() => {}}
    />
  ),
  author: User.mock({displayName: 'Gandalf', avatarUrl: ''}),
  message:
    "End? No, the journey doesn't end here. Death is just another path, one that we all must take. The grey rain-curtain of this world rolls back, and all turns to silver glass, and then you see it. White shores, and beyond, a far green country under a swift sunrise.",
  isEditing: false,
  isUnread: true,
  isSplitView: false,
  editor: User.mock({_id: '5', displayName: 'Pippin'}),
  timingDisplay: 'Jan 1 4:20pm',
  editedTimingDisplay: 'Jan 2 6:45pm',
  lastReplyAtDisplay: 'Jan 3 2:00am',
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Reply onReply={() => {}} delimiterKey="reply" />
      <ThreadingToolbar.Like onClick={() => {}} likeCount={5} isLiked={true} delimiterKey="like" />
      <ThreadingToolbar.Expansion
        onExpand={() => {}}
        expandText={<ReplyInfo replyCount={24} unreadCount={4} />}
        delimiterKey="expansion"
      />
    </ThreadingToolbar>
  ),
}

export const DiscussionEntryEdit = Template.bind({})
DiscussionEntryEdit.args = {
  isTopic: false,
  postUtilities: (
    <ThreadActions
      goToTopic={() => {}}
      onEdit={() => {}}
      onDelete={() => {}}
      onMarkAllAsUnread={() => {}}
      onToggleUnread={() => {}}
      onOpenInSpeedGrader={() => {}}
    />
  ),
  author: User.mock({displayName: 'Gandalf', avatarUrl: ''}),
  message:
    "End? No, the journey doesn't end here. Death is just another path, one that we all must take. The grey rain-curtain of this world rolls back, and all turns to silver glass, and then you see it. White shores, and beyond, a far green country under a swift sunrise.",
  isEditing: true,
  isSplitView: false,
  timingDisplay: 'Jan 1 4:20pm',
  editedTimingDisplay: 'Jan 2 6:45pm',
  lastReplyAtDisplay: 'Jan 3 2:00am',
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Reply onReply={() => {}} delimiterKey="reply" />
      <ThreadingToolbar.Like onClick={() => {}} likeCount={5} isLiked={true} delimiterKey="like" />
      <ThreadingToolbar.Expansion
        onExpand={() => {}}
        expandText={<ReplyInfo replyCount={24} unreadCount={4} />}
        delimiterKey="expansion"
      />
    </ThreadingToolbar>
  ),
}

export const DiscussionEntryNoAuthor = Template.bind({})
DiscussionEntryNoAuthor.args = {
  isTopic: false,
  postUtilities: (
    <ThreadActions
      goToTopic={() => {}}
      onEdit={() => {}}
      onDelete={() => {}}
      onMarkAllAsUnread={() => {}}
      onToggleUnread={() => {}}
      onOpenInSpeedGrader={() => {}}
    />
  ),
  message: 'Hey man! where is my author?!?!?!',
  isEditing: false,
  isSplitView: false,
  timingDisplay: 'Jan 1 4:20pm',
  editedTimingDisplay: 'Jan 2 6:45pm',
  lastReplyAtDisplay: 'Jan 3 2:00am',
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Reply onReply={() => {}} delimiterKey="reply" />
      <ThreadingToolbar.Like onClick={() => {}} likeCount={5} isLiked={true} delimiterKey="like" />
      <ThreadingToolbar.Expansion
        onExpand={() => {}}
        expandText={<ReplyInfo replyCount={24} unreadCount={4} />}
        delimiterKey="expansion"
      />
    </ThreadingToolbar>
  ),
}

export const DeletedEntry = Template.bind({})
DeletedEntry.args = {
  deleted: true,
  isTopic: false,
  author: User.mock({displayName: 'Morty Smith', avatarUrl: ''}),
  editor: User.mock({_id: '5', displayName: 'Rick Sanchez'}),
  message: 'Where is my portal gun MORTY!!!',
  isEditing: false,
  isSplitView: false,
  timingDisplay: 'Jan 1 4:20pm',
  editedTimingDisplay: 'Jan 2 6:45pm',
  lastReplyAtDisplay: 'Jan 3 2:00am',
  children: (
    <ThreadingToolbar>
      <ThreadingToolbar.Reply onReply={() => {}} delimiterKey="reply" />
      <ThreadingToolbar.Like onClick={() => {}} likeCount={5} isLiked={true} delimiterKey="like" />
      <ThreadingToolbar.Expansion
        onExpand={() => {}}
        expandText={<ReplyInfo replyCount={24} unreadCount={4} />}
        delimiterKey="expansion"
      />
    </ThreadingToolbar>
  ),
}
