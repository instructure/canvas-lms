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

import React, {useCallback} from 'react'
import {useNode} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {IconButton} from '@instructure/ui-buttons'
import {IconBoxLine} from '@instructure/ui-icons'
import {IconPopup} from '../../common/IconPopup'
import {type IconBlockProps, type IconSize} from './types'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

const IconBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))

  const handleSizeChange = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      setProp((prps: IconBlockProps) => (prps.size = value as IconSize))
    },
    [setProp]
  )
  return (
    <Flex gap="small">
      <Menu
        placement="bottom"
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Size')}
            title={I18n.t('Size')}
          >
            <IconBoxLine size="x-small" />
          </IconButton>
        }
        onSelect={handleSizeChange}
      >
        <Menu.Item value="small" type="checkbox" defaultSelected={props.size === 'small'}>
          {I18n.t('Small')}
        </Menu.Item>
        <Menu.Item value="medium" type="checkbox" defaultSelected={props.size === 'medium'}>
          {I18n.t('Medium')}
        </Menu.Item>
        <Menu.Item value="large" type="checkbox" defaultSelected={props.size === 'large'}>
          {I18n.t('Large')}
        </Menu.Item>
      </Menu>
      <IconPopup iconName={props.iconName} />
    </Flex>
  )
}

export {IconBlockToolbar}
