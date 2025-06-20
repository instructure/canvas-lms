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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TestStatus} from './types'
import {ReactElement} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {Pill} from '@instructure/ui-pill'
import {IconCompleteLine, IconTroubleLine} from '@instructure/ui-icons'

const I18n = createI18nScope('ldap_settings_test')

export interface LDAPTestStatusProps {
  title: string
  status: TestStatus
}

const LDAPTestStatus = ({title, status}: LDAPTestStatusProps) => {
  const statusComponentMap: Record<TestStatus, ReactElement> = {
    idle: <></>,
    loading: <Spinner renderTitle={I18n.t('Loading ldap test')} size="x-small" />,
    succeed: (
      <Pill color="success" renderIcon={<IconCompleteLine />}>
        {I18n.t('OK')}
      </Pill>
    ),
    failed: (
      <Pill color="danger" renderIcon={<IconTroubleLine />}>
        {I18n.t('Failed')}
      </Pill>
    ),
    canceled: <Pill>{I18n.t('Canceled')}</Pill>,
  }
  const component = statusComponentMap[status]

  return (
    <Flex justifyItems="space-between">
      <Heading variant="titleCardMini">{title}</Heading>
      <Text>{component}</Text>
    </Flex>
  )
}

export default LDAPTestStatus
