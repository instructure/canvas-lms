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

import {AlertManagerContext} from 'jsx/shared/components/AlertManager'
import ComposeModalContainer from './ComposeModalContainer'
import {Conversation} from 'jsx/canvas_inbox/graphqlData/Conversation'
import {CONVERSATIONS_QUERY, COURSES_QUERY, REPLY_CONVERSATION_QUERY} from '../../Queries'
import {CREATE_CONVERSATION} from '../../Mutations'
import I18n from 'i18n!conversations_2'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'

const ComposeModalManager = (props) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendingMessage, setSendingMessage] = useState(false)

  const coursesQuery = useQuery(COURSES_QUERY, {
    variables: {
      userID: ENV.current_user_id?.toString(),
    },
    skip: props.isReply,
  })

  const replyConversationQuery = useQuery(REPLY_CONVERSATION_QUERY, {
    variables: {
      conversationID: props.conversation?._id,
      participants: props.conversation?.conversationMessagesConnection.nodes[0].author._id,
    },
    skip: !props.isReply,
  })

  const updateCache = (cache, result) => {
    if (result.data.createConversation.errors) {
      setOnFailure(I18n.t('Error occurred while creating conversation message'))
      return
    }

    let legacyNode
    try {
      const queryResult = JSON.parse(
        JSON.stringify(
          cache.readQuery({
            query: CONVERSATIONS_QUERY,
            variables: {
              scope: 'sent',
              userID: ENV.current_user_id?.toString(),
            },
          })
        )
      )
      legacyNode = queryResult.legacyNode
    } catch (e) {
      // readQuery throws an exception if the query isn't already in the cache
      // If its not in the cache we don't want to do anything
      return
    }

    legacyNode.conversationsConnection.nodes.unshift(
      ...result.data.createConversation.conversations
    )

    cache.writeQuery({
      query: CONVERSATIONS_QUERY,
      variables: {
        scope: 'sent',
        userID: ENV.current_user_id?.toString(),
      },
      data: {legacyNode},
    })
  }

  const onConversationCreateComplete = (success) => {
    setSendingMessage(false)

    if (success) {
      setOnSuccess(I18n.t('Message sent successfully'))
    } else {
      setOnFailure(I18n.t('Error creating conversation'))
    }
  }

  const [createConversation] = useMutation(CREATE_CONVERSATION, {
    update: updateCache,
    onCompleted: (data) => onConversationCreateComplete(!data.createConversation.errors),
    onError: () => onConversationCreateComplete(false),
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
      courses={coursesQuery?.data?.legacyNode}
      createConversation={createConversation}
      isReply={props.isReply}
      onDismiss={props.onDismiss}
      open={props.open}
      pastConversation={replyConversationQuery?.data?.legacyNode}
      sendingMessage={sendingMessage}
      setSendingMessage={setSendingMessage}
    />
  )
}

ComposeModalManager.propTypes = {
  conversation: Conversation.shape,
  isReply: PropTypes.bool,
  onDismiss: PropTypes.func,
  open: PropTypes.bool,
}

export default ComposeModalManager
