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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {IconMiniArrowDownLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {type ViewOwnProps} from '@instructure/ui-view'
import {type HeadingBlockProps} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const HeadingBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))

  const handleLevelChange = useCallback(
    (
      _e: any,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      const level = value as HeadingBlockProps['level']
      setProp((prps: HeadingBlockProps) => (prps.level = level))
    },
    [setProp],
  )
  const handleFontSizeChange = useCallback(
    (
      _e: any,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      if (value === 'default') {
        setProp((prps: HeadingBlockProps) => delete prps.fontSize)
      } else {
        setProp((prps: HeadingBlockProps) => (prps.fontSize = value as string))
      }
    },
    [setProp],
  )

  return (
    <Flex gap="x-small">
      <Menu
        label="Heading level"
        trigger={
          <Button size="small">
            <Flex gap="x-small">
              <Text size="small">Level</Text>
              <IconMiniArrowDownLine size="x-small" />
            </Flex>
          </Button>
        }
      >
        <Menu.Item
          type="checkbox"
          value="h2"
          onSelect={handleLevelChange}
          selected={props.level === 'h2'}
        >
          <Text size="small">Heading 2</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="h3"
          onSelect={handleLevelChange}
          selected={props.level === 'h3'}
        >
          <Text size="small">Heading 3</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="h4"
          onSelect={handleLevelChange}
          selected={props.level === 'h4'}
        >
          <Text size="small">Heading 4</Text>
        </Menu.Item>
      </Menu>

      <Menu
        label="Font size"
        trigger={
          <Button size="small">
            <Flex gap="x-small">
              <Text size="small">{I18n.t('Font Size')}</Text>
              <IconMiniArrowDownLine size="x-small" />
            </Flex>
          </Button>
        }
      >
        <Menu.Item
          type="checkbox"
          value="default"
          onSelect={handleFontSizeChange}
          selected={props.fontSize === undefined}
        >
          {I18n.t('Default')}
        </Menu.Item>
        {['0.875rem', '1rem', '1.375rem', '1.75rem', '2.375rem', '3rem', '4rem'].map(size => (
          <Menu.Item
            type="checkbox"
            key={size}
            value={size}
            onSelect={handleFontSizeChange}
            selected={props.fontSize === size}
          >
            <Text size="small">{size}</Text>
          </Menu.Item>
        ))}
      </Menu>
    </Flex>
  )
}

export {HeadingBlockToolbar}
