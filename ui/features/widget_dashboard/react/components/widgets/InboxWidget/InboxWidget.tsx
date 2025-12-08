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
import {List} from '@instructure/ui-list'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Link} from '@instructure/ui-link'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import MessageItem from './MessageItem'
import type {BaseWidgetProps, InboxMessage} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

const MOCK_MESSAGES: InboxMessage[] = [
  {
    id: '1',
    subject: 'Assignment feedback available',
    lastMessageAt: '2025-12-08T10:00:00Z',
    messagePreview: 'Hey, I left some feedback on your...',
    workflowState: 'unread',
    conversationUrl: '/conversations/1',
    participants: [
      {
        id: 'user1',
        name: 'John Smith',
        avatarUrl: undefined,
      },
    ],
  },
  {
    id: '2',
    subject: 'Course announcement: Quiz next week',
    lastMessageAt: '2025-12-07T14:30:00Z',
    messagePreview: 'Just a reminder that we have a quiz...',
    workflowState: 'unread',
    conversationUrl: '/conversations/2',
    participants: [
      {
        id: 'user2',
        name: 'Sarah Johnson',
        avatarUrl: undefined,
      },
    ],
  },
  {
    id: '3',
    subject: 'Group project update',
    lastMessageAt: '2025-12-05T09:15:00Z',
    messagePreview: 'The group project deadline has been...',
    workflowState: 'read',
    conversationUrl: '/conversations/3',
    participants: [
      {
        id: 'user3',
        name: 'Mike Davis',
        avatarUrl: undefined,
      },
    ],
  },
]

const InboxWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  dragHandleProps,
  isLoading = false,
  error = null,
  onRetry,
}) => {
  const messages = MOCK_MESSAGES

  const renderFilterSelect = () => (
    <SimpleSelect
      renderLabel={I18n.t('Filter:')}
      value="unread"
      onChange={() => {}}
      size="small"
      width="7rem"
      data-testid="inbox-filter-select"
    >
      <SimpleSelect.Option id="unread" value="unread">
        {I18n.t('Unread')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="read" value="read">
        {I18n.t('Read')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="all" value="all">
        {I18n.t('All')}
      </SimpleSelect.Option>
    </SimpleSelect>
  )

  const renderContent = () => {
    if (messages.length === 0) {
      return (
        <View as="div" margin="large 0">
          <Text color="secondary" size="medium" data-testid="no-messages-message">
            {I18n.t('No messages')}
          </Text>
        </View>
      )
    }

    return (
      <View as="div">
        <List isUnstyled margin="0">
          {messages.map(message => (
            <List.Item key={message.id} margin="0">
              <MessageItem message={message} />
            </List.Item>
          ))}
        </List>
      </View>
    )
  }

  const renderActions = () => (
    <Link href="/conversations" isWithinText={false} data-testid="show-all-messages-link">
      <Text size="small">{I18n.t('Show all messages in inbox')}</Text>
    </Link>
  )

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error}
      onRetry={onRetry}
      loadingText={I18n.t('Loading messages...')}
      actions={renderActions()}
    >
      <Flex direction="column" gap="small">
        <Flex.Item overflowX="visible" overflowY="visible">
          {renderFilterSelect()}
        </Flex.Item>
        <Flex.Item shouldGrow>{renderContent()}</Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default InboxWidget
