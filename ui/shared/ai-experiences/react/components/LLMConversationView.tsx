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
import {Alert} from '@instructure/ui-alerts'
import {IconPlayLine, IconXLine, IconRefreshLine, IconFullScreenLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {
  LLMConversationMessage,
  LLMConversationViewProps,
  ConversationProgress,
} from '../../types'
import ConversationProgressComponent from './ConversationProgress'
import FocusMode from './FocusMode'
import MessageThread from './MessageThread'

const I18n = createI18nScope('ai_experiences')

interface ConversationResponse {
  id: string
  messages: LLMConversationMessage[]
  progress?: ConversationProgress
}

const LLMConversationView: React.FC<LLMConversationViewProps> = ({
  isOpen,
  onClose: _onClose,
  returnFocusRef,
  courseId,
  aiExperienceId,
  aiExperienceTitle,
  facts: _facts,
  learningObjectives: _learningObjectives,
  scenario: _scenario,
  isExpanded = false,
  onToggleExpanded,
  isTeacherPreview = false,
}) => {
  const [messages, setMessages] = useState<LLMConversationMessage[]>([])
  const [conversationId, setConversationId] = useState<string | null>(null)
  const [progress, setProgress] = useState<ConversationProgress | null>(null)
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [isInitializing, setIsInitializing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [screenReaderAnnouncement, setScreenReaderAnnouncement] = useState('')
  const [isFocusModeOpen, setIsFocusModeOpen] = useState(false)
  const closeButtonRef = useRef<HTMLButtonElement>(null)
  const textAreaRef = useRef<HTMLTextAreaElement>(null)
  const normalModeMessagesContainerRef = useRef<HTMLDivElement | null>(null)
  const focusModeMessagesContainerRef = useRef<HTMLDivElement | null>(null)
  const normalModeBottomRef = useRef<HTMLDivElement | null>(null)
  const focusModeBottomRef = useRef<HTMLDivElement | null>(null)
  const hasInitializedRef = useRef(false)
  const lastAssistantMessageRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    // Reset on new initialization so instant-scroll applies again after restart
    if (isInitializing) {
      hasInitializedRef.current = false
    }
    const bottomRef = isFocusModeOpen ? focusModeBottomRef : normalModeBottomRef
    // Use instant on initial load so buttons are fully in view immediately;
    // use smooth for subsequent messages to preserve the original UX.
    const behavior = hasInitializedRef.current ? 'smooth' : 'instant'
    if (!isInitializing) {
      hasInitializedRef.current = true
    }
    bottomRef.current?.scrollIntoView({behavior, block: 'end'})
  }, [messages, isLoading, isFocusModeOpen, isInitializing])

  useEffect(() => {
    if (isOpen && isExpanded && messages.length === 0) {
      // Backend will check for existing conversation automatically
      initializeConversation()
    }
    // Focus the close button when the conversation is expanded
    if (isOpen && isExpanded && closeButtonRef.current) {
      closeButtonRef.current.focus()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, isExpanded])

  // Announce new Assistant messages to screen readers and focus text input
  useEffect(() => {
    if (messages.length === 0) return

    const lastMessage = messages[messages.length - 1]
    if (lastMessage?.role === 'Assistant' && !isLoading) {
      setScreenReaderAnnouncement(I18n.t('Assistant: %{message}', {message: lastMessage.text}))
      // Only move focus if the user isn't already focused on another interactive
      // element (e.g. the feedback form textarea or a button)
      const active = document.activeElement
      const isFocusIdle = !active || active === document.body || active === textAreaRef.current
      if (isFocusIdle) {
        // Focus the message bubble so keyboard/SR users can read it and Tab
        // naturally to the Like/Dislike buttons, then the message input
        lastAssistantMessageRef.current?.focus({preventScroll: true})
      }
    }
  }, [messages, isLoading])

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
    setError(null)
    try {
      // First, check if there's an active conversation
      const {json: activeConversation} = await doFetchApi<ConversationResponse>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations`,
        method: 'GET',
      })

      // If active conversation exists, use it
      if (activeConversation?.id && activeConversation?.messages) {
        setConversationId(activeConversation.id)
        setMessages(activeConversation.messages)
        setProgress(activeConversation.progress || null)
        setError(null)
      } else {
        // No active conversation, create a new one
        const {json: newConversation} = await doFetchApi<ConversationResponse>({
          path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations`,
          method: 'POST',
        })

        if (newConversation?.id && newConversation?.messages) {
          setConversationId(newConversation.id)
          setMessages(newConversation.messages)
          setProgress(newConversation.progress || null)
          setError(null)
        }
      }
    } catch (error) {
      setError(I18n.t('Failed to start conversation. Please try again.'))
    } finally {
      setIsInitializing(false)
    }
  }

  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading || !conversationId) return

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
    setError(null)

    try {
      const {json} = await doFetchApi<ConversationResponse>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations/${conversationId}/messages`,
        method: 'POST',
        body: {
          message: newUserMessage,
        },
      })

      if (json?.messages) {
        setMessages(json.messages)
        setProgress(json.progress || null)
        setError(null)
      }
    } catch (error) {
      setError(I18n.t('Failed to send message. Please try again.'))
      // Remove the optimistically added message on error
      setMessages(prev => prev.slice(0, -1))
      // Focus text input after error
      textAreaRef.current?.focus({preventScroll: true})
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

  const handleRestart = async () => {
    setMessages([])
    setInputValue('')
    setIsInitializing(true)
    setError(null)

    try {
      // Create a new conversation (server will automatically complete any existing active conversation)
      const {json, response} = await doFetchApi<ConversationResponse>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations`,
        method: 'POST',
      })

      if (!response?.ok) {
        setError(I18n.t('Failed to restart conversation. Please try again.'))
        return
      }

      if (json?.id && json?.messages) {
        setConversationId(json.id)
        setMessages(json.messages)
        setProgress(json.progress || null)
        setError(null)
      }
    } catch (error) {
      setError(I18n.t('Failed to restart conversation. Please try again.'))
      // Focus text input after error
      textAreaRef.current?.focus({preventScroll: true})
    } finally {
      setIsInitializing(false)
    }
  }

  const renderConversationContent = (inFocusMode = false) => (
    <View as="div" padding="medium" background="secondary">
      {error && (
        <Alert
          variant="error"
          margin="0 0 small 0"
          renderCloseButtonLabel={I18n.t('Close')}
          onDismiss={() => setError(null)}
        >
          {error}
        </Alert>
      )}
      <View
        as="div"
        margin="0 0 medium 0"
        padding="xx-small"
        role="log"
        aria-label={I18n.t('Conversation messages')}
        elementRef={el => {
          normalModeMessagesContainerRef.current = el as HTMLDivElement | null
        }}
      >
        <MessageThread
          messages={messages}
          conversationId={conversationId}
          courseId={courseId ?? ''}
          aiExperienceId={aiExperienceId ?? ''}
          isLoading={isLoading}
          isInitializing={isInitializing}
          lastAssistantMessageRef={lastAssistantMessageRef}
          bottomRef={normalModeBottomRef}
        />
      </View>

      <View as="div" padding="small" background="primary" borderWidth="small" borderRadius="medium">
        <div style={{marginBottom: '0.75rem'}}>
          <Text weight="bold" size="small">
            {I18n.t('Message')}
          </Text>
        </div>
        <Flex gap="small" alignItems="center">
          <Flex.Item shouldGrow shouldShrink>
            <TextArea
              data-testid="llm-conversation-message-input"
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
              data-testid="llm-conversation-send-message-button"
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
  )

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
        <Flex gap="small" alignItems="center" justifyItems="space-between">
          <Flex gap="small" alignItems="center">
            <IconPlayLine size="small" />
            <View>
              <Heading level="h3" margin="0 0 xx-small 0">
                {isTeacherPreview ? I18n.t('Preview') : I18n.t('Conversation')}
              </Heading>
              <Text size="small">
                {isTeacherPreview
                  ? I18n.t('Here, you can have a chat with the AI just like a student would.')
                  : I18n.t('Start the experience by having a conversation with the AI. Good luck!')}
              </Text>
            </View>
          </Flex>
          {progress && (
            <View as="div" minWidth="200px">
              <ConversationProgressComponent progress={progress} />
            </View>
          )}
        </Flex>
      </View>
    )
  }

  // Expanded state - full conversation interface
  return (
    <View as="div" borderWidth="small" borderRadius="medium" overflowX="hidden">
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
                returnFocusRef?.current?.focus()
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
              data-testid="llm-conversation-close-preview-button"
            >
              <IconXLine />
            </IconButton>
            <View>
              <Heading level="h3" margin="0 0 xx-small 0">
                {isTeacherPreview ? I18n.t('Preview') : I18n.t('Conversation')}
              </Heading>
              <Text size="small">
                {isTeacherPreview
                  ? I18n.t('Here, you can have a chat with the AI just like a student would.')
                  : I18n.t('Start the experience by having a conversation with the AI. Good luck!')}
              </Text>
            </View>
          </Flex>
          <Flex gap="small">
            <Button
              data-testid="llm-conversation-focus-mode-button"
              onClick={() => setIsFocusModeOpen(true)}
              size="medium"
              renderIcon={<IconFullScreenLine />}
            >
              {I18n.t('Focus Mode')}
            </Button>
            <Button
              data-testid="llm-conversation-restart-button"
              onClick={handleRestart}
              size="medium"
              renderIcon={<IconRefreshLine />}
            >
              {I18n.t('Restart')}
            </Button>
          </Flex>
        </Flex>
        {progress && (
          <View as="div" margin="small 0 0 0">
            <ConversationProgressComponent progress={progress} />
          </View>
        )}
      </View>

      {/* Chat conversation section */}
      {renderConversationContent()}

      {/* Focus Mode */}
      <FocusMode
        isOpen={isFocusModeOpen}
        onClose={() => setIsFocusModeOpen(false)}
        title={aiExperienceTitle}
      >
        <View
          as="div"
          borderWidth="small"
          borderRadius="medium"
          overflowX="hidden"
          overflowY="hidden"
          height="100%"
          elementRef={(el: Element | null) => {
            if (el) {
              ;(el as HTMLElement).style.outline = 'none'
            }
          }}
        >
          <div aria-live="polite" aria-atomic="true">
            <ScreenReaderContent>{screenReaderAnnouncement}</ScreenReaderContent>
          </div>
          <Flex direction="column" height="100%">
            {/* Preview header section in focus mode */}
            <Flex.Item>
              <View as="div" padding="medium" background="primary" borderWidth="0 0 small 0">
                <Flex gap="small" alignItems="center" justifyItems="space-between">
                  <Flex gap="small" alignItems="center">
                    <View>
                      <Heading level="h3" margin="0 0 xx-small 0">
                        {isTeacherPreview ? I18n.t('Preview') : I18n.t('Conversation')}
                      </Heading>
                      <Text size="small">
                        {isTeacherPreview
                          ? I18n.t(
                              'Here, you can have a chat with the AI just like a student would.',
                            )
                          : I18n.t(
                              'Start the experience by having a conversation with the AI. Good luck!',
                            )}
                      </Text>
                    </View>
                  </Flex>
                  <Button
                    data-testid="llm-conversation-restart-button-focus"
                    onClick={handleRestart}
                    size="medium"
                    renderIcon={<IconRefreshLine />}
                  >
                    {I18n.t('Restart')}
                  </Button>
                </Flex>
                {progress && (
                  <View as="div" margin="small 0 0 0">
                    <ConversationProgressComponent progress={progress} />
                  </View>
                )}
              </View>
            </Flex.Item>
            {/* Conversation content in focus mode */}
            <Flex.Item shouldGrow shouldShrink style={{display: 'flex', flexDirection: 'column'}}>
              <View
                as="div"
                padding="medium"
                background="secondary"
                height="100%"
                style={{boxSizing: 'border-box'}}
              >
                {error && (
                  <Alert
                    variant="error"
                    margin="0 0 small 0"
                    renderCloseButtonLabel={I18n.t('Close')}
                    onDismiss={() => setError(null)}
                  >
                    {error}
                  </Alert>
                )}
                <div style={{display: 'flex', flexDirection: 'column', height: '100%'}}>
                  <div
                    style={{flex: 1, overflowY: 'auto', marginBottom: '1rem', padding: '0.5rem'}}
                    role="log"
                    aria-label={I18n.t('Conversation messages')}
                    ref={el => {
                      focusModeMessagesContainerRef.current = el as HTMLDivElement | null
                    }}
                  >
                    <MessageThread
                      messages={messages}
                      conversationId={conversationId}
                      courseId={courseId ?? ''}
                      aiExperienceId={aiExperienceId ?? ''}
                      isLoading={isLoading}
                      isInitializing={isInitializing}
                      lastAssistantMessageRef={lastAssistantMessageRef}
                      bottomRef={focusModeBottomRef}
                    />
                  </div>
                  <div
                    style={{
                      padding: '0.75rem',
                      backgroundColor: 'white',
                      border: '1px solid #C7CDD1',
                      borderRadius: '0.5rem',
                    }}
                  >
                    <div style={{marginBottom: '0.75rem'}}>
                      <Text weight="bold" size="small">
                        {I18n.t('Message')}
                      </Text>
                    </div>
                    <Flex gap="small" alignItems="center">
                      <Flex.Item shouldGrow shouldShrink>
                        <TextArea
                          data-testid="llm-conversation-message-input"
                          label={<span style={{display: 'none'}}>{I18n.t('Your answer...')}</span>}
                          value={inputValue}
                          onChange={e => setInputValue(e.target.value)}
                          onKeyDown={handleKeyPress}
                          placeholder={I18n.t('Your answer...')}
                          height="60px"
                          disabled={isLoading || isInitializing}
                          textareaRef={(el: HTMLTextAreaElement | null) => {
                            ;(
                              textAreaRef as React.MutableRefObject<HTMLTextAreaElement | null>
                            ).current = el
                          }}
                        />
                      </Flex.Item>
                      <Flex.Item>
                        <Button
                          data-testid="llm-conversation-send-message-button"
                          onClick={handleSendMessage}
                          color="primary"
                          interaction={
                            isLoading || isInitializing || !inputValue.trim()
                              ? 'disabled'
                              : 'enabled'
                          }
                        >
                          {I18n.t('Send')}
                        </Button>
                      </Flex.Item>
                    </Flex>
                  </div>
                </div>
              </View>
            </Flex.Item>
          </Flex>
        </View>
      </FocusMode>
    </View>
  )
}

export default LLMConversationView
