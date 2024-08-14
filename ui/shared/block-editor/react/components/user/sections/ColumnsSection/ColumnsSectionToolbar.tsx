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
import {Flex} from '@instructure/ui-flex'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {IconCheckLine} from '@instructure/ui-icons'
import {type ColumnsSectionVariant, type ColumnsSectionProps} from './types'
import {ColumnCountPopup} from './ColumnCountPopup'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/columnss-block')

const ColumnsSectionToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [vart, setVart] = useState<ColumnsSectionVariant>(props.variant)

  const handleChangeVariant = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      const val = value as ColumnsSectionVariant
      setVart(val)
      setProp((prps: ColumnsSectionProps) => (prps.variant = val))
    },
    [setProp]
  )

  return (
    <Flex gap="small">
      <ColumnCountPopup columns={props.columns} />

      <Menu
        trigger={
          <IconButton
            size="small"
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Column style')}
          >
            <IconCheckLine size="x-small" />
          </IconButton>
        }
        onSelect={handleChangeVariant}
      >
        <Menu.Item type="checkbox" value="fixed" defaultSelected={vart === 'fixed'}>
          {I18n.t('Fixed')}
        </Menu.Item>
        <Menu.Item type="checkbox" value="fluid" defaultSelected={vart === 'fluid'}>
          {I18n.t('Fluid')}
        </Menu.Item>
      </Menu>
    </Flex>
  )
}

export {ColumnsSectionToolbar}
