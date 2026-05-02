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

import React, {useState, useEffect, useRef, useCallback} from 'react'
import {InstUISettingsProvider} from '@instructure/emotion'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {Alert} from '@instructure/ui-alerts'
import {IconRefreshLine, IconFullScreenLine, IconAiSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {
  LLMConversationMessage,
  LLMConversationViewProps,
  ConversationProgress,
} from '../../types'
import ConversationHeader from './ConversationHeader'
import ConversationProgressComponent from './ConversationProgress'
import FocusMode from './FocusMode'
import GradientBorder from './GradientBorder'
import MessageThread from './MessageThread'
import {BRAND_GRADIENT, RADIUS_SM, RADIUS_PILL, navyButtonTheme, roundedTheme} from '../brand'

const I18n = createI18nScope('ai_experiences')

const expandButtonTheme = {borderRadius: RADIUS_PILL, smallHeight: '1.75rem'}
const sendButtonTheme = navyButtonTheme

const gradientTextStyle = {
  background: BRAND_GRADIENT,
  WebkitBackgroundClip: 'text' as const,
  WebkitTextFillColor: 'transparent' as const,
  backgroundClip: 'text' as const,
}

const gradientButtonWrapperStyle = {
  display: 'inline-block',
  background: BRAND_GRADIENT,
  borderRadius: RADIUS_SM,
}

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
  learningObjectives,
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
  const expandButtonRef = useRef<HTMLButtonElement | null>(null)
  const textAreaRef = useRef<HTMLTextAreaElement>(null)
  const normalModeMessagesContainerRef = useRef<HTMLDivElement | null>(null)
  const focusModeMessagesContainerRef = useRef<HTMLDivElement | null>(null)
  const normalModeBottomRef = useRef<HTMLDivElement | null>(null)
  const focusModeBottomRef = useRef<HTMLDivElement | null>(null)
  const hasInitializedRef = useRef(false)
  const messagesRef = useRef(messages)
  messagesRef.current = messages

  const initializeConversation = useCallback(async () => {
    setIsInitializing(true)
    setError(null)
    try {
      const {json: activeConversation} = await doFetchApi<ConversationResponse>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations`,
        method: 'GET',
      })

      if (activeConversation?.id && activeConversation?.messages) {
        setConversationId(activeConversation.id)
        setMessages(activeConversation.messages)
        setProgress(activeConversation.progress || null)
        setError(null)
      } else {
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
    } catch (_error) {
      setError(I18n.t('Failed to start conversation. Please try again.'))
    } finally {
      setIsInitializing(false)
    }
  }, [courseId, aiExperienceId])

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
    if (isOpen && isExpanded && messagesRef.current.length === 0) {
      initializeConversation()
    }
    if (isOpen && isExpanded && closeButtonRef.current) {
      closeButtonRef.current.focus()
    }
  }, [isOpen, isExpanded, initializeConversation])

  // Announce new Assistant messages to screen readers
  useEffect(() => {
    if (messages.length === 0) return

    const lastMessage = messages[messages.length - 1]
    if (lastMessage?.role === 'Assistant' && !isLoading) {
      setScreenReaderAnnouncement(I18n.t('Assistant: %{message}', {message: lastMessage.text}))
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
    textAreaRef.current?.focus()

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
    } catch (_error) {
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
    } catch (_error) {
      setError(I18n.t('Failed to restart conversation. Please try again.'))
      // Focus text input after error
      textAreaRef.current?.focus({preventScroll: true})
    } finally {
      setIsInitializing(false)
    }
  }

  const renderConversationContent = (_inFocusMode = false) => (
    <View as="div" padding="medium" background="primary">
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
        />
      </View>

      <GradientBorder>
        <div style={{padding: '0.75rem'}}>
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
                disabled={isInitializing}
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
                themeOverride={sendButtonTheme}
              >
                {I18n.t('Send')}
              </Button>
            </Flex.Item>
          </Flex>
        </div>
      </GradientBorder>
      <div ref={normalModeBottomRef} />
    </View>
  )

  if (!isOpen) return null

  // Collapsed state - preview card with gradient header and start chatting CTA
  if (!isExpanded) {
    const objectivesCount = learningObjectives?.split('\n').filter(Boolean).length ?? 0
    return (
      <InstUISettingsProvider theme={roundedTheme}>
        <div
          ref={(el: HTMLDivElement | null) => {
            if (el && returnFocusRef) returnFocusRef.current = el
          }}
        >
          <GradientBorder>
            <ConversationHeader />
            <View as="div" padding="x-large" background="primary" textAlign="center">
              <View as="div" margin="0 0 small 0">
                <Heading level="h3">
                  <span style={gradientTextStyle}>{I18n.t('Preview the chat')}</span>
                </Heading>
              </View>
              <View as="div" margin="0 0 medium 0">
                <Text>
                  {isTeacherPreview
                    ? I18n.t('Chat with the AI just like a learner')
                    : I18n.t(
                        'Show what you know. %{count} learning targets to complete this activity.',
                        {count: objectivesCount},
                      )}
                </Text>
              </View>
              <div style={gradientButtonWrapperStyle}>
                <Button
                  data-testid="llm-conversation-start-button"
                  onClick={onToggleExpanded}
                  color="primary-inverse"
                  withBackground={false}
                  themeOverride={{borderRadius: '0.5rem'}}
                >
                  <span style={{display: 'flex', alignItems: 'center', gap: '0.375rem'}}>
                    <IconAiSolid />
                    {I18n.t('Test as learner')}
                  </span>
                </Button>
              </div>
            </View>
          </GradientBorder>
        </div>
      </InstUISettingsProvider>
    )
  }

  // Expanded state - full conversation interface
  return (
    <InstUISettingsProvider theme={roundedTheme}>
      <GradientBorder>
        <div aria-live="polite" aria-atomic="true">
          <ScreenReaderContent>{screenReaderAnnouncement}</ScreenReaderContent>
        </div>
        <ConversationHeader
          action={
            <Button
              data-testid="llm-conversation-focus-mode-button"
              onClick={() => setIsFocusModeOpen(true)}
              size="small"
              color="primary-inverse"
              withBackground={false}
              renderIcon={<IconFullScreenLine />}
              themeOverride={expandButtonTheme}
              elementRef={(el: Element | null) => {
                expandButtonRef.current = el as HTMLButtonElement | null
              }}
            >
              {I18n.t('Expand')}
            </Button>
          }
        />
        {/* Progress bar row — white background */}
        <View as="div" padding="small medium" background="primary" borderWidth="0 0 small 0">
          <Flex gap="small" alignItems="center">
            {progress && (
              <Flex.Item shouldGrow shouldShrink>
                <ConversationProgressComponent progress={progress} />
              </Flex.Item>
            )}
            <Flex.Item>
              <Button data-testid="llm-conversation-restart-button" onClick={handleRestart}>
                {I18n.t('Reset')}
              </Button>
            </Flex.Item>
          </Flex>
        </View>

        {/* Chat conversation section */}
        {renderConversationContent()}

        {/* Focus Mode */}
        <FocusMode
          isOpen={isFocusModeOpen}
          onClose={() => {
            setIsFocusModeOpen(false)
            setTimeout(() => expandButtonRef.current?.focus(), 0)
          }}
          title={aiExperienceTitle}
        >
          <GradientBorder style={{height: '100%'}} fillHeight>
            <View
              as="div"
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
                  <ConversationHeader
                    action={
                      <Button
                        data-testid="llm-conversation-restart-button-focus"
                        onClick={handleRestart}
                        size="small"
                        color="primary-inverse"
                        withBackground={false}
                        renderIcon={<IconRefreshLine />}
                        themeOverride={expandButtonTheme}
                      >
                        {I18n.t('Reset')}
                      </Button>
                    }
                  />
                  {progress && (
                    <View
                      as="div"
                      padding="small medium"
                      background="primary"
                      borderWidth="0 0 small 0"
                    >
                      <ConversationProgressComponent progress={progress} />
                    </View>
                  )}
                </Flex.Item>
                {/* Conversation content in focus mode */}
                <Flex.Item
                  shouldGrow
                  shouldShrink
                  style={{display: 'flex', flexDirection: 'column'}}
                >
                  <View
                    as="div"
                    padding="medium"
                    background="primary"
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
                        style={{
                          flex: 1,
                          overflowY: 'auto',
                          marginBottom: '1rem',
                          padding: '0.5rem',
                        }}
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
                          bottomRef={focusModeBottomRef}
                        />
                      </div>
                      <GradientBorder>
                        <div style={{padding: '0.75rem'}}>
                          <div style={{marginBottom: '0.75rem'}}>
                            <Text weight="bold" size="small">
                              {I18n.t('Message')}
                            </Text>
                          </div>
                          <Flex gap="small" alignItems="center">
                            <Flex.Item shouldGrow shouldShrink>
                              <TextArea
                                data-testid="llm-conversation-message-input"
                                label={
                                  <span style={{display: 'none'}}>{I18n.t('Your answer...')}</span>
                                }
                                value={inputValue}
                                onChange={e => setInputValue(e.target.value)}
                                onKeyDown={handleKeyPress}
                                placeholder={I18n.t('Your answer...')}
                                height="60px"
                                disabled={isInitializing}
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
                                themeOverride={sendButtonTheme}
                              >
                                {I18n.t('Send')}
                              </Button>
                            </Flex.Item>
                          </Flex>
                        </div>
                      </GradientBorder>
                    </div>
                  </View>
                </Flex.Item>
              </Flex>
            </View>
          </GradientBorder>
        </FocusMode>
      </GradientBorder>
    </InstUISettingsProvider>
  )
}

export default LLMConversationView
