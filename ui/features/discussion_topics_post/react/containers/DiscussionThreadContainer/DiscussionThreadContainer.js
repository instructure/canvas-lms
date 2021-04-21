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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CollapseReplies} from '../../components/CollapseReplies/CollapseReplies'
import {
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT
} from '../../../graphql/Mutations'
import {DeletedPostMessage} from '../../components/DeletedPostMessage/DeletedPostMessage'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import {PER_PAGE} from '../../utils/constants'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const mockThreads = {
  id: '432',
  author: {
    name: 'Jeffrey Johnson',
    avatarUrl: 'someURL'
  },
  createdAt: '2021-02-08T13:36:05-07:00',
  message:
    '<p>This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends.</p>',
  read: true,
  lastReply: null,
  rootEntryParticipantCounts: {
    unreadCount: 0,
    repliesCount: 0
  },
  subentriesCount: 0
}

export const DiscussionThreadContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [expandReplies, setExpandReplies] = useState(false)

  const [deleteDiscussionEntry] = useMutation(DELETE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.deleteDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The entry was successfully deleted'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while deleting the entry'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error while deleting the entry'))
    }
  })

  const [toggleUnread] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    onCompleted: data => {
      if (data.updateDiscussionEntryParticipant.discussionEntry.read) {
        setOnSuccess(I18n.t('The entry was successfully marked as read'))
      } else {
        setOnSuccess(I18n.t('The entry was successfully marked as unread'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the entry.'))
    }
  })

  const marginDepth = 4 * props.depth

  const threadActions = []
  if (!props.deleted) {
    threadActions.push(<ThreadingToolbar.Reply key={`reply-${props.id}`} onReply={() => {}} />)
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${props.id}`}
        onClick={() => {}}
        isLiked={props.rating}
        likeCount={props.ratingCount}
      />
    )
  }

  const createdAt = Date.parse(props.createdAt)

  if (props.depth === 0 && props.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.id}`}
        expandText={I18n.t('%{replies} replies, %{unread} unread', {
          replies: props.rootEntryParticipantCounts?.repliesCount,
          unread: props.rootEntryParticipantCounts?.unreadCount
        })}
        onClick={() => setExpandReplies(!expandReplies)}
      />
    )
  }

  const onDelete = () => {
    if (window.confirm(I18n.t('Are you sure you want to delete this entry?'))) {
      deleteDiscussionEntry({
        variables: {
          id: props._id
        }
      })
    }
  }

  const renderPostMessage = () => {
    if (props.deleted) {
      const name = props.editor ? props.editor.name : props.author.name
      return (
        <DeletedPostMessage deleterName={name} timingDisplay={createdAt.toDateString()}>
          <ThreadingToolbar>{threadActions}</ThreadingToolbar>
        </DeletedPostMessage>
      )
    } else {
      return (
        <PostMessage
          authorName={props.author.name}
          avatarUrl={props.author.avatarUrl}
          timingDisplay={createdAt.toDateString()}
          message={props.message}
          isUnread={!props.read}
        >
          <ThreadingToolbar>{threadActions}</ThreadingToolbar>
        </PostMessage>
      )
    }
  }

  return (
    <>
      <div style={{marginLeft: marginDepth + 'rem', paddingLeft: '0.75rem'}}>
        <Flex>
          <Flex.Item shouldShrink shouldGrow>
            {renderPostMessage()}
          </Flex.Item>
          {!props.deleted && (
            <Flex.Item align="stretch">
              <ThreadActions
                id={props.id}
                isUnread={!props.read}
                onToggleUnread={() => {
                  toggleUnread({
                    variables: {
                      discussionEntryId: props._id,
                      read: !props.read
                    }
                  })
                }}
                onDelete={props.permissions.delete ? onDelete : null}
              />
            </Flex.Item>
          )}
        </Flex>
      </div>
      {(expandReplies || props.depth > 0) && props.subentriesCount > 0 && (
        <DiscussionSubentries discussionEntryId={props._id} depth={props.depth + 1} />
      )}
      {expandReplies && props.depth === 0 && props.lastReply && (
        <div
          style={{marginLeft: '4rem'}}
          width="100%"
          key={`discussion-thread-collapse-${props.id}`}
        >
          <View
            background="primary"
            borderWidth="none none small none"
            padding="none none small none"
            display="block"
            width="100%"
            margin="none none medium none"
          >
            <CollapseReplies onClick={() => setExpandReplies(false)} />
          </View>
        </div>
      )}
    </>
  )
}

DiscussionThreadContainer.propTypes = {
  ...DiscussionEntry.shape,
  depth: PropTypes.number
}

DiscussionThreadContainer.defaultProps = {
  depth: 0
}

export default DiscussionThreadContainer

const DiscussionSubentries = props => {
  const {setOnFailure} = useContext(AlertManagerContext)

  const subentries = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables: {
      discussionEntryID: props.discussionEntryId,
      perPage: PER_PAGE
    }
  })

  if (subentries.error) {
    setOnFailure(I18n.t('Error loading replies'))
    return null
  }

  if (subentries.loading) {
    return <LoadingIndicator />
  }

  return subentries.data.legacyNode.discussionSubentriesConnection.nodes.map(entry => (
    <DiscussionThreadContainer
      key={`discussion-thread-${entry.id}`}
      depth={props.depth}
      {...entry}
    />
  ))
}

DiscussionSubentries.propTypes = {
  discussionEntryId: PropTypes.string,
  depth: PropTypes.number
}
