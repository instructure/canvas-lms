/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {useQuery} from '@canvas/query'
import accountsQuery from '../queries/accountsQuery'
import type {Account} from '../../../../api.d'

const I18n = useI18nScope('AccountsTray')
export default function AccountsTray() {
  const {data, isLoading, isSuccess} = useQuery<Account[], Error>({
    queryKey: ['accounts'],
    queryFn: accountsQuery,
    fetchAtLeastOnce: true,
  })

  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {I18n.t('Admin')}
      </Heading>
      <hr role="presentation" />
      <List isUnstyled={true} margin="small 0" itemSpacing="small">
        <List.Item key="all">
          <Link isWithinText={false} href="/accounts">
            {I18n.t('All Accounts')}
          </Link>
        </List.Item>
        <List.Item key="hr">
          <hr role="presentation" />
        </List.Item>
        {isLoading && (
          <List.Item>
            <Spinner delay={500} size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
        {isSuccess &&
          data.map(account => (
            <List.Item key={account.id}>
              <Link isWithinText={false} href={`/accounts/${account.id}`}>
                {account.name}
              </Link>
            </List.Item>
          ))}
      </List>
    </View>
  )
}
