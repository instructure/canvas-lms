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
import {OldPostMessage} from '../../components/PostMessage/OldPostMessage'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {SearchContext} from '../../utils/constants'
import {Flex} from '@instructure/ui-flex'

export const DiscussionEntryMessageContainer = props => {
  const createdAt = DateHelper.formatDatetimeForDiscussions(props.discussionEntry.createdAt)
  const editedAt = DateHelper.formatDatetimeForDiscussions(props.discussionEntry.updatedAt)
  const {searchTerm, filter} = useContext(SearchContext)

  const wasEdited =
    !!props.discussionEntry?.editor?._id &&
    props.discussionEntry.createdAt !== props.discussionEntry.updatedAt

  if (props.discussionEntry.deleted) {
    const name = props.discussionEntry.editor
      ? props.discussionEntry.editor?.displayName
      : props.discussionEntry.author?.displayName
    return (
      <Flex padding="0 0 0 medium">
        <DeletedPostMessage
          deleterName={name}
          timingDisplay={createdAt}
          deletedTimingDisplay={editedAt}
        >
          <ThreadingToolbar>{props.threadActions}</ThreadingToolbar>
        </DeletedPostMessage>
      </Flex>
    )
  } else {
    return (
      <Flex padding={props.padding}>
        <OldPostMessage
          author={props.discussionEntry.author}
          editor={props.discussionEntry.editor}
          editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
            props.discussionEntry.updatedAt
          )}
          isIsolatedView={props.isIsolatedView}
          lastReplyAtDisplayText={DateHelper.formatDatetimeForDiscussions(
            props.discussionEntry.lastReply?.createdAt
          )}
          timingDisplay={createdAt}
          showCreatedAsTooltip={wasEdited}
          message={props.discussionEntry.message}
          isUnread={!props.discussionEntry.entryParticipant.read}
          isEditing={props.isEditing}
          onCancel={props.onCancel}
          onSave={props.onSave}
          isForcedRead={props.discussionEntry.entryParticipant?.forcedReadState}
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
        </OldPostMessage>
      </Flex>
    )
  }
}

DiscussionEntryMessageContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape,
  threadActions: PropTypes.arrayOf(PropTypes.object),
  isEditing: PropTypes.bool,
  onCancel: PropTypes.func,
  onSave: PropTypes.func,
  isIsolatedView: PropTypes.bool,
  onOpenIsolatedView: PropTypes.func,
  padding: PropTypes.string,
}

DiscussionEntryMessageContainer.defaultProps = {
  threadActions: [],
  isEditing: false,
  onCancel: () => {},
  onSave: () => {},
  padding: '0 0 0 0',
}

export default DiscussionEntryMessageContainer
