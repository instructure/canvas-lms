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
  updateDiscussionTopicEntryCounts,
  updateDiscussionEntryRootEntryCounts,
  addReplyToDiscussionEntry,
  getSpeedGraderUrl,
  getOptimisticResponse,
  buildQuotedReply,
} from '../../utils'
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
import {IsolatedThreadsContainer} from '../IsolatedThreadsContainer/IsolatedThreadsContainer'
import {IsolatedParent} from './IsolatedParent'
import LoadingIndicator from '@canvas/loading-indicator'
import PropTypes from 'prop-types'
import React, {useCallback, useContext, useEffect, useMemo, useState} from 'react'
import {Tray} from '@instructure/ui-tray'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_topics_post')

export const IsolatedViewContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
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
        props.onOpenIsolatedView(
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
      ...(isolatedEntryOlderDirection.data?.legacyNode.discussionSubentriesConnection.nodes || []),
      ...(isolatedEntryNewerDirection.data?.legacyNode.discussionSubentriesConnection.nodes || []),
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
        parentEntryId: replyId,
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
          isolatedEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection.nodes,
          props.replyFromId
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

  const isolatedEntryOlderDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
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

  const isolatedEntryNewerDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
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
    isolatedEntryOlderDirection.fetchMore({
      variables: {
        discussionEntryID: props.discussionEntryId,
        last: ENV.per_page,
        before:
          isolatedEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.pageInfo
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
    isolatedEntryNewerDirection.fetchMore({
      variables: {
        discussionEntryID: props.discussionEntryId,
        first: ENV.per_page,
        after:
          isolatedEntryNewerDirection.data.legacyNode.discussionSubentriesConnection.pageInfo
            .endCursor,
        sort: 'asc',
        courseID: window.ENV?.course_id,
        beforeRelativeEntry: false,
        includeRelativeEntry: false,
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        isolatedEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes = [
          ...isolatedEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes,
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
    return isolatedEntryOlderDirection.loading || isolatedEntryNewerDirection.loading
  }, [isolatedEntryNewerDirection.loading, isolatedEntryOlderDirection.loading])

  const entriesLoadingError = useCallback(() => {
    return isolatedEntryOlderDirection?.error || isolatedEntryNewerDirection?.error
  }, [isolatedEntryNewerDirection.error, isolatedEntryOlderDirection.error])

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
          errorSubject={I18n.t('Isolated Entry query error')}
          errorCategory={I18n.t('Isolated Entry Post Error Page')}
        />
      )
    }
  }, [entriesAreLoading])

  const hasMoreOlderReplies =
    isolatedEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection?.pageInfo
      ?.hasPreviousPage

  useEffect(() => {
    if (
      props.highlightEntryId &&
      props.highlightEntryId !== props.discussionEntryId &&
      !fetchingMoreOlderReplies
    ) {
      const isOnSubentries =
        isolatedEntryOlderDirection.data.legacyNode?.discussionSubentriesConnection.nodes.some(
          entry => entry._id === props.highlightEntryId
        )

      if (!isOnSubentries && hasMoreOlderReplies) {
        setFetchingMoreOlderReplies(true)
        fetchOlderEntries()
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.highlightEntryId, props.discussionEntryId])

  const renderIsolatedView = () => {
    return (
      <>
        <IsolatedParent
          discussionTopic={props.discussionTopic}
          discussionEntry={isolatedEntryOlderDirection.data.legacyNode}
          onToggleUnread={() => toggleUnread(isolatedEntryOlderDirection.data.legacyNode)}
          onDelete={() => onDelete(isolatedEntryOlderDirection.data.legacyNode)}
          onOpenInSpeedGrader={() =>
            onOpenInSpeedGrader(isolatedEntryOlderDirection.data.legacyNode)
          }
          onToggleRating={() => toggleRating(isolatedEntryOlderDirection.data.legacyNode)}
          onSave={onUpdate}
          onOpenIsolatedView={props.onOpenIsolatedView}
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
                rceIdentifier={props.replyFromId}
                discussionAnonymousState={props.discussionTopic?.anonymousState}
                canReplyAnonymously={props.discussionTopic?.canReplyAnonymously}
                onSubmit={(message, includeReplyPreview, fileId, anonymousAuthorState) => {
                  onReplySubmit(
                    message,
                    fileId,
                    includeReplyPreview,
                    props.replyFromId,
                    anonymousAuthorState
                  )
                  props.setRCEOpen(false)
                }}
                onCancel={() => props.setRCEOpen(false)}
                quotedEntry={buildQuotedReply(
                  isolatedEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection
                    .nodes,
                  props.replyFromId
                )}
                value={findDraftMessage(
                  isolatedEntryOlderDirection.data.legacyNode.root_entry_id ||
                    isolatedEntryOlderDirection.data.legacyNode._id
                )}
                onSetDraftSaved={setDraftSaved}
                draftSaved={draftSaved}
                updateDraft={newDraftMessage => {
                  createDiscussionEntryDraft({
                    variables: {
                      discussionTopicId: props.discussionTopic._id,
                      message: newDraftMessage,
                      parentId: props.replyFromId,
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
        </IsolatedParent>
        {!props.RCEOpen && (
          <View as="div" borderWidth="small none none none" padding="medium none none">
            <IsolatedThreadsContainer
              discussionTopic={props.discussionTopic}
              discussionEntry={isolatedEntryOlderDirection.data.legacyNode}
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
              onOpenIsolatedView={(discussionEntryId, rootEntryId, withRCE, highlightEntryId) => {
                props.setHighlightEntryId(highlightEntryId)
                props.onOpenIsolatedView(discussionEntryId, rootEntryId, withRCE)
              }}
              goToTopic={props.goToTopic}
              highlightEntryId={props.highlightEntryId}
              hasMoreOlderReplies={hasMoreOlderReplies}
              hasMoreNewerReplies={
                isolatedEntryNewerDirection.data?.legacyNode?.discussionSubentriesConnection
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
    <Tray
      data-testid="isolated-view-container"
      open={props.open}
      placement="end"
      size="medium"
      offset="large"
      label="Isolated View"
      shouldCloseOnDocumentClick={true}
      onDismiss={e => {
        // When the RCE is open, it steals the mouse position when using it and we do this trick
        // to avoid the whole Tray getting closed because of a click inside the RCE area.
        if (e.clientY - e.target.offsetTop === 0) {
          return
        }

        // don't close if the user clicks on a modal presented over the Tray
        if (e.target.closest('.ui-dialog')) {
          return
        }

        if (props.onClose) {
          props.onClose()
        }
      }}
    >
      <span className="discussions-isolated-view-content">
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading margin="medium medium none" theme={{h2FontWeight: 700}}>
              Thread
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={() => {
                if (props.onClose) {
                  props.onClose()
                }
              }}
            />
          </Flex.Item>
        </Flex>
        {contentIsReady ? renderIsolatedView() : renderErrorOrLoading}
      </span>
    </Tray>
  )
}

IsolatedViewContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntryId: PropTypes.string,
  open: PropTypes.bool,
  onClose: PropTypes.func,
  RCEOpen: PropTypes.bool,
  setRCEOpen: PropTypes.func,
  onOpenIsolatedView: PropTypes.func,
  goToTopic: PropTypes.func,
  highlightEntryId: PropTypes.string,
  replyFromId: PropTypes.string,
  setHighlightEntryId: PropTypes.func,
  relativeEntryId: PropTypes.string,
  removeDraftFromDiscussionCache: PropTypes.func,
  updateDraftCache: PropTypes.func,
}

export default IsolatedViewContainer
