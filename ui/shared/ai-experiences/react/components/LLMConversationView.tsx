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

import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {IconAiLine} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {LLMConversationMessage, LLMConversationViewProps} from '../../types'

const I18n = createI18nScope('ai_experiences')

interface ContinueConversationResponse {
  messages: LLMConversationMessage[]
}

const LLMConversationView: React.FC<LLMConversationViewProps> = ({
  isOpen,
  onClose,
  returnFocusRef,
  courseId,
  aiExperienceId,
  aiExperienceTitle,
  facts,
  learningObjectives,
  scenario,
}) => {
  const [messages, setMessages] = useState<LLMConversationMessage[]>([])
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [isInitializing, setIsInitializing] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({behavior: 'smooth'})
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  useEffect(() => {
    if (isOpen && messages.length === 0) {
      initializeConversation()
    }
    // Focus the close button when the conversation is opened
    if (isOpen && closeButtonRef.current) {
      closeButtonRef.current.focus()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen])

  const initializeConversation = async () => {
    setIsInitializing(true)
    try {
      const {json} = await doFetchApi<ContinueConversationResponse>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/continue_conversation`,
        method: 'POST',
      })

      if (json?.messages) {
        setMessages(json.messages)
      }
    } catch (error) {
      console.error('Failed to initialize conversation:', error)
    } finally {
      setIsInitializing(false)
    }
  }

  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading) return

    const newUserMessage = inputValue
    const userMessage: LLMConversationMessage = {
      role: 'User',
      text: newUserMessage,
      timestamp: new Date(),
    }

    // Optimistically add user message to UI
    setMessages(prev => [...prev, userMessage])
    setInputValue('')
    setIsLoading(true)

    try {
      const {json} = await doFetchApi<ContinueConversationResponse>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/continue_conversation`,
        method: 'POST',
        body: {
          messages,
          new_user_message: newUserMessage,
        },
      })

      if (json?.messages) {
        setMessages(json.messages)
      }
    } catch (error) {
      console.error('Failed to send message:', error)
      // Remove the optimistically added message on error
      setMessages(prev => prev.slice(0, -1))
    } finally {
      setIsLoading(false)
    }
  }

  const handleKeyPress = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      handleSendMessage()
    }
  }

  const handleClose = () => {
    setMessages([])
    setInputValue('')
    onClose()
    // Return focus to the button that opened the conversation
    if (returnFocusRef?.current) {
      returnFocusRef.current.focus()
    }
  }

  if (!isOpen) return null

  return (
    <View
      as="div"
      padding="medium"
      background="transparent"
      borderWidth="small 0 0 0"
      shadow="above"
    >
      <Flex direction="column" gap="small">
        <Flex gap="small" alignItems="center" justifyItems="space-between">
          <Flex gap="small" alignItems="center">
            <IconAiLine />
            <Heading level="h3">{aiExperienceTitle || I18n.t('AI Experience')}</Heading>
          </Flex>
          <Button
            onClick={handleClose}
            size="small"
            elementRef={el => {
              if (el) {
                // @ts-expect-error - elementRef accepts Element but we need HTMLButtonElement for focus()
                closeButtonRef.current = el
              }
            }}
          >
            {I18n.t('Close and Reset')}
          </Button>
        </Flex>

        <View
          as="div"
          height="400px"
          overflowY="auto"
          padding="small"
          background="primary"
          borderRadius="medium"
        >
          {isInitializing ? (
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Spinner renderTitle={I18n.t('Initializing conversation...')} />
            </Flex>
          ) : (
            <>
              {messages.slice(1).map((message, index) => {
                const isUser = message.role === 'User'
                return (
                  <Flex key={index} justifyItems={isUser ? 'end' : 'start'} margin="small 0">
                    <View
                      as="div"
                      maxWidth="75%"
                      padding="small"
                      background={isUser ? 'brand' : 'secondary'}
                      borderRadius="medium"
                      shadow="resting"
                    >
                      <Text
                        weight="bold"
                        size="small"
                        color={isUser ? 'primary-inverse' : 'primary'}
                      >
                        {isUser ? I18n.t('You') : I18n.t('AI Assistant')}
                      </Text>
                      <View as="div" margin="xx-small 0 0 0">
                        <Text color={isUser ? 'primary-inverse' : 'primary'}>{message.text}</Text>
                      </View>
                    </View>
                  </Flex>
                )
              })}
              {isLoading && (
                <View as="div" margin="small 0" textAlign="center">
                  <Spinner renderTitle={I18n.t('Thinking...')} size="small" />
                </View>
              )}
              <div ref={messagesEndRef} />
            </>
          )}
        </View>

        <Flex gap="small">
          <Flex.Item shouldGrow shouldShrink>
            <TextArea
              label={I18n.t('Your message')}
              value={inputValue}
              onChange={e => setInputValue(e.target.value)}
              onKeyDown={handleKeyPress}
              placeholder={I18n.t('Type your message here...')}
              height="100px"
              disabled={isLoading || isInitializing}
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              onClick={handleSendMessage}
              color="primary"
              interaction={
                isLoading || isInitializing || !inputValue.trim() ? 'disabled' : 'enabled'
              }
            >
              {I18n.t('Send')}
            </Button>
          </Flex.Item>
        </Flex>
      </Flex>
    </View>
  )
}

export default LLMConversationView
