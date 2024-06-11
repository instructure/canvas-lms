/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useNode} from '@craftjs/core'
import {IconButton} from '@instructure/ui-buttons'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {IconCheckLine} from '@instructure/ui-icons'
import {type ColumnsSectionVariant} from './types'
import {ColumnCountPopup} from './ColumnCountPopup'

const ColumnsSectionToolbar = () => {
  const {
    columns,
    variant,
    actions: {setProp},
  } = useNode(node => ({
    columns: node.data.props.columns,
    variant: node.data.props.variant,
  }))
  const [vart, setVart] = useState<ColumnsSectionVariant>(variant)

  const handleChangeVariant = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      setVart(value as ColumnsSectionVariant)
      setProp(prps => (prps.variant = value))
    },
    [setProp]
  )

  return (
    <div>
      <ColumnCountPopup columns={columns} />

      <Menu
        trigger={
          <IconButton
            size="small"
            withBorder={false}
            withBackground={false}
            screenReaderLabel="variant"
          >
            <IconCheckLine size="x-small" />
          </IconButton>
        }
        onSelect={handleChangeVariant}
      >
        <Menu.Item type="checkbox" value="fixed" selected={vart === 'fixed'}>
          Fixed
        </Menu.Item>
        <Menu.Item type="checkbox" value="fluid" selected={vart === 'fluid'}>
          Fluid
        </Menu.Item>
      </Menu>
    </div>
  )
}

export {ColumnsSectionToolbar}
