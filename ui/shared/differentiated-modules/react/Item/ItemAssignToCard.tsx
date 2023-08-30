/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
// import AssigneeSelector from '../AssigneeSelector'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

// TODO: until we resolve how to handle queries (which wreak havoc on specs)
function AssigneeSelector({cardId}: {cardId: string}) {
  return (
    <View as="div" borderWidth="small" padding="small" margin="medium 0 0 0">
      Assign To goes here (cardId: {cardId})
    </View>
  )
}

export type ItemAssignToCardProps = {
  cardId: string
  // courseId: string
  // moduleItemId: string
  onDelete?: (cardId: string) => void
}

export default function ItemAssignToCard({
  cardId,
  // courseId,
  // moduleItemId,
  onDelete,
}: ItemAssignToCardProps) {
  const handleDelete = useCallback(() => {
    onDelete?.(cardId)
  }, [cardId, onDelete])

  return (
    <View
      data-testid="item-assign-to-card"
      as="div"
      position="relative"
      padding="medium small small small"
      borderWidth="small"
      borderColor="primary"
    >
      {typeof onDelete === 'function' && (
        <div
          style={{
            position: 'absolute',
            insetInlineEnd: '.75rem',
            insetBlockStart: '.75rem',
            zIndex: 2,
          }}
        >
          <IconButton
            color="danger"
            screenReaderLabel={I18n.t('Delete')}
            size="small"
            withBackground={false}
            withBorder={false}
            onClick={handleDelete}
          >
            <IconTrashLine />
          </IconButton>
        </div>
      )}
      <AssigneeSelector cardId={cardId} />
      <View as="div" margin="small none">
        <DateTimeInput
          description={
            <ScreenReaderContent>{I18n.t('Choose a due date and time')}</ScreenReaderContent>
          }
          dateRenderLabel={I18n.t('Date')}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          defaultValue={new Date().toISOString()}
          layout="columns"
        />
      </View>
      <View as="div" margin="small none">
        <DateTimeInput
          description={
            <ScreenReaderContent>
              {I18n.t('Choose an available from date and time')}
            </ScreenReaderContent>
          }
          dateRenderLabel={I18n.t('Available from')}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          defaultValue={new Date().toISOString()}
          layout="columns"
        />
      </View>
      <View as="div" margin="small none">
        <DateTimeInput
          description={
            <ScreenReaderContent>
              {I18n.t('Choose an available to date and time')}
            </ScreenReaderContent>
          }
          dateRenderLabel={I18n.t('Until')}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          defaultValue={new Date().toISOString()}
          layout="columns"
        />
      </View>
    </View>
  )
}
