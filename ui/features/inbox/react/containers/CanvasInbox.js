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

import ComposeModalManager from './ComposeModalContainer/ComposeModalManager'
import {Flex} from '@instructure/ui-flex'
import React, {useState, useEffect} from 'react'
import MessageListContainer from './MessageListContainer'
import MessageListActionContainer from './MessageListActionContainer'

const CanvasInbox = () => {
  const [scope, setScope] = useState('inbox')
  const [courseFilter, setCourseFilter] = useState()
  const [selectedConversations, setSelectedConversations] = useState([])
  const [composeModal, setComposeModal] = useState(false)
  const [deleteDisabled, setDeleteDisabled] = useState(true)
  const [archiveDisabled, setArchiveDisabled] = useState(true)
  const [isReply, setIsReply] = useState(false)
  const [isReplyAll, setIsReplyAll] = useState(false)
  const [displayUnarchiveButton, setDisplayUnarchiveButton] = useState(false)
  const userID = ENV.current_user_id?.toString()

  const updateSelectedConversations = conversations => {
    setSelectedConversations(conversations)
    setDeleteDisabled(conversations.length === 0)
    setArchiveDisabled(conversations.length === 0)
  }

  const removeFromSelectedConversations = conversations => {
    const conversationIds = conversations.map(convo => convo._id)
    setSelectedConversations(prev => {
      const updated = prev.filter(selectedConvo => !conversationIds.includes(selectedConvo._id))
      setDeleteDisabled(updated.length === 0)
      setArchiveDisabled(updated.length === 0)
      return updated
    })
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
            course={courseFilter}
            scope={scope}
            onSelectMailbox={setScope}
            onCourseFilterSelect={setCourseFilter}
            selectedConversations={selectedConversations}
            onCompose={() => setComposeModal(true)}
            onReply={() => {
              setIsReply(true)
              setComposeModal(true)
            }}
            onReplyAll={() => {
              setIsReplyAll(true)
              setComposeModal(true)
            }}
            deleteDisabled={deleteDisabled}
            deleteToggler={setDeleteDisabled}
            archiveDisabled={archiveDisabled}
            archiveToggler={setArchiveDisabled}
            onConversationRemove={removeFromSelectedConversations}
            displayUnarchiveButton={displayUnarchiveButton}
          />
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink>
          <Flex height="100%" as="div" align="center" justifyItems="center">
            <Flex.Item width="400px" height="100%">
              <MessageListContainer
                course={courseFilter}
                scope={scope}
                onSelectMessage={updateSelectedConversations}
              />
            </Flex.Item>
            <Flex.Item shouldGrow shouldShrink height="100%">
              <div className="testing-class-name-canvas-inbox">Message Content Goes Here</div>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      <ComposeModalManager
        conversation={selectedConversations[0]}
        isReply={isReply}
        isReplyAll={isReplyAll}
        onDismiss={() => {
          setComposeModal(false)
          setIsReply(false)
          setIsReplyAll(false)
        }}
        open={composeModal}
      />
    </div>
  )
}

export default CanvasInbox
