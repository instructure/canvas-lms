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
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {UPDATE_DISCUSSION_ENTRY_PARTICIPANT} from '../../../graphql/Mutations'
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
  const [isRead, setRead] = useState(props.read)

  const [toggleUnread] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }

      // Optimistic change mostly done because of testing. The change will
      //   get reverted if the mutation fails.
      setRead(!isRead)

      if (!isRead) {
        setOnSuccess(I18n.t('The entry was successfully marked as unread.'))
      } else {
        setOnSuccess(I18n.t('The entry was successfully marked as read.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the entry.'))
    }
  })

  const marginDepth = 4 * props.depth

  const threadActions = [
    <ThreadingToolbar.Reply key={`reply-${props.id}`} onReply={() => {}} />,
    <ThreadingToolbar.Like
      key={`like-${props.id}`}
      onClick={() => {}}
      isLiked={props.rating}
      likeCount={props.ratingCount}
    />
  ]

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

  const createdAt = Date.parse(props.createdAt)

  return (
    <>
      <div style={{marginLeft: marginDepth + 'rem'}}>
        <Flex>
          <Flex.Item shouldShrink shouldGrow>
            <PostMessage
              authorName={props.author.name}
              avatarUrl={props.author.avatarUrl}
              timingDisplay={createdAt.toDateString()}
              message={props.message}
              isUnread={!isRead}
            >
              <ThreadingToolbar>{threadActions}</ThreadingToolbar>
            </PostMessage>
          </Flex.Item>
          <Flex.Item align="stretch">
            <ThreadActions
              id={props.id}
              isUnread={!isRead}
              onToggleUnread={() => {
                toggleUnread({
                  variables: {
                    discussionEntryId: props._id,
                    read: !isRead
                  }
                })
              }}
            />
          </Flex.Item>
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

  const PER_PAGE = 25

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
