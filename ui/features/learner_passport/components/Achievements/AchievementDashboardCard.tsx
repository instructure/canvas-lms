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
import {IconButton} from '@instructure/ui-buttons'
import {
  IconEditLine,
  IconMoreLine,
  IconReviewScreenLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'

import AchievementCard from './AchievementCard'
import type {AchievementCardProps} from './AchievementCard'

const AchievementDashboardCard = (props: AchievementCardProps) => {
  return (
    <View as="div" position="relative" borderWidth="small" shadow="resting">
      <div style={{position: 'absolute', top: '.5rem', right: '.5rem'}}>
        <Menu
          onSelect={undefined}
          placement="bottom"
          trigger={
            <IconButton screenReaderLabel="More" withBackground={false} withBorder={false}>
              <IconMoreLine />
            </IconButton>
          }
        >
          <Menu.Item value="view">
            <IconReviewScreenLine /> View
          </Menu.Item>
          <Menu.Item value="edit">
            <IconEditLine /> Edit
          </Menu.Item>

          <Menu.Item value="delete">
            <IconTrashLine /> Delete
          </Menu.Item>
        </Menu>
      </div>
      <AchievementCard {...props} />
    </View>
  )
}

export default AchievementDashboardCard
