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
import {Heading} from '@instructure/ui-heading'
import {Pill} from '@instructure/ui-pill'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import type {CommMessage, WorkflowStateColorMap} from './types'

const I18n = createI18nScope('comm_messages')

const PILL_COLORS: WorkflowStateColorMap = {
  sent: 'success',
  dashboard: 'success',
  created: 'info',
  staged: 'info',
  sending: 'info',
  cancelled: 'danger',
  bounced: 'danger',
  closed: 'primary',
}

function HeaderRow({hdr, value}: {hdr: string; value: string | null}): JSX.Element {
  const cellStyling = {padding: '0.125rem 0 0.125rem 1rem'}
  return (
    <tr>
      <td>
        <Text variant="contentImportant">{hdr}</Text>
      </td>
      <td style={cellStyling}>
        <Text variant="content">{value}</Text>
      </td>
    </tr>
  )
}

function MessageBody({body}: {body: string}): JSX.Element[] {
  const result = body.trim().split('\n')
  return result.map((line, index) => (
    <View key={`line-${index}`} as="div" padding="space8 none">
      <Text variant="content">{line}</Text>
    </View>
  ))
}

export interface CommMessageProps {
  message: CommMessage
}

export default function CommMessageDisplay({message}: CommMessageProps): JSX.Element {
  const formatDate = useDateTimeFormat('time.formats.medium')
  return (
    <View
      as="div"
      borderRadius="small"
      borderWidth="small"
      padding="paddingCardSmall"
      margin="moduleElements none"
    >
      <Flex alignItems="start" margin="space12 none">
        <Flex.Item shouldGrow>
          <Heading variant="titleCardRegular">{message.subject}</Heading>
        </Flex.Item>
        <Flex.Item>
          <Pill color={PILL_COLORS[message.workflow_state]}>{message.workflow_state}</Pill>
        </Flex.Item>
      </Flex>
      <table>
        <tbody>
          <HeaderRow hdr={I18n.t('To')} value={message.to} />
          <HeaderRow hdr={I18n.t('From')} value={`${message.from_name} <${message.from}>`} />
          <HeaderRow hdr={I18n.t('Created at')} value={formatDate(message.created_at)} />
          <HeaderRow hdr={I18n.t('Sent at')} value={formatDate(message.sent_at) || '—'} />
        </tbody>
      </table>
      <View
        as="div"
        data-testid="body"
        borderRadius="small"
        borderWidth="small"
        maxHeight="400px"
        overflowY="auto"
        padding="paddingCardSmall"
        margin="moduleElements none none none"
      >
        <MessageBody body={message.body} />
      </View>
    </View>
  )
}
