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
import {Button, IconButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {IconPlayLine, IconXLine, IconRefreshLine} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {LLMConversationMessage, LLMConversationViewProps} from '../../types'

const I18n = createI18nScope('ai_experiences')

interface ContinueConversationResponse {
  messages: LLMConversationMessage[]
}

const LLMConversationView: React.FC<LLMConversationViewProps> = ({
  isOpen,
  onClose: _onClose,
  returnFocusRef: _returnFocusRef,
  courseId,
  aiExperienceId,
  aiExperienceTitle: _aiExperienceTitle,
  facts: _facts,
  learningObjectives: _learningObjectives,
  scenario: _scenario,
  isExpanded = false,
  onToggleExpanded,
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
    if (isOpen && isExpanded && messages.length === 0) {
      initializeConversation()
    }
    // Focus the close button when the conversation is expanded
    if (isOpen && isExpanded && closeButtonRef.current) {
      closeButtonRef.current.focus()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, isExpanded])

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

  const handleRestart = () => {
    setMessages([])
    setInputValue('')
    initializeConversation()
  }

  if (!isOpen) return null

  // Collapsed state - clickable preview card
  if (!isExpanded) {
    return (
      <View
        as="div"
        padding="medium"
        background="primary"
        borderWidth="small"
        borderRadius="medium"
        cursor="pointer"
        onClick={onToggleExpanded}
        role="button"
        tabIndex={0}
        onKeyDown={e => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault()
            onToggleExpanded?.()
          }
        }}
      >
        <Flex gap="small" alignItems="center">
          <IconPlayLine size="small" />
          <View>
            <Heading level="h3" margin="0 0 xx-small 0">
              {I18n.t('Preview')}
            </Heading>
            <Text size="small">
              {I18n.t('Here, you can have a chat with the AI just like a student would.')}
            </Text>
          </View>
        </Flex>
      </View>
    )
  }

  // Expanded state - full conversation interface
  return (
    <View as="div" borderWidth="small" borderRadius="medium" overflowX="hidden" overflowY="hidden">
      {/* Preview header section */}
      <View as="div" padding="medium" background="primary" borderWidth="0 0 small 0">
        <Flex gap="small" alignItems="center" justifyItems="space-between">
          <Flex gap="small" alignItems="center">
            <IconButton
              onClick={() => {
                onToggleExpanded?.()
                setMessages([])
                setInputValue('')
              }}
              size="small"
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('Close preview')}
              elementRef={el => {
                if (el) {
                  // @ts-expect-error - elementRef accepts Element but we need HTMLButtonElement for focus()
                  closeButtonRef.current = el
                }
              }}
            >
              <IconXLine />
            </IconButton>
            <View>
              <Heading level="h3" margin="0 0 xx-small 0">
                {I18n.t('Preview')}
              </Heading>
              <Text size="small">
                {I18n.t('Here, you can have a chat with the AI just like a student would.')}
              </Text>
            </View>
          </Flex>
          <Button onClick={handleRestart} size="medium" renderIcon={<IconRefreshLine />}>
            {I18n.t('Restart')}
          </Button>
        </Flex>
      </View>

      {/* Chat conversation section */}
      <View as="div" padding="medium" background="secondary">
        <View as="div" height="400px" overflowY="auto" margin="0 0 medium 0">
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
                      background={isUser ? 'primary' : undefined}
                      borderRadius="medium"
                      borderWidth={isUser ? 'small' : undefined}
                    >
                      <Text>{message.text}</Text>
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

        {/* Message input section */}
        <View
          as="div"
          padding="small"
          background="primary"
          borderWidth="small"
          borderRadius="medium"
        >
          <div style={{marginBottom: '0.75rem'}}>
            <Text weight="bold" size="small">
              {I18n.t('Message box')}
            </Text>
          </div>
          <Flex gap="small" alignItems="center">
            <Flex.Item shouldGrow shouldShrink>
              <TextArea
                label={<span style={{display: 'none'}}>{I18n.t('Your answer...')}</span>}
                value={inputValue}
                onChange={e => setInputValue(e.target.value)}
                onKeyDown={handleKeyPress}
                placeholder={I18n.t('Your answer...')}
                height="60px"
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
        </View>
      </View>
    </View>
  )
}

export default LLMConversationView
