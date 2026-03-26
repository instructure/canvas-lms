/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useState, forwardRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconArrowDownLine,
  IconArrowUpLine,
  IconDuplicateLine,
  IconEditLine,
  IconMoreLine,
  IconOutcomesLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('rubrics-criterion-row-popover')

type CriterionRowPopoverProps = {
  isFirstIndex: boolean
  isLastIndex: boolean
  onMoveUp: () => void
  onMoveDown: () => void
  isLearningOutcome?: boolean
  isRegenerating?: boolean
  onEditCriterion?: () => void
  onDeleteCriterion?: () => void
  onDuplicateCriterion?: () => void
}
export const CriterionRowPopover = forwardRef<HTMLSpanElement, CriterionRowPopoverProps>(
  (
    {
      isFirstIndex,
      isLastIndex,
      onMoveUp,
      onMoveDown,
      isLearningOutcome,
      isRegenerating,
      onEditCriterion,
      onDeleteCriterion,
      onDuplicateCriterion,
    },
    ref,
  ) => {
    const [isPopoverOpen, setPopoverIsOpen] = useState(false)

    const closeAndCall = (fn: () => void) => () => {
      fn()
      setPopoverIsOpen(false)
    }

    const editLabel = isLearningOutcome
      ? I18n.t('View Outcome Criterion')
      : I18n.t('Edit Criterion')

    return (
      <span ref={ref}>
        <Popover
          renderTrigger={
            <IconButton
              screenReaderLabel={I18n.t('Criterion Options')}
              data-testid="criterion-options-popover"
              withBackground={false}
              withBorder={false}
              size="small"
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
              onClick={closeAndCall(onMoveUp)}
              data-testid="move-up-criterion-menu-item"
            >
              <IconArrowUpLine />
              <View as="span" margin="0 0 0 x-small">
                {I18n.t('Move Up')}
              </View>
            </Menu.Item>
            <Menu.Item
              value="move-down"
              disabled={isLastIndex}
              onClick={closeAndCall(onMoveDown)}
              data-testid="move-down-criterion-menu-item"
            >
              <IconArrowDownLine />
              <View as="span" margin="0 0 0 x-small">
                {I18n.t('Move Down')}
              </View>
            </Menu.Item>
            {onEditCriterion && <Menu.Separator />}
            {onEditCriterion && (
              <Menu.Item
                value="edit"
                onClick={closeAndCall(onEditCriterion)}
                data-testid="edit-criterion-menu-item"
              >
                {isLearningOutcome ? <IconOutcomesLine /> : <IconEditLine />}
                <View as="span" margin="0 0 0 x-small">
                  {editLabel}
                </View>
              </Menu.Item>
            )}
            {onDeleteCriterion && (
              <Menu.Item
                value="delete"
                disabled={isRegenerating}
                onClick={closeAndCall(onDeleteCriterion)}
                data-testid="delete-criterion-menu-item"
              >
                <IconTrashLine />
                <View as="span" margin="0 0 0 x-small">
                  {I18n.t('Delete Criterion')}
                </View>
              </Menu.Item>
            )}
            {onDuplicateCriterion && (
              <Menu.Item
                value="duplicate"
                disabled={isRegenerating}
                onClick={closeAndCall(onDuplicateCriterion)}
                data-testid="duplicate-criterion-menu-item"
              >
                <IconDuplicateLine />
                <View as="span" margin="0 0 0 x-small">
                  {I18n.t('Duplicate Criterion')}
                </View>
              </Menu.Item>
            )}
          </Menu>
        </Popover>
      </span>
    )
  },
)

CriterionRowPopover.displayName = 'CriterionRowPopover'
