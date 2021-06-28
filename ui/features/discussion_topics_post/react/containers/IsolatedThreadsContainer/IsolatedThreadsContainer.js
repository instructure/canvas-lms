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
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {Flex} from '@instructure/ui-flex'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import {PostMessageContainer} from '../PostMessageContainer/PostMessageContainer'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {useQuery} from 'react-apollo'

export const IsolatedThreadsContainer = props => {
  const courseID = window.ENV?.course_id !== null ? parseInt(window.ENV?.course_id, 10) : -1
  const {setOnFailure} = useContext(AlertManagerContext)

  const variables = {
    discussionEntryID: props.discussionEntryId,
    perPage: 5,
    sort: 'desc',
    courseID
  }
  const subentries = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables
  })

  if (subentries.error) {
    setOnFailure(I18n.t('There was an unexpected error loading the replies.'))
    return null
  }

  if (subentries.loading) {
    return <LoadingIndicator />
  }

  /**
   * We need the sort function, because we want the subEntries to return in desc (created_at) order,
   * thus newest to oldest.
   * But when we want to render the entries, we want them displayed {oldest to newest} => {top to bottom}.
   */
  const sortReverseDisplay = (a, b) => {
    return new Date(a.createdAt) - new Date(b.createdAt)
  }

  return (
    <div
      style={{
        marginLeft: `6.0rem`,
        paddingRight: '0.75rem'
      }}
    >
      {
        // TODO: Conditionally render "show more replies" button
      }
      {subentries.data.legacyNode.discussionSubentriesConnection.nodes
        .sort(sortReverseDisplay)
        .map(entry => (
          <IsolatedThreadContainer discussionEntry={entry} key={`discussion-thread-${entry.id}`} />
        ))}
    </div>
  )
}

IsolatedThreadsContainer.propTypes = {
  discussionEntryId: PropTypes.string
}
IsolatedThreadsContainer.defaultProps = {}

export default IsolatedThreadsContainer

const IsolatedThreadContainer = props => {
  const threadActions = []
  const entry = props.discussionEntry

  if (entry.permissions.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${entry.id}`}
        authorName={entry.author.name}
        delimiterKey={`reply-delimiter-${entry.id}`}
        onClick={() => {}}
      />
    )
  }
  if (entry.permissions.viewRating && (entry.permissions.rate || entry.ratingSum > 0)) {
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${entry.id}`}
        delimiterKey={`like-delimiter-${entry.id}`}
        onClick={() => {}}
        authorName={entry.author.name}
        isLiked={entry.rating}
        likeCount={entry.ratingSum || 0}
        interaction={entry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (entry.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${entry.id}`}
        delimiterKey={`expand-delimiter-${entry.id}`}
        expandText={I18n.t(
          {
            one: '%{count} reply, %{unread} unread',
            other: '%{count} replies, %{unread} unread'
          },
          {
            count: entry.rootEntryParticipantCounts?.repliesCount || 0,
            unread: entry.rootEntryParticipantCounts?.unreadCount || 0
          }
        )}
        isReadOnly
        isExpanded={false}
        onClick={() => {}}
      />
    )
  }

  return (
    <div>
      <Flex>
        <Flex.Item shouldShrink shouldGrow>
          <PostMessageContainer discussionEntry={entry} threadActions={threadActions} />
        </Flex.Item>
        {!entry.deleted && (
          <Flex.Item align="stretch">
            <ThreadActions
              id={entry.id}
              isUnread={!DiscussionEntry.read}
              onToggleUnread={() => {}}
              onDelete={() => {}}
              onEdit={() => {}}
              onOpenInSpeedGrader={() => {}}
              goToParent={() => {}}
              goToTopic={() => {}}
            />
          </Flex.Item>
        )}
      </Flex>
    </div>
  )
}

IsolatedThreadContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape
}
