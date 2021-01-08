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
import React from 'react'
import {View} from '@instructure/ui-view'

import {MessageListItem, conversationProp} from './MessageListItem'

export const MessageListHolder = ({...props}) => {
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
            conversation={conversation.conversation}
            isStarred={conversation.label === 'starred'}
            isUnread={conversation.workflowState === 'unread'}
            onOpen={props.onOpen}
            onSelect={props.onSelect}
            onStar={props.onStar}
            key={conversation.id}
          />
        )
      })}
    </View>
  )
}

const conversationParticipantsProp = PropTypes.shape({
  id: PropTypes.number,
  workflowState: PropTypes.string,
  conversation: conversationProp
})

MessageListHolder.propTypes = {
  conversations: PropTypes.arrayOf(conversationParticipantsProp),
  onOpen: PropTypes.func,
  onSelect: PropTypes.func,
  onStar: PropTypes.func
}
