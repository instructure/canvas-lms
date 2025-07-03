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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconArrowDownLine,
  IconArrowUpLine,
  IconMoreLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('rubrics-compact-rating-popover')

type CompactRatingPopoverProps = {
  isFirstIndex: boolean
  isLastIndex: boolean
  onMoveUp: () => void
  onMoveDown: () => void
  onDelete: () => void
  showRemoveButton: boolean
}
export const CompactRatingPopover = ({
  isFirstIndex,
  isLastIndex,
  onMoveUp,
  onMoveDown,
  onDelete,
  showRemoveButton,
}: CompactRatingPopoverProps) => {
  const [isPopoverOpen, setPopoverIsOpen] = useState(false)

  return (
    <Popover
      renderTrigger={
        <IconButton
          screenReaderLabel={I18n.t('Rating Options')}
          data-testid="rating-options-popover"
        >
          <IconMoreLine />
        </IconButton>
      }
      shouldRenderOffscreen={false}
      on="click"
      placement="bottom center"
      constrain="window"
      withArrow={false}
      isShowingContent={isPopoverOpen}
      onShowContent={() => {
        setPopoverIsOpen(true)
      }}
      onHideContent={() => {
        setPopoverIsOpen(false)
      }}
    >
      <Menu>
        <Menu.Item
          value="move-up"
          disabled={isFirstIndex}
          onClick={onMoveUp}
          data-testid="move-up-rating-menu-item"
        >
          <IconArrowUpLine />
          <View as="span" margin="0 0 0 x-small">
            {I18n.t('Move Up')}
          </View>
        </Menu.Item>
        <Menu.Item
          value="move-down"
          disabled={isLastIndex}
          onClick={onMoveDown}
          data-testid="move-down-rating-menu-item"
        >
          <IconArrowDownLine />
          <View as="span" margin="0 0 0 x-small">
            {I18n.t('Move Down')}
          </View>
        </Menu.Item>
        <Menu.Separator />
        <Menu.Item
          value="delete"
          onClick={onDelete}
          disabled={!showRemoveButton}
          data-testid="delete-rating-menu-item"
        >
          <IconTrashLine />
          <View as="span" margin="0 0 0 x-small">
            {I18n.t('Delete')}
          </View>
        </Menu.Item>
      </Menu>
    </Popover>
  )
}
