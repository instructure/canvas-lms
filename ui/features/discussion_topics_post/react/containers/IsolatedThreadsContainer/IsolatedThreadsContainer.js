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
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import I18n from 'i18n!discussion_topics_post'
import {PostMessageContainer} from '../PostMessageContainer/PostMessageContainer'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {ShowOlderRepliesButton} from '../../components/ShowOlderRepliesButton/ShowOlderRepliesButton'
import {UPDATE_DISCUSSION_ENTRY} from '../../../graphql/Mutations'
import {useMutation} from 'react-apollo'

export const IsolatedThreadsContainer = props => {
  /**
   * We need the sort function, because we want the subEntries to return in desc (created_at) order,
   * thus newest to oldest.
   * But when we want to render the entries, we want them displayed {oldest to newest} => {top to bottom}.
   */
  const sortReverseDisplay = (a, b) => {
    return new Date(a.createdAt) - new Date(b.createdAt)
  }

  const subentriesCount = props.discussionEntry.subentriesCount
  const actualSubentriesCount = props.discussionEntry.discussionSubentriesConnection.nodes.length
  const hasMoreReplies = actualSubentriesCount < subentriesCount

  return (
    <div
      style={{
        marginLeft: `6.0rem`,
        paddingRight: '0.75rem'
      }}
      data-testid="isolated-view-children"
    >
      {hasMoreReplies && (
        <div
          style={{
            marginBottom: `1.5rem`
          }}
        >
          <ShowOlderRepliesButton onClick={props.showOlderReplies} />
        </div>
      )}
      {props.discussionEntry.discussionSubentriesConnection.nodes
        .sort(sortReverseDisplay)
        .map(entry => (
          <IsolatedThreadContainer
            discussionEntry={entry}
            key={entry.id}
            onToggleRating={props.onToggleRating}
            onToggleUnread={props.onToggleUnread}
            onDelete={props.onDelete}
            onOpenInSpeedGrader={props.onOpenInSpeedGrader}
            onOpenIsolatedView={props.onOpenIsolatedView}
            highlightParent={props.highlightParent}
          />
        ))}
    </div>
  )
}

IsolatedThreadsContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  showOlderReplies: PropTypes.func,
  onOpenIsolatedView: PropTypes.func,
  highlightParent: PropTypes.func
}

export default IsolatedThreadsContainer

const IsolatedThreadContainer = props => {
  const threadActions = []
  const entry = props.discussionEntry

  const [isEditing, setIsEditing] = useState(false)
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [updateDiscussionEntry] = useMutation(UPDATE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.updateDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The reply was successfully updated.'))
        setIsEditing(false)
      } else {
        setOnFailure(I18n.t('There was an unexpected error while updating the reply.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error while updating the reply.'))
    }
  })

  const onUpdate = newMesssage => {
    updateDiscussionEntry({
      variables: {
        discussionEntryId: entry._id,
        message: newMesssage
      }
    })
  }

  if (entry.permissions.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${entry.id}`}
        authorName={entry.author.name}
        delimiterKey={`reply-delimiter-${entry.id}`}
        onClick={() => props.onOpenIsolatedView(entry.id, true)}
      />
    )
  }
  if (entry.permissions.viewRating && (entry.permissions.rate || entry.ratingSum > 0)) {
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${entry.id}`}
        delimiterKey={`like-delimiter-${entry.id}`}
        onClick={() => props.onToggleRating(props.discussionEntry)}
        authorName={entry.author.name}
        isLiked={entry.rating}
        likeCount={entry.ratingSum || 0}
        interaction={entry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (entry.subentriesCount) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${entry.id}`}
        delimiterKey={`expand-delimiter-${entry.id}`}
        expandText={I18n.t('View Replies')}
        isExpanded={false}
        onClick={() => props.onOpenIsolatedView(entry.id, false)}
      />
    )
  }

  /**
   * TODO: Implement highlight logic
   */
  const highlightEntry = false

  return (
    <Highlight isHighlighted={highlightEntry}>
      <Flex>
        <Flex.Item shouldShrink shouldGrow>
          <PostMessageContainer
            discussionEntry={entry}
            threadActions={threadActions}
            isEditing={isEditing}
            onCancel={() => {
              setIsEditing(false)
            }}
            onSave={onUpdate}
          />
        </Flex.Item>
        {!entry.deleted && (
          <Flex.Item align="stretch">
            <ThreadActions
              id={entry.id}
              isUnread={!DiscussionEntry.read}
              onToggleUnread={() => props.onToggleUnread(props.discussionEntry)}
              onDelete={() => props.onDelete(props.discussionEntry)}
              onEdit={
                entry.permissions?.update
                  ? () => {
                      setIsEditing(true)
                    }
                  : null
              }
              onOpenInSpeedGrader={() => props.onOpenInSpeedGrader(props.discussionEntry)}
              goToParent={() => {
                if (entry?.parent?.id === entry?.rootEntry?.id) {
                  // Something else is trying to scroll this and with this timeout we give it a moment and then we execute our scroll.
                  setTimeout(() => {
                    document.querySelector('span[data-cid="Transition"]').scrollTo(0, 0)
                  }, 0)
                } else {
                  props.onOpenIsolatedView(entry.rootEntry.id, false)
                }

                props.highlightParent()
              }}
              goToTopic={() => {}}
            />
          </Flex.Item>
        )}
      </Flex>
    </Highlight>
  )
}

IsolatedThreadContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onOpenIsolatedView: PropTypes.func,
  highlightParent: PropTypes.func
}
