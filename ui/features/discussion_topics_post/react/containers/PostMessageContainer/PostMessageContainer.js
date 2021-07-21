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

import DateHelper from '@canvas/datetime/dateHelper'
import {DeletedPostMessage} from '../../components/DeletedPostMessage/DeletedPostMessage'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {SearchContext} from '../../utils/constants'

export const PostMessageContainer = props => {
  const createdAt = DateHelper.formatDatetimeForDiscussions(props.discussionEntry.createdAt)
  const {searchTerm, filter} = useContext(SearchContext)

  if (props.discussionEntry.deleted) {
    const name = props.discussionEntry.editor
      ? props.discussionEntry.editor.name
      : props.discussionEntry.author.name
    return (
      <DeletedPostMessage deleterName={name} timingDisplay={createdAt}>
        <ThreadingToolbar>{props.threadActions}</ThreadingToolbar>
      </DeletedPostMessage>
    )
  } else {
    return (
      <PostMessage
        authorName={props.discussionEntry.author.name}
        avatarUrl={props.discussionEntry.author.avatarUrl}
        lastReplyAtDisplayText={DateHelper.formatDatetimeForDiscussions(
          props.discussionEntry.lastReply?.createdAt
        )}
        timingDisplay={createdAt}
        message={props.discussionEntry.message}
        isUnread={!props.discussionEntry.read}
        isEditing={props.isEditing}
        onCancel={props.onCancel}
        onSave={props.onSave}
        isForcedRead={props.discussionEntry.forcedReadState}
        discussionRoles={props?.discussionRoles}
      >
        <ThreadingToolbar searchTerm={searchTerm} filter={filter}>
          {props.threadActions}
        </ThreadingToolbar>
      </PostMessage>
    )
  }
}

PostMessageContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape,
  threadActions: PropTypes.arrayOf(PropTypes.object),
  isEditing: PropTypes.bool,
  onCancel: PropTypes.func,
  onSave: PropTypes.func
}

PostMessageContainer.defaultProps = {
  threadActions: [],
  isEditing: false,
  onCancel: () => {},
  onSave: () => {}
}

export default PostMessageContainer
