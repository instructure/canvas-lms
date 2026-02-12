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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Tabs} from '@instructure/ui-tabs'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {useConversationDetail} from '../hooks/useAIConversations'
import {useConversationEvaluation} from '../hooks/useConversationEvaluation'
import type {LLMConversationMessage, ConversationProgress} from '@canvas/ai-experiences/types'
import {AIAnalysisTab} from './AIAnalysisTab'

const I18n = createI18nScope('ai_experiences_ai_conversations')

interface ConversationPanelProps {
  conversationId?: string
  courseId: string | number
  aiExperienceId: string | number
}

interface MessageListProps {
  messages: LLMConversationMessage[]
  progress?: ConversationProgress | null
  isLoading: boolean
}

const MessageList: React.FC<MessageListProps> = ({messages, progress, isLoading}) => {
  if (isLoading) {
    return (
      <View as="div" padding="large" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading conversation')} />
      </View>
    )
  }

  if (messages.length === 0) {
    return (
      <View as="div" padding="large">
        <Text>{I18n.t('No messages in this conversation')}</Text>
      </View>
    )
  }

  return (
    <View as="div" padding="medium">
      {messages.slice(1).map((message, index) => {
        const isUser = message.role === 'User'

        return (
          <View
            key={index}
            as="div"
            margin="0 0 medium 0"
            textAlign={isUser ? 'end' : 'start'}
            data-testid={`llm-conversation-message-${message.role}`}
          >
            <View
              as="div"
              display="inline-block"
              maxWidth="70%"
              padding="small"
              background={isUser ? 'primary' : undefined}
              borderRadius="medium"
              borderWidth={isUser ? 'small' : undefined}
              textAlign="start"
            >
              <Text>
                <span style={{whiteSpace: 'pre-wrap'}}>{message.text}</span>
              </Text>
            </View>
          </View>
        )
      })}
    </View>
  )
}

const ConversationPanel: React.FC<ConversationPanelProps> = ({
  conversationId,
  courseId,
  aiExperienceId,
}) => {
  const {conversation, isLoading, error} = useConversationDetail(
    courseId,
    aiExperienceId,
    conversationId,
  )
  const [selectedTab, setSelectedTab] = useState<number>(0)
  const [messages, setMessages] = useState<LLMConversationMessage[]>([])
  const [progress, setProgress] = useState<ConversationProgress | null>(null)

  // Check if evaluation feature is enabled
  const isEvaluationEnabled = window.ENV.ai_experiences_evaluation_enabled

  // Evaluation hook for AI analysis tab
  const {
    evaluation,
    isLoading: isLoadingEvaluation,
    error: evaluationError,
    fetchEvaluation,
  } = useConversationEvaluation(courseId, aiExperienceId, conversationId)

  useEffect(() => {
    if (conversation?.messages) {
      // Convert backend messages to LLMConversationMessage format
      const convertedMessages: LLMConversationMessage[] = conversation.messages.map(msg => ({
        role: msg.role === 'assistant' ? 'Assistant' : 'User',
        text: msg.content || '',
        timestamp: new Date(),
      }))
      setMessages(convertedMessages)
      // Type guard for progress object
      const prog = conversation.progress
      if (prog && typeof prog === 'object' && 'status' in prog) {
        setProgress(prog as unknown as ConversationProgress)
      } else {
        setProgress(null)
      }
    }
  }, [conversation])

  if (!conversationId) {
    return (
      <View as="div" padding="large" textAlign="center" height="100vh">
        <View as="div" margin="large 0 0 0">
          <Text size="large" color="secondary">
            {I18n.t('Select a student to view their conversation')}
          </Text>
        </View>
      </View>
    )
  }

  if (error) {
    return (
      <View as="div" padding="large">
        <Text color="danger">{I18n.t('Error loading conversation')}</Text>
      </View>
    )
  }

  return (
    <Flex as="div" height="100%" direction="column">
      <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="auto">
        <View as="div" borderWidth="0 0 small 0" padding="medium">
          <Tabs onRequestTabChange={(_e, {index}) => setSelectedTab(index)}>
            <Tabs.Panel
              id="conversation-tab"
              renderTitle={I18n.t('Conversation')}
              isSelected={selectedTab === 0}
            >
              <MessageList messages={messages} progress={progress} isLoading={isLoading} />
            </Tabs.Panel>

            <Tabs.Panel
              id="ai-analysis-tab"
              renderTitle={I18n.t('AI analysis')}
              isSelected={selectedTab === 1}
            >
              {isEvaluationEnabled ? (
                <AIAnalysisTab
                  studentName={conversation?.student?.name}
                  evaluation={evaluation}
                  isLoading={isLoadingEvaluation}
                  error={evaluationError}
                  onRequestEvaluation={fetchEvaluation}
                />
              ) : (
                <View as="div" padding="large" textAlign="center">
                  <Text color="secondary">{I18n.t('AI analysis coming soon')}</Text>
                </View>
              )}
            </Tabs.Panel>
          </Tabs>
        </View>
      </Flex.Item>

      <View
        as="div"
        padding="medium"
        borderWidth="small 0 0 0"
        background="secondary"
        textAlign="end"
      >
        <Flex justifyItems="end" gap="small">
          <Flex.Item>
            <Button>{I18n.t('Cancel')}</Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="primary" interaction="disabled">
              {I18n.t('Grade')}
            </Button>
          </Flex.Item>
        </Flex>
      </View>
    </Flex>
  )
}

export default ConversationPanel
