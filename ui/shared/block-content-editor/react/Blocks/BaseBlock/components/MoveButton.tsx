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

import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconSortLine,
  IconMoveDownBottomLine,
  IconMoveDownLine,
  IconMoveUpTopLine,
  IconMoveUpLine,
} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'

const I18n = createI18nScope('block_content_editor')

type MenuItem = {
  key: string
  onClick: () => void
  icon: JSX.Element
  label: string
}

export const MoveButton = (props: {
  canMoveUp: boolean
  canMoveDown: boolean
  onMoveUp: () => void
  onMoveDown: () => void
  onMoveToTop: () => void
  onMoveToBottom: () => void
  title: string
}) => {
  if (!props.canMoveUp && !props.canMoveDown) return null

  const moveUpMenuItems: MenuItem[] = [
    {
      key: 'move-to-top',
      onClick: props.onMoveToTop,
      icon: <IconMoveUpTopLine />,
      label: I18n.t('Move to top: %{title}', {title: props.title}),
    },
    {
      key: 'move-up',
      onClick: props.onMoveUp,
      icon: <IconMoveUpLine />,
      label: I18n.t('Move up: %{title}', {title: props.title}),
    },
  ]

  const moveDownMenuItems: MenuItem[] = [
    {
      key: 'move-down',
      onClick: props.onMoveDown,
      icon: <IconMoveDownLine />,
      label: I18n.t('Move down: %{title}', {title: props.title}),
    },
    {
      key: 'move-to-bottom',
      onClick: props.onMoveToBottom,
      icon: <IconMoveDownBottomLine />,
      label: I18n.t('Move to bottom: %{title}', {title: props.title}),
    },
  ]

  const menuItems: MenuItem[] = [
    ...(props.canMoveUp ? moveUpMenuItems : []),
    ...(props.canMoveDown ? moveDownMenuItems : []),
  ]

  return (
    <Menu
      trigger={
        <IconButton
          data-testid="move-block-button"
          data-action-button
          screenReaderLabel={I18n.t('Move block: %{title}', {title: props.title})}
        >
          <IconSortLine />
        </IconButton>
      }
      placement="bottom end"
      offsetY={4}
      withArrow={false}
    >
      {menuItems.map(item => (
        <Menu.Item key={item.key} onClick={item.onClick} data-testid={`${item.key}-menu-item`}>
          <Flex>
            <Flex.Item>{item.icon}</Flex.Item>
            <Flex.Item margin="0 0 0 small">{item.label}</Flex.Item>
          </Flex>
        </Menu.Item>
      ))}
    </Menu>
  )
}
