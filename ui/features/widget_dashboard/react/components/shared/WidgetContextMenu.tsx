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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {
  IconMoveUpTopLine,
  IconMoveUpLine,
  IconMoveDownLine,
  IconMoveDownBottomLine,
} from '@instructure/ui-icons'

const I18n = createI18nScope('widget_dashboard')

interface WidgetContextMenuProps {
  trigger: React.ReactElement
  onSelect?: (action: string) => void
}

const WidgetContextMenu: React.FC<WidgetContextMenuProps> = ({trigger, onSelect}) => {
  const handleSelect = (action: string) => {
    onSelect?.(action)
  }

  return (
    <Menu placement="bottom start" trigger={trigger}>
      <Menu.Item onSelect={() => handleSelect('move-to-top')}>
        <IconMoveUpTopLine /> {I18n.t('Move to top')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-up')}>
        <IconMoveUpLine /> {I18n.t('Move up')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-down')}>
        <IconMoveDownLine /> {I18n.t('Move down')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-to-bottom')}>
        <IconMoveDownBottomLine /> {I18n.t('Move to bottom')}
      </Menu.Item>
    </Menu>
  )
}

export default WidgetContextMenu
