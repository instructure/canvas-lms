/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {type ReactNode} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Avatar} from '@instructure/ui-avatar'
import type {User} from './types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('temporary_enrollment')

type Props = {
  user: User
  children?: ReactNode
}

export function TempEnrollAvatar(props: Props) {
  return (
    <Flex gap="x-small">
      <Flex.Item>
        <Avatar
          size="small"
          name={props.user.name}
          src={props.user.avatar_url || undefined}
          data-fs-exclude={true}
          data-heap-redact-attributes="name"
          alt={I18n.t('Avatar for %{name}', {name: props.user.name})}
        />
      </Flex.Item>
      <Flex.Item shouldShrink={true}>
        <Text>{props.children ?? props.user.name}</Text>
      </Flex.Item>
    </Flex>
  )
}
