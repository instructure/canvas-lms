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
import {Assignment} from '../../../graphql/Assignment'
import {CollapseReplies} from '../../components/CollapseReplies/CollapseReplies'
import DateHelper from '../../../../../shared/datetime/dateHelper'
import {
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY
} from '../../../graphql/Mutations'
import {DeletedPostMessage} from '../../components/DeletedPostMessage/DeletedPostMessage'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
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
import {isGraded, getSpeedGraderUrl} from '../../utils'
import theme from '@instructure/canvas-theme'

export const mockThreads = {
  discussionEntry: {
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
}

export const DiscussionThreadContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [expandReplies, setExpandReplies] = useState(false)
  const [isEditing, setIsEditing] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)

  const [deleteDiscussionEntry] = useMutation(DELETE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.deleteDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The reply was successfully deleted.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
    }
  })

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

  const [updateDiscussionEntryParticipant] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      setOnSuccess(I18n.t('The reply was successfully updated.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the reply.'))
    }
  })

  const toggleRating = () => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: props.discussionEntry._id,
        rating: props.discussionEntry.rating ? 'not_liked' : 'liked'
      }
    })
  }

  const toggleUnread = () => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: props.discussionEntry._id,
        read: !props.discussionEntry.read
      }
    })
  }

  const marginDepth = `calc(${theme.variables.spacing.xxLarge} * ${props.depth})`
  const replyMarginDepth = `calc(${theme.variables.spacing.xxLarge} * ${props.depth + 1})`

  const threadActions = []
  if (!props.discussionEntry.deleted) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${props.discussionEntry.id}`}
        delimiterKey={`reply-delimiter-${props.discussionEntry.id}`}
        onClick={() => {
          setEditorExpanded(!editorExpanded)
        }}
      />
    )
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${props.discussionEntry.id}`}
        delimiterKey={`like-delimiter-${props.discussionEntry.id}`}
        onClick={toggleRating}
        isLiked={props.discussionEntry.rating}
        likeCount={props.discussionEntry.ratingSum || 0}
      />
    )
  }

  const createdAt = DateHelper.formatDatetimeForDiscussions(props.discussionEntry.createdAt)

  if (props.depth === 0 && props.discussionEntry.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.discussionEntry.id}`}
        delimiterKey={`expand-delimiter-${props.discussionEntry.id}`}
        expandText={I18n.t('%{replies} replies, %{unread} unread', {
          replies: props.discussionEntry.rootEntryParticipantCounts?.repliesCount,
          unread: props.discussionEntry.rootEntryParticipantCounts?.unreadCount
        })}
        onClick={() => setExpandReplies(!expandReplies)}
        isExpanded={expandReplies}
      />
    )
  }

  const onDelete = () => {
    // eslint-disable-next-line no-alert
    if (window.confirm(I18n.t('Are you sure you want to delete this entry?'))) {
      deleteDiscussionEntry({
        variables: {
          id: props.discussionEntry._id
        }
      })
    }
  }

  const onUpdate = newMesssage => {
    updateDiscussionEntry({
      variables: {
        discussionEntryId: props.discussionEntry._id,
        message: newMesssage
      }
    })
  }

  const renderPostMessage = () => {
    if (props.discussionEntry.deleted) {
      const name = props.discussionEntry.editor
        ? props.discussionEntry.editor.name
        : props.discussionEntry.author.name
      return (
        <DeletedPostMessage deleterName={name} timingDisplay={createdAt}>
          <ThreadingToolbar>{threadActions}</ThreadingToolbar>
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
          isEditing={isEditing}
          onCancel={() => {
            setIsEditing(false)
          }}
          onSave={onUpdate}
        >
          <ThreadingToolbar>{threadActions}</ThreadingToolbar>
        </PostMessage>
      )
    }
  }

  // TODO: Change this to the new canGrade permission.
  const canGrade =
    (isGraded(props.assignment) && props.discussionEntry.permissions?.update) || false

  return (
    <>
      <div style={{marginLeft: marginDepth, paddingLeft: theme.variables.spacing.small}}>
        <Flex>
          <Flex.Item shouldShrink shouldGrow>
            {renderPostMessage()}
          </Flex.Item>
          {!props.discussionEntry.deleted && (
            <Flex.Item align="stretch">
              <ThreadActions
                id={props.discussionEntry.id}
                isUnread={!props.discussionEntry.read}
                onToggleUnread={toggleUnread}
                onMarkAllAsUnread={() => {}}
                onDelete={props.discussionEntry.permissions?.delete ? onDelete : null}
                onEdit={
                  props.discussionEntry.permissions?.update
                    ? () => {
                        setIsEditing(true)
                      }
                    : null
                }
                onOpenInSpeedGrader={
                  canGrade
                    ? () => {
                        window.location.assign(
                          getSpeedGraderUrl(
                            ENV.course_id,
                            props.assignment._id,
                            props.discussionEntry.author._id
                          )
                        )
                      }
                    : null
                }
              />
            </Flex.Item>
          )}
        </Flex>
      </div>
      <div style={{marginLeft: replyMarginDepth}}>
        {editorExpanded && (
          <View
            display="block"
            background="primary"
            borderWidth="none none small none"
            padding="none none small none"
            margin="none none xSmall none"
          >
            <DiscussionEdit onCancel={() => setEditorExpanded(false)} />
          </View>
        )}
      </div>
      {(expandReplies || props.depth > 0) && props.discussionEntry.subentriesCount > 0 && (
        <DiscussionSubentries
          discussionEntryId={props.discussionEntry._id}
          depth={props.depth + 1}
        />
      )}
      {expandReplies && props.depth === 0 && props.discussionEntry.lastReply && (
        <View
          as="div"
          margin="none none none xx-large"
          width="100%"
          key={`discussion-thread-collapse-${props.discussionEntry.id}`}
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
        </View>
      )}
    </>
  )
}

DiscussionThreadContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape,
  depth: PropTypes.number,
  assignment: Assignment.shape
}

DiscussionThreadContainer.defaultProps = {
  depth: 0,
  assignment: {}
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
    setOnFailure(I18n.t('There was an unexpected error loading the replies.'))
    return null
  }

  if (subentries.loading) {
    return <LoadingIndicator />
  }

  const discussionTopic = subentries.data.legacyNode

  return discussionTopic.discussionSubentriesConnection.nodes.map(entry => (
    <DiscussionThreadContainer
      key={`discussion-thread-${entry.id}`}
      depth={props.depth}
      assignment={discussionTopic?.assignment}
      discussionEntry={entry}
    />
  ))
}

DiscussionSubentries.propTypes = {
  discussionEntryId: PropTypes.string,
  depth: PropTypes.number
}
