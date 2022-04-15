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
  ADD_CONVERSATION_MESSAGE,
  CREATE_CONVERSATION,
  CREATE_SUBMISSION_COMMENT
} from '../../../graphql/Mutations'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import ComposeModalContainer from './ComposeModalContainer'
import {Conversation} from '../../../graphql/Conversation'
import {ConversationMessage} from '../../../graphql/ConversationMessage'
import {
  CONVERSATION_MESSAGES_QUERY,
  COURSES_QUERY,
  REPLY_CONVERSATION_QUERY,
  SUBMISSION_COMMENTS_QUERY,
  VIEWABLE_SUBMISSIONS_QUERY
} from '../../../graphql/Queries'
import {useScope as useI18nScope} from '@canvas/i18n'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import {ConversationContext} from '../../../util/constants'

const I18n = useI18nScope('conversations_2')

const ComposeModalManager = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendingMessage, setSendingMessage] = useState(false)
  const {isSubmissionCommentsType} = useContext(ConversationContext)

  const coursesQuery = useQuery(COURSES_QUERY, {
    variables: {
      userID: ENV.current_user_id?.toString()
    },
    skip: props.isReply || props.isReplyAll || props.isForward
  })

  const getParticipants = () => {
    if (isSubmissionCommentsType) return

    const lastAuthorId = props.conversationMessage
      ? props.conversationMessage?.author._id.toString()
      : props.conversation?.messages[0].author._id.toString()

    if (props.isReply && lastAuthorId !== ENV.current_user_id.toString()) {
      return [lastAuthorId]
    } else {
      const recipients = props.conversationMessage
        ? props.conversationMessage?.recipients
        : props.conversation?.messages[0]?.recipients
      return recipients?.map(r => r._id.toString())
    }
  }

  const replyConversationQuery = useQuery(REPLY_CONVERSATION_QUERY, {
    variables: {
      conversationID: props.conversation?._id,
      participants: getParticipants(),
      ...(props.conversationMessage && {createdBefore: props.conversationMessage.createdAt})
    },
    skip: !(props.isReply || props.isReplyAll || props.isForward) || isSubmissionCommentsType
  })

  const updateConversationsCache = (cache, result) => {
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

    if (props.isReply || props.isReplyAll || props.isForward) {
      legacyNode.conversationsConnection.nodes
        .find(c => c.conversation._id === props.conversation._id)
        .conversation.conversationMessagesConnection.nodes.unshift(
          result.data.addConversationMessage.conversationMessage
        )
    } else {
      legacyNode.conversationsConnection.nodes.unshift(
        ...result.data.createConversation.conversations
      )
    }

    cache.writeQuery({
      ...props.conversationsQueryOption,
      data: {legacyNode}
    })
  }

  const updateReplyConversationsCache = (cache, result) => {
    if (props.isReply || props.isReplyAll || props.isForward) {
      const replyQueryResult = JSON.parse(
        JSON.stringify(
          cache.readQuery({
            query: REPLY_CONVERSATION_QUERY,
            variables: {
              conversationID: props.conversation?._id,
              participants: getParticipants(),
              ...(props.conversationMessage && {createdBefore: props.conversationMessage.createdAt})
            }
          })
        )
      )

      replyQueryResult.legacyNode.conversationMessagesConnection.nodes.unshift(
        result.data.addConversationMessage.conversationMessage
      )

      cache.writeQuery({
        query: REPLY_CONVERSATION_QUERY,
        variables: {
          conversationID: props.conversation?._id,
          participants: getParticipants(),
          ...(props.conversationMessage && {createdBefore: props.conversationMessage.createdAt})
        },
        data: {legacyNode: replyQueryResult.legacyNode}
      })
    }
  }

  const updateConversationMessagesCache = (cache, result) => {
    if (props?.conversation) {
      const querytoUpdate = {
        query: CONVERSATION_MESSAGES_QUERY,
        variables: {
          conversationID: props.conversation._id
        }
      }
      const data = JSON.parse(JSON.stringify(cache.readQuery(querytoUpdate)))

      data.legacyNode.conversationMessagesConnection.nodes = [
        result.data.addConversationMessage.conversationMessage,
        ...data.legacyNode.conversationMessagesConnection.nodes
      ]

      cache.writeQuery({...querytoUpdate, data})
    }
  }

  const updateSubmissionCommentsCache = (cache, result) => {
    if (props?.conversation) {
      const queryToUpdate = {
        query: SUBMISSION_COMMENTS_QUERY,
        variables: {
          submissionID: props.conversation._id
        }
      }
      const data = JSON.parse(JSON.stringify(cache.readQuery(queryToUpdate)))

      data.legacyNode.commentsConnection.nodes.push(
        result.data.createSubmissionComment.submissionComment
      )
      cache.writeQuery({...queryToUpdate, data})
    }

    const queryToUpdate = {
      query: VIEWABLE_SUBMISSIONS_QUERY,
      variables: {
        userID: ENV.current_user_id?.toString()
      }
    }
    const data = JSON.parse(JSON.stringify(cache.readQuery(queryToUpdate)))
    const submissionToUpdate = data.legacyNode.viewableSubmissionsConnection.nodes.find(
      c => c._id === props.conversation._id
    )
    submissionToUpdate.commentsConnection.nodes.push(
      result.data.createSubmissionComment.submissionComment
    )

    cache.writeQuery({...queryToUpdate, data})
  }

  const updateCache = (cache, result) => {
    if (isSubmissionCommentsType) {
      if (result.data.createSubmissionComment.errors) {
        setOnFailure(I18n.t('Error occurred while creating submission comment'))
        return
      }
    } else if (props.isReply || props.isReplyAll || props.isForward) {
      if (result.data.addConversationMessage.errors) {
        setOnFailure(I18n.t('Error occurred while adding message to conversation'))
        return
      }
    } else if (result.data.createConversation.errors) {
      setOnFailure(I18n.t('Error occurred while creating conversation message'))
      return
    }
    if (isSubmissionCommentsType) {
      updateSubmissionCommentsCache(cache, result)
    } else {
      updateConversationMessagesCache(cache, result)
      updateConversationsCache(cache, result)
      updateReplyConversationsCache(cache, result)
    }
  }

  const onConversationCreateComplete = success => {
    setSendingMessage(false)

    if (success) {
      setOnSuccess(I18n.t('Message sent!'), false)
    } else {
      setOnFailure(I18n.t('Error creating conversation'))
    }
  }

  const [createConversation] = useMutation(CREATE_CONVERSATION, {
    update: updateCache,
    onCompleted: data => onConversationCreateComplete(!data.createConversation.errors),
    onError: () => onConversationCreateComplete(false)
  })

  const [addConversationMessage] = useMutation(ADD_CONVERSATION_MESSAGE, {
    update: updateCache,
    onCompleted: data => onConversationCreateComplete(!data.addConversationMessage.errors),
    onError: () => onConversationCreateComplete(false)
  })

  const [createSubmissionComment] = useMutation(CREATE_SUBMISSION_COMMENT, {
    update: updateCache,
    onCompleted: data => onConversationCreateComplete(!data.createSubmissionComment.errors),
    onError: () => onConversationCreateComplete(false)
  })

  if (!props.open) {
    return null
  }

  // Handle query errors
  if (coursesQuery?.error) {
    setOnFailure(I18n.t('Error loading course data'))
    return null
  }
  if (replyConversationQuery?.error) {
    setOnFailure(I18n.t('Error loading past messages'))
    return null
  }

  // Handle loading
  if (coursesQuery?.loading || replyConversationQuery?.loading) {
    return <ModalSpinner label={I18n.t('Loading')} message={I18n.t('Loading Compose Modal')} />
  }

  return (
    <ComposeModalContainer
      addConversationMessage={data => {
        addConversationMessage({
          variables: {
            ...data.variables,
            conversationId: props.conversation?._id,
            recipients: data.variables.recipients ? data.variables.recipients : getParticipants()
          }
        })
      }}
      createSubmissionComment={data => {
        createSubmissionComment({
          variables: {
            ...data.variables,
            submissionId: props?.conversation?._id
          }
        })
      }}
      courses={coursesQuery?.data?.legacyNode}
      createConversation={createConversation}
      isReply={props.isReply || props.isReplyAll}
      isForward={props.isForward}
      onDismiss={props.onDismiss}
      open={props.open}
      pastConversation={replyConversationQuery?.data?.legacyNode}
      sendingMessage={sendingMessage}
      setSendingMessage={setSendingMessage}
      onSelectedIdsChange={props.onSelectedIdsChange}
      selectedIds={props.selectedIds}
      submissionCommentsHeader={isSubmissionCommentsType ? props?.conversation?.subject : null}
    />
  )
}

ComposeModalManager.propTypes = {
  conversation: Conversation.shape,
  conversationMessage: ConversationMessage.shape,
  isReply: PropTypes.bool,
  isReplyAll: PropTypes.bool,
  isForward: PropTypes.bool,
  onDismiss: PropTypes.func,
  open: PropTypes.bool,
  conversationsQueryOption: PropTypes.object,
  onSelectedIdsChange: PropTypes.func,
  selectedIds: PropTypes.array
}

export default ComposeModalManager
