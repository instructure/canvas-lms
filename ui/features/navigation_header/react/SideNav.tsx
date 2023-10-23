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

import React from 'react'
import {Navigation} from '@instructure/ui-navigation'
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
import {
  IconAdminLine,
  IconCalendarMonthLine,
  IconCanvasLogoSolid,
  IconCoursesLine,
  IconDashboardLine,
  IconHomeLine,
  IconInboxLine,
  IconQuestionLine,
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_user_tutorial')

const SideNav = () => {
  const isK5User = window.ENV.K5_USER
  return (
    <div style={{height: '100vh'}} data-testid="sidenav-container">
      <Navigation
        label="Main navigation"
        toggleLabel={{
          expandedLabel: 'Minimize Navigation',
          minimizedLabel: 'Expand Navigation',
        }}
      >
        <Navigation.Item
          icon={<IconCanvasLogoSolid size="medium" data-testid="icon-canvas-logo" />}
          label={<ScreenReaderContent>{I18n.t('Home')}</ScreenReaderContent>}
          href="/"
          themeOverride={{
            iconColor: 'white',
            contentPadding: '1rem',
            backgroundColor: 'transparent',
            hoverBackgroundColor: 'transparent',
          }}
          data-testid="sidenav-header-logo"
        />
        <Navigation.Item
          icon={
            <Avatar
              data-testid="avatar"
              name={window.ENV.current_user.display_name}
              size="x-small"
              src={window.ENV.current_user.avatar_image_url}
            />
          }
          label={I18n.t('Account')}
          onClick={() => {
            // this.loadSubNav('account')
          }}
        />
        <Navigation.Item
          icon={<IconAdminLine />}
          label={I18n.t('Admin')}
          href="/accounts"
          onClick={event => {
            event.preventDefault()
          }}
        />
        <Navigation.Item
          selected={true}
          icon={isK5User ? <IconHomeLine data-testid="K5HomeIcon" /> : <IconDashboardLine />}
          label={isK5User ? I18n.t('Home') : I18n.t('Dashboard')}
          href="/"
        />
        <Navigation.Item
          icon={<IconCoursesLine />}
          label={isK5User ? I18n.t('Subjects') : I18n.t('Courses')}
          href="/courses"
          onClick={event => {
            event.preventDefault()
          }}
        />
        <Navigation.Item
          icon={<IconCalendarMonthLine />}
          label={I18n.t('Calendar')}
          href="/calendar"
        />
        <Navigation.Item
          icon={
            <Badge count={99}>
              <IconInboxLine />
            </Badge>
          }
          label={I18n.t('Inbox')}
          href="/conversations"
        />
        <Navigation.Item
          icon={<IconQuestionLine />}
          label={I18n.t('Help')}
          href="/accounts/self/settings"
        />
      </Navigation>
    </div>
  )
}

export default SideNav
