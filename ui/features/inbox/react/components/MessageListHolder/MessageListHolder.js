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

import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {View} from '@instructure/ui-view'

import {MessageListItem, conversationProp} from './MessageListItem'

export const MessageListHolder = ({...props}) => {
  const [selectedMessages, setSelectedMessages] = useState([])
  const [rangeClickStart, setRangeClickStart] = useState()

  const provideConversationsForOnSelect = conversationIds => {
    const matchedConversations = props.conversations.filter(c => conversationIds.includes(c._id))
    props.onSelect(matchedConversations)
  }

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
          />
        )
      })}
    </View>
  )
}

const conversationParticipantsProp = PropTypes.shape({
  id: PropTypes.string,
  workflowState: PropTypes.string,
  conversation: conversationProp
})

MessageListHolder.propTypes = {
  conversations: PropTypes.arrayOf(conversationParticipantsProp),
  id: PropTypes.number,
  onOpen: PropTypes.func,
  onSelect: PropTypes.func,
  onStar: PropTypes.func
}

MessageListHolder.defaultProps = {
  onOpen: () => {},
  onSelect: () => {},
  onStar: () => {}
}
