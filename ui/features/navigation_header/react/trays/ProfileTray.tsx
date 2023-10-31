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
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import LogoutButton from '../LogoutButton'
import HighContrastModeToggle from './HighContrastModeToggle'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {useQuery} from '@canvas/query'
import profileQuery from '../queries/profileQuery'
import {getUnreadCount} from '../queries/unreadCountQuery'
import type {ProfileTab, TabCountsObj} from '../../../../api.d'

const I18n = useI18nScope('ProfileTray')

// Trying to keep this as generalized as possible, but it's still a bit
// gross matching on the id of the tray tabs given to us by Rails
const idsToCounts = [{id: 'content_shares', countName: 'unreadShares'}]

function CountBadge({counts, id}: {counts: TabCountsObj; id: string}) {
  const found = idsToCounts.filter(x => x.id === id)
  if (found.length === 0) return null // no count defined for this label
  const count = counts[found[0].countName]
  if (count === 0) return null // zero count is not displayed
  return (
    <Badge
      count={count}
      standalone={true}
      margin="0 0 xxx-small small"
      formatOutput={(count_: string) => (
        <AccessibleContent alt={I18n.t('%{count} unread.', {count: count_})}>
          {count_}
        </AccessibleContent>
      )}
    />
  )
}

function ProfileTabLink({id, html_url, label, counts}: ProfileTab) {
  return (
    <View className={`profile-tab-${id}`} as="div" margin="small 0">
      <Link isWithinText={false} href={html_url}>
        {label}
        <CountBadge counts={counts} id={id} />
      </Link>
    </View>
  )
}

export default function ProfileTray() {
  const {
    data: profileTabs,
    isLoading,
    isSuccess,
  } = useQuery<ProfileTab[], Error>({
    queryKey: ['profile'],
    queryFn: profileQuery,
    fetchAtLeastOnce: true,
  })

  const countsEnabled = Boolean(
    window.ENV.current_user_id && !window.ENV.current_user?.fake_student
  )

  const {data: unreadContentSharesCount} = useQuery({
    queryKey: ['unread_count', 'content_shares'],
    queryFn: getUnreadCount,
    staleTime: 60 * 60 * 1000, // 1 hour
    enabled: countsEnabled && ENV.CAN_VIEW_CONTENT_SHARES,
    fetchAtLeastOnce: true,
  })

  const counts: TabCountsObj = {
    unreadShares: unreadContentSharesCount,
  }

  const userDisplayName = window.ENV.current_user.display_name
  const userPronouns = window.ENV.current_user.pronouns
  const userAvatarURL = window.ENV.current_user.avatar_is_fallback
    ? ''
    : window.ENV.current_user.avatar_image_url

  return (
    <View as="div" padding="medium">
      <View textAlign="center">
        <Avatar
          name={userDisplayName}
          src={userAvatarURL}
          alt={I18n.t('User profile picture')}
          size="x-large"
          display="block"
          margin="auto"
          data-fs-exclude={true}
        />
        <div style={{wordBreak: 'break-word'}}>
          <Heading level="h3" as="h2">
            {userDisplayName}
            {userPronouns && (
              <Text size="large" fontStyle="italic">
                &nbsp;({userPronouns})
              </Text>
            )}
          </Heading>
        </div>
        <LogoutButton size="small" margin="medium 0 x-small 0" />
      </View>
      <hr role="presentation" />
      <List isUnstyled={true} margin="none" itemSpacing="small">
        {isLoading && (
          <List.Item key="loading">
            <div style={{textAlign: 'center'}}>
              <Spinner margin="medium" renderTitle="Loading" />
            </div>
          </List.Item>
        )}
        {isSuccess &&
          profileTabs.map(tab => (
            <List.Item key={tab.id}>
              <ProfileTabLink {...tab} counts={counts} />
            </List.Item>
          ))}
      </List>
      <hr role="presentation" />
      <HighContrastModeToggle />
    </View>
  )
}
