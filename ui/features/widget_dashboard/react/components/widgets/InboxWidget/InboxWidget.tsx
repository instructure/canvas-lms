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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Link} from '@instructure/ui-link'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import MessageItem from './MessageItem'
import type {BaseWidgetProps} from '../../../types'
import {useInboxMessages, type InboxFilter} from '../../../hooks/useInboxMessages'

const I18n = createI18nScope('widget_dashboard')

const InboxWidget: React.FC<BaseWidgetProps> = ({widget, isEditMode = false, dragHandleProps}) => {
  const [filter, setFilter] = useState<InboxFilter>('unread')
  const {data: messages = [], isLoading, error, refetch} = useInboxMessages({limit: 5, filter})

  const handleFilterChange = (newFilter: InboxFilter) => {
    setFilter(newFilter)
  }

  const renderFilterSelect = () => (
    <SimpleSelect
      renderLabel={I18n.t('Filter:')}
      value={filter}
      onChange={(_event, {value}) => handleFilterChange(value as InboxFilter)}
      size="small"
      width="7rem"
      data-testid="inbox-filter-select"
    >
      <SimpleSelect.Option id="unread" value="unread">
        {I18n.t('Unread')}
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
    <View as="div" textAlign="center">
      <Link href="/conversations" isWithinText={false} data-testid="show-all-messages-link">
        <Text size="small">{I18n.t('Show all messages in inbox')}</Text>
      </Link>
    </View>
  )

  const handleRetry = () => {
    refetch()
  }

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error ? String(error) : null}
      onRetry={handleRetry}
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
