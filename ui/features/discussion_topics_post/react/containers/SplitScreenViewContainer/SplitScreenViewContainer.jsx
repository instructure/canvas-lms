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
  updateDiscussionTopicEntryCounts,
  updateDiscussionEntryRootEntryCounts,
  addReplyToDiscussionEntry,
  getSpeedGraderUrl,
  getOptimisticResponse,
  buildQuotedReply,
  getDisplayName,
} from '../../utils'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CloseButton} from '@instructure/ui-buttons'
import {
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY,
} from '../../../graphql/Mutations'
import {Discussion} from '../../../graphql/Discussion'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import GenericErrorPage from '@canvas/generic-error-page'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {SplitScreenThreadsContainer} from '../SplitScreenThreadsContainer/SplitScreenThreadsContainer'
import {SplitScreenParent} from './SplitScreenParent'
import LoadingIndicator from '@canvas/loading-indicator'
import PropTypes from 'prop-types'
import React, {useCallback, useContext, useEffect, useMemo, useRef, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'
import * as ReactDOMServer from 'react-dom/server'
import useCreateDiscussionEntry from '../../hooks/useCreateDiscussionEntry'

const I18n = useI18nScope('discussion_topics_post')

export const SplitScreenViewContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {replyFromId, setReplyFromId} = useContext(DiscussionManagerUtilityContext)
  const [fetchingMoreOlderReplies, setFetchingMoreOlderReplies] = useState(false)
  const [fetchingMoreNewerReplies, setFetchingMoreNewerReplies] = useState(false)
  const closeButtonRef = useRef()

  const replyButtonRef = useRef()
  const moreOptionsButtonRef = useRef()

  const updateCache = (cache, result) => {
    const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
    const variables = {
      discussionEntryID: newDiscussionEntry.parentId,
      last: ENV.split_screen_view_initial_page_size,
      sort: 'asc',
      includeRelativeEntry: false,
    }

    updateDiscussionTopicEntryCounts(cache, props.discussionTopic.id, {repliesCountChange: 1})
    addReplyToDiscussionEntry(cache, variables, newDiscussionEntry)

    props.setHighlightEntryId(newDiscussionEntry._id)
  }

  const onEntryCreationCompletion = data => {
    props.setHighlightEntryId(data.createDiscussionEntry.discussionEntry._id)
    if (splitScreenEntryOlderDirection.data.legacyNode.depth > 3) {
      props.onOpenSplitScreenView(data.createDiscussionEntry.discussionEntry.rootEntryId, false)
    } else if (splitScreenEntryOlderDirection.data.legacyNode.depth === 3) {
      props.onOpenSplitScreenView(data.createDiscussionEntry.discussionEntry.parentId, false)
    }
  }

  const {createDiscussionEntry} = useCreateDiscussionEntry(onEntryCreationCompletion, updateCache)

  const [deleteDiscussionEntry] = useMutation(DELETE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.deleteDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The reply was successfully deleted.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
      }
    },
    onError: () => setOnFailure(I18n.t('There was an unexpected error while deleting the reply.')),
  })

  const [updateDiscussionEntry] = useMutation(UPDATE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.updateDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The reply was successfully updated.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while updating the reply.'))
      }
    },
    onError: () => setOnFailure(I18n.t('There was an unexpected error while updating the reply.')),
  })

  const updateDiscussionEntryParticipantCache = (cache, result) => {
    const entry = [
      ...(splitScreenEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection?.nodes ||
        []),
      ...(splitScreenEntryNewerDirection.data?.legacyNode?.discussionSubentriesConnection?.nodes ||
        []),
    ].find(
      oldEntry => oldEntry._id === result.data.updateDiscussionEntryParticipant.discussionEntry._id
    )
    if (
      entry &&
      entry.entryParticipant?.read !==
        result.data.updateDiscussionEntryParticipant.discussionEntry.entryParticipant?.read
    ) {
      const discussionUnreadCountChange = result.data.updateDiscussionEntryParticipant
        .discussionEntry.entryParticipant?.read
        ? -1
        : 1
      updateDiscussionTopicEntryCounts(cache, props.discussionTopic.id, {
        unreadCountChange: discussionUnreadCountChange,
      })
      updateDiscussionEntryRootEntryCounts(
        cache,
        result.data.updateDiscussionEntryParticipant.discussionEntry,
        discussionUnreadCountChange
      )
    }
  }

  const [updateDiscussionEntryParticipant] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    update: updateDiscussionEntryParticipantCache,
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      setOnSuccess(I18n.t('The reply was successfully updated.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the reply.'))
    },
  })

  const toggleRating = discussionEntry => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: discussionEntry._id,
        rating: discussionEntry.entryParticipants?.rating ? 'not_liked' : 'liked',
      },
    })
  }

  const toggleUnread = discussionEntry => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: discussionEntry._id,
        read: !discussionEntry.entryParticipant?.read,
        forcedReadState: discussionEntry.entryParticipant?.read || null,
      },
    })
  }

  const onDelete = discussionEntry => {
    // eslint-disable-next-line no-alert
    if (window.confirm(I18n.t('Are you sure you want to delete this entry?'))) {
      deleteDiscussionEntry({
        variables: {
          id: discussionEntry._id,
        },
      })
    }
  }

  const onUpdate = (discussionEntry, message, file) => {
    updateDiscussionEntry({
      variables: {
        discussionEntryId: discussionEntry._id,
        message,
        fileId: file?._id,
        removeAttachment: !file?._id,
      },
    })
  }

  const onOpenInSpeedGrader = discussionEntry => {
    window.open(getSpeedGraderUrl(discussionEntry.author._id), '_blank')
  }

  // This reply method is used for the split-screen reply
  const onReplySubmit = (message, file, quotedEntryId, isAnonymousAuthor) => {
    // In this case. The parentEntry is the Entry that was clicked to start the reply
    const parentEntryDepth = splitScreenEntryOlderDirection.data.legacyNode.depth
    const parentId = splitScreenEntryOlderDirection.data.legacyNode._id
    const parentIdOfParentEntry = splitScreenEntryOlderDirection.data?.legacyNode?.parentId
    const rootTopicReplyId = splitScreenEntryOlderDirection.data?.legacyNode?.rootEntryId

    // We are support 3 different cases
    // 1. Normally a parent id will just be the id of the entry that was clicked to start the reply
    // 2. When the entry that was clicked is at a nested depth of 3, then the parent id will be the parent of the parent
    // 3. When the entry that was clicked is nested at a depth larger than 3, then the parent id will be the root entry id
    const createdEntryParentId =
      parentEntryDepth === 3
        ? parentIdOfParentEntry
        : parentEntryDepth > 3
        ? rootTopicReplyId
        : parentId
    const variables = {
      discussionTopicId: props.discussionTopic._id,
      parentEntryId: createdEntryParentId,
      isAnonymousAuthor,
      message,
      fileId: file?._id,
      quotedEntryId,
    }
    const optimisticResponse = getOptimisticResponse({
      message,
      attachment: file,
      parentId: createdEntryParentId,
      rootEntryId: rootTopicReplyId,
      quotedEntry: buildQuotedReply(
        splitScreenEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection?.nodes,
        replyFromId
      ),
      isAnonymous:
        !!props.discussionTopic.anonymousState && props.discussionTopic.canReplyAnonymously,
    })
    createDiscussionEntry({variables, optimisticResponse})
    props.setHighlightEntryId('DISCUSSION_ENTRY_PLACEHOLDER')
  }

  const getRCEStartingValue = () => {
    // Check if mentions in discussions are enabled
    if (!ENV.rce_mentions_in_discussions) {
      return ''
    }
    const mentionsValue =
      splitScreenEntryOlderDirection.data.legacyNode.depth >= 3
        ? ReactDOMServer.renderToString(
            <span
              className="mceNonEditable mention"
              data-mention={splitScreenEntryOlderDirection?.data?.legacyNode.author?._id}
            >
              @{getDisplayName(splitScreenEntryOlderDirection.data.legacyNode)}
            </span>
          )
        : ''

    return mentionsValue
  }

  const splitScreenEntryOlderDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables: {
      discussionEntryID: props.discussionEntryId,
      last: ENV.split_screen_view_initial_page_size,
      sort: 'asc',
      ...(props.relativeEntryId &&
        props.relativeEntryId !== props.discussionEntryId && {
          relativeEntryId: props.relativeEntryId,
        }),
      includeRelativeEntry: !!props.relativeEntryId,
    },
  })

  const splitScreenEntryNewerDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    skip: !props.relativeEntryId,
    variables: {
      discussionEntryID: props.discussionEntryId,
      first: 0,
      sort: 'asc',
      ...(props.relativeEntryId && {relativeEntryId: props.relativeEntryId}),
      includeRelativeEntry: false,
      beforeRelativeEntry: false,
    },
  })

  const fetchOlderEntries = () => {
    splitScreenEntryOlderDirection.fetchMore({
      variables: {
        discussionEntryID: props.discussionEntryId,
        last: ENV.per_page,
        before:
          splitScreenEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.pageInfo
            .startCursor,
        sort: 'asc',
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        setFetchingMoreOlderReplies(false)
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            discussionSubentriesConnection: {
              nodes: [
                ...fetchMoreResult.legacyNode.discussionSubentriesConnection?.nodes,
                ...previousResult.legacyNode.discussionSubentriesConnection?.nodes,
              ],
              pageInfo: fetchMoreResult.legacyNode.discussionSubentriesConnection.pageInfo,
              __typename: 'DiscussionEntryConnection',
            },
          },
        }
      },
    })
  }

  const fetchNewerEntries = () => {
    splitScreenEntryNewerDirection.fetchMore({
      variables: {
        discussionEntryID: props.discussionEntryId,
        first: ENV.per_page,
        after:
          splitScreenEntryNewerDirection.data.legacyNode.discussionSubentriesConnection.pageInfo
            .endCursor,
        sort: 'asc',
        beforeRelativeEntry: false,
        includeRelativeEntry: false,
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        splitScreenEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes = [
          ...splitScreenEntryOlderDirection.data.legacyNode.discussionSubentriesConnection?.nodes,
          ...fetchMoreResult.legacyNode.discussionSubentriesConnection?.nodes,
        ]
        setFetchingMoreNewerReplies(false)
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            discussionSubentriesConnection: {
              nodes: [
                ...previousResult.legacyNode.discussionSubentriesConnection?.nodes,
                ...fetchMoreResult.legacyNode.discussionSubentriesConnection?.nodes,
              ],
              pageInfo: fetchMoreResult.legacyNode.discussionSubentriesConnection.pageInfo,
              __typename: 'DiscussionEntryConnection',
            },
          },
        }
      },
    })
  }

  const entriesAreLoading = useCallback(() => {
    return splitScreenEntryOlderDirection.loading || splitScreenEntryNewerDirection.loading
  }, [splitScreenEntryNewerDirection.loading, splitScreenEntryOlderDirection.loading])

  const entriesLoadingError = useCallback(() => {
    return splitScreenEntryOlderDirection?.error || splitScreenEntryNewerDirection?.error
  }, [splitScreenEntryNewerDirection.error, splitScreenEntryOlderDirection.error])

  const contentIsReady = useMemo(() => {
    return !(entriesAreLoading() || entriesLoadingError())
  }, [entriesAreLoading, entriesLoadingError])

  const renderErrorOrLoading = useMemo(() => {
    if (entriesAreLoading()) {
      return <LoadingIndicator />
    } else {
      return (
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorSubject={I18n.t('Splitscreen Entry query error')}
          errorCategory={I18n.t('Splitscreen Entry Post Error Page')}
        />
      )
    }
  }, [entriesAreLoading])

  const hasMoreOlderReplies =
    splitScreenEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection?.pageInfo
      ?.hasPreviousPage

  useEffect(() => {
    if (
      props.highlightEntryId &&
      props.highlightEntryId !== props.discussionEntryId &&
      !fetchingMoreOlderReplies
    ) {
      const isOnSubentries =
        splitScreenEntryOlderDirection.data.legacyNode?.discussionSubentriesConnection?.nodes.some(
          entry => entry._id === props.highlightEntryId
        )

      if (!isOnSubentries && hasMoreOlderReplies) {
        setFetchingMoreOlderReplies(true)
        fetchOlderEntries()
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.highlightEntryId, props.discussionEntryId])

  useEffect(() => {
    if (!props.RCEOpen) setReplyFromId(null)
  }, [props.RCEOpen, setReplyFromId])

  useEffect(() => {
    closeButtonRef?.current?.focus()
  }, [props.discussionEntryId])

  const renderSplitScreenView = () => {
    return (
      <>
        <SplitScreenParent
          discussionTopic={props.discussionTopic}
          discussionEntry={splitScreenEntryOlderDirection.data.legacyNode}
          onToggleUnread={() => toggleUnread(splitScreenEntryOlderDirection.data.legacyNode)}
          onDelete={() => onDelete(splitScreenEntryOlderDirection.data.legacyNode)}
          onOpenInSpeedGrader={() =>
            onOpenInSpeedGrader(splitScreenEntryOlderDirection.data.legacyNode)
          }
          onToggleRating={() => toggleRating(splitScreenEntryOlderDirection.data.legacyNode)}
          onSave={onUpdate}
          onOpenSplitScreenView={props.onOpenSplitScreenView}
          setRCEOpen={props.setRCEOpen}
          RCEOpen={props.RCEOpen}
          goToTopic={props.goToTopic}
          isHighlighted={props.highlightEntryId === props.discussionEntryId}
          replyButtonRef={replyButtonRef}
          moreOptionsButtonRef={moreOptionsButtonRef}
        >
          {props.RCEOpen && props.isTrayFinishedOpening && (
            <View
              display="block"
              background="primary"
              borderWidth="none none none none"
              padding="none small small"
              margin="none none x-small"
            >
              <DiscussionEdit
                rceIdentifier={props.discussionEntryId}
                discussionAnonymousState={props.discussionTopic?.anonymousState}
                canReplyAnonymously={props.discussionTopic?.canReplyAnonymously}
                onSubmit={(message, quotedEntryId, file, anonymousAuthorState) => {
                  onReplySubmit(message, file, quotedEntryId, anonymousAuthorState)
                  props.setRCEOpen(false)
                }}
                onCancel={() => {
                  props.setRCEOpen(false)
                  setTimeout(() => {
                    replyButtonRef?.current?.focus()
                  }, 0)
                }}
                quotedEntry={buildQuotedReply(
                  [
                    splitScreenEntryOlderDirection.data.legacyNode,
                    ...splitScreenEntryOlderDirection.data?.legacyNode
                      ?.discussionSubentriesConnection?.nodes,
                  ].filter(item => item),
                  replyFromId
                )}
                value={getRCEStartingValue()}
                onInit={() => {
                  // TinyMCE popup menus' z-index should be greater than tray.
                  const menus = document.querySelector('.tox.tox-tinymce-aux')
                  if (menus) {
                    menus.style.zIndex = '10000'
                  }
                }}
                isAnnouncement={props.discussionTopic.isAnnouncement}
              />
            </View>
          )}
        </SplitScreenParent>
        {!props.RCEOpen && (
          <View as="div" borderWidth="small none none none">
            <SplitScreenThreadsContainer
              discussionTopic={props.discussionTopic}
              discussionEntry={splitScreenEntryOlderDirection.data.legacyNode}
              onToggleRating={toggleRating}
              onToggleUnread={toggleUnread}
              onDelete={onDelete}
              onOpenInSpeedGrader={onOpenInSpeedGrader}
              showOlderReplies={() => {
                setFetchingMoreOlderReplies(true)
                fetchOlderEntries()
              }}
              showNewerReplies={() => {
                setFetchingMoreNewerReplies(true)
                fetchNewerEntries()
              }}
              onOpenSplitScreenView={(discussionEntryId, withRCE, highlightEntryId) => {
                props.setHighlightEntryId(highlightEntryId)
                props.onOpenSplitScreenView(discussionEntryId, withRCE)
              }}
              goToTopic={props.goToTopic}
              highlightEntryId={props.highlightEntryId}
              hasMoreOlderReplies={hasMoreOlderReplies}
              hasMoreNewerReplies={
                splitScreenEntryNewerDirection.data?.legacyNode?.discussionSubentriesConnection
                  ?.pageInfo?.hasNextPage && !!props.relativeEntryId
              }
              fetchingMoreOlderReplies={fetchingMoreOlderReplies}
              fetchingMoreNewerReplies={fetchingMoreNewerReplies}
              moreOptionsButtonRef={moreOptionsButtonRef}
            />
          </View>
        )}
      </>
    )
  }

  return (
    <span
      className="discussions-split-screen-view-content"
      data-testid="discussions-split-screen-view-content"
    >
      <Flex>
        <Flex.Item width="480px" shouldGrow={true} shouldShrink={true}>
          <Heading margin="medium medium none" themeOverride={{h2FontWeight: 700}}>
            {I18n.t('Thread')}
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            size="medium"
            margin="small auto none"
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            data-testid="splitscreen-container-close-button"
            onClick={() => {
              if (props.setRCEOpen) {
                props.setRCEOpen(false)
              }
              if (props.onClose) {
                props.onClose()
              }
            }}
            elementRef={el => {
              closeButtonRef.current = el
            }}
          />
        </Flex.Item>
      </Flex>
      {contentIsReady ? renderSplitScreenView() : renderErrorOrLoading}
    </span>
  )
}

SplitScreenViewContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntryId: PropTypes.string,
  onClose: PropTypes.func,
  RCEOpen: PropTypes.bool,
  setRCEOpen: PropTypes.func,
  onOpenSplitScreenView: PropTypes.func,
  goToTopic: PropTypes.func,
  highlightEntryId: PropTypes.string,
  setHighlightEntryId: PropTypes.func,
  relativeEntryId: PropTypes.string,
  isTrayFinishedOpening: PropTypes.bool,
}

export default SplitScreenViewContainer
