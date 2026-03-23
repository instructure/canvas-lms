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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import MessageFeedback from './MessageFeedback'
import type {LLMConversationMessage} from '../../types'

const I18n = createI18nScope('ai_experiences')

interface MessageThreadProps {
  messages: LLMConversationMessage[]
  conversationId: string | null
  courseId: string | number
  aiExperienceId: string | number
  isLoading?: boolean
  isInitializing?: boolean
  lastAssistantMessageRef?: React.MutableRefObject<HTMLElement | null>
  bottomRef?: React.MutableRefObject<HTMLDivElement | null>
}

const MessageThread = ({
  messages,
  conversationId,
  courseId,
  aiExperienceId,
  isLoading = false,
  isInitializing = false,
  lastAssistantMessageRef,
  bottomRef,
}: MessageThreadProps) => {
  if (isInitializing) {
    return (
      <Flex justifyItems="center" alignItems="center" height="100%">
        <Spinner renderTitle={I18n.t('Initializing conversation...')} />
      </Flex>
    )
  }

  const visibleMessages = messages.slice(1)

  return (
    <>
      {visibleMessages.map((message, index) => {
        const isUser = message.role === 'User'
        const isLastMessage = index === visibleMessages.length - 1
        const isLastAssistantMessage = isLastMessage && !isUser

        return (
          <View
            key={index}
            as="div"
            display="block"
            margin="small 0"
            textAlign={isUser ? 'end' : 'start'}
          >
            <View
              as="div"
              display="inline-block"
              maxWidth="70%"
              padding="small"
              background={isUser ? 'primary' : undefined}
              borderRadius="medium"
              borderWidth={isUser ? 'small' : undefined}
              role="article"
              aria-label={isUser ? I18n.t('Your message') : I18n.t('Message from Assistant')}
              tabIndex={isLastAssistantMessage ? -1 : undefined}
              textAlign="start"
              elementRef={
                isLastAssistantMessage && lastAssistantMessageRef
                  ? el => {
                      lastAssistantMessageRef.current = el as HTMLElement | null
                    }
                  : undefined
              }
            >
              <Text data-testid={`llm-conversation-message-${message.role}`}>
                <span style={{whiteSpace: 'pre-wrap'}}>{message.text}</span>
              </Text>
            </View>
            {!isUser && message.id && conversationId && (
              <MessageFeedback
                messageId={message.id}
                initialFeedback={message.feedback ?? []}
                courseId={courseId}
                aiExperienceId={String(aiExperienceId)}
                conversationId={conversationId}
              />
            )}
          </View>
        )
      })}
      {isLoading && (
        <View as="div" margin="small 0" textAlign="center">
          <Spinner renderTitle={I18n.t('Thinking...')} size="small" />
        </View>
      )}
      {bottomRef && <div ref={bottomRef} style={{height: '1rem'}} />}
    </>
  )
}

export default MessageThread
