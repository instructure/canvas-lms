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
import {Conversation} from '../../../graphql/Conversation'
import {ConversationContext} from '../../../util/constants'
import {CONVERSATION_MESSAGES_QUERY, SUBMISSION_COMMENTS_QUERY} from '../../../graphql/Queries'
import {DELETE_CONVERSATION_MESSAGES} from '../../../graphql/Mutations'
import {useScope as useI18nScope} from '@canvas/i18n'
import {MessageDetailHeader} from '../../components/MessageDetailHeader/MessageDetailHeader'
import {MessageDetailItem} from '../../components/MessageDetailItem/MessageDetailItem'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState, useMemo, useCallback} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'
import {inboxMessagesWrapper} from '../../../util/utils'

const I18n = useI18nScope('conversations_2')

export const MessageDetailContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {setMessageOpenEvent, messageOpenEvent, isSubmissionCommentsType} =
    useContext(ConversationContext)
  const [messageRef, setMessageRef] = useState()
  const variables = {
    conversationID: props.conversation._id,
  }
  const [isLoadingMoreData, setIsLoadingMoreData] = useState(false)

  const [lastMessageItem, setLastMessageItem] = useState(null)

  const onItemRefSet = useCallback(refCurrent => {
    setLastMessageItem(refCurrent)
  }, [])

  const removeConversationMessagesFromCache = (cache, result) => {
    const options = {
      query: CONVERSATION_MESSAGES_QUERY,
      variables,
    }
    const data = JSON.parse(JSON.stringify(cache.readQuery(options)))

    data.legacyNode.conversationMessagesConnection.nodes =
      data.legacyNode.conversationMessagesConnection.nodes.filter(
        message =>
          !result.data.deleteConversationMessages.conversationMessageIds.includes(message._id)
      )

    cache.writeQuery({...options, data})

    let legacyNode
    try {
      const queryResult = JSON.parse(
        JSON.stringify(cache.readQuery(props.conversationsQueryOption))
      )
      legacyNode = queryResult.legacyNode
    } catch (e) {
      // readQuery throws an exception if the query isn't already in the cache
      // If its not in the cache we don't want to do anything
      return
    }

    // This mutation allows to delete multiple messages at once
    // but the mutation is run with only one.
    const conversationMessageId = result.data.deleteConversationMessages.conversationMessageIds[0]
    const matchingConversation = legacyNode.conversationsConnection.nodes.find(c =>
      c.conversation.conversationMessagesConnection.nodes.find(m => m._id === conversationMessageId)
    )

    if (matchingConversation) {
      matchingConversation.conversation.conversationMessagesCount--
    }

    cache.writeQuery({
      ...props.conversationsQueryOption,
      data: {legacyNode},
    })
  }

  const handleDeleteConversationMessage = conversationMessageId => {
    const delMsg = I18n.t(
      'Are you sure you want to delete your copy of this message? This action cannot be undone.'
    )

    const confirmResult = window.confirm(delMsg) // eslint-disable-line no-alert
    if (confirmResult) {
      deleteConversationMessages({variables: {ids: [conversationMessageId]}})
    }
  }

  const [deleteConversationMessages] = useMutation(DELETE_CONVERSATION_MESSAGES, {
    update: removeConversationMessagesFromCache,
    onCompleted() {
      setOnSuccess(I18n.t('Successfully deleted the conversation message'), false)
    },
    onError() {
      setOnFailure(I18n.t('There was an unexpected error deleting the conversation message'))
    },
  })

  const conversationMessagesQuery = useQuery(CONVERSATION_MESSAGES_QUERY, {
    variables,
    skip: isSubmissionCommentsType,
  })

  const submissionCommentsQuery = useQuery(SUBMISSION_COMMENTS_QUERY, {
    variables: {submissionID: props.conversation._id, sort: 'desc'},
    skip: !isSubmissionCommentsType,
  })

  // Intial focus on message when loaded
  useEffect(() => {
    if (!conversationMessagesQuery.loading && messageOpenEvent && messageRef) {
      // Focus
      messageRef?.focus()
      setMessageOpenEvent(false)
    }
  }, [conversationMessagesQuery.loading, messageRef, messageOpenEvent, setMessageOpenEvent])

  // Set Conversation to read when the conversationMessages are loaded
  useEffect(() => {
    const idIsStoredInSessionStorage = JSON.parse(
      sessionStorage.getItem('conversationsManuallyMarkedUnread')
    )?.includes(props.conversation._id)

    if (
      !idIsStoredInSessionStorage &&
      (conversationMessagesQuery.data?.legacyNode || submissionCommentsQuery.data?.legacyNode) &&
      props.conversation.workflowState === 'unread'
    ) {
      props.onReadStateChange('read', [props.conversation])
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [conversationMessagesQuery.data, submissionCommentsQuery.data])

  const inboxMessageData = useMemo(() => {
    if (
      (conversationMessagesQuery.loading && !conversationMessagesQuery.data) ||
      (submissionCommentsQuery.loading && !submissionCommentsQuery.data)
    ) {
      return []
    }

    const data = isSubmissionCommentsType
      ? submissionCommentsQuery.data?.legacyNode
      : conversationMessagesQuery.data?.legacyNode

    if (data) {
      const canReply = isSubmissionCommentsType ? true : data?.canReply
      props.setCanReply(canReply)
    }

    const messageData = inboxMessagesWrapper(data, isSubmissionCommentsType)

    if (
      messageData.inboxMessages.length > 0 &&
      !conversationMessagesQuery.loading &&
      !submissionCommentsQuery.loading
    ) {
      messageData.inboxMessages[messageData.inboxMessages.length - 1].isLast = true
    }

    return messageData
  }, [
    conversationMessagesQuery.data,
    conversationMessagesQuery.loading,
    isSubmissionCommentsType,
    props,
    submissionCommentsQuery.data,
    submissionCommentsQuery.loading,
  ])

  const fetchMoreMenuData = () => {
    setIsLoadingMoreData(true)
    if (!isSubmissionCommentsType) {
      conversationMessagesQuery.fetchMore({
        variables: {
          _id: inboxMessageData.inboxMessages[inboxMessageData.inboxMessages.length - 1]._id,
          variables,
          afterMessage:
            conversationMessagesQuery.data?.legacyNode?.conversationMessagesConnection?.pageInfo
              ?.endCursor,
        },
        updateQuery: (previousResult, {fetchMoreResult}) => {
          setIsLoadingMoreData(false)

          const prev_nodes = previousResult?.legacyNode?.conversationMessagesConnection?.nodes
          const fetchMore_nodes = fetchMoreResult?.legacyNode?.conversationMessagesConnection?.nodes
          const fetchMore_pageInfo =
            fetchMoreResult?.legacyNode?.conversationMessagesConnection?.pageInfo
          return {
            legacyNode: {
              _id: fetchMoreResult?.legacyNode?._id,
              id: fetchMoreResult?.legacyNode?.id,
              conversationMessagesConnection: {
                nodes: [...prev_nodes, ...fetchMore_nodes],
                pageInfo: fetchMore_pageInfo,
                __typename: 'ConversationMessageConnection',
              },
              __typename: 'Conversation',
            },
          }
        },
      })
    } else {
      submissionCommentsQuery.fetchMore({
        variables: {
          _id: inboxMessageData.inboxMessages[inboxMessageData.inboxMessages.length - 1]._id,
          submissionID: props.conversation._id,
          sort: 'desc',
          afterComment:
            submissionCommentsQuery.data?.legacyNode?.commentsConnection?.pageInfo?.endCursor,
        },
        updateQuery: (previousResult, {fetchMoreResult}) => {
          setIsLoadingMoreData(false)

          const prev_nodes = previousResult.legacyNode.commentsConnection.nodes
          const fetchMore_nodes = fetchMoreResult.legacyNode.commentsConnection.nodes
          const fetchMore_pageInfo = fetchMoreResult?.legacyNode?.commentsConnection?.pageInfo
          return {
            legacyNode: {
              _id: fetchMoreResult?.legacyNode?._id,
              id: fetchMoreResult?.legacyNode?.id,
              commentsConnection: {
                nodes: [...prev_nodes, ...fetchMore_nodes],
                pageInfo: fetchMore_pageInfo,
                __typename: 'SubmissionCommentConnection',
              },
              user: {
                ...fetchMoreResult?.legacyNode?.user,
              },
              __typename: 'Submission',
            },
          }
        },
      })
    }
  }

  const hasMoreMenuData =
    conversationMessagesQuery.data?.legacyNode?.conversationMessagesConnection?.pageInfo
      ?.hasNextPage ||
    submissionCommentsQuery.data?.legacyNode?.commentsConnection?.pageInfo?.hasNextPage

  const isLoading = conversationMessagesQuery.loading || submissionCommentsQuery.loading

  // Creates an oberserver on the last scroll item to fetch more data when it becomes visible
  useEffect(() => {
    if (lastMessageItem && hasMoreMenuData) {
      const observer = new IntersectionObserver(
        ([menuItem]) => {
          if (menuItem.isIntersecting) {
            observer.unobserve(lastMessageItem)
            setLastMessageItem(null)
            fetchMoreMenuData()
          }
        },
        {
          root: null,
          rootMargin: '0px',
          threshold: 0.4,
        }
      )

      if (lastMessageItem) {
        observer.observe(lastMessageItem)
      }

      return () => {
        if (lastMessageItem) observer.unobserve(lastMessageItem)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasMoreMenuData, isSubmissionCommentsType, lastMessageItem])

  if (conversationMessagesQuery?.error || submissionCommentsQuery?.error) {
    setOnFailure(I18n.t('Failed to load conversation messages.'))
    return
  }

  const renderLoading = () => {
    return (
      <View as="div" textAlign="center" margin="large none" data-testid="conversation-loader">
        <Spinner renderTitle={() => I18n.t('Loading Conversation Messages')} variant="inverse" />
      </View>
    )
  }

  // Render individual menu items
  const renderMenuItem = (message, isLast) => (
    <View
      as="div"
      borderWidth="small none none none"
      padding="small"
      key={message.id}
      elementRef={el => {
        if (isLast) {
          onItemRefSet(el)
        }
      }}
    >
      <MessageDetailItem
        conversationMessage={message}
        contextName={inboxMessageData?.contextName}
        onReply={inboxMessageData?.canReply ? () => props.onReply(message) : null}
        onReplyAll={inboxMessageData?.canReply ? () => props.onReplyAll(message) : null}
        onDelete={() => handleDeleteConversationMessage(message._id)}
        onForward={() => props.onForward(message)}
      />
    </View>
  )

  // Memo which returns array of ConversationListItem's
  // eslint-disable-next-line react-hooks/rules-of-hooks
  const renderedItems = useMemo(() => {
    const menuData = inboxMessageData?.inboxMessages

    if (isLoading && !isLoadingMoreData) {
      return renderLoading()
    }

    return menuData.map(message => {
      return renderMenuItem(message, message?.isLast)
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inboxMessageData?.inboxMessages])

  return (
    <>
      <MessageDetailHeader
        onBack={props.onBack}
        focusRef={setMessageRef}
        text={props.conversation.subject || I18n.t('(No subject)')}
        onForward={props.onForward}
        onReply={inboxMessageData?.canReply ? props.onReply : null}
        onReplyAll={inboxMessageData?.canReply ? props.onReplyAll : null}
        onArchive={props.onArchive}
        onUnarchive={props.onUnarchive}
        onStar={props.onStar}
        onUnstar={props.onUnstar}
        onDelete={() => props.onDelete([props.conversation._id])}
        submissionCommentURL={inboxMessageData?.submissionCommentURL}
        scope={props.scope}
      />
      {isLoading && !isLoadingMoreData && renderLoading()}
      {(!isLoading || isLoadingMoreData) && (
        <View as="div" height="100%" overflowX="hidden" overflowY="auto" display="inline">
          {renderedItems}
          {isLoadingMoreData && renderLoading()}
        </View>
      )}
    </>
  )
}

MessageDetailContainer.propTypes = {
  conversation: Conversation.shape,
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func,
  onArchive: PropTypes.func,
  onUnarchive: PropTypes.func,
  onDelete: PropTypes.func,
  onForward: PropTypes.func,
  onStar: PropTypes.func,
  onUnstar: PropTypes.func,
  onReadStateChange: PropTypes.func,
  onBack: PropTypes.func,
  setCanReply: PropTypes.func,
  scope: PropTypes.string,
  conversationsQueryOption: PropTypes.object,
}
