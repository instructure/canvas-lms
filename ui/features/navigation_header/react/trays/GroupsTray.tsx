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
import groupsQuery from '../queries/groupsQuery'
import type {AccessibleGroup} from '../../../../api.d'

const I18n = useI18nScope('GroupsTray')

export default function GroupsTray() {
  const {data, isLoading, isSuccess} = useQuery<AccessibleGroup[], Error>({
    queryKey: ['groups', 'self', 'can_access'],
    queryFn: groupsQuery,
    fetchAtLeastOnce: true,
  })

  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {I18n.t('Groups')}
      </Heading>
      <hr role="presentation" />
      <List isUnstyled={true} margin="small 0" itemSpacing="small">
        <List.Item key="all">
          <Link isWithinText={false} href="/groups">
            {I18n.t('All Groups')}
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
          data.map(group => (
            <List.Item key={group.id}>
              <Link isWithinText={false} href={`/groups/${group.id}`}>
                {group.name}
              </Link>
            </List.Item>
          ))}
      </List>
    </View>
  )
}
