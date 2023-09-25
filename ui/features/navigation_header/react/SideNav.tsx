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
// @ts-expect-error
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
// @ts-expect-error
import {IconAdminLine, IconDashboardLine, IconUserLine, IconInboxLine} from '@instructure/ui-icons'

const SideNav = () => {
  return (
    <div>
      <Navigation
        label="Main navigation"
        toggleLabel={{
          expandedLabel: 'Minimize Navigation',
          minimizedLabel: 'Expand Navigation',
        }}
      >
        {/* @ts-expect-error */}
        <Navigation.Item
          icon={<Avatar name="Ziggy Marley" size="x-small" />}
          label="Account"
          onClick={() => {
            // this.loadSubNav('account')
          }}
        />
        {/* @ts-expect-error */}
        <Navigation.Item icon={<IconAdminLine />} label="Admin" href="#" />
        {/* @ts-expect-error */}
        <Navigation.Item selected={true} icon={<IconDashboardLine />} label="Dashboard" href="#" />
        {/* @ts-expect-error */}
        <Navigation.Item
          icon={
            <Badge count={99}>
              <IconInboxLine />
            </Badge>
          }
          label="Inbox"
          href="#"
        />
        {/* @ts-expect-error */}
        <Navigation.Item icon={<IconUserLine />} label="Profile" href="#" />
      </Navigation>
    </div>
  )
}

export default SideNav
