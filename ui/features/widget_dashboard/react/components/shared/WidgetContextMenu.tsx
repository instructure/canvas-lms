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
  IconArrowStartLine,
  IconArrowEndLine,
} from '@instructure/ui-icons'
import type {Widget, WidgetConfig} from '../../types'
import {LEFT_COLUMN, RIGHT_COLUMN} from '../../constants'

const I18n = createI18nScope('widget_dashboard')

interface WidgetContextMenuProps {
  trigger: React.ReactElement
  widget: Widget
  config: WidgetConfig
  onSelect?: (action: string) => void
}

const getWidgetConstraints = (widget: Widget, config: WidgetConfig) => {
  const colWidgets = config.widgets.filter(w => w.position.col === widget.position.col)
  const sortedColWidgets = [...colWidgets].sort((a, b) => a.position.row - b.position.row)
  const widgetIndex = sortedColWidgets.findIndex(w => w.id === widget.id)

  return {
    isFirstInColumn: widgetIndex === 0,
    isLastInColumn: widgetIndex === sortedColWidgets.length - 1,
    isInLeftColumn: widget.position.col === LEFT_COLUMN,
    isInRightColumn: widget.position.col === RIGHT_COLUMN,
  }
}

const WidgetContextMenu: React.FC<WidgetContextMenuProps> = ({
  trigger,
  widget,
  config,
  onSelect,
}) => {
  const handleSelect = (action: string) => {
    onSelect?.(action)
  }

  const constraints = getWidgetConstraints(widget, config)

  return (
    <Menu placement="bottom start" trigger={trigger}>
      <Menu.Item
        onSelect={() => handleSelect('move-to-top')}
        disabled={constraints.isFirstInColumn}
      >
        <IconMoveUpTopLine /> {I18n.t('Move to top')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-up')} disabled={constraints.isFirstInColumn}>
        <IconMoveUpLine /> {I18n.t('Move up')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-down')} disabled={constraints.isLastInColumn}>
        <IconMoveDownLine /> {I18n.t('Move down')}
      </Menu.Item>
      <Menu.Item
        onSelect={() => handleSelect('move-to-bottom')}
        disabled={constraints.isLastInColumn}
      >
        <IconMoveDownBottomLine /> {I18n.t('Move to bottom')}
      </Menu.Item>
      <Menu.Item
        onSelect={() => handleSelect('move-left-top')}
        disabled={constraints.isInLeftColumn}
      >
        <IconArrowStartLine /> {I18n.t('Move left top')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-left')} disabled={constraints.isInLeftColumn}>
        <IconArrowStartLine /> {I18n.t('Move left bottom')}
      </Menu.Item>
      <Menu.Item
        onSelect={() => handleSelect('move-right-top')}
        disabled={constraints.isInRightColumn}
      >
        <IconArrowEndLine /> {I18n.t('Move right top')}
      </Menu.Item>
      <Menu.Item onSelect={() => handleSelect('move-right')} disabled={constraints.isInRightColumn}>
        <IconArrowEndLine /> {I18n.t('Move right bottom')}
      </Menu.Item>
    </Menu>
  )
}

export default WidgetContextMenu
