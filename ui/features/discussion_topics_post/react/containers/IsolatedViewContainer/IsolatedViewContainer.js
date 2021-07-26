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

import {addReplyToDiscussion, addReplyToDiscussionEntry, getSpeedGraderUrl} from '../../utils'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CloseButton} from '@instructure/ui-buttons'
import {
  CREATE_DISCUSSION_ENTRY,
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY
} from '../../../graphql/Mutations'
import {Discussion} from '../../../graphql/Discussion'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../../graphql/Queries'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!discussion_topics_post'
import {ISOLATED_VIEW_INITIAL_PAGE_SIZE, PER_PAGE} from '../../utils/constants'
import {IsolatedThreadsContainer} from '../IsolatedThreadsContainer/IsolatedThreadsContainer'
import {IsolatedParent} from './IsolatedParent'
import LoadingIndicator from '@canvas/loading-indicator'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {Tray} from '@instructure/ui-tray'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const IsolatedViewContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const updateCache = (cache, result) => {
    const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry

    addReplyToDiscussion(cache, props.discussionTopic.id)
    addReplyToDiscussionEntry(
      cache,
      ISOLATED_VIEW_INITIAL_PAGE_SIZE,
      newDiscussionEntry,
      window.ENV?.course_id,
      props.relativeEntryId
    )
  }

  const [createDiscussionEntry] = useMutation(CREATE_DISCUSSION_ENTRY, {
    update: updateCache,
    onCompleted: data => {
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))
      props.setHighlightEntryId(data.createDiscussionEntry.discussionEntry.id)
      if (props.discussionEntryId !== data.createDiscussionEntry.discussionEntry.parent.id) {
        props.onOpenIsolatedView(data.createDiscussionEntry.discussionEntry.parent.id, false)
      }
    },
    onError: () =>
      setOnFailure(I18n.t('There was an unexpected error creating the discussion entry.'))
  })

  const [deleteDiscussionEntry] = useMutation(DELETE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.deleteDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The reply was successfully deleted.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
      }
    },
    onError: () => setOnFailure(I18n.t('There was an unexpected error while deleting the reply.'))
  })

  const [updateDiscussionEntry] = useMutation(UPDATE_DISCUSSION_ENTRY, {
    onCompleted: data => {
      if (!data.updateDiscussionEntry.errors) {
        setOnSuccess(I18n.t('The reply was successfully updated.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error while updating the reply.'))
      }
    },
    onError: () => setOnFailure(I18n.t('There was an unexpected error while updating the reply.'))
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

  const toggleRating = discussionEntry => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: discussionEntry._id,
        rating: discussionEntry.rating ? 'not_liked' : 'liked'
      }
    })
  }

  const toggleUnread = discussionEntry => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: discussionEntry._id,
        read: !discussionEntry.read,
        forcedReadState: discussionEntry.read || null
      }
    })
  }

  const markAsRead = discussionEntry => {
    updateDiscussionEntryParticipant({
      variables: {
        discussionEntryId: discussionEntry._id,
        read: true,
        forcedReadState: discussionEntry.read || null
      }
    })
  }

  const onDelete = discussionEntry => {
    // eslint-disable-next-line no-alert
    if (window.confirm(I18n.t('Are you sure you want to delete this entry?'))) {
      deleteDiscussionEntry({
        variables: {
          id: discussionEntry._id
        }
      })
    }
  }

  const onUpdate = (discussionEntry, message) => {
    updateDiscussionEntry({
      variables: {
        discussionEntryId: discussionEntry._id,
        message
      }
    })
  }

  const onOpenInSpeedGrader = discussionEntry => {
    window.open(
      getSpeedGraderUrl(
        window.ENV?.course_id,
        props.discussionTopic.assignment._id,
        discussionEntry.author._id
      ),
      '_blank'
    )
  }

  const onReplySubmit = (message, discussionEntry) => {
    createDiscussionEntry({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        parentEntryId: discussionEntry.rootEntry?.id || discussionEntry.id,
        message
      }
    })
  }

  const isolatedEntryOlderDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables: {
      discussionEntryID: props.discussionEntryId,
      last: ISOLATED_VIEW_INITIAL_PAGE_SIZE,
      sort: 'asc',
      courseID: window.ENV?.course_id,
      relativeEntryId: props.relativeEntryId,
      includeRelativeEntry: !!props.relativeEntryId
    }
  })

  const isolatedEntryNewerDirection = useQuery(DISCUSSION_SUBENTRIES_QUERY, {
    variables: {
      discussionEntryID: props.discussionEntryId,
      first: 0,
      sort: 'asc',
      courseID: window.ENV?.course_id,
      relativeEntryId: props.relativeEntryId,
      includeRelativeEntry: false,
      beforeRelativeEntry: false
    }
  })

  if (isolatedEntryOlderDirection.error) {
    setOnFailure(I18n.t('There was an unexpected error loading the discussion entry.'))
    props.onClose()
    return null
  }

  const fetchOlderEntries = () => {
    isolatedEntryOlderDirection.fetchMore({
      variables: {
        discussionEntryID: props.discussionEntryId,
        last: PER_PAGE,
        before:
          isolatedEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.pageInfo
            .startCursor,
        sort: 'asc',
        courseID: window.ENV?.course_id
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            discussionSubentriesConnection: {
              nodes: [
                ...fetchMoreResult.legacyNode.discussionSubentriesConnection.nodes,
                ...previousResult.legacyNode.discussionSubentriesConnection.nodes
              ],
              pageInfo: fetchMoreResult.legacyNode.discussionSubentriesConnection.pageInfo,
              __typename: 'DiscussionEntryConnection'
            }
          }
        }
      }
    })
  }

  if (isolatedEntryNewerDirection.error) {
    setOnFailure(I18n.t('There was an unexpected error loading the discussion entry.'))
    props.onClose()
    return null
  }

  const fetchNewerEntries = () => {
    isolatedEntryNewerDirection.fetchMore({
      variables: {
        discussionEntryID: props.discussionEntryId,
        first: PER_PAGE,
        after:
          isolatedEntryNewerDirection.data.legacyNode.discussionSubentriesConnection.pageInfo
            .endCursor,
        sort: 'asc',
        courseID: window.ENV?.course_id,
        beforeRelativeEntry: false,
        includeRelativeEntry: false
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        isolatedEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes = [
          ...isolatedEntryOlderDirection.data.legacyNode.discussionSubentriesConnection.nodes,
          ...fetchMoreResult.legacyNode.discussionSubentriesConnection.nodes
        ]
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            discussionSubentriesConnection: {
              nodes: [
                ...previousResult.legacyNode.discussionSubentriesConnection.nodes,
                ...fetchMoreResult.legacyNode.discussionSubentriesConnection.nodes
              ],
              pageInfo: fetchMoreResult.legacyNode.discussionSubentriesConnection.pageInfo,
              __typename: 'DiscussionEntryConnection'
            }
          }
        }
      }
    })
  }

  return (
    <Tray
      data-testid="isolated-view-container"
      open={props.open}
      placement="end"
      size="medium"
      offset="large"
      label="Isolated View"
      shouldCloseOnDocumentClick
      onDismiss={e => {
        // When the RCE is open, it steals the mouse position when using it and we do this trick
        // to avoid the whole Tray getting closed because of a click inside the RCE area.
        if (e.clientY - e.target.offsetTop === 0) {
          return
        }

        if (props.onClose) {
          props.onClose()
        }
      }}
    >
      <Flex>
        <Flex.Item shouldGrow shouldShrink>
          <Heading margin="medium medium medium" theme={{h2FontWeight: 700}}>
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
      {isolatedEntryOlderDirection.loading ? (
        <LoadingIndicator />
      ) : (
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
                padding="none none small none"
                margin="none none x-small none"
              >
                <DiscussionEdit
                  onSubmit={text => {
                    onReplySubmit(text, isolatedEntryOlderDirection.data.legacyNode)
                    props.setRCEOpen(false)
                  }}
                  onCancel={() => props.setRCEOpen(false)}
                  replyPreview={isolatedEntry.data?.legacyNode?.replyPreview}
                />
              </View>
            )}
          </IsolatedParent>
          {!props.RCEOpen && (
            <IsolatedThreadsContainer
              discussionTopic={props.discussionTopic}
              discussionEntry={isolatedEntryOlderDirection.data.legacyNode}
              onToggleRating={toggleRating}
              onToggleUnread={toggleUnread}
              onDelete={onDelete}
              markAsRead={markAsRead}
              onOpenInSpeedGrader={onOpenInSpeedGrader}
              showOlderReplies={fetchOlderEntries}
              showNewerReplies={fetchNewerEntries}
              onOpenIsolatedView={(discussionEntryId, withRCE, highlightEntryId) => {
                props.setHighlightEntryId(highlightEntryId)
                props.onOpenIsolatedView(discussionEntryId, withRCE)
              }}
              goToTopic={props.goToTopic}
              highlightEntryId={props.highlightEntryId}
              hasMoreOlderReplies={
                isolatedEntryOlderDirection.data?.legacyNode?.discussionSubentriesConnection
                  ?.pageInfo?.hasPreviousPage
              }
              hasMoreNewerReplies={
                isolatedEntryNewerDirection.data?.legacyNode?.discussionSubentriesConnection
                  ?.pageInfo?.hasNextPage && !!props.relativeEntryId
              }
            />
          )}
        </>
      )}
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
  setHighlightEntryId: PropTypes.func,
  relativeEntryId: PropTypes.string
}

export default IsolatedViewContainer
