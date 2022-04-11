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
import React, {useContext, useEffect, useState, useMemo} from 'react'
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
    conversationID: props.conversation._id
  }

  const removeConversationMessagesFromCache = (cache, result) => {
    const options = {
      query: CONVERSATION_MESSAGES_QUERY,
      variables
    }
    const data = JSON.parse(JSON.stringify(cache.readQuery(options)))

    data.legacyNode.conversationMessagesConnection.nodes =
      data.legacyNode.conversationMessagesConnection.nodes.filter(
        message =>
          !result.data.deleteConversationMessages.conversationMessageIds.includes(message._id)
      )

    cache.writeQuery({...options, data})
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
    }
  })

  const conversationMessagesQuery = useQuery(CONVERSATION_MESSAGES_QUERY, {
    variables,
    skip: isSubmissionCommentsType
  })

  const submissionCommentsQuery = useQuery(SUBMISSION_COMMENTS_QUERY, {
    variables: {submissionID: props.conversation._id},
    skip: !isSubmissionCommentsType
  })

  // Intial focus on message when loaded
  useEffect(() => {
    if (!conversationMessagesQuery.loading && messageOpenEvent && messageRef) {
      // Focus
      messageRef?.focus()
      setMessageOpenEvent(false)
    }
  }, [conversationMessagesQuery.loading, messageRef, messageOpenEvent, setMessageOpenEvent])

  const inboxMessageData = useMemo(() => {
    const data = isSubmissionCommentsType
      ? submissionCommentsQuery.data?.legacyNode
      : conversationMessagesQuery.data?.legacyNode

    return inboxMessagesWrapper(data, isSubmissionCommentsType)
  }, [conversationMessagesQuery.data, isSubmissionCommentsType, submissionCommentsQuery.data])

  if (conversationMessagesQuery?.loading || submissionCommentsQuery?.loading) {
    return (
      <View as="div" textAlign="center" margin="large none">
        <Spinner renderTitle={() => I18n.t('Loading Conversation Messages')} variant="inverse" />
      </View>
    )
  }

  if (conversationMessagesQuery?.error || submissionCommentsQuery?.error) {
    setOnFailure(I18n.t('Failed to load conversation messages.'))
    return
  }

  return (
    <>
      <MessageDetailHeader
        focusRef={setMessageRef}
        text={props.conversation.subject}
        onForward={props.onForward}
        onReply={
          isSubmissionCommentsType
            ? () => {
                setOnFailure(I18n.t('comment reply is not enabled'))
              }
            : props.onReply
        }
        onReplyAll={
          isSubmissionCommentsType
            ? () => {
                setOnFailure(I18n.t('comment reply all is not enabled'))
              }
            : props.onReplyAll
        }
        onDelete={
          isSubmissionCommentsType
            ? () => {
                setOnFailure(I18n.t('comment delete is not enabled'))
              }
            : () => props.onDelete([props.conversation._id])
        }
      />
      {inboxMessageData?.inboxMessages.map(message => (
        <View as="div" borderWidth="small none none none" padding="small" key={message.id}>
          <MessageDetailItem
            conversationMessage={message}
            contextName={inboxMessageData?.contextName}
            onReply={
              isSubmissionCommentsType
                ? () => {
                    setOnFailure(I18n.t('comment reply is not enabled'))
                  }
                : () => props.onReply(message)
            }
            onReplyAll={
              isSubmissionCommentsType
                ? () => {
                    setOnFailure(I18n.t('comment reply all is not enabled'))
                  }
                : () => props.onReplyAll(message)
            }
            onDelete={
              isSubmissionCommentsType
                ? () => {
                    setOnFailure(I18n.t('comment delete is not enabled'))
                  }
                : () => handleDeleteConversationMessage(message._id)
            }
            onForward={() => props.onForward(message)}
          />
        </View>
      ))}
    </>
  )
}

MessageDetailContainer.propTypes = {
  conversation: Conversation.shape,
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func,
  onDelete: PropTypes.func,
  onForward: PropTypes.func
}
