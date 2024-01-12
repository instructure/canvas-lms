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

import React, {useCallback} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine, IconReviewScreenLine, IconTrashLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {LearnerGroupType} from '../../../types'
import {showUnimplemented} from '../../../shared/utils'

type LearnerGroupCardProps = {
  group: LearnerGroupType
  onRemove: (badgeId: string) => void
}

const LearnerGroupCard = ({group, onRemove}: LearnerGroupCardProps) => {
  const handleKabobMenuSelect = useCallback(
    (event: React.SyntheticEvent, value) => {
      switch (value) {
        case 'view':
          // setTrayIsOpen(true)
          showUnimplemented({currentTarget: {textContent: 'View Learner Group'}})
          break
        case 'remove':
          onRemove(group.id)
          break
      }
    },
    [group.id, onRemove]
  )

  return (
    <View
      as="div"
      position="relative"
      background="secondary"
      borderWidth="small"
      borderRadius="medium"
      padding="small"
      margin="0 0 medium 0"
      height="auto"
    >
      <div style={{position: 'absolute', top: '0.5rem', right: '0.5rem'}}>
        <Menu
          onSelect={handleKabobMenuSelect}
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
          <Menu.Item value="remove">
            <IconTrashLine /> Remove
          </Menu.Item>
        </Menu>
      </div>
      <Text as="div" weight="bold">
        {group.name}
      </Text>
      <View as="div" margin="small 0 0 0">
        <Tag text="Not Started" margin="0 small 0 0" />
        <Text size="small">{group.memberCount} Members</Text>
      </View>
    </View>
  )
}

export default LearnerGroupCard
