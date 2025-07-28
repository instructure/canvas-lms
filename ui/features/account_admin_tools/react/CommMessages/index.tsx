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

import React, {useCallback, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import CommMessageUserList from './CommMessageUserList'
import CommMessageList from './CommMessageList'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import type {MessagesQueryParams} from './types'

//  DESIGN NOTES
//
//  The top level rendered here is a "Section", which is subdivided into two
//  "Modules", one for the search field and resulting pickable user list, and
//  one for the resulting list of messages.
//
//  The "list of messages" Module is either a flat Alert that no messages were
//  found, or a list of "Cards", one for each message.

const I18n = createI18nScope('comm_messages')

export interface CommMessagesViewProps {
  accountId: string
}

export default function CommMessagesView({accountId}: CommMessagesViewProps): JSX.Element {
  const [query, setQuery] = useState<MessagesQueryParams | null>(null)

  const handleSelect = useCallback(
    (parms: MessagesQueryParams | null) => {
      if (parms === null && query === null) return
      setQuery(parms)
    },
    [query],
  )

  return (
    <>
      <Heading variant="titleSection">{I18n.t('View Notifications')}</Heading>
      <View margin="sectionElements none" as="div">
        <Text variant="descriptionSection">
          {I18n.t(
            'To view all notifications sent to a Canvas user, select the user and then a date range.',
          )}
        </Text>
      </View>
      <CommMessageUserList accountId={accountId} onUserAndDateSelected={handleSelect} />
      <CommMessageList query={query} />
    </>
  )
}
