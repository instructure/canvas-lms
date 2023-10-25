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

import React, {useEffect, useState} from 'react'
import {Navigation} from '@instructure/ui-navigation'
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
import {Img} from '@instructure/ui-img'
import {
  IconAdminLine,
  IconCalendarMonthLine,
  IconCanvasLogoSolid,
  IconCoursesLine,
  IconDashboardLine,
  IconFolderLine,
  IconHomeLine,
  IconInboxLine,
  IconInfoLine,
  IconLifePreserverLine,
  IconQuestionLine,
  IconSettingsLine,
} from '@instructure/ui-icons'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useQuery} from '@tanstack/react-query'
import {getUnreadCount} from './queries/unreadCountQuery'
import {getSetting} from './queries/settingsQuery'

const I18n = useI18nScope('sidenav')

export const InformationIconEnum = {
  INFORMATION: 'information',
  FOLDER: 'folder',
  COG: 'cog',
  LIFE_SAVER: 'lifepreserver',
}

const SideNav = () => {
  let logoUrl = null
  const [isMinimized, setIsMinimized] = useState(false)
  const isK5User = window.ENV.K5_USER
  const helpIcon = window.ENV.help_link_icon

  const navItemThemeOverride = {
    iconColor: 'white',
    contentPadding: '0.1rem',
    backgroundColor: 'transparent',
    hoverBackgroundColor: 'transparent',
  }

  const getHelpIcon = (): JSX.Element => {
    switch (helpIcon) {
      case InformationIconEnum.INFORMATION:
        return <IconInfoLine data-testid="HelpInfo" />
      case InformationIconEnum.FOLDER:
        return <IconFolderLine data-testid="HelpFolder" />
      case InformationIconEnum.COG:
        return <IconSettingsLine data-testid="HelpCog" />
      case InformationIconEnum.LIFE_SAVER:
        return <IconLifePreserverLine data-testid="HelpLifePreserver" />
      default:
        return <IconQuestionLine data-testid="HelpQuestion" />
    }
  }
  const countsEnabled = Boolean(
    window.ENV.current_user_id && !window.ENV.current_user?.fake_student
  )
  const brandConfig =
    (window.ENV.active_brand_config as {
      variables: {'ic-brand-header-image': string}
    }) ?? null

  if (brandConfig) {
    const variables = brandConfig.variables
    logoUrl = variables['ic-brand-header-image']
  }

  useEffect(() => {
    if (isMinimized) document.body.classList.remove('primary-nav-expanded')
    else document.body.classList.add('primary-nav-expanded')
  }, [isMinimized, setIsMinimized])

  const {data: unreadConversationsCount} = useQuery({
    queryKey: ['unread_count', 'conversations'],
    queryFn: getUnreadCount,
    staleTime: 2 * 60 * 1000, // two minutes
    enabled: countsEnabled && !ENV.current_user_disabled_inbox,
  })

  const {data: unreadContentSharesCount} = useQuery({
    queryKey: ['unread_count', 'content_shares'],
    queryFn: getUnreadCount,
    staleTime: 5 * 60 * 1000, // two minutes
    enabled: countsEnabled && ENV.CAN_VIEW_CONTENT_SHARES,
  })

  const {data: releaseNotesBadgeDisabled} = useQuery({
    queryKey: ['settings', 'release_notes_badge_disabled'],
    queryFn: getSetting,
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes,
  })

  const {data: unreadReleaseNotesCount} = useQuery({
    queryKey: ['unread_count', 'release_notes'],
    queryFn: getUnreadCount,
    staleTime: 24 * 60 * 60 * 1000, // one day
    enabled: countsEnabled && ENV.FEATURES.embedded_release_notes && !releaseNotesBadgeDisabled,
  })

  return (
    <div style={{width: '100%', height: '100vh'}} data-testid="sidenav-container">
      <Navigation
        label="Main navigation"
        toggleLabel={{
          expandedLabel: 'Minimize Navigation',
          minimizedLabel: 'Expand Navigation',
        }}
        onMinimized={() => setIsMinimized(!isMinimized)}
        themeOverride={{
          minimizedWidth: '100%',
        }}
      >
        <Navigation.Item
          icon={
            !logoUrl ? (
              <div style={{margin: '0.5rem 0 0.5rem 0'}}>
                <IconCanvasLogoSolid
                  size={!isMinimized ? 'medium' : 'small'}
                  data-testid="sidenav-canvas-logo"
                />
              </div>
            ) : (
              <Img
                display="inline-block"
                alt="sidenav-brand-logomark"
                margin={`${!isMinimized ? 'xxx-small' : 'x-small'} 0 small 0`}
                src={logoUrl}
                data-testid="sidenav-brand-logomark"
              />
            )
          }
          label={<ScreenReaderContent>{I18n.t('Home')}</ScreenReaderContent>}
          href="/"
          themeOverride={{
            ...navItemThemeOverride,
            contentPadding: '0',
          }}
          data-testid="sidenav-header-logo"
        />
        <Navigation.Item
          icon={
            <Badge
              count={unreadContentSharesCount}
              formatOutput={(count: string) =>
                (unreadContentSharesCount || 0) > 0 ? (
                  <AccessibleContent
                    alt={I18n.t(
                      {
                        one: 'One unread share.',
                        other: '%{count} unread shares.',
                      },
                      {count}
                    )}
                  >
                    {count}
                  </AccessibleContent>
                ) : (
                  ''
                )
              }
            >
              <Avatar
                name={window.ENV.current_user.display_name}
                size="x-small"
                src={window.ENV.current_user.avatar_image_url}
                data-testid="sidenav-user-avatar"
              />
            </Badge>
          }
          label={I18n.t('Account')}
          onClick={() => {
            // this.loadSubNav('account')
          }}
          themeOverride={navItemThemeOverride}
        />
        <Navigation.Item
          icon={<IconAdminLine />}
          label={I18n.t('Admin')}
          href="/accounts"
          onClick={event => {
            event.preventDefault()
          }}
          themeOverride={navItemThemeOverride}
        />
        <Navigation.Item
          selected={true}
          icon={isK5User ? <IconHomeLine data-testid="K5HomeIcon" /> : <IconDashboardLine />}
          label={isK5User ? I18n.t('Home') : I18n.t('Dashboard')}
          href="/"
          themeOverride={navItemThemeOverride}
        />
        <Navigation.Item
          icon={<IconCoursesLine />}
          label={isK5User ? I18n.t('Subjects') : I18n.t('Courses')}
          href="/courses"
          onClick={event => {
            event.preventDefault()
          }}
          themeOverride={navItemThemeOverride}
        />
        <Navigation.Item
          icon={<IconCalendarMonthLine />}
          label={I18n.t('Calendar')}
          href="/calendar"
          themeOverride={navItemThemeOverride}
        />
        <Navigation.Item
          icon={
            <Badge
              count={unreadConversationsCount}
              formatOutput={(count: string) =>
                (unreadConversationsCount || 0) > 0 ? (
                  <AccessibleContent
                    alt={I18n.t(
                      {
                        one: 'One unread message.',
                        other: '%{count} unread messages.',
                      },
                      {count}
                    )}
                  >
                    {count}
                  </AccessibleContent>
                ) : (
                  ''
                )
              }
            >
              <IconInboxLine />
            </Badge>
          }
          label={I18n.t('Inbox')}
          href="/conversations"
          themeOverride={navItemThemeOverride}
        />
        <Navigation.Item
          icon={
            <Badge
              count={unreadReleaseNotesCount}
              formatOutput={(count: string) =>
                (unreadReleaseNotesCount || 0) > 0 ? (
                  <AccessibleContent
                    alt={I18n.t(
                      {
                        one: 'One unread release note.',
                        other: '%{count} unread release notes.',
                      },
                      {count}
                    )}
                  >
                    {count}
                  </AccessibleContent>
                ) : (
                  ''
                )
              }
            >
              {getHelpIcon()}
            </Badge>
          }
          label={I18n.t('Help')}
          href="/accounts/self/settings"
          themeOverride={navItemThemeOverride}
        />
      </Navigation>
    </div>
  )
}

export default SideNav
