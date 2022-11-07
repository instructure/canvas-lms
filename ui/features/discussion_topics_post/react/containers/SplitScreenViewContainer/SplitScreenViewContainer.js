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
} from '../../utils'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CloseButton} from '@instructure/ui-buttons'
import {
  CREATE_DISCUSSION_ENTRY,
  CREATE_DISCUSSION_ENTRY_DRAFT,
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
import React, {useCallback, useContext, useEffect, useMemo, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_topics_post')

export const SplitScreenViewContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {replyFromId, setReplyFromId} = useContext(DiscussionManagerUtilityContext)
  const [fetchingMoreOlderReplies, setFetchingMoreOlderReplies] = useState(false)
  const [fetchingMoreNewerReplies, setFetchingMoreNewerReplies] = useState(false)
  const [draftSaved, setDraftSaved] = useState(true)

  const updateCache = (cache, result) => {
    const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
    const variables = {
      discussionEntryID: newDiscussionEntry.rootEntryId,
      last: ENV.isolated_view_initial_page_size,
      sort: 'asc',
      courseID: window.ENV?.course_id,
      includeRelativeEntry: false,
    }

    updateDiscussionTopicEntryCounts(cache, props.discussionTopic.id, {repliesCountChange: 1})
    props.removeDraftFromDiscussionCache(cache, result)
    addReplyToDiscussionEntry(cache, variables, newDiscussionEntry)

    props.setHighlightEntryId(newDiscussionEntry._id)
  }

  const [createDiscussionEntry] = useMutation(CREATE_DISCUSSION_ENTRY, {
    update: updateCache,
    onCompleted: data => {
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))
      props.setHighlightEntryId(data.createDiscussionEntry.discussionEntry._id)
      if (
        props.discussionEntryId !== data.createDiscussionEntry.discussionEntry.rootEntryId ||
        props.relativeEntryId
      ) {
        props.onOpenSplitScreenView(
          data.createDiscussionEntry.discussionEntry.rootEntryId,
          data.createDiscussionEntry.discussionEntry.rootEntryId,
          false
        )
      }
    },
    onError: () =>
      setOnFailure(I18n.t('There was an unexpected error creating the discussion entry.')),
  })

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
      ...(splitScreenEntryOlderDirection.data?.legacyNode.discussionSubentriesConnection.nodes ||
        []),
      ...(splitScreenEntryNewerDirection.data?.legacyNode.discussionSubentriesConnection.nodes ||
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
      updateDiscussionEntryRootEntryCounts(cache, result, discussionUnreadCountChange)
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

  const onUpdate = (discussionEntry, message, fileId) => {
    updateDiscussionEntry({
      variables: {
        discussionEntryId: discussionEntry._id,
        message,
        removeAttachment: !fileId,
      },
    })
  }

  const onOpenInSpeedGrader = discussionEntry => {
    window.open(getSpeedGraderUrl(discussionEntry.author._id), '_blank')
  }

  const onReplySubmit = (message, fileId, includeReplyPreview, replyId, isAnonymousAuthor) => {
    createDiscussionEntry({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        parentEntryId: replyFromId || props.discussionEntryId,
        isAnonymousAuthor,
        message,
        fileId,
        includeReplyPreview,
        courseID: ENV.course_id,
      },
      optimisticResponse: getOptimisticResponse({
        message,
        parentId: replyId,
        rootEntryId: props.discussionEntryId,
        quotedEntry: buildQuotedReply(
          splitScreenEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection.nodes,
          replyFromId
        ),
        isAnonymous:
          !!props.discussionTopic.anonymousState && props.discussionTopic.canReplyAnonymously,
      }),
    })
  }

  const [createDiscussionEntryDraft] = useMutation(CREATE_DISCUSSION_ENTRY_DRAFT, {
    update: props.updateDraftCache,
    onCompleted: () => {
      setOnSuccess('Draft message saved.')
      setDraftSaved(true)
    },
    onError: () => {
      setOnFailure(I18n.t('Unable to save draft message.'))
    },
  })

  const findDraftMessage = rootId => {
    let rootEntryDraftMessage = ''
    props.discussionTopic?.discussionEntryDraftsConnection?.nodes.every(draftEntry => {
      if (
        draftEntry.rootEntryId &&
        draftEntry.rootEntryId === rootId &&
        !draftEntry.discussionEntryId
      ) {
        rootEntryDraftMessage = draftEntry.message
        return false
      }
      return true
    })
    return rootEntryDraftMessage
  }

  const splitScreenEntryOlderDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables: {
      discussionEntryID: props.discussionEntryId,
      last: ENV.isolated_view_initial_page_size,
      sort: 'asc',
      courseID: window.ENV?.course_id,
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
      courseID: window.ENV?.course_id,
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
        courseID: window.ENV?.course_id,
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        setFetchingMoreOlderReplies(false)
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            discussionSubentriesConnection: {
              nodes: [
                ...fetchMoreResult.legacyNode.discussionSubentriesConnection.nodes,
                ...previousResult.legacyNode.discussionSubentriesConnection.nodes,
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
        courseID: window.ENV?.course_id,
        beforeRelativeEntry: false,
        includeRelativeEntry: false,
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        splitScreenEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes = [
          ...splitScreenEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes,
          ...fetchMoreResult.legacyNode.discussionSubentriesConnection.nodes,
        ]
        setFetchingMoreNewerReplies(false)
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            discussionSubentriesConnection: {
              nodes: [
                ...previousResult.legacyNode.discussionSubentriesConnection.nodes,
                ...fetchMoreResult.legacyNode.discussionSubentriesConnection.nodes,
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
        splitScreenEntryOlderDirection.data.legacyNode?.discussionSubentriesConnection.nodes.some(
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
        >
          {props.RCEOpen && (
            <View
              display="block"
              background="primary"
              borderWidth="none none none none"
              padding="none small small"
              margin="none none x-small"
            >
              <DiscussionEdit
                discussionAnonymousState={props.discussionTopic?.anonymousState}
                canReplyAnonymously={props.discussionTopic?.canReplyAnonymously}
                onSubmit={(message, includeReplyPreview, fileId, anonymousAuthorState) => {
                  onReplySubmit(
                    message,
                    fileId,
                    includeReplyPreview,
                    replyFromId,
                    anonymousAuthorState
                  )
                  props.setRCEOpen(false)
                }}
                onCancel={() => props.setRCEOpen(false)}
                quotedEntry={buildQuotedReply(
                  [
                    splitScreenEntryOlderDirection.data.legacyNode,
                    ...splitScreenEntryOlderDirection.data?.legacyNode
                      ?.discussionSubentriesConnection.nodes,
                  ],
                  replyFromId
                )}
                value={findDraftMessage(
                  splitScreenEntryOlderDirection.data.legacyNode.root_entry_id ||
                    splitScreenEntryOlderDirection.data.legacyNode._id
                )}
                onSetDraftSaved={setDraftSaved}
                draftSaved={draftSaved}
                updateDraft={newDraftMessage => {
                  createDiscussionEntryDraft({
                    variables: {
                      discussionTopicId: props.discussionTopic._id,
                      message: newDraftMessage,
                      parentId: replyFromId,
                    },
                  })
                }}
                onInit={() => {
                  // TinyMCE popup menus' z-index should be greater than tray.
                  const menus = document.querySelector('.tox.tox-tinymce-aux')
                  if (menus) {
                    menus.style.zIndex = '10000'
                  }
                }}
              />
            </View>
          )}
        </SplitScreenParent>
        {!props.RCEOpen && (
          <View as="div" borderWidth="small none none none" padding="medium none none">
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
              onOpenSplitScreenView={(
                discussionEntryId,
                rootEntryId,
                withRCE,
                highlightEntryId
              ) => {
                props.setHighlightEntryId(highlightEntryId)
                props.onOpenSplitScreenView(discussionEntryId, rootEntryId, withRCE)
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
              updateDraftCache={props.updateDraftCache}
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
          <Heading margin="medium medium none" theme={{h2FontWeight: 700}}>
            Thread
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            margin="small auto none"
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            data-testid="splitscreen-container-close-button"
            onClick={() => {
              if (props.onClose) {
                props.onClose()
              }
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
  removeDraftFromDiscussionCache: PropTypes.func,
  updateDraftCache: PropTypes.func,
}

export default SplitScreenViewContainer
