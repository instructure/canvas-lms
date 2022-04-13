/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useCallback} from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

const I18n = useI18nScope('assignments_bulk_edit')

function BulkEditDateSelect({selectDateRange}) {
  const [startDate, setStartDate] = useState(null)
  const [endDate, setEndDate] = useState(null)

  const dateFormatter = useDateTimeFormat('date.formats.medium_with_weekday')

  const handleApply = useCallback(() => {
    const start = startDate || new Date(-100000, 1)
    const end = endDate || new Date(100000, 0)
    selectDateRange(start, end)
  }, [endDate, startDate, selectDateRange])

  function outOfOrder() {
    return startDate && endDate && startDate > endDate
  }
  function canApply() {
    return (startDate || endDate) && !outOfOrder()
  }

  function messages() {
    return outOfOrder()
      ? [{text: I18n.t('The end date must be after the start date'), type: 'error'}]
      : []
  }

  return (
    <Flex margin="0 0 medium 0">
      {/* Using a flex to force FormFieldGroup to shrink and not be full width */}
      <Flex.Item>
        <FormFieldGroup
          description={I18n.t('Select by date range')}
          layout="columns"
          colSpacing="small"
          messages={messages()}
        >
          {/* Use a View to trick FormFieldGroup into having one child for layout purposes */}
          {/* Otherwise all the children get equal space, and we don't want that */}
          <View>
            <CanvasDateInput
              selectedDate={startDate}
              renderLabel={
                <ScreenReaderContent>{I18n.t('Selection start date')}</ScreenReaderContent>
              }
              formatDate={dateFormatter}
              onSelectedDateChange={setStartDate}
            />
            <View as="span" margin="0 small">
              <Text weight="bold">{I18n.t('to')}</Text>
            </View>
            <CanvasDateInput
              selectedDate={endDate}
              renderLabel={
                <ScreenReaderContent>{I18n.t('Selection end date')}</ScreenReaderContent>
              }
              formatDate={dateFormatter}
              onSelectedDateChange={setEndDate}
            />
            <Button
              margin="0 0 0 small"
              size="small"
              interaction={canApply() ? 'enabled' : 'disabled'}
              onClick={handleApply}
            >
              <ScreenReaderContent>{I18n.t('Apply date range selection')}</ScreenReaderContent>
              <PresentationContent>{I18n.t('Apply')}</PresentationContent>
            </Button>
          </View>
        </FormFieldGroup>
      </Flex.Item>
    </Flex>
  )
}

export default BulkEditDateSelect
