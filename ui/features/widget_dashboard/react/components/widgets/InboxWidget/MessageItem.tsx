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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Avatar} from '@instructure/ui-avatar'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import type {InboxMessage} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

const truncateText = (text: string, maxLength: number = 80): string => {
  if (!text || text.length <= maxLength) return text
  return text.slice(0, maxLength).trim() + '...'
}

interface TruncatedTextProps {
  children: string
  maxLength?: number
}

const TruncatedText: React.FC<TruncatedTextProps> = ({children, maxLength = 80}) => (
  <Text title={children.length > maxLength ? children : undefined} wrap="break-word" size="x-small">
    {truncateText(children, maxLength)}
  </Text>
)

interface MessageItemProps {
  message: InboxMessage
}

const MessageItem: React.FC<MessageItemProps> = ({message}) => {
  const sender = message.participants[0] || {id: 'unknown', name: I18n.t('Unknown Sender')}

  return (
    <View
      as="div"
      padding="x-small 0"
      borderWidth="0 0 small 0"
      borderColor="primary"
      width="100%"
      maxWidth="100%"
      data-testid={`message-item-${message.id}`}
      role="group"
      aria-label={message.subject}
    >
      <Flex direction="column" gap="xxx-small">
        <Flex.Item overflowY="visible">
          <Flex direction="row" gap="x-small">
            <Flex.Item shouldShrink={false}>
              <Avatar
                name={sender?.name || I18n.t('Unknown Sender')}
                src={sender?.avatarUrl}
                size="medium"
              />
            </Flex.Item>

            <Flex.Item shouldGrow shouldShrink>
              <Flex direction="column" gap="xxx-small">
                <Flex.Item shouldShrink overflowX="visible" overflowY="visible">
                  <Flex direction="row" justifyItems="space-between" alignItems="start" gap="small">
                    <Flex.Item shouldGrow shouldShrink>
                      <Text size="x-small" color="secondary" wrap="break-word">
                        {sender?.name || I18n.t('Unknown Sender')}
                      </Text>
                    </Flex.Item>
                    <Flex.Item shouldShrink={false}>
                      <Text size="x-small" color="secondary">
                        <FriendlyDatetime
                          dateTime={message.lastMessageAt}
                          format={I18n.t('#date.formats.medium')}
                          alwaysUseSpecifiedFormat={true}
                        />
                      </Text>
                    </Flex.Item>
                  </Flex>
                </Flex.Item>

                <Flex.Item>
                  <Text weight="bold" size="small" wrap="normal" color="primary">
                    <TruncatedText maxLength={60}>{message.subject}</TruncatedText>
                  </Text>
                </Flex.Item>

                <Flex.Item>
                  <Text size="x-small" color="secondary">
                    <TruncatedText maxLength={80}>{message.messagePreview}</TruncatedText>
                  </Text>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default MessageItem
