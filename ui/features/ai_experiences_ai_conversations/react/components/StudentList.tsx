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
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Avatar} from '@instructure/ui-avatar'
import {Badge} from '@instructure/ui-badge'
import {Spinner} from '@instructure/ui-spinner'
import {IconButton} from '@instructure/ui-buttons'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {useStudentConversations} from '../hooks/useAIConversations'

const I18n = createI18nScope('ai_experiences_ai_conversations')

interface StudentListProps {
  courseId: string | number
  aiExperienceId: string | number
  selectedConversationId?: string
  onSelectStudent: (conversationId: string) => void
}

const StudentList: React.FC<StudentListProps> = ({
  courseId,
  aiExperienceId,
  selectedConversationId,
  onSelectStudent,
}) => {
  const {conversations, isLoading, error} = useStudentConversations(courseId, aiExperienceId)

  if (isLoading) {
    return (
      <View as="div" padding="large" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading student conversations')} />
      </View>
    )
  }

  if (error) {
    return (
      <View as="div" padding="large">
        <Text color="danger">{I18n.t('Error loading conversations')}</Text>
      </View>
    )
  }

  if (conversations.length === 0) {
    return (
      <View as="div" padding="large">
        <Text>{I18n.t('No student conversations yet')}</Text>
      </View>
    )
  }

  return (
    <View as="div" padding="medium" height="100vh" overflowY="auto">
      <Heading level="h3" margin="0 0 medium 0">
        {I18n.t('Student')}
      </Heading>

      {conversations.map(conversation => {
        const isSelected = conversation.id === selectedConversationId

        return (
          <View
            key={conversation.id}
            as="div"
            padding="small"
            margin="0 0 small 0"
            borderWidth="small"
            borderRadius="medium"
            background={isSelected ? 'brand' : 'primary'}
            cursor="pointer"
            onClick={() => conversation.id && onSelectStudent(conversation.id)}
            data-testid={`student-conversation-${conversation.id}`}
          >
            <Flex gap="small" alignItems="start">
              <Flex.Item>
                <Avatar
                  name={conversation.student.name}
                  src={conversation.student.avatar_url}
                  size="small"
                />
              </Flex.Item>
              <Flex.Item shouldGrow shouldShrink>
                <View>
                  <Flex justifyItems="space-between" alignItems="center">
                    <Flex.Item shouldGrow>
                      <Text weight="bold">{conversation.student.name}</Text>
                    </Flex.Item>
                    <Flex.Item>
                      <IconButton
                        screenReaderLabel={I18n.t('Open in new tab')}
                        size="small"
                        withBackground={false}
                        withBorder={false}
                        onClick={e => {
                          e.stopPropagation()
                          window.open(
                            `/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations#${conversation.id}`,
                            '_blank',
                          )
                        }}
                      >
                        <IconExternalLinkLine />
                      </IconButton>
                    </Flex.Item>
                  </Flex>

                  <View as="div" margin="xx-small 0 0 0">
                    <Text size="small" color="secondary">
                      {I18n.t('Updated %{date}', {
                        date: new Date(conversation.updated_at || '').toLocaleDateString(),
                      })}
                    </Text>
                  </View>

                  {conversation.workflow_state === 'completed' && (
                    <View as="div" margin="xx-small 0 0 0">
                      <Badge type="notification" standalone margin="0">
                        <Text size="x-small">{I18n.t('Submitted')}</Text>
                      </Badge>
                    </View>
                  )}
                </View>
              </Flex.Item>
            </Flex>
          </View>
        )
      })}
    </View>
  )
}

export default StudentList
