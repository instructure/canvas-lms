/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
  AUTO_MARK_AS_READ_DELAY,
  SearchContext,
  DiscussionManagerUtilityContext,
} from '../../utils/constants'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import DateHelper from '@canvas/datetime/dateHelper'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  isTopicAuthor,
  updateDiscussionTopicEntryCounts,
  updateDiscussionEntryRootEntryCounts,
  responsiveQuerySizes,
  getDisplayName,
} from '../../utils'
import {DiscussionEntryContainer} from '../DiscussionEntryContainer/DiscussionEntryContainer'
import PropTypes from 'prop-types'
import React, {useContext, useState, useEffect, useCallback} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {ShowMoreRepliesButton} from '../../components/ShowMoreRepliesButton/ShowMoreRepliesButton'
import {Spinner} from '@instructure/ui-spinner'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {
  UPDATE_DISCUSSION_ENTRIES_READ_STATE,
  UPDATE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
} from '../../../graphql/Mutations'
import {useMutation} from 'react-apollo'
import {View} from '@instructure/ui-view'
import {ReportReply} from '../../components/ReportReply/ReportReply'

const I18n = useI18nScope('discussion_topics_post')

export const SplitScreenThreadsContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [discussionEntriesToUpdate, setDiscussionEntriesToUpdate] = useState(new Set())

  const updateCache = (cache, result) => {
    updateDiscussionTopicEntryCounts(cache, props.discussionTopic.id, {
      unreadCountChange: -result?.data?.updateDiscussionEntriesReadState?.discussionEntries?.length,
    })

    // update each root discussionEntry in cache
    result?.data?.updateDiscussionEntriesReadState?.discussionEntries?.forEach(discussionEntry => {
      const discussionEntryOptions = {
        id: btoa('DiscussionEntry-' + discussionEntry._id),
        fragment: DiscussionEntry.fragment,
        fragmentName: 'DiscussionEntry',
      }

      const data = JSON.parse(JSON.stringify(cache.readFragment(discussionEntryOptions)))

      data.entryParticipant.read = discussionEntry.entryParticipant.read

      cache.writeFragment({
        ...discussionEntryOptions,
        data,
      })

      if (discussionEntry.rootEntryId && !discussionEntry.deleted) {
        const discussionUnreadCountChange = discussionEntry.entryParticipant.read ? -1 : 1
        updateDiscussionEntryRootEntryCounts(cache, discussionEntry, discussionUnreadCountChange)
      }
    })
  }

  const [updateDiscussionEntriesReadState] = useMutation(UPDATE_DISCUSSION_ENTRIES_READ_STATE, {
    update: updateCache,
    onCompleted: () => {
      setOnSuccess(I18n.t('The replies were successfully updated'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error while updating the replies'))
    },
  })

  const extractedSubentryNodes = props.discussionEntry.discussionSubentriesConnection?.nodes // extracting to new variable to use in useEffect deps
  useEffect(() => {
    if (discussionEntriesToUpdate.size > 0) {
      const interval = setInterval(() => {
        const entryIds = Array.from(discussionEntriesToUpdate)
        const entries = extractedSubentryNodes.filter(
          entry => entryIds.includes(entry._id) && entry.entryParticipant?.read === false
        )

        entries.forEach(entry => (entry.entryParticipant.read = true))
        setDiscussionEntriesToUpdate(new Set())
        updateDiscussionEntriesReadState({
          variables: {
            discussionEntryIds: entryIds,
            read: true,
          },
          optimisticResponse: {
            updateDiscussionEntriesReadState: {
              discussionEntries: entries,
              __typename: 'UpdateDiscussionEntriesReadStatePayload',
            },
          },
        })
      }, AUTO_MARK_AS_READ_DELAY)

      return () => clearInterval(interval)
    }
  }, [discussionEntriesToUpdate, extractedSubentryNodes, updateDiscussionEntriesReadState])

  const setToBeMarkedAsRead = entryId => {
    if (!discussionEntriesToUpdate.has(entryId)) {
      const entries = Array.from(discussionEntriesToUpdate)
      setDiscussionEntriesToUpdate(new Set([...entries, entryId]))
    }
  }

  return (
    <View data-testid="split-screen-view-children" padding="0 small 0 small">
      {props.hasMoreOlderReplies && (
        <View as="div" padding="0 0 small medium">
          <ShowMoreRepliesButton
            onClick={props.showOlderReplies}
            buttonText={I18n.t('Show older replies')}
            fetchingMoreReplies={props.fetchingMoreOlderReplies}
          />
          {props.fetchingMoreOlderReplies && (
            <Spinner
              renderTitle="loading older replies"
              data-testid="old-reply-spinner"
              size="x-small"
              margin="0 0 0 small"
            />
          )}
        </View>
      )}
      {props.discussionEntry?.discussionSubentriesConnection?.nodes?.map(entry => (
        <SplitScreenThreadContainer
          discussionTopic={props.discussionTopic}
          discussionEntry={entry}
          key={entry.id}
          onToggleRating={props.onToggleRating}
          onToggleUnread={props.onToggleUnread}
          onDelete={props.onDelete}
          onOpenInSpeedGrader={props.onOpenInSpeedGrader}
          onOpenSplitScreenView={props.onOpenSplitScreenView}
          setToBeMarkedAsRead={setToBeMarkedAsRead}
          goToTopic={props.goToTopic}
          isHighlighted={entry._id === props.highlightEntryId}
          moreOptionsButtonRef={props.moreOptionsButtonRef}
        />
      ))}
      {props.hasMoreNewerReplies && (
        <View as="div" padding="0 0 small medium">
          <ShowMoreRepliesButton
            onClick={props.showNewerReplies}
            buttonText={I18n.t('Show newer replies')}
            fetchingMoreReplies={props.fetchingMoreNewerReplies}
          />
          {props.fetchingMoreNewerReplies && (
            <Spinner
              renderTitle="loading newer replies"
              data-testid="new-reply-spinner"
              size="x-small"
              margin="0 0 0 small"
            />
          )}
        </View>
      )}
    </View>
  )
}

SplitScreenThreadsContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: DiscussionEntry.shape,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  showOlderReplies: PropTypes.func,
  showNewerReplies: PropTypes.func,
  onOpenSplitScreenView: PropTypes.func,
  goToTopic: PropTypes.func,
  highlightEntryId: PropTypes.string,
  hasMoreOlderReplies: PropTypes.bool,
  hasMoreNewerReplies: PropTypes.bool,
  fetchingMoreOlderReplies: PropTypes.bool,
  fetchingMoreNewerReplies: PropTypes.bool,
  moreOptionsButtonRef: PropTypes.any,
}

export default SplitScreenThreadsContainer

const SplitScreenThreadContainer = props => {
  const threadActions = []
  const [isEditing, setIsEditing] = useState(false)
  const [showReportModal, setShowReportModal] = useState(false)
  const [reportModalIsLoading, setReportModalIsLoading] = useState(false)
  const [reportingError, setReportingError] = useState(false)

  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {setReplyFromId} = useContext(DiscussionManagerUtilityContext)
  const {filter} = useContext(SearchContext)
  const [threadRefCurrent, setThreadRefCurrent] = useState(null)

  const onThreadRefCurrentSet = useCallback(refCurrent => {
    setThreadRefCurrent(refCurrent)
  }, [])

  // Scrolling auto listener to mark messages as read
  useEffect(() => {
    if (
      !ENV.manual_mark_as_read &&
      !props.discussionEntry.entryParticipant?.read &&
      !props.discussionEntry?.entryParticipant?.forcedReadState
    ) {
      const observer = new IntersectionObserver(
        ([entry]) => entry.isIntersecting && props.setToBeMarkedAsRead(props.discussionEntry._id),
        {
          root: null,
          rootMargin: '0px',
          threshold: 0.4,
        }
      )

      if (threadRefCurrent) observer.observe(threadRefCurrent)

      return () => {
        if (threadRefCurrent) observer.unobserve(threadRefCurrent)
      }
    }
  }, [threadRefCurrent, props.discussionEntry.entryParticipant.read, props, filter])

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
    },
  })

  const [updateDiscussionEntryReported] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      setReportModalIsLoading(false)
      setShowReportModal(false)
      setOnSuccess(I18n.t('You have reported this reply.'), false)
    },
    onError: () => {
      setReportModalIsLoading(false)
      setReportingError(true)
      setTimeout(() => {
        setReportingError(false)
      }, 3000)
    },
  })

  const onUpdate = (message, _quotedEntryId, file) => {
    updateDiscussionEntry({
      variables: {
        discussionEntryId: props.discussionEntry._id,
        message,
        fileId: file?._id,
        removeAttachment: !file?._id,
      },
    })
  }

  if (props?.discussionEntry?.permissions?.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${props.discussionEntry.id}`}
        authorName={getDisplayName(props.discussionEntry)}
        delimiterKey={`reply-delimiter-${props.discussionEntry.id}`}
        onClick={() => props.onOpenSplitScreenView(props.discussionEntry._id, true)}
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
        onClick={() => props.onToggleRating(props.discussionEntry)}
        authorName={getDisplayName(props.discussionEntry)}
        isLiked={!!props.discussionEntry.entryParticipant?.rating}
        likeCount={props.discussionEntry.ratingSum || 0}
        interaction={props.discussionEntry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (props.discussionEntry.subentriesCount) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.discussionEntry.id}`}
        delimiterKey={`expand-delimiter-${props.discussionEntry.id}`}
        authorName={getDisplayName(props.discussionEntry)}
        expandText={I18n.t('View Replies')}
        isExpanded={false}
        onClick={() => props.onOpenSplitScreenView(props.discussionEntry._id, false)}
      />
    )
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          padding: 'x-small',
        },
        desktop: {
          padding: '0 medium',
        },
      }}
      render={responsiveProps => (
        <div ref={onThreadRefCurrentSet}>
          <View as="div" padding={responsiveProps.padding}>
            <Highlight isHighlighted={props.isHighlighted}>
              <Flex padding="small">
                <Flex.Item shouldShrink={true} shouldGrow={true}>
                  <DiscussionEntryContainer
                    discussionTopic={props.discussionTopic}
                    discussionEntry={props.discussionEntry}
                    isTopic={false}
                    postUtilities={
                      <ThreadActions
                        authorName={getDisplayName(props.discussionEntry)}
                        id={props.discussionEntry.id}
                        isUnread={!props.discussionEntry.entryParticipant?.read}
                        onToggleUnread={() => props.onToggleUnread(props.discussionEntry)}
                        onDelete={
                          props.discussionEntry.permissions?.delete
                            ? () => props.onDelete(props.discussionEntry)
                            : null
                        }
                        onEdit={
                          props.discussionEntry.permissions?.update
                            ? () => {
                                setIsEditing(true)
                              }
                            : null
                        }
                        onOpenInSpeedGrader={
                          props.discussionTopic.permissions?.speedGrader
                            ? () => props.onOpenInSpeedGrader(props.discussionEntry)
                            : null
                        }
                        goToParent={() => {
                          props.onOpenSplitScreenView(
                            props.discussionEntry.rootEntryId,
                            false,
                            props.discussionEntry.rootEntryId
                          )
                        }}
                        goToTopic={props.goToTopic}
                        goToQuotedReply={
                          props.discussionEntry.quotedEntry !== null
                            ? () => {
                                props.onOpenSplitScreenView(
                                  props.discussionEntry.rootEntryId,
                                  false,
                                  props.discussionEntry.quotedEntry._id
                                )
                              }
                            : null
                        }
                        onQuoteReply={
                          props?.discussionEntry?.permissions?.reply
                            ? () => {
                                setReplyFromId(props.discussionEntry._id)
                                props.onOpenSplitScreenView(props.discussionEntry._id, true)
                              }
                            : null
                        }
                        onReport={
                          props.discussionTopic.permissions?.studentReporting
                            ? () => {
                                setShowReportModal(true)
                              }
                            : null
                        }
                        isReported={props.discussionEntry?.entryParticipant?.reportType != null}
                        moreOptionsButtonRef={props.moreOptionsButtonRef}
                      />
                    }
                    author={props.discussionEntry.author}
                    anonymousAuthor={props.discussionEntry.anonymousAuthor}
                    message={props.discussionEntry.message}
                    isEditing={isEditing}
                    onSave={onUpdate}
                    onCancel={() => {
                      setIsEditing(false)
                      setTimeout(() => {
                        props.moreOptionsButtonRef?.current?.focus()
                      }, 0)
                    }}
                    isSplitView={true}
                    editor={props.discussionEntry.editor}
                    isUnread={!props.discussionEntry.entryParticipant?.read}
                    isForcedRead={props.discussionEntry.entryParticipant?.forcedReadState}
                    createdAt={props.discussionEntry.createdAt}
                    updatedAt={props.discussionEntry.updatedAt}
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
                    isTopicAuthor={isTopicAuthor(
                      props.discussionTopic.author,
                      props.discussionEntry.author
                    )}
                    quotedEntry={props.discussionEntry.quotedEntry}
                    attachment={props.discussionEntry.attachment}
                  >
                    <View as="div">
                      <ThreadingToolbar discussionEntry={props.discussionEntry} isSplitView={true}>
                        {threadActions}
                      </ThreadingToolbar>
                    </View>
                  </DiscussionEntryContainer>
                  <ReportReply
                    onCloseReportModal={() => {
                      setShowReportModal(false)
                    }}
                    onSubmit={reportType => {
                      updateDiscussionEntryReported({
                        variables: {
                          discussionEntryId: props.discussionEntry._id,
                          reportType,
                        },
                      })
                      setReportModalIsLoading(true)
                    }}
                    showReportModal={showReportModal}
                    isLoading={reportModalIsLoading}
                    errorSubmitting={reportingError}
                  />
                </Flex.Item>
              </Flex>
            </Highlight>
          </View>
        </div>
      )}
    />
  )
}

SplitScreenThreadContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: DiscussionEntry.shape,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  setToBeMarkedAsRead: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onOpenSplitScreenView: PropTypes.func,
  goToTopic: PropTypes.func,
  isHighlighted: PropTypes.bool,
  moreOptionsButtonRef: PropTypes.any,
}
