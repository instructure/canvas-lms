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

import {
  addReplyToDiscussionEntry,
  getSpeedGraderUrl,
  updateDiscussionTopicRepliesCount
} from '../../utils'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CollapseReplies} from '../../components/CollapseReplies/CollapseReplies'
import {
  CREATE_DISCUSSION_ENTRY,
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY
} from '../../../graphql/Mutations'
import DateHelper from '@canvas/datetime/dateHelper'
import {Discussion} from '../../../graphql/Discussion'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import {PER_PAGE, SearchContext} from '../../utils/constants'
import {PostContainer} from '../PostContainer/PostContainer'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useRef, useState} from 'react'
import {ReplyInfo} from '../../components/ReplyInfo/ReplyInfo'
import theme from '@instructure/canvas-theme'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const mockThreads = {
  discussionEntry: {
    id: '432',
    author: {
      displayName: 'Jeffrey Johnson',
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
    subentriesCount: 0,
    permissions: {
      attach: true,
      create: true,
      delete: true,
      rate: true,
      read: true,
      reply: true,
      update: true,
      viewRating: true
    }
  }
}

export const DiscussionThreadContainer = props => {
  const {searchTerm, sort} = useContext(SearchContext)
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [expandReplies, setExpandReplies] = useState(false)
  const [isEditing, setIsEditing] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)
  const threadRef = useRef()

  const updateCache = (cache, result) => {
    const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
    const variables = {
      discussionEntryID: newDiscussionEntry.parent.id,
      first: PER_PAGE,
      sort,
      courseID: window.ENV?.course_id
    }

    updateDiscussionTopicRepliesCount(cache, props.discussionTopic.id)
    addReplyToDiscussionEntry(cache, variables, newDiscussionEntry)
  }

  const [createDiscussionEntry] = useMutation(CREATE_DISCUSSION_ENTRY, {
    update: updateCache,
    onCompleted: () => {
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error creating the discussion entry.'))
    }
  })

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
        read: !props.discussionEntry.read,
        forcedReadState: props.discussionEntry.read || null
      }
    })
  }

  const marginDepth = `calc(${theme.variables.spacing.xxLarge} * ${props.depth})`
  const replyMarginDepth = `calc(${theme.variables.spacing.xxLarge} * ${props.depth + 1})`

  const threadActions = []
  if (props.discussionEntry.permissions.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${props.discussionEntry.id}`}
        authorName={props.discussionEntry.author.displayName}
        delimiterKey={`reply-delimiter-${props.discussionEntry.id}`}
        onClick={() => {
          const newEditorExpanded = !editorExpanded
          setEditorExpanded(newEditorExpanded)

          if (ENV.isolated_view) {
            props.onOpenIsolatedView(props.discussionEntry._id, true)
          }
        }}
      />
    )
  }
  if (
    props.discussionEntry.permissions.viewRating &&
    (props.discussionEntry.permissions.rate || props.discussionEntry.ratingSum > 0)
  ) {
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${props.discussionEntry.id}`}
        delimiterKey={`like-delimiter-${props.discussionEntry.id}`}
        onClick={toggleRating}
        authorName={props.discussionEntry.author.displayName}
        isLiked={props.discussionEntry.rating}
        likeCount={props.discussionEntry.ratingSum || 0}
        interaction={props.discussionEntry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (props.depth === 0 && props.discussionEntry.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.discussionEntry.id}`}
        delimiterKey={`expand-delimiter-${props.discussionEntry.id}`}
        expandText={
          <ReplyInfo
            replyCount={props.discussionEntry.rootEntryParticipantCounts?.repliesCount}
            unreadCount={props.discussionEntry.rootEntryParticipantCounts?.unreadCount}
          />
        }
        onClick={() => {
          if (ENV.isolated_view) {
            props.onOpenIsolatedView(props.discussionEntry._id, false)
          } else {
            setExpandReplies(!expandReplies)
          }
        }}
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

  const onOpenInSpeedGrader = () => {
    window.open(
      getSpeedGraderUrl(
        ENV.course_id,
        props.discussionTopic.assignment._id,
        props.discussionEntry.author._id
      ),
      '_blank'
    )
  }

  // Scrolling auto listener to mark messages as read
  useEffect(() => {
    if (
      !ENV.manual_mark_as_read &&
      !props.discussionEntry.read &&
      !props.discussionEntry?.forcedReadState
    ) {
      const observer = new IntersectionObserver(() => props.markAsRead(props.discussionEntry._id), {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
      })

      if (threadRef.current) observer.observe(threadRef.current)

      return () => {
        if (threadRef.current) observer.unobserve(threadRef.current)
      }
    }
  }, [threadRef, props.discussionEntry.read, props])

  const onReplySubmit = text => {
    createDiscussionEntry({
      variables: {
        discussionTopicId: ENV.discussion_topic_id,
        parentEntryId: props.discussionEntry._id,
        message: text
      }
    })
    setEditorExpanded(false)
  }

  /**
   * TODO: Implement highlight logic
   */
  const highlightEntry = false

  return (
    <>
      <Highlight isHighlighted={highlightEntry}>
        <div style={{marginLeft: marginDepth}} ref={threadRef}>
          <Flex padding="medium medium small medium">
            <Flex.Item shouldShrink shouldGrow>
              <PostContainer
                isTopic={false}
                postUtilities={
                  !props.discussionEntry.deleted ? (
                    <ThreadActions
                      id={props.discussionEntry.id}
                      isUnread={!props.discussionEntry.read}
                      onToggleUnread={toggleUnread}
                      onDelete={props.discussionEntry.permissions?.delete ? onDelete : null}
                      onEdit={
                        props.discussionEntry.permissions?.update
                          ? () => {
                              setIsEditing(true)
                            }
                          : null
                      }
                      onOpenInSpeedGrader={
                        props.discussionTopic.permissions?.speedGrader ? onOpenInSpeedGrader : null
                      }
                      goToParent={
                        props.depth === 0
                          ? null
                          : () => {
                              const topOffset = props.parentRef.current.offsetTop
                              window.scrollTo(0, topOffset - 44)
                            }
                      }
                      goToTopic={props.goToTopic}
                    />
                  ) : null
                }
                author={props.discussionEntry.author}
                message={props.discussionEntry.message}
                isEditing={isEditing}
                onSave={onUpdate}
                onCancel={() => setIsEditing(false)}
                isIsolatedView={false}
                editor={props.discussionEntry.editor}
                isUnread={!props.discussionEntry.read}
                isForcedRead={props.discussionEntry.forcedReadState}
                timingDisplay={DateHelper.formatDatetimeForDiscussions(
                  props.discussionEntry.createdAt
                )}
                editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
                  props.discussionEntry.updatedAt
                )}
                lastReplyAtDisplay={DateHelper.formatDatetimeForDiscussions(
                  props.discussionEntry.lastReply?.createdAt
                )}
                deleted={props.discussionEntry.deleted}
              >
                {threadActions.length > 0 && (
                  <View as="div" padding="x-small none none">
                    <ThreadingToolbar
                      searchTerm={searchTerm}
                      discussionEntry={props.discussionEntry}
                      onOpenIsolatedView={props.onOpenIsolatedView}
                      isIsolatedView={false}
                    >
                      {threadActions}
                    </ThreadingToolbar>
                  </View>
                )}
              </PostContainer>
            </Flex.Item>
          </Flex>
        </div>
      </Highlight>
      <div style={{marginLeft: replyMarginDepth}}>
        {editorExpanded && !ENV.isolated_view && (
          <View
            display="block"
            background="primary"
            borderWidth="none none small none"
            padding="none none small none"
            margin="none none x-small none"
          >
            <DiscussionEdit
              onSubmit={text => {
                onReplySubmit(text)
              }}
              onCancel={() => setEditorExpanded(false)}
            />
          </View>
        )}
      </div>
      {(expandReplies || props.depth > 0) && props.discussionEntry.subentriesCount > 0 && (
        <DiscussionSubentries
          discussionTopic={props.discussionTopic}
          discussionEntryId={props.discussionEntry._id}
          depth={props.depth + 1}
          markAsRead={props.markAsRead}
          parentRef={threadRef}
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
  discussionTopic: Discussion.shape,
  discussionEntry: PropTypes.object.isRequired,
  depth: PropTypes.number,
  markAsRead: PropTypes.func,
  parentRef: PropTypes.object,
  onOpenIsolatedView: PropTypes.func,
  goToTopic: PropTypes.func
}

DiscussionThreadContainer.defaultProps = {
  depth: 0
}

export default DiscussionThreadContainer

const DiscussionSubentries = props => {
  const {setOnFailure} = useContext(AlertManagerContext)
  const {sort} = useContext(SearchContext)
  const variables = {
    discussionEntryID: props.discussionEntryId,
    first: PER_PAGE,
    sort,
    courseID: window.ENV?.course_id
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

  return subentries.data.legacyNode.discussionSubentriesConnection.nodes.map(entry => (
    <DiscussionThreadContainer
      key={`discussion-thread-${entry.id}`}
      depth={props.depth}
      discussionEntry={entry}
      discussionTopic={props.discussionTopic}
      markAsRead={props.markAsRead}
      parentRef={props.parentRef}
    />
  ))
}

DiscussionSubentries.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntryId: PropTypes.string,
  depth: PropTypes.number,
  markAsRead: PropTypes.func,
  parentRef: PropTypes.object
}
