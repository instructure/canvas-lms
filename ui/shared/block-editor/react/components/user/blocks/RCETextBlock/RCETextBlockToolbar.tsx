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
import {useNode, type Node} from '@craftjs/core'

import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {type ViewOwnProps} from '@instructure/ui-view'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {IconResize} from '../../../../assets/internal-icons'

import {type RCETextBlockProps} from './types'
import {type SizeVariant} from '../../../editor/types'
import {useScope as createI18nScope} from '@canvas/i18n'

import {changeSizeVariant} from '../../../../utils/resizeHelpers'

const I18n = createI18nScope('block-editor')

const RCETextBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode((n: Node) => ({
    node: n,
    props: n.data.props,
  }))

  const handleChangeSzVariant = useCallback(
    (
      _e: any,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      setProp((prps: RCETextBlockProps) => {
        prps.sizeVariant = value as SizeVariant

        if (node.dom) {
          const {width, height} = changeSizeVariant(node.dom, value as SizeVariant)
          prps.width = width
          prps.height = height
        }
      })
    },
    [node.dom, setProp],
  )

  return (
    <Flex gap="small" data-testid="rce-text-block-toolbar">
      <Menu
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Block Size')}
            title={I18n.t('Block Size')}
          >
            <IconResize size="x-small" />
          </IconButton>
        }
      >
        <Menu.Item
          type="checkbox"
          value="auto"
          selected={props.sizeVariant === 'auto'}
          onSelect={handleChangeSzVariant}
        >
          <Text size="small">{I18n.t('Auto')}</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="pixel"
          selected={props.sizeVariant === 'pixel'}
          onSelect={handleChangeSzVariant}
        >
          <Text size="small">{I18n.t('Fixed size')}</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="percent"
          selected={props.sizeVariant === 'percent'}
          onSelect={handleChangeSzVariant}
        >
          <Text size="small">{I18n.t('Percent size')}</Text>
        </Menu.Item>
      </Menu>
    </Flex>
  )
}

export {RCETextBlockToolbar}
