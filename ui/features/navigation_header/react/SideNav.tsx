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
  IconDashboardLine,
  IconUserLine,
  IconInboxLine,
  IconCanvasLogoSolid,
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_user_tutorial')

const SideNav = () => {
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
          href="#"
          themeOverride={{
            iconColor: 'white',
            contentPadding: '1rem',
            backgroundColor: 'transparent',
            hoverBackgroundColor: 'transparent',
          }}
          data-testid="sidenav-header-logo"
        />
        <Navigation.Item
          icon={<Avatar name="Ziggy Marley" size="x-small" />}
          label="Account"
          onClick={() => {
            // this.loadSubNav('account')
          }}
        />
        <Navigation.Item icon={<IconAdminLine />} label="Admin" href="#" />
        <Navigation.Item selected={true} icon={<IconDashboardLine />} label="Dashboard" href="#" />
        <Navigation.Item
          icon={
            <Badge count={99}>
              <IconInboxLine />
            </Badge>
          }
          label="Inbox"
          href="#"
        />
        <Navigation.Item icon={<IconUserLine />} label="Profile" href="#" />
      </Navigation>
    </div>
  )
}

export default SideNav
