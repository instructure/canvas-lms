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

import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Tabs} from '@instructure/ui-tabs'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Pill} from '@instructure/ui-pill'
import {IconAiColoredSolid, IconFullScreenLine} from '@instructure/ui-icons'
import {AIExperience} from '../../types'
import {useStudentConversations, useConversationDetail} from '../hooks/useAIConversations'
import type {LLMConversationMessage} from '@canvas/ai-experiences/types'
import FocusMode from '@canvas/ai-experiences/react/components/FocusMode'

const I18n = createI18nScope('ai_experiences_ai_conversations')

interface AIConversationsPageProps {
  aiExperience: AIExperience
  courseId: string | number
}

const AIConversationsPage: React.FC<AIConversationsPageProps> = ({aiExperience, courseId}) => {
  const {conversations, isLoading: isLoadingConversations} = useStudentConversations(
    courseId,
    aiExperience.id,
  )

  // Get initial identifier from URL hash
  const getIdentifierFromHash = () => {
    const hash = window.location.hash.slice(1)
    return hash || undefined
  }

  const [selectedIdentifier, setSelectedIdentifier] = useState<string | undefined>(
    getIdentifierFromHash,
  )
  const [selectedTab, setSelectedTab] = useState<number>(0)
  const [isFocusModeOpen, setIsFocusModeOpen] = useState(false)

  // Find the selected student data and determine if they have a conversation
  const selectedStudentData = conversations.find(
    conv => (conv.id || `user_${conv.user_id}`) === selectedIdentifier,
  )
  const hasConversation = selectedStudentData?.has_conversation !== false
  const selectedConversationId = hasConversation ? selectedStudentData?.id : undefined

  const {conversation, isLoading: isLoadingConversation} = useConversationDetail(
    courseId,
    aiExperience.id,
    selectedConversationId || undefined,
  )

  // Update URL hash when student is selected
  const handleSelectStudent = (_event: React.SyntheticEvent, data: {value?: string | number}) => {
    const identifier = data.value as string
    setSelectedIdentifier(identifier)
    if (identifier) {
      window.location.hash = identifier
    } else {
      window.location.hash = ''
    }
  }

  // Listen for hash changes (back/forward navigation)
  useEffect(() => {
    const handleHashChange = () => {
      setSelectedIdentifier(getIdentifierFromHash())
    }

    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [])

  // Convert messages to LLMConversationMessage format
  const messages: LLMConversationMessage[] =
    conversation?.messages.map(msg => ({
      role: msg.role === 'assistant' || msg.role === 'Assistant' ? 'Assistant' : 'User',
      text: msg.content || msg.text || '',
      timestamp: msg.timestamp ? new Date(msg.timestamp) : new Date(),
    })) || []

  // Count messages by role (exclude first User message which is the trigger)
  const aiMessageCount = messages.filter(m => m.role === 'Assistant').length
  const studentMessageCount = Math.max(0, messages.filter(m => m.role === 'User').length - 1)

  const renderMessages = (inFocusMode = false) => {
    const messageContent = messages.slice(1).map((message, index) => {
      const isUser = message.role === 'User'
      return (
        <View key={index} as="div" margin="0 0 medium 0" textAlign={isUser ? 'end' : 'start'}>
          <View
            as="div"
            display="inline-block"
            maxWidth="70%"
            padding="small medium"
            background={isUser ? 'primary' : 'primary'}
            borderRadius="medium"
            textAlign="start"
          >
            <Text>{message.text}</Text>
          </View>
        </View>
      )
    })

    if (inFocusMode) {
      return (
        <View
          as="div"
          padding="medium"
          background="secondary"
          borderRadius="medium"
          overflowY="auto"
          style={{flex: 1, boxSizing: 'border-box'}}
        >
          {messageContent}
        </View>
      )
    }

    return (
      <View
        as="div"
        padding="medium"
        background="secondary"
        borderRadius="medium"
        height="calc(100vh - 400px)"
        overflowY="auto"
      >
        {messageContent}
      </View>
    )
  }

  return (
    <View as="div" margin="medium">
      <View as="div" margin="0 0 medium 0">
        <Flex alignItems="center" gap="small">
          <Flex.Item>
            <IconAiColoredSolid size="small" />
          </Flex.Item>
          <Flex.Item>
            <Heading level="h1">{I18n.t('AI Conversations')}</Heading>
          </Flex.Item>
        </Flex>
      </View>

      <Flex direction="column" height="100vh">
        <Flex.Item padding="0 0 medium 0">
          <SimpleSelect
            renderLabel={I18n.t('Student')}
            value={selectedIdentifier}
            onChange={handleSelectStudent}
            placeholder={I18n.t('Select a student')}
            disabled={isLoadingConversations}
          >
            {conversations.map(conv => {
              const identifier = conv.id || `user_${conv.user_id}`
              return (
                <SimpleSelect.Option key={identifier} id={identifier} value={identifier}>
                  {conv.student.name}
                </SimpleSelect.Option>
              )
            })}
          </SimpleSelect>
        </Flex.Item>

        {selectedIdentifier && !hasConversation && (
          <View as="div" padding="large" textAlign="center">
            <Text size="large" color="secondary">
              {I18n.t('This student has not started a conversation yet')}
            </Text>
          </View>
        )}

        {selectedIdentifier && hasConversation && conversation && (
          <>
            <Flex.Item padding="0 0 medium 0">
              <Flex gap="small" alignItems="center" justifyItems="space-between">
                <Flex gap="small" alignItems="center">
                  <Flex.Item>
                    <Text>
                      {I18n.t('%{count} Messages by AI', {count: aiMessageCount})} •{' '}
                      {I18n.t('%{count} Messages by student', {count: studentMessageCount})}
                    </Text>
                  </Flex.Item>
                  <Flex.Item>
                    <Pill>
                      {I18n.t('Last Updated %{date}', {
                        date: new Date(conversation.updated_at || '').toLocaleString(),
                      })}
                    </Pill>
                  </Flex.Item>
                </Flex>
                <Flex.Item>
                  <Button
                    data-testid="ai-conversations-focus-mode-button"
                    onClick={() => setIsFocusModeOpen(true)}
                    size="medium"
                    renderIcon={<IconFullScreenLine />}
                  >
                    {I18n.t('Focus Mode')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item shouldGrow shouldShrink>
              <Tabs onRequestTabChange={(_e, {index}) => setSelectedTab(index)}>
                <Tabs.Panel
                  id="conversation-tab"
                  renderTitle={I18n.t('Conversation')}
                  isSelected={selectedTab === 0}
                >
                  {isLoadingConversation ? (
                    <View as="div" padding="large" textAlign="center">
                      <Spinner renderTitle={I18n.t('Loading conversation')} />
                    </View>
                  ) : (
                    renderMessages()
                  )}
                </Tabs.Panel>

                <Tabs.Panel
                  id="ai-analysis-tab"
                  renderTitle={I18n.t('AI analysis')}
                  isSelected={selectedTab === 1}
                >
                  <View as="div" padding="large" textAlign="center">
                    <Text color="secondary">{I18n.t('AI analysis coming soon')}</Text>
                  </View>
                </Tabs.Panel>
              </Tabs>
            </Flex.Item>
          </>
        )}

        {!selectedIdentifier && (
          <View as="div" padding="large" textAlign="center">
            <Text size="large" color="secondary">
              {I18n.t('Select a student to view their conversation')}
            </Text>
          </View>
        )}
      </Flex>

      {/* Focus Mode */}
      {selectedIdentifier && hasConversation && conversation && (
        <FocusMode
          isOpen={isFocusModeOpen}
          onClose={() => setIsFocusModeOpen(false)}
          title={aiExperience.title}
        >
          <Flex direction="column" height="100%" style={{overflow: 'hidden'}}>
            <Flex.Item>
              <View as="div" margin="0 0 medium 0">
                <Flex gap="small" alignItems="center">
                  <Flex.Item>
                    <Text>
                      {I18n.t('%{count} Messages by AI', {count: aiMessageCount})} •{' '}
                      {I18n.t('%{count} Messages by student', {count: studentMessageCount})}
                    </Text>
                  </Flex.Item>
                  <Flex.Item>
                    <Pill>
                      {I18n.t('Last Updated %{date}', {
                        date: new Date(conversation.updated_at || '').toLocaleString(),
                      })}
                    </Pill>
                  </Flex.Item>
                </Flex>
              </View>
            </Flex.Item>

            <Flex.Item
              shouldGrow
              shouldShrink
              style={{display: 'flex', flexDirection: 'column', overflow: 'hidden'}}
            >
              <div style={{height: '100%', display: 'flex', flexDirection: 'column'}}>
                <Tabs
                  onRequestTabChange={(_e, {index}) => setSelectedTab(index)}
                  style={{height: '100%', display: 'flex', flexDirection: 'column'}}
                >
                  <Tabs.Panel
                    id="conversation-tab-focus"
                    renderTitle={I18n.t('Conversation')}
                    isSelected={selectedTab === 0}
                    style={{flex: '1 1 auto', display: 'flex', flexDirection: 'column'}}
                  >
                    {isLoadingConversation ? (
                      <Flex
                        as="div"
                        padding="large"
                        height="100%"
                        alignItems="center"
                        justifyItems="center"
                      >
                        <Spinner renderTitle={I18n.t('Loading conversation')} />
                      </Flex>
                    ) : (
                      renderMessages(true)
                    )}
                  </Tabs.Panel>

                  <Tabs.Panel
                    id="ai-analysis-tab-focus"
                    renderTitle={I18n.t('AI analysis')}
                    isSelected={selectedTab === 1}
                  >
                    <View as="div" padding="large" textAlign="center">
                      <Text color="secondary">{I18n.t('AI analysis coming soon')}</Text>
                    </View>
                  </Tabs.Panel>
                </Tabs>
              </div>
            </Flex.Item>
          </Flex>
        </FocusMode>
      )}
    </View>
  )
}

export default AIConversationsPage
