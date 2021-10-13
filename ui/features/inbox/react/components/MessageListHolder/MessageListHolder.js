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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import I18n from 'i18n!conversations_2'
import PropTypes from 'prop-types'
import React, {useEffect, useState, useContext} from 'react'
import {useMutation} from 'react-apollo'
import {View} from '@instructure/ui-view'

import {MessageListItem, conversationProp} from './MessageListItem'
import {UPDATE_CONVERSATION_PARTICIPANTS} from '../../../graphql/Mutations'

export const MessageListHolder = ({...props}) => {
  const [selectedMessages, setSelectedMessages] = useState([])
  const [rangeClickStart, setRangeClickStart] = useState()
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const provideConversationsForOnSelect = conversationIds => {
    const matchedConversations = props.conversations
      .filter(c => conversationIds.includes(c._id))
      .map(c => c.conversation)
    props.onSelect(matchedConversations)
  }

  /*
   * When conversations change, we need to re-provide the selectedConversations (CanvasInbox).
   * That way, other components have the latest state of the selected the conversations.
   * For example, MessageListActionContainer would have the correct actions.
   */
  useEffect(() => {
    provideConversationsForOnSelect(selectedMessages)
  }, [props.conversations])

  // Toggle function for adding/removing IDs from state
  const updatedSelectedItems = _id => {
    const updatedSelectedMessage = selectedMessages
    if (selectedMessages.includes(_id)) {
      const index = updatedSelectedMessage.indexOf(_id)
      updatedSelectedMessage.splice(index, 1)
    } else {
      updatedSelectedMessage.push(_id)
    }
    setSelectedMessages([...updatedSelectedMessage])
    provideConversationsForOnSelect([...updatedSelectedMessage])
  }

  // Key handler for MessageListItems
  const handleItemSelection = (e, _id, conversation, multiple) => {
    // Prevents selecting text when shift clicking to select range
    if (e.shiftKey) {
      window.document.getSelection().removeAllRanges()
    }

    if (e.shiftKey && rangeClickStart && multiple) {
      // Range Click
      rangeSelect(_id)
    } else if (multiple) {
      // MultiSelect
      setRangeClickStart(_id)
      updatedSelectedItems(_id)
    } else {
      // Single Select
      setRangeClickStart(_id)
      setSelectedMessages([_id])
      provideConversationsForOnSelect([_id])
    }
  }

  // Logic to select range of items
  const rangeSelect = rangeClickEnd => {
    let positionStart = null
    let positionEnd = null

    // Find position of start/ending messages
    for (let i = 0; i < props.conversations.length; i++) {
      const conversation = props.conversations[i]
      if (conversation._id === rangeClickStart) {
        positionStart = i
      } else if (conversation._id === rangeClickEnd) {
        positionEnd = i
      }

      if (positionStart !== null && positionEnd !== null) {
        break // Exit loop when both positions are found
      }
    }

    // Determine distance and direction of selection
    const direction = Math.sign(positionEnd - positionStart)
    const distance = Math.abs(positionStart - positionEnd) + 1

    // Walk array to add range selected ids
    const rangeSelectedIds = []
    for (let i = positionStart, j = distance; j > 0; i += direction, j--) {
      const conversation = props.conversations[i]
      rangeSelectedIds.push(conversation._id)
    }

    // Add newly selected Ids to list
    const updatedSelectedMessage = selectedMessages
    rangeSelectedIds.forEach(id => {
      if (!selectedMessages.includes(id)) {
        updatedSelectedMessage.push(id)
      }
    })
    setSelectedMessages([...updatedSelectedMessage])
    provideConversationsForOnSelect([...updatedSelectedMessage])
  }

  const [readStateChangeConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted(data) {
      if (data.updateConversationParticipants.errors) {
        setOnFailure(I18n.t('Read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Read state Changed!',
              other: 'Read states Changed!'
            },
            {count: '1000'}
          )
        )
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    }
  })

  return (
    <View
      as="div"
      maxWidth={400}
      height="100%"
      overflowX="hidden"
      overflowY="auto"
      borderWidth="small"
    >
      {props.conversations?.map(conversation => {
        return (
          <MessageListItem
            id={conversation._id}
            conversation={conversation.conversation}
            isStarred={conversation.label === 'starred'}
            isSelected={selectedMessages.includes(conversation._id)}
            isUnread={conversation.workflowState === 'unread'}
            onOpen={props.onOpen}
            onSelect={handleItemSelection}
            onStar={props.onStar}
            key={conversation._id}
            readStateChangeConversationParticipants={readStateChangeConversationParticipants}
          />
        )
      })}
    </View>
  )
}

const conversationParticipantsProp = PropTypes.shape({
  id: PropTypes.string,
  _id: PropTypes.string,
  workflowState: PropTypes.string,
  conversation: conversationProp,
  label: PropTypes.string
})

MessageListHolder.propTypes = {
  conversations: PropTypes.arrayOf(conversationParticipantsProp),
  id: PropTypes.string,
  onOpen: PropTypes.func,
  onSelect: PropTypes.func,
  onStar: PropTypes.func
}

MessageListHolder.defaultProps = {
  onOpen: () => {},
  onSelect: () => {},
  onStar: () => {}
}
