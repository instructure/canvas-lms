/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {InstUISettingsProvider} from '@instructure/emotion'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Pill} from '@instructure/ui-pill'
import {
  IconFullScreenLine,
  IconArrowOpenStartLine,
  IconArrowOpenEndLine,
} from '@instructure/ui-icons'
import {AIExperience, LLMConversationMessage} from '../../types'
import {useStudentConversations, useConversationDetail} from '../hooks/useAIConversations'
import FocusMode from './FocusMode'
import MessageThread from './MessageThread'
import GradientBorder from './GradientBorder'
import ConversationHeader from './ConversationHeader'
import {roundedTheme, RADIUS_PILL, RADIUS_SM} from '../brand'

const I18n = createI18nScope('ai_experiences_ai_conversations')

const expandButtonTheme = {borderRadius: RADIUS_PILL, smallHeight: '1.75rem'}
const pillTextStyle: React.CSSProperties = {fontWeight: 'bold', color: '#000000'}
const navButtonTheme = {
  borderRadius: RADIUS_SM,
  secondaryBackground: '#ffffff',
  secondaryHoverBackground: '#f5f5f5',
  secondaryActiveBackground: '#ebebeb',
}

interface AIConversationsContainerProps {
  aiExperience: AIExperience
  courseId: string | number
}

const AIConversationsContainer: React.FC<AIConversationsContainerProps> = ({
  aiExperience,
  courseId,
}) => {
  const {conversations, isLoading: isLoadingConversations} = useStudentConversations(
    courseId,
    aiExperience.id,
  )

  const [selectedIdentifier, setSelectedIdentifier] = useState<string | undefined>(undefined)
  const [isFocusModeOpen, setIsFocusModeOpen] = useState(false)

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

  const currentIndex = conversations.findIndex(
    conv => (conv.id || `user_${conv.user_id}`) === selectedIdentifier,
  )
  const hasPrevious = currentIndex > 0
  const hasNext = currentIndex >= 0 && currentIndex < conversations.length - 1

  const handleSelectStudent = (_event: React.SyntheticEvent, data: {value?: string | number}) => {
    setSelectedIdentifier(data.value as string)
  }

  const handlePrevious = () => {
    if (hasPrevious) {
      const prev = conversations[currentIndex - 1]
      setSelectedIdentifier(prev.id || `user_${prev.user_id}`)
    }
  }

  const handleNext = () => {
    if (hasNext) {
      const next = conversations[currentIndex + 1]
      setSelectedIdentifier(next.id || `user_${next.user_id}`)
    }
  }

  useEffect(() => {
    if (conversations.length === 0 || selectedIdentifier) return

    const studentWithConversation = conversations.find(conv => Boolean(conv.id))
    const studentToSelect = studentWithConversation || conversations[0]

    if (studentToSelect) {
      setSelectedIdentifier(studentToSelect.id || `user_${studentToSelect.user_id}`)
    }
  }, [conversations, selectedIdentifier])

  const messages: LLMConversationMessage[] =
    conversation?.messages.map(msg => ({
      id: msg.id,
      role: msg.role.toLowerCase() === 'assistant' ? 'Assistant' : 'User',
      text: msg.content || msg.text || '',
      timestamp: msg.timestamp ? new Date(msg.timestamp) : new Date(),
      feedback: msg.feedback ?? [],
    })) || []

  const aiMessageCount = messages.filter(m => m.role === 'Assistant').length
  const studentMessageCount = Math.max(0, messages.filter(m => m.role === 'User').length - 1)

  const renderConversationMessages = () => {
    if (isLoadingConversation) {
      return (
        <View as="div" padding="large" textAlign="center">
          <Spinner renderTitle={I18n.t('Loading conversation')} />
        </View>
      )
    }
    return (
      <MessageThread
        messages={messages}
        conversationId={selectedConversationId ?? null}
        courseId={courseId}
        aiExperienceId={aiExperience.id}
      />
    )
  }

  return (
    <View as="div" margin="medium 0">
      {/* Filter row */}
      <Flex justifyItems="space-between" alignItems="end" margin="0 0 medium 0">
        <Flex.Item>
          <SimpleSelect
            key={`student-select-${conversations.length}`}
            renderLabel={I18n.t('Filter by student')}
            value={selectedIdentifier}
            onChange={handleSelectStudent}
            placeholder={I18n.t('Select a student')}
            disabled={isLoadingConversations}
          >
            {conversations.map(conv => {
              const identifier = conv.id || `user_${conv.user_id}`
              const hasConv = Boolean(conv.id)
              const displayName = hasConv
                ? `✓ ${conv.student.name}`
                : `${conv.student.name} (No conversation)`
              return (
                <SimpleSelect.Option
                  key={identifier}
                  id={identifier}
                  value={identifier}
                  isDisabled={!hasConv}
                >
                  {displayName}
                </SimpleSelect.Option>
              )
            })}
          </SimpleSelect>
        </Flex.Item>
        <Flex.Item>
          <Flex gap="small">
            <Button
              data-testid="ai-conversations-previous-button"
              onClick={handlePrevious}
              interaction={hasPrevious ? 'enabled' : 'disabled'}
              renderIcon={<IconArrowOpenStartLine size="x-small" />}
              themeOverride={navButtonTheme}
            >
              {I18n.t('Previous')}
            </Button>
            <Button
              data-testid="ai-conversations-next-button"
              onClick={handleNext}
              interaction={hasNext ? 'enabled' : 'disabled'}
              themeOverride={navButtonTheme}
            >
              <span style={{display: 'flex', alignItems: 'center', gap: '0.375rem'}}>
                {I18n.t('Next')}
                <IconArrowOpenEndLine size="x-small" />
              </span>
            </Button>
          </Flex>
        </Flex.Item>
      </Flex>

      {/* Student name heading */}
      {selectedStudentData && (
        <Heading level="h2" margin="0 0 small 0" data-testid="ai-conversations-student-heading">
          {selectedStudentData.student.name}
        </Heading>
      )}

      {/* Status pills */}
      {selectedIdentifier && hasConversation && conversation && (
        <Flex gap="small" margin="0 0 medium 0">
          <Flex.Item>
            <Pill color={conversation.workflow_state === 'completed' ? 'success' : 'info'}>
              <span style={pillTextStyle}>
                {conversation.workflow_state === 'completed'
                  ? I18n.t('Completed %{date}', {
                      date: new Date(conversation.updated_at || '').toLocaleString(),
                    })
                  : I18n.t('In progress')}
              </span>
            </Pill>
          </Flex.Item>
          <Flex.Item>
            <Pill>
              <span style={pillTextStyle}>
                {I18n.t('IgniteAI messages: %{count}', {count: aiMessageCount})}
              </span>
            </Pill>
          </Flex.Item>
          <Flex.Item>
            <Pill>
              <span style={pillTextStyle}>
                {I18n.t('Student messages: %{count}', {count: studentMessageCount})}
              </span>
            </Pill>
          </Flex.Item>
        </Flex>
      )}

      {/* No conversation state */}
      {selectedIdentifier && !hasConversation && (
        <View as="div" padding="large" textAlign="center">
          <Text size="large" color="secondary">
            {I18n.t('This student has not started a conversation yet')}
          </Text>
        </View>
      )}

      {/* Conversation card */}
      {selectedIdentifier && hasConversation && (
        <InstUISettingsProvider theme={roundedTheme}>
          <GradientBorder>
            <ConversationHeader
              action={
                <Button
                  data-testid="ai-conversations-expand-button"
                  onClick={() => setIsFocusModeOpen(true)}
                  size="small"
                  color="primary-inverse"
                  withBackground={false}
                  renderIcon={<IconFullScreenLine />}
                  themeOverride={expandButtonTheme}
                >
                  {I18n.t('Expand')}
                </Button>
              }
            />
            <View
              as="div"
              padding="medium"
              background="primary"
              maxHeight="calc(100vh - 510px)"
              overflowY="auto"
            >
              {renderConversationMessages()}
            </View>
          </GradientBorder>
        </InstUISettingsProvider>
      )}

      {/* Empty state */}
      {!selectedIdentifier && (
        <View as="div" padding="large" textAlign="center">
          <Text size="large" color="secondary">
            {I18n.t('Select a student to view their conversation')}
          </Text>
        </View>
      )}

      {/* Focus Mode */}
      {selectedIdentifier && hasConversation && conversation && (
        <FocusMode
          isOpen={isFocusModeOpen}
          onClose={() => setIsFocusModeOpen(false)}
          title={aiExperience.title}
        >
          <GradientBorder style={{height: '100%'}} fillHeight>
            <View as="div" overflowX="hidden" overflowY="hidden" height="100%">
              <Flex direction="column" height="100%">
                <Flex.Item>
                  <ConversationHeader />
                </Flex.Item>
                <Flex.Item
                  shouldGrow
                  shouldShrink
                  style={{display: 'flex', flexDirection: 'column', overflow: 'hidden'}}
                >
                  <View
                    as="div"
                    padding="medium"
                    background="primary"
                    height="100%"
                    overflowY="auto"
                    style={{boxSizing: 'border-box'}}
                  >
                    {renderConversationMessages()}
                  </View>
                </Flex.Item>
              </Flex>
            </View>
          </GradientBorder>
        </FocusMode>
      )}
    </View>
  )
}

export default AIConversationsContainer
