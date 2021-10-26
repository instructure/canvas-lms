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

import {Conversation} from '../../../graphql/Conversation'
import {MessageDetailHeader} from '../../components/MessageDetailHeader/MessageDetailHeader'
import {MessageDetailItem} from '../../components/MessageDetailItem/MessageDetailItem'
import React from 'react'

import {View} from '@instructure/ui-view'

export const MessageDetailContainer = props => {
  return (
    <>
      <MessageDetailHeader text={props.conversation.subject} />
      {props.conversation.conversationMessagesConnection.nodes.map(message => (
        <View as="div" borderWidth="small none none none" padding="small">
          <MessageDetailItem
            key={message.id}
            conversationMessage={message}
            context={props.conversation.contextName}
          />
        </View>
      ))}
    </>
  )
}

MessageDetailContainer.propTypes = {
  conversation: Conversation.shape
}
