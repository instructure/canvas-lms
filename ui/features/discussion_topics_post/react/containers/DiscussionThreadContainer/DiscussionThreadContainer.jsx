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
  updateDiscussionEntryRootEntryCounts,
  updateDiscussionTopicEntryCounts,
  responsiveQuerySizes,
  isTopicAuthor,
  getDisplayName,
  getOptimisticResponse,
  buildQuotedReply,
  addReplyToAllRootEntries,
  addSubentriesCountToParentEntry,
} from '../../utils'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_THREAD_READ_STATE,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY,
} from '../../../graphql/Mutations'
import DateHelper from '@canvas/datetime/dateHelper'
import {Discussion} from '../../../graphql/Discussion'
import {DISCUSSION_ENTRY_ALL_ROOT_ENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {
  SearchContext,
  DiscussionManagerUtilityContext,
  AllThreadsState,
} from '../../utils/constants'
import {DiscussionEntryContainer} from '../DiscussionEntryContainer/DiscussionEntryContainer'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState, useCallback, useRef, useMemo} from 'react'
import * as ReactDOMServer from 'react-dom/server'
import {ReplyInfo} from '../../components/ReplyInfo/ReplyInfo'
import {Responsive} from '@instructure/ui-responsive'

import theme from '@instructure/canvas-theme'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {useMutation, useQuery, useApolloClient} from 'react-apollo'
import {View} from '@instructure/ui-view'
import {ReportReply} from '../../components/ReportReply/ReportReply'
import {Text} from '@instructure/ui-text'
import useCreateDiscussionEntry from '../../hooks/useCreateDiscussionEntry'

const I18n = useI18nScope('discussion_topics_post')

const defaultExpandedReplies = id => {
  if (ENV.DISCUSSION?.preferences?.discussions_splitscreen_view) return false
  if (id === ENV.discussions_deep_link?.entry_id) return false
  if (id === ENV.discussions_deep_link?.root_entry_id) return true

  return false
}

export const DiscussionThreadContainer = props => {
  const replyButtonRef = useRef()
  const expansionButtonRef = useRef()
  const moreOptionsButtonRef = useRef()

  const {searchTerm, filter, allThreadsStatus, expandedThreads, setExpandedThreads} =
    useContext(SearchContext)
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {replyFromId, setReplyFromId, usedThreadingToolbarChildRef} = useContext(DiscussionManagerUtilityContext)
  const [expandReplies, setExpandReplies] = useState(
    defaultExpandedReplies(props.discussionEntry._id)
  )
  const [isEditing, setIsEditing] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)
  const [threadRefCurrent, setThreadRefCurrent] = useState(null)
  const [showReportModal, setShowReportModal] = useState(false)
  const [reportModalIsLoading, setReportModalIsLoading] = useState(false)
  const [reportingError, setReportingError] = useState(false)
  const [firstSubReply, setFirstSubReply] = useState(false)

  const updateLoadedSubentry = updatedEntry => {
    // if it's a subentry then we need to update the loadedSubentry.
    if (props.setLoadedSubentries) {
      props.setLoadedSubentries(loadedSubentries => {
        return loadedSubentries.map(entry =>
          !!updatedEntry.rootEntryId && entry.id === updatedEntry.id ? updatedEntry : entry
        )
      })
    }
  }

  const updateDiscussionEntryParticipantCache = (cache, result) => {
    if (
      props.discussionEntry.entryParticipant?.read !==
      result.data.updateDiscussionEntryParticipant.discussionEntry.entryParticipant?.read
    ) {
      const discussionUnreadCountChange = result.data.updateDiscussionEntryParticipant
        .discussionEntry.entryParticipant?.read
        ? -1
        : 1
      updateDiscussionTopicEntryCounts(cache, props.discussionTopic.id, {
        unreadCountChange: discussionUnreadCountChange,
      })

      if (result.data.updateDiscussionEntryParticipant.discussionEntry.rootEntryId) {
        updateDiscussionEntryRootEntryCounts(
          cache,
          result.data.updateDiscussionEntryParticipant.discussionEntry,
          discussionUnreadCountChange
        )
      }
    }
  }

  const updateCache = (cache, result) => {
    const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
    const variables = {
      discussionEntryID: newDiscussionEntry.parentId,
      first: ENV.per_page,
      sort: 'asc',
    }

    updateDiscussionTopicEntryCounts(cache, props.discussionTopic.id, {repliesCountChange: 1})
    const foundParentEntryQuery = addReplyToDiscussionEntry(cache, variables, newDiscussionEntry)
    if (props.refetchDiscussionEntries && !foundParentEntryQuery) props.refetchDiscussionEntries()
    addReplyToAllRootEntries(cache, newDiscussionEntry)
    addSubentriesCountToParentEntry(cache, newDiscussionEntry)
    props.setHighlightEntryId(newDiscussionEntry._id)

    // It is a known issue that the first reply of a sub reply has not initiated the sub query call,
    // as a result we cannot add an entry to it. Before we had expand buttons for each sub-entry,
    // now we must manually trigger the first one.
    // See addReplyToDiscussionEntry definition for more details.
    if (
      result.data.createDiscussionEntry.discussionEntry.parentId === props.discussionEntry._id &&
      !props.discussionEntry.subentriesCount
    ) {
      setFirstSubReply(true)
    }
  }

  const onEntryCreationCompletion = data => {
    setExpandReplies(true)
    props.setHighlightEntryId(data.createDiscussionEntry.discussionEntry._id)
  }

  const {createDiscussionEntry} = useCreateDiscussionEntry(onEntryCreationCompletion, updateCache)

  const [deleteDiscussionEntry] = useMutation(DELETE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.deleteDiscussionEntry.errors) {
        updateLoadedSubentry(data.deleteDiscussionEntry.discussionEntry)
        setOnSuccess(I18n.t('The reply was successfully deleted.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
    },
  })

  const [updateDiscussionEntry] = useMutation(UPDATE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.updateDiscussionEntry.errors) {
        updateLoadedSubentry(data.updateDiscussionEntry.discussionEntry)
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

  const [updateDiscussionEntryParticipant] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    update: updateDiscussionEntryParticipantCache,
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      updateLoadedSubentry(data.updateDiscussionEntryParticipant.discussionEntry)
      setOnSuccess(I18n.t('The reply was successfully updated.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the reply.'))
    },
  })

  const [updateDiscussionEntryReported] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      updateLoadedSubentry(data.updateDiscussionEntryParticipant.discussionEntry)
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

  const toggleRating = () => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: props.discussionEntry._id,
        rating: props.discussionEntry.entryParticipant?.rating ? 'not_liked' : 'liked',
      },
    })
  }

  const toggleUnread = () => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: props.discussionEntry._id,
        read: !props.discussionEntry.entryParticipant?.read,
        forcedReadState: true,
      },
    })
  }

  const getReplyLeftMargin = responsiveProp => {
    // If the entry is in threadMode, then we want the RCE to be aligned with the authorInfo
    const threadMode = props.discussionEntry?.depth > 1
    if (responsiveProp.padding === undefined || responsiveProp.padding === null || !threadMode) {
      return `calc(${theme.variables.spacing.xxLarge} * ${props.depth + 1})`
    }
    // This assumes that the responsive prop is using the css short hand for padding with 3 variables to get the left padding value
    const responsiveLeftPadding = responsiveProp.padding.split(' ')[1] || ''
    // The flex component uses the notation xx-small but the canvas theme saves the value as xxSmall
    const camelCaseResponsiveLeftPadding = responsiveLeftPadding.replace(/-(.)/g, (_, nextLetter) =>
      nextLetter.toUpperCase()
    )
    // Retrieve the css value based on the canvas theme variable
    const discussionEditLeftPadding = theme.variables.spacing[camelCaseResponsiveLeftPadding] || '0'

    // This assumes that the discussionEntryContainer left padding is small
    const discussionEntryContainerLeftPadding = theme.variables.spacing.small || '0'

    return `calc(${theme.variables.spacing.xxLarge} * ${props.depth} + ${discussionEntryContainerLeftPadding} + ${discussionEditLeftPadding})`
  }

  const client = useApolloClient()
  const resetDiscussionCache = () => {
    client.resetStore()
  }

  const [updateDiscussionThreadReadState] = useMutation(UPDATE_DISCUSSION_THREAD_READ_STATE, {
    update: resetDiscussionCache,
  })

  // Condense SplitScreen to one variable & link with the SplitScreenButton
  const splitScreenOn = props.userSplitScreenPreference

  const threadActions = []
  if (props?.discussionEntry?.permissions?.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        replyButtonRef={replyButtonRef}
        key={`reply-${props.discussionEntry._id}`}
        authorName={getDisplayName(props.discussionEntry)}
        delimiterKey={`reply-delimiter-${props.discussionEntry._id}`}
        onClick={() => {
          const newEditorExpanded = !editorExpanded
          setEditorExpanded(newEditorExpanded)

          if (splitScreenOn) {
            usedThreadingToolbarChildRef.current = replyButtonRef.current
            props.onOpenSplitView(props.discussionEntry._id, true)
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
        key={`like-${props.discussionEntry._id}`}
        delimiterKey={`like-delimiter-${props.discussionEntry._id}`}
        onClick={toggleRating}
        authorName={getDisplayName(props.discussionEntry)}
        isLiked={!!props.discussionEntry.entryParticipant?.rating}
        likeCount={props.discussionEntry.ratingSum || 0}
        interaction={props.discussionEntry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (props.depth === 0 && props.discussionEntry.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        expansionButtonRef={expansionButtonRef}
        key={`expand-${props.discussionEntry._id}`}
        delimiterKey={`expand-delimiter-${props.discussionEntry._id}`}
        authorName={getDisplayName(props.discussionEntry)}
        expandText={
          <ReplyInfo
            replyCount={props.discussionEntry.rootEntryParticipantCounts?.repliesCount}
            unreadCount={props.discussionEntry.rootEntryParticipantCounts?.unreadCount}
          />
        }
        onClick={() => {
          if (splitScreenOn) {
            usedThreadingToolbarChildRef.current = expansionButtonRef.current
            props.onOpenSplitView(props.discussionEntry._id, false)
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
          id: props.discussionEntry._id,
        },
      })
    }
  }

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

  const onOpenInSpeedGrader = () => {
    window.open(getSpeedGraderUrl(props.discussionEntry.author._id), '_blank')
  }

  // Scrolling auto listener to mark messages as read
  const onThreadRefCurrentSet = useCallback(refCurrent => {
    setThreadRefCurrent(refCurrent)
  }, [])

  const updateReadState = discussionEntry => {
    props.markAsRead(discussionEntry._id)
    // manually update this entry's read state, then updateLoadedSubentry
    discussionEntry.entryParticipant.read = !discussionEntry.entryParticipant?.read
    updateLoadedSubentry(discussionEntry)
  }

  useEffect(() => {
    if (
      !ENV.manual_mark_as_read &&
      !props.discussionEntry.entryParticipant?.read &&
      !props.discussionEntry?.entryParticipant?.forcedReadState
    ) {
      const observer = new IntersectionObserver(
        ([entry]) => entry.isIntersecting && updateReadState(props.discussionEntry),
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
  }, [threadRefCurrent, props.discussionEntry.entryParticipant.read, props])

  useEffect(() => {
    if (allThreadsStatus === AllThreadsState.Expanded && !expandReplies) {
      setExpandReplies(true)
    }
    if (allThreadsStatus === AllThreadsState.Collapsed && expandReplies) {
      setExpandReplies(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [allThreadsStatus])

  useEffect(() => {
    if (expandReplies && !expandedThreads.includes(props.discussionEntry._id)) {
      setExpandedThreads([...expandedThreads, props.discussionEntry._id])
    } else if (!expandReplies && expandedThreads.includes(props.discussionEntry._id)) {
      setExpandedThreads(expandedThreads.filter(v => v !== props.discussionEntry._id))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [expandReplies])

  // This reply is used with inline-view reply
  const onReplySubmit = (message, quotedEntryId, isAnonymousAuthor, file) => {
    const getParentId = () => {
      switch (props.discussionEntry.depth) {
        case 1:
          return props.discussionEntry._id
        case 2:
          return props.discussionEntry._id
        case 3:
          return props.discussionEntry.parentId
        default:
          return props.discussionEntry.rootEntryId
      }
    }
    const variables = {
      discussionTopicId: ENV.discussion_topic_id,
      parentEntryId: getParentId(),
      fileId: file?._id,
      isAnonymousAuthor,
      message,
      quotedEntryId,
    }
    const optimisticResponse = getOptimisticResponse({
      message,
      attachment: file,
      parentId: getParentId(),
      depth: props.discussionEntry.depth,
      rootEntryId: props.discussionEntry.rootEntryId,
      quotedEntry:
        quotedEntryId && typeof buildQuotedReply === 'function'
          ? buildQuotedReply([props.discussionEntry], getParentId())
          : null,
      isAnonymous:
        !!props.discussionTopic.anonymousState && props.discussionTopic.canReplyAnonymously,
    })
    createDiscussionEntry({variables, optimisticResponse})

    props.setHighlightEntryId('DISCUSSION_ENTRY_PLACEHOLDER')
    setEditorExpanded(false)
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        // If you change the padding notation on these, please update the getReplyLeftMargin function
        mobile: {
          marginDepth: `calc(${theme.variables.spacing.medium} * ${props.depth})`,
          padding: 'small xx-small small',
          toolbarLeftPadding: undefined,
        },
        desktop: {
          marginDepth: `calc(${theme.variables.spacing.xxLarge} * ${props.depth})`,
          padding: 'small medium small',
          toolbarLeftPadding: props.depth === 0 ? '0 0 0 xx-small' : undefined,
        },
      }}
      render={responsiveProps => (
        <>
          <Highlight isHighlighted={props.discussionEntry._id === props.highlightEntryId}>
            <div style={{marginLeft: responsiveProps.marginDepth}} ref={onThreadRefCurrentSet}>
              <Flex padding={responsiveProps.padding}>
                <Flex.Item shouldShrink={true} shouldGrow={true}>
                  <DiscussionEntryContainer
                    discussionTopic={props.discussionTopic}
                    discussionEntry={props.discussionEntry}
                    isTopic={false}
                    postUtilities={
                      !props.discussionEntry.deleted ? (
                        <ThreadActions
                          moreOptionsButtonRef={moreOptionsButtonRef}
                          id={props.discussionEntry._id}
                          authorName={getDisplayName(props.discussionEntry)}
                          isUnread={!props.discussionEntry.entryParticipant?.read}
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
                            props.discussionTopic.permissions?.speedGrader
                              ? onOpenInSpeedGrader
                              : null
                          }
                          goToParent={
                            props.depth === 0
                              ? null
                              : () => {
                                  props.setHighlightEntryId(props.discussionEntry.parentId)
                                }
                          }
                          goToTopic={props.goToTopic}
                          onReport={
                            props.discussionTopic.permissions?.studentReporting
                              ? () => {
                                  setShowReportModal(true)
                                }
                              : null
                          }
                          isReported={props.discussionEntry?.entryParticipant?.reportType != null}
                          onQuoteReply={
                            props?.discussionEntry?.permissions?.reply
                              ? () => {
                                  setReplyFromId(props.discussionEntry._id)
                                  if (splitScreenOn) {
                                    props.onOpenSplitView(props.discussionEntry._id, true)
                                  } else {
                                    setEditorExpanded(true)
                                  }
                                }
                              : null
                          }
                          onMarkThreadAsRead={readState =>
                            updateDiscussionThreadReadState({
                              variables: {
                                discussionEntryId: props.discussionEntry.rootEntryId
                                  ? props.discussionEntry.rootEntryId
                                  : props.discussionEntry.id,
                                read: readState,
                              },
                            })
                          }
                        />
                      ) : null
                    }
                    author={props.discussionEntry.author}
                    anonymousAuthor={props.discussionEntry.anonymousAuthor}
                    message={props.discussionEntry.message}
                    isEditing={isEditing}
                    onSave={onUpdate}
                    onCancel={() => {
                      setIsEditing(false)
                      setTimeout(() => {
                        moreOptionsButtonRef?.current?.focus()
                      }, 0)
                    }}
                    isSplitView={false}
                    editor={props.discussionEntry.editor}
                    isUnread={
                      !props.discussionEntry.entryParticipant?.read ||
                      !!props.discussionEntry?.rootEntryParticipantCounts?.unreadCount
                    }
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
                    attachment={props.discussionEntry.attachment}
                    quotedEntry={props.discussionEntry.quotedEntry}
                  >
                    {threadActions.length > 0 && (
                      <View as="div" padding={responsiveProps.toolbarLeftPadding}>
                        <ThreadingToolbar
                          searchTerm={searchTerm}
                          discussionEntry={props.discussionEntry}
                          onOpenSplitView={props.onOpenSplitView}
                          isSplitView={false}
                          filter={filter}
                        >
                          {threadActions}
                        </ThreadingToolbar>
                      </View>
                    )}
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
            </div>
          </Highlight>
          <div style={{marginLeft: getReplyLeftMargin(responsiveProps)}}>
            {editorExpanded && !splitScreenOn && (
              <View
                display="block"
                background="primary"
                padding="none none small none"
                margin="none none x-small none"
              >
                <DiscussionEdit
                  rceIdentifier={props.discussionEntry._id}
                  discussionAnonymousState={props.discussionTopic?.anonymousState}
                  canReplyAnonymously={props.discussionTopic?.canReplyAnonymously}
                  onSubmit={(message, quotedEntryId, file, anonymousAuthorState) => {
                    onReplySubmit(message, quotedEntryId, anonymousAuthorState, file)
                  }}
                  onCancel={() => {
                    setEditorExpanded(false)
                    setTimeout(() => {
                      replyButtonRef?.current?.focus()
                    }, 0)
                  }}
                  quotedEntry={buildQuotedReply([props.discussionEntry], replyFromId)}
                  value={
                    !!ENV.rce_mentions_in_discussions && props.discussionEntry.depth > 2
                      ? ReactDOMServer.renderToString(
                          <span
                            className="mceNonEditable mention"
                            data-mention={props.discussionEntry.author?._id}
                          >
                            @{getDisplayName(props.discussionEntry)}
                          </span>
                        )
                      : ''
                  }
                  isAnnouncement={props.discussionTopic.isAnnouncement}
                />
              </View>
            )}
          </div>
          {((expandReplies && !searchTerm) || props.depth > 0 || firstSubReply) &&
            !splitScreenOn &&
            (props.discussionEntry.subentriesCount > 0 || firstSubReply) && (
              <DiscussionSubentries
                discussionTopic={props.discussionTopic}
                discussionEntryId={props.discussionEntry._id}
                depth={props.depth + 1}
                markAsRead={props.markAsRead}
                parentRefCurrent={threadRefCurrent}
                highlightEntryId={props.highlightEntryId}
                setHighlightEntryId={props.setHighlightEntryId}
                allRootEntries={props.allRootEntries}
              />
            )}
        </>
      )}
    />
  )
}

DiscussionThreadContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: PropTypes.object.isRequired,
  refetchDiscussionEntries: PropTypes.func,
  depth: PropTypes.number,
  markAsRead: PropTypes.func,
  onOpenSplitView: PropTypes.func,
  goToTopic: PropTypes.func,
  highlightEntryId: PropTypes.string,
  setHighlightEntryId: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  allRootEntries: PropTypes.array,
  setLoadedSubentries: PropTypes.func,
}

DiscussionThreadContainer.defaultProps = {
  depth: 0,
}

export default DiscussionThreadContainer

const DiscussionSubentries = props => {
  const {setOnFailure} = useContext(AlertManagerContext)
  const [loadedSubentries, setLoadedSubentries] = useState([])

  const variables = {
    discussionEntryID: props.discussionEntryId,
  }

  const query = useQuery(DISCUSSION_ENTRY_ALL_ROOT_ENTRIES_QUERY, {
    variables,
    skip: props.allRootEntries && Array.isArray(props.allRootEntries),
  })

  const allRootEntries = props.allRootEntries || query?.data?.legacyNode?.allRootEntries || []
  const subentries = allRootEntries.filter(entry => entry.parentId === props.discussionEntryId)
  const subentriesIds = subentries.map(entry => entry._id).join('')

  useEffect(() => {
    const loadedSubentriesIds = loadedSubentries.map(entry => entry._id).join('')

    // this means on all update mutations (including delete) we need to manually update loadedSubentries
    if (subentries.length > 0 && subentriesIds !== loadedSubentriesIds) {
      if (loadedSubentries.length < subentries.length) {
        setTimeout(() => {
          setLoadedSubentries(previousloadedSubentries =>
            previousloadedSubentries.concat(
              subentries.slice(loadedSubentries.length, loadedSubentries.length + 10)
            )
          )
        }, 500)
      } else {
        // There is a mismatch of IDs, so we need to reset the loadedSubentries
        setLoadedSubentries(subentries)
      }
    }
  }, [subentries, loadedSubentries, subentriesIds])

  if (query.error) {
    setOnFailure(I18n.t('There was an unexpected error loading the replies.'))
    return null
  }

  const isLoading = query.loading || loadedSubentries.length < subentries.length

  return (
    <>
      {loadedSubentries.map(entry => (
        <DiscussionSubentriesMemo
          key={`discussion-thread-${entry._id}`}
          depth={props.depth}
          discussionEntry={entry}
          discussionTopic={props.discussionTopic}
          markAsRead={props.markAsRead}
          parentRefCurrent={props.parentRefCurrent}
          highlightEntryId={props.highlightEntryId}
          setHighlightEntryId={props.setHighlightEntryId}
          allRootEntries={allRootEntries}
          setLoadedSubentries={setLoadedSubentries}
        />
      ))}
      <LoadingReplies isLoading={isLoading} />
    </>
  )
}

DiscussionSubentries.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntryId: PropTypes.string,
  depth: PropTypes.number,
  markAsRead: PropTypes.func,
  parentRefCurrent: PropTypes.object,
  highlightEntryId: PropTypes.string,
  setHighlightEntryId: PropTypes.func,
  allRootEntries: PropTypes.array,
}

const DiscussionSubentriesMemo = props => {
  return useMemo(() => {
    return (
      <DiscussionThreadContainer
        depth={props.depth}
        discussionEntry={props.discussionEntry}
        discussionTopic={props.discussionTopic}
        markAsRead={props.markAsRead}
        parentRefCurrent={props.parentRefCurrent}
        highlightEntryId={props.highlightEntryId}
        setHighlightEntryId={props.setHighlightEntryId}
        allRootEntries={props.allRootEntries}
        setLoadedSubentries={props.setLoadedSubentries}
      />
    )
  }, [
    props.depth,
    props.discussionEntry,
    props.discussionTopic,
    props.markAsRead,
    props.parentRefCurrent,
    props.highlightEntryId,
    props.setHighlightEntryId,
    props.allRootEntries,
    props.setLoadedSubentries,
  ])
}

DiscussionSubentries.propTypes = {
  discussionTopic: Discussion.shape,
  depth: PropTypes.number,
  markAsRead: PropTypes.func,
  parentRefCurrent: PropTypes.object,
  highlightEntryId: PropTypes.string,
  setHighlightEntryId: PropTypes.func,
  allRootEntries: PropTypes.array,
}

const LoadingReplies = props => {
  return useMemo(() => {
    return (
      props.isLoading && (
        <Flex justifyItems="start" margin="0 large" padding="0 x-large">
          <Flex.Item>
            <Spinner renderTitle={I18n.t('Loading more replies')} size="x-small" />
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <Text>{I18n.t('Loading replies...')}</Text>
          </Flex.Item>
        </Flex>
      )
    )
  }, [props.isLoading])
}

LoadingReplies.propTypes = {
  isLoading: PropTypes.bool,
}
