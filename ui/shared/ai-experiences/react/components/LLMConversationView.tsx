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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {LLMConversationMessage, LLMConversationViewProps} from '../../types'

const I18n = createI18nScope('ai_experiences')

interface ContinueConversationResponse {
  messages: LLMConversationMessage[]
}

const LLMConversationView: React.FC<LLMConversationViewProps> = ({
  isOpen,
  onClose: _onClose,
  returnFocusRef,
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
  const [lastMessageElement, setLastMessageElement] = useState<HTMLElement | null>(null)
  const [screenReaderAnnouncement, setScreenReaderAnnouncement] = useState('')
  const closeButtonRef = useRef<HTMLButtonElement>(null)
  const textAreaRef = useRef<HTMLTextAreaElement>(null)

  const scrollToLastMessage = () => {
    lastMessageElement?.scrollIntoView({behavior: 'smooth', block: 'start'})
  }

  useEffect(() => {
    scrollToLastMessage()
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

  // Announce new Assistant messages to screen readers
  useEffect(() => {
    if (messages.length === 0) return

    const lastMessage = messages[messages.length - 1]
    if (lastMessage?.role === 'Assistant' && !isLoading) {
      setScreenReaderAnnouncement(I18n.t('Assistant: %{message}', {message: lastMessage.text}))

      // Move focus to the last message briefly, then back to textarea
      if (lastMessageElement) {
        lastMessageElement.focus()
        setTimeout(() => {
          textAreaRef.current?.focus({preventScroll: true})
        }, 100)
      }
    }
  }, [messages, isLoading, lastMessageElement])

  // Announce loading states
  useEffect(() => {
    if (isLoading) {
      setScreenReaderAnnouncement(I18n.t('Assistant is thinking...'))
    }
  }, [isLoading])

  useEffect(() => {
    if (isInitializing) {
      setScreenReaderAnnouncement(I18n.t('Initializing conversation...'))
    }
  }, [isInitializing])

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
    // Focus textarea after restart
    setTimeout(() => {
      textAreaRef.current?.focus({preventScroll: true})
    }, 100)
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
        elementRef={(el: Element | null) => {
          if (el && returnFocusRef) {
            // @ts-expect-error - returnFocusRef expects HTMLElement but View gives Element
            returnFocusRef.current = el
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
      <div aria-live="polite" aria-atomic="true">
        <ScreenReaderContent>{screenReaderAnnouncement}</ScreenReaderContent>
      </div>
      {/* Preview header section */}
      <View as="div" padding="medium" background="primary" borderWidth="0 0 small 0">
        <Flex gap="small" alignItems="center" justifyItems="space-between">
          <Flex gap="small" alignItems="center">
            <IconButton
              onClick={() => {
                onToggleExpanded?.()
                setMessages([])
                setInputValue('')
                // Return focus to the element that opened the chat
                setTimeout(() => {
                  returnFocusRef?.current?.focus()
                }, 100)
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
        <View
          as="div"
          height="400px"
          overflowY="auto"
          margin="0 0 medium 0"
          role="log"
          aria-label={I18n.t('Conversation messages')}
        >
          {isInitializing ? (
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Spinner renderTitle={I18n.t('Initializing conversation...')} />
            </Flex>
          ) : (
            <>
              {messages.slice(1).map((message, index) => {
                const isUser = message.role === 'User'
                const isLastMessage = index === messages.slice(1).length - 1
                const isLastAssistantMessage = isLastMessage && !isUser
                return (
                  <Flex
                    key={index}
                    justifyItems={isUser ? 'end' : 'start'}
                    margin="small 0"
                    elementRef={
                      isLastMessage
                        ? (el: Element | null) => setLastMessageElement(el as HTMLElement)
                        : undefined
                    }
                  >
                    <Flex.Item shouldShrink overflowX="hidden" overflowY="hidden">
                      <View
                        as="div"
                        padding="small"
                        background={isUser ? 'primary' : undefined}
                        borderRadius="medium"
                        borderWidth={isUser ? 'small' : undefined}
                        role="article"
                        aria-label={
                          isUser ? I18n.t('Your message') : I18n.t('Message from Assistant')
                        }
                        tabIndex={isLastAssistantMessage ? -1 : undefined}
                        maxWidth="75%"
                      >
                        <Text>{message.text}</Text>
                      </View>
                    </Flex.Item>
                  </Flex>
                )
              })}
              {isLoading && (
                <View as="div" margin="small 0" textAlign="center">
                  <Spinner renderTitle={I18n.t('Thinking...')} size="small" />
                </View>
              )}
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
                textareaRef={(el: HTMLTextAreaElement | null) => {
                  ;(textAreaRef as React.MutableRefObject<HTMLTextAreaElement | null>).current = el
                }}
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
