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

  const authorId = props.discussionEntry?.author?._id
  const editorId = props.discussionEntry?.editor?._id
  const editorName = props.discussionEntry?.editor?.displayName
  const editedTimingDisplay = DateHelper.formatDatetimeForDiscussions(
    props.discussionEntry.updatedAt
  )

  const wasEdited =
    !!editorId && props.discussionEntry.createdAt !== props.discussionEntry.updatedAt

  if (props.discussionEntry.deleted) {
    const name = props.discussionEntry.editor
      ? props.discussionEntry.editor.displayName
      : props.discussionEntry.author.displayName
    return (
      <DeletedPostMessage deleterName={name} timingDisplay={createdAt}>
        <ThreadingToolbar>{props.threadActions}</ThreadingToolbar>
      </DeletedPostMessage>
    )
  } else {
    return (
      <PostMessage
        authorName={props.discussionEntry.author.displayName}
        editorName={wasEdited && editorId !== authorId ? editorName : null}
        editedTimingDisplay={wasEdited ? editedTimingDisplay : null}
        avatarUrl={props.discussionEntry.author.avatarUrl}
        isIsolatedView={props.isIsolatedView}
        lastReplyAtDisplayText={DateHelper.formatDatetimeForDiscussions(
          props.discussionEntry.lastReply?.createdAt
        )}
        timingDisplay={createdAt}
        showCreatedAsTooltip={wasEdited}
        message={props.discussionEntry.message}
        isUnread={!props.discussionEntry.read}
        isEditing={props.isEditing}
        onCancel={props.onCancel}
        onSave={props.onSave}
        isForcedRead={props.discussionEntry.forcedReadState}
        discussionRoles={props?.discussionRoles}
      >
        <ThreadingToolbar
          searchTerm={searchTerm}
          filter={filter}
          discussionEntry={props.discussionEntry}
          onOpenIsolatedView={props.onOpenIsolatedView}
          isIsolatedView={props.isIsolatedView}
        >
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
  onSave: PropTypes.func,
  isIsolatedView: PropTypes.bool,
  onOpenIsolatedView: PropTypes.func
}

PostMessageContainer.defaultProps = {
  threadActions: [],
  isEditing: false,
  onCancel: () => {},
  onSave: () => {}
}

export default PostMessageContainer
