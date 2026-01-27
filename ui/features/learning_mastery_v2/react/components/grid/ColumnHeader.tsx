/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {CELL_HEIGHT, COLUMN_WIDTH} from '@canvas/outcomes/react/utils/constants'
import TruncateWithTooltip from '@canvas/instui-bindings/react/TruncateWithTooltip'

export interface ColumnHeaderProps {
  title: string
  optionsMenuTriggerLabel?: string
  optionsMenuItems?: React.ReactNode[]
  columnWidth?: number
}

export const ColumnHeader: React.FC<ColumnHeaderProps> = ({
  title,
  optionsMenuTriggerLabel,
  optionsMenuItems = [],
  columnWidth = COLUMN_WIDTH,
}) => {
  return (
    <View background="secondary" as="div" width={columnWidth} data-testid="column-header">
      <Flex
        alignItems="center"
        justifyItems="space-between"
        height={CELL_HEIGHT}
        padding="none xx-small"
      >
        <Flex.Item size="80%">
          <Text weight="bold">
            <TruncateWithTooltip>{title}</TruncateWithTooltip>
          </Text>
        </Flex.Item>
        {optionsMenuItems.length > 0 && (
          <Menu
            placement="bottom"
            trigger={
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={optionsMenuTriggerLabel}
              >
                <IconMoreLine />
              </IconButton>
            }
          >
            {optionsMenuItems}
          </Menu>
        )}
      </Flex>
    </View>
  )
}
