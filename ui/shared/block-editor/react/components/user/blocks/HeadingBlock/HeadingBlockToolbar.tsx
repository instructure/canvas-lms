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

const HeadingBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))

  const handleLevelChange = useCallback(
    (
      e: React.MouseEvent<ViewOwnProps, MouseEvent>,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      setProp(prps => (prps.level = value))
    },
    [setProp]
  )

  return (
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
  )
}

export {HeadingBlockToolbar}
