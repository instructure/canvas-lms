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
import {CONVERSATION_MESSAGES_QUERY} from '../../../graphql/Queries'
import {DELETE_CONVERSATION_MESSAGES} from '../../../graphql/Mutations'
import I18n from 'i18n!conversations_2'
import {MessageDetailHeader} from '../../components/MessageDetailHeader/MessageDetailHeader'
import {MessageDetailItem} from '../../components/MessageDetailItem/MessageDetailItem'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const MessageDetailContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const removeConversationMessagesFromCache = (cache, result) => {
    const data = JSON.parse(
      JSON.stringify(
        cache.readFragment({
          id: props.conversation.id,
          fragment: Conversation.fragment,
          fragmentName: 'Conversation'
        })
      )
    )

    data.conversationMessagesConnection.nodes = data.conversationMessagesConnection.nodes.filter(
      message =>
        !result.data.deleteConversationMessages.conversationMessageIds.includes(message._id)
    )

    cache.writeFragment({
      id: props.conversation.id,
      fragment: Conversation.fragment,
      fragmentName: 'Conversation',
      data
    })
  }

  const [deleteConversationMessages] = useMutation(DELETE_CONVERSATION_MESSAGES, {
    update: removeConversationMessagesFromCache,
    onCompleted() {
      setOnSuccess(I18n.t('Successfully deleted the conversation message'))
    },
    onError() {
      setOnFailure(I18n.t('There was an unexpected error deleting the conversation message'))
    }
  })

  const {loading, error, data} = useQuery(CONVERSATION_MESSAGES_QUERY, {
    variables: {
      conversationID: props.conversation._id
    }
  })

  if (loading) {
    return (
      <View as="div" textAlign="center" margin="large none">
        <Spinner renderTitle={() => I18n.t('Loading Conversation Messages')} variant="inverse" />
      </View>
    )
  }

  if (error) {
    setOnFailure(I18n.t('Failed to load conversation messages.'))
    return
  }

  return (
    <>
      <MessageDetailHeader
        text={props.conversation.subject}
        onReply={props.onReply}
        onReplyAll={props.onReplyAll}
      />
      {data?.legacyNode?.conversationMessagesConnection.nodes.map(message => (
        <View as="div" borderWidth="small none none none" padding="small" key={message.id}>
          <MessageDetailItem
            conversationMessage={message}
            context={props.conversation.contextName}
            onReply={() => props.onReply(message)}
            onReplyAll={() => props.onReplyAll(message)}
            onDelete={() => deleteConversationMessages({variables: {ids: [message._id]}})}
          />
        </View>
      ))}
    </>
  )
}

MessageDetailContainer.propTypes = {
  conversation: Conversation.shape,
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func
}
