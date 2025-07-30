/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import TopNavPortal from '@canvas/top-navigation/react/TopNavPortal'
import {Heading} from '@instructure/ui-heading'
import Message from './Message'

export type MessageDataSet = {
  element: HTMLElement
  messageId: string
  secureId: string
  workflowState: string
  subject: string
}

const I18n = createI18nScope('messages')

// Pull out each message rendered in the DOM by the ERB, remove them
// from the DOM, and then render them in React. We can do this once
// at module load time because the ERB-rendered elements are static.
const messagesInDOM = document.querySelectorAll('#content .message')
const messageData: MessageDataSet[] = Array.from(messagesInDOM).map(message => {
  const element = message as HTMLElement
  element.remove()
  const {messageId, secureId, workflowState, subject} = element.dataset as unknown as MessageDataSet
  return {element, messageId, secureId, workflowState, subject}
})

export interface MessagesProps {
  userId: string
  userName: string
}

export function Messages({userId, userName}: MessagesProps): JSX.Element {
  return (
    <>
      <TopNavPortal />
      <Heading variant="titlePageDesktop">{I18n.t('Messages for %{userName}', {userName})}</Heading>
      {messageData.map(msg => (
        <Message key={msg.messageId} userId={userId} {...msg} />
      ))}
    </>
  )
}
