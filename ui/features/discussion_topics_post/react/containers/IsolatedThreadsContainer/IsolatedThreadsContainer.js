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

import {AUTO_MARK_AS_READ_DELAY} from '../../utils/constants'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import I18n from 'i18n!discussion_topics_post'
import {PostMessageContainer} from '../PostMessageContainer/PostMessageContainer'
import PropTypes from 'prop-types'
import React, {useContext, useState, useEffect, useRef} from 'react'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {ShowOlderRepliesButton} from '../../components/ShowOlderRepliesButton/ShowOlderRepliesButton'
import {
  UPDATE_DISCUSSION_ENTRIES_READ_STATE,
  UPDATE_DISCUSSION_ENTRY
} from '../../../graphql/Mutations'
import {useMutation} from 'react-apollo'
import theme from '@instructure/canvas-theme'

export const IsolatedThreadsContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [discussionEntriesToUpdate, setDiscussionEntriesToUpdate] = useState(new Set())

  const [updateDiscussionEntriesReadState] = useMutation(UPDATE_DISCUSSION_ENTRIES_READ_STATE, {
    onCompleted: () => {
      setOnSuccess(I18n.t('The replies were successfully updated'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error while updating the replies'))
    }
  })

  useEffect(() => {
    if (discussionEntriesToUpdate.size > 0) {
      const interval = setInterval(() => {
        const entryIds = Array.from(discussionEntriesToUpdate)
        const entries = props.discussionEntry.discussionSubentriesConnection.nodes.filter(entry =>
          entryIds.includes(entry._id)
        )
        entries.forEach(entry => (entry.read = true))
        setDiscussionEntriesToUpdate(new Set())
        updateDiscussionEntriesReadState({
          variables: {
            discussionEntryIds: entryIds,
            read: true
          },
          optimisticResponse: {
            updateDiscussionEntriesReadState: {
              discussionEntries: entries,
              __typename: 'UpdateDiscussionEntriesReadStatePayload'
            }
          }
        })
      }, AUTO_MARK_AS_READ_DELAY)

      return () => clearInterval(interval)
    }
  }, [
    discussionEntriesToUpdate,
    props.discussionEntry.discussionSubentriesConnection.nodes,
    updateDiscussionEntriesReadState
  ])

  const setToBeMarkedAsRead = entryId => {
    if (!discussionEntriesToUpdate.has(entryId)) {
      const entries = Array.from(discussionEntriesToUpdate)
      setDiscussionEntriesToUpdate(new Set([...entries, entryId]))
    }
  }

  return (
    <div
      style={{
        marginLeft: '4.25rem',
        paddingRight: theme.variables.spacing.small,
        paddingBottom: theme.variables.spacing.xLarge
      }}
      data-testid="isolated-view-children"
    >
      {props.hasMoreOlderReplies && (
        <div
          style={{
            marginBottom: theme.variables.spacing.medium,
            paddingLeft: theme.variables.spacing.medium
          }}
        >
          <ShowOlderRepliesButton onClick={props.showOlderReplies} />
        </div>
      )}
      {props.discussionEntry.discussionSubentriesConnection.nodes.map(entry => (
        <IsolatedThreadContainer
          discussionTopic={props.discussionTopic}
          discussionEntry={entry}
          key={entry.id}
          onToggleRating={props.onToggleRating}
          onToggleUnread={props.onToggleUnread}
          onDelete={props.onDelete}
          onOpenInSpeedGrader={props.onOpenInSpeedGrader}
          onOpenIsolatedView={props.onOpenIsolatedView}
          setToBeMarkedAsRead={setToBeMarkedAsRead}
          goToTopic={props.goToTopic}
          isHighlighted={entry.id === props.highlightEntryId}
        />
      ))}
    </div>
  )
}

IsolatedThreadsContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: DiscussionEntry.shape,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  showOlderReplies: PropTypes.func,
  onOpenIsolatedView: PropTypes.func,
  goToTopic: PropTypes.func,
  highlightEntryId: PropTypes.string,
  hasMoreOlderReplies: PropTypes.bool
}

export default IsolatedThreadsContainer

const IsolatedThreadContainer = props => {
  const threadActions = []
  const entry = props.discussionEntry

  const [isEditing, setIsEditing] = useState(false)
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const threadRef = useRef()

  // Scrolling auto listener to mark messages as read
  useEffect(() => {
    if (
      !ENV.manual_mark_as_read &&
      !props.discussionEntry.read &&
      !props.discussionEntry?.forcedReadState
    ) {
      const observer = new IntersectionObserver(
        () => props.setToBeMarkedAsRead(props.discussionEntry._id),
        {
          root: null,
          rootMargin: '0px',
          threshold: 0.1
        }
      )

      if (threadRef.current) observer.observe(threadRef.current)

      return () => {
        if (threadRef.current) observer.unobserve(threadRef.current)
      }
    }
  }, [threadRef, props.discussionEntry.read, props])

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
        authorName={entry.author.displayName}
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
        authorName={entry.author.displayName}
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

  return (
    <div ref={threadRef}>
      <Highlight isHighlighted={props.isHighlighted}>
        <Flex>
          <Flex.Item shouldShrink shouldGrow>
            <PostMessageContainer
              discussionEntry={entry}
              threadActions={threadActions}
              isEditing={isEditing}
              isIsolatedView
              padding="small 0 small medium"
              onCancel={() => {
                setIsEditing(false)
              }}
              onSave={onUpdate}
            />
          </Flex.Item>
          {!entry.deleted && (
            <Flex.Item align="stretch" padding="small 0 0 0">
              <ThreadActions
                id={entry.id}
                isUnread={!entry.read}
                onToggleUnread={() => props.onToggleUnread(entry)}
                onDelete={entry.permissions?.delete ? () => props.onDelete(entry) : null}
                onEdit={
                  entry.permissions?.update
                    ? () => {
                        setIsEditing(true)
                      }
                    : null
                }
                onOpenInSpeedGrader={
                  props.discussionTopic.permissions?.speedGrader
                    ? () => props.onOpenInSpeedGrader(entry)
                    : null
                }
                goToParent={() => {
                  props.onOpenIsolatedView(entry.rootEntry.id, false, entry.rootEntry.id)
                }}
                goToTopic={props.goToTopic}
              />
            </Flex.Item>
          )}
        </Flex>
      </Highlight>
    </div>
  )
}

IsolatedThreadContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: DiscussionEntry.shape,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  setToBeMarkedAsRead: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onOpenIsolatedView: PropTypes.func,
  goToTopic: PropTypes.func,
  isHighlighted: PropTypes.bool
}
