/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState, useEffect, useContext} from 'react'
import ComposeModalManager from './ComposeModalContainer/ComposeModalManager'
import {MessageDetailContainer} from './MessageDetailContainer/MessageDetailContainer'
import MessageListActionContainer from './MessageListActionContainer'
import ConversationListContainer from './ConversationListContainer'
import {NoSelectedConversation} from '../components/NoSelectedConversation/NoSelectedConversation'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import I18n from 'i18n!conversations_2'
import {useMutation} from 'react-apollo'
import {DELETE_CONVERSATIONS} from '../../graphql/Mutations'
import {CONVERSATIONS_QUERY} from '../../graphql/Queries'

const CanvasInbox = () => {
  const [scope, setScope] = useState('inbox')
  const [courseFilter, setCourseFilter] = useState()
  const [userFilter, setUserFilter] = useState()
  const [selectedConversations, setSelectedConversations] = useState([])
  const [selectedConversationMessage, setSelectedConversationMessage] = useState()
  const [composeModal, setComposeModal] = useState(false)
  const [deleteDisabled, setDeleteDisabled] = useState(true)
  const [archiveDisabled, setArchiveDisabled] = useState(true)
  const [isReply, setIsReply] = useState(false)
  const [isReplyAll, setIsReplyAll] = useState(false)
  const [isForward, setIsForward] = useState(false)
  const [displayUnarchiveButton, setDisplayUnarchiveButton] = useState(false)
  const userID = ENV.current_user_id?.toString()

  const updateSelectedConversations = conversations => {
    setSelectedConversations(conversations)
    setDeleteDisabled(conversations.length === 0)
    setArchiveDisabled(conversations.length === 0)
    setSelectedConversationMessage(null)
  }

  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const conversationsQueryOption = {
    query: CONVERSATIONS_QUERY,
    variables: {
      userID: ENV.current_user_id?.toString(),
      scope,
      filter: [userFilter, courseFilter]
    }
  }

  const handleDelete = individualConversation => {
    const conversationsToDeleteByID =
      individualConversation || selectedConversations.map(convo => convo._id)

    const delMsg = I18n.t(
      {
        one: 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.',
        other:
          'Are you sure you want to delete your copy of these conversations? This action cannot be undone.'
      },
      {count: conversationsToDeleteByID.length}
    )
    const confirmResult = window.confirm(delMsg) // eslint-disable-line no-alert
    if (confirmResult) {
      deleteConversations({variables: {ids: conversationsToDeleteByID}})
    } else {
      // confirm message was cancelled by user
      setDeleteDisabled(false)
    }
  }

  const handleDeleteComplete = data => {
    const deletedConversationIDs = data.deleteConversations.conversationIds
    const deletedSuccessMsg = I18n.t(
      {
        one: 'Message Deleted!',
        other: 'Messages Deleted!'
      },
      {count: deletedConversationIDs.length}
    )

    if (data.deleteConversations.errors) {
      // keep delete button enabled since deletion returned errors
      setDeleteDisabled(false)
      setOnFailure(I18n.t('Delete operation failed'))
    } else {
      setDeleteDisabled(true)
      removeFromSelectedConversations(deletedConversationIDs)
      setOnSuccess(deletedSuccessMsg, false)
    }
  }

  const removeFromSelectedConversations = conversationIds => {
    setSelectedConversations(prev => {
      const updated = prev.filter(selectedConvo => !conversationIds.includes(selectedConvo._id))
      setDeleteDisabled(updated.length === 0)
      setArchiveDisabled(updated.length === 0)
      return updated
    })
  }

  const removeDeletedConversationsFromCache = (cache, result) => {
    const conversationsFromCache = JSON.parse(
      JSON.stringify(cache.readQuery(conversationsQueryOption))
    )

    const conversationIDsFromResult = result.data.deleteConversations.conversationIds

    const updatedCPs = conversationsFromCache.legacyNode.conversationsConnection.nodes.filter(
      conversationParticipant => {
        return !conversationIDsFromResult.includes(conversationParticipant.conversation._id)
      }
    )

    conversationsFromCache.legacyNode.conversationsConnection.nodes = updatedCPs
    cache.writeQuery({...conversationsQueryOption, data: conversationsFromCache})
  }

  const [deleteConversations] = useMutation(DELETE_CONVERSATIONS, {
    update: removeDeletedConversationsFromCache,
    onCompleted(data) {
      handleDeleteComplete(data)
    },
    onError() {
      setOnFailure(I18n.t('Delete operation failed'))
    }
  })

  const onReply = ({conversationMessage = null, replyAll = false} = {}) => {
    setSelectedConversationMessage(conversationMessage)
    setIsReplyAll(replyAll)
    setIsReply(!replyAll)
    setComposeModal(true)
  }

  const onForward = () => {
    setIsForward(true)
    setComposeModal(true)
  }

  useEffect(() => {
    setDeleteDisabled(selectedConversations.length === 0)
    setArchiveDisabled(selectedConversations.length === 0)
    if (selectedConversations.length === 0) {
      setDisplayUnarchiveButton(false)
    } else {
      setDisplayUnarchiveButton(
        selectedConversations[0].conversationParticipantsConnection?.nodes?.some(cp => {
          return cp.user._id === userID && cp.workflowState === 'archived'
        })
      )
    }
  }, [selectedConversations, userID])

  return (
    <div className="canvas-inbox-container">
      <Flex height="100vh" width="100%" as="div" direction="column">
        <Flex.Item>
          <MessageListActionContainer
            activeMailbox={scope}
            onSelectMailbox={newScope => {
              setSelectedConversations([])
              setScope(newScope)
            }}
            onCourseFilterSelect={course => {
              setSelectedConversations([])
              setCourseFilter(course)
            }}
            onUserFilterSelect={userIDFilter => {
              setUserFilter(userIDFilter)
            }}
            selectedConversations={selectedConversations}
            onCompose={() => setComposeModal(true)}
            onReply={() => onReply()}
            onReplyAll={() => onReply({replyAll: true})}
            onForward={() => onForward()}
            deleteDisabled={deleteDisabled}
            deleteToggler={setDeleteDisabled}
            archiveDisabled={archiveDisabled}
            archiveToggler={setArchiveDisabled}
            onConversationRemove={removeFromSelectedConversations}
            displayUnarchiveButton={displayUnarchiveButton}
            conversationsQueryOptions={conversationsQueryOption}
            onDelete={handleDelete}
          />
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink>
          <Flex height="100%" as="div" align="center" justifyItems="center">
            <Flex.Item width="400px" height="100%">
              <ConversationListContainer
                course={courseFilter}
                userFilter={userFilter}
                scope={scope}
                onSelectConversation={updateSelectedConversations}
              />
            </Flex.Item>
            <Flex.Item shouldGrow shouldShrink height="100%" overflowY="auto">
              {selectedConversations.length > 0 ? (
                <MessageDetailContainer
                  conversation={selectedConversations[0]}
                  onReply={conversationMessage => onReply({conversationMessage})}
                  onReplyAll={conversationMessage => onReply({conversationMessage, replyAll: true})}
                  onDelete={handleDelete}
                />
              ) : (
                <View padding="small">
                  <NoSelectedConversation />
                </View>
              )}
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      <ComposeModalManager
        conversation={selectedConversations[0]}
        conversationMessage={selectedConversationMessage}
        isReply={isReply}
        isReplyAll={isReplyAll}
        isForward={isForward}
        onDismiss={() => {
          setComposeModal(false)
          setIsReply(false)
          setIsReplyAll(false)
          setIsForward(false)
          setSelectedConversationMessage(null)
        }}
        open={composeModal}
        conversationsQueryOption={conversationsQueryOption}
      />
    </div>
  )
}

export default CanvasInbox
