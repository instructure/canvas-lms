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
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Portal} from '@instructure/ui-portal'
import {useQuery} from '@canvas/query'
import {getUnreadCount} from './queries/unreadCountQuery'
import {getSetting} from '@canvas/settings-query/react/settingsQuery'

const I18n = useI18nScope('Navigation')

const unreadReleaseNotesCountElement = document.querySelector(
  '#global_nav_help_link .menu-item__badge'
)
const unreadInboxCountElement = document.querySelector(
  '#global_nav_conversations_link .menu-item__badge'
)
const unreadSharesCountElement = document.querySelector(
  '#global_nav_profile_link .menu-item__badge'
)

export default function NavigationBadges() {
  const countsEnabled = Boolean(
    window.ENV.current_user_id && !window.ENV.current_user?.fake_student
  )

  const {data: releaseNotesBadgeDisabled} = useQuery({
    queryKey: ['settings', 'release_notes_badge_disabled'],
    queryFn: getSetting,
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes,
    fetchAtLeastOnce: true,
  })

  const {data: unreadContentSharesCount, isSuccess: hasUnreadContentSharesCount} = useQuery({
    queryKey: ['unread_count', 'content_shares'],
    queryFn: getUnreadCount,
    staleTime: 60 * 60 * 1000, // 1 hour
    enabled: countsEnabled && ENV.CAN_VIEW_CONTENT_SHARES,
    refetchOnWindowFocus: true,
  })

  const {data: unreadConversationsCount, isSuccess: hasUnreadConversationsCount} = useQuery({
    queryKey: ['unread_count', 'conversations'],
    queryFn: getUnreadCount,
    staleTime: 2 * 60 * 1000, // two minutes
    enabled: countsEnabled && !ENV.current_user_disabled_inbox,
    broadcast: true,
    refetchOnWindowFocus: true,
  })

  const {data: unreadReleaseNotesCount, isSuccess: hasUnreadReleaseNotesCount} = useQuery({
    queryKey: ['unread_count', 'release_notes'],
    queryFn: getUnreadCount,
    staleTime: 24 * 60 * 60 * 1000, // 24 hours
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes && !releaseNotesBadgeDisabled,
  })

  return (
    <>
      <Portal
        open={hasUnreadContentSharesCount && unreadContentSharesCount > 0}
        mountNode={unreadSharesCountElement}
      >
        <ScreenReaderContent>
          <>
            {I18n.t(
              {
                one: 'One unread share.',
                other: '%{count} unread shares.',
              },
              {count: unreadContentSharesCount}
            )}
          </>
        </ScreenReaderContent>
        <PresentationContent>{unreadContentSharesCount}</PresentationContent>
      </Portal>

      <Portal
        open={hasUnreadConversationsCount && unreadConversationsCount > 0}
        mountNode={unreadInboxCountElement}
      >
        <ScreenReaderContent>
          <>
            {I18n.t(
              {
                one: 'One unread message.',
                other: '%{count} unread messages.',
              },
              {count: unreadConversationsCount}
            )}
          </>
        </ScreenReaderContent>
        <PresentationContent>{unreadConversationsCount}</PresentationContent>
      </Portal>

      <Portal
        open={hasUnreadReleaseNotesCount && unreadReleaseNotesCount > 0}
        mountNode={unreadReleaseNotesCountElement}
      >
        <ScreenReaderContent>
          <>
            {I18n.t(
              {
                one: 'One unread release note.',
                other: '%{count} unread release notes.',
              },
              {count: unreadReleaseNotesCount}
            )}
          </>
        </ScreenReaderContent>
        <PresentationContent>{unreadReleaseNotesCount}</PresentationContent>
      </Portal>
    </>
  )
}
