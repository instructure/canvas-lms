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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {useQuery} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import LogoutButton from '../LogoutButton'
import HighContrastModeToggle from '../trays/HighContrastModeToggle'
import {ActiveText} from './utils'
import profileQuery from '../queries/profileQuery'

const I18n = useI18nScope('CoursesTray')

export default function CoursesList() {
  const {data, isLoading, isSuccess} = useQuery({
    queryKey: ['profile'],
    queryFn: profileQuery,
    fetchAtLeastOnce: true,
  })

  return (
    <List isUnstyled={true} itemSpacing="small" margin="0 0 0 x-large">
      {isLoading && (
        <List.Item>
          <Spinner margin="auto" size="small" renderTitle={I18n.t('Loading')} />
        </List.Item>
      )}
      {isSuccess &&
        data.map(tab => (
          <List.Item key={tab.id}>
            <Link href={tab.html_url} isWithinText={false} display="block">
              <ActiveText url={tab.html_url}>{tab.label}</ActiveText>
            </Link>
          </List.Item>
        ))}
      <List.Item>
        <LogoutButton />
      </List.Item>
      <List.Item>
        <HighContrastModeToggle isMobile={true} />
      </List.Item>
    </List>
  )
}
