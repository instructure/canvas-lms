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

import React, {useCallback, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconMoreLine, IconReviewScreenLine, IconTrashLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {PathwayBadgeType} from '../../../types'
import ViewBadgeTray from './ViewBadgeTray'

type PathwayBadgeCardProps = {
  badge: PathwayBadgeType
  onRemove: (badgeId: string) => void
}

const PathwayBadgeCard = ({badge, onRemove}: PathwayBadgeCardProps) => {
  const [trayIsOpen, setTrayIsOpen] = useState(false)

  const handleKabobMenuSelect = useCallback(
    (event: React.SyntheticEvent, value) => {
      switch (value) {
        case 'view':
          setTrayIsOpen(true)
          break
        case 'remove':
          onRemove(badge.id)
          break
      }
    },
    [badge.id, onRemove]
  )

  const handleCloseTray = useCallback(() => {
    setTrayIsOpen(false)
  }, [])

  return (
    <>
      <View
        as="div"
        position="relative"
        background="secondary"
        borderWidth="small"
        padding="medium"
        shadow="resting"
        width="512px"
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
        <Flex as="div" gap="medium" padding="medium">
          <div style={{width: '100px', height: '100px', background: 'grey'}} />
          <View as="div">
            <Text as="div" weight="bold">
              {badge.title}
            </Text>
            <Text as="div">{badge.issuer.name}</Text>
          </View>
        </Flex>
      </View>
      <ViewBadgeTray badge={badge} open={trayIsOpen} onClose={handleCloseTray} />
    </>
  )
}

export default PathwayBadgeCard
