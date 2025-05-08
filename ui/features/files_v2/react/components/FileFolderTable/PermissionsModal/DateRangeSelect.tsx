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
import {DateTimeInput} from '@instructure/ui-date-time-input'
import type {FormMessage} from '@instructure/ui-form-field'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {
  DATE_RANGE_TYPE_OPTIONS,
  isStartDateRequired,
  isEndDateRequired,
  type DateRangeTypeOption,
} from './PermissionsModalUtils'

const I18n = createI18nScope('files_v2')

export type DateRangeSelectProps = {
  dateRangeType: DateRangeTypeOption | null
  onChangeDateRangeType: (event: React.SyntheticEvent, data: {id?: string}) => void
  unlockAt: string | null
  unlockAtDateInputRef: (el: HTMLInputElement | null) => void
  unlockAtTimeInputRef: (el: HTMLInputElement | null) => void
  unlockAtError: FormMessage[] | undefined
  onChangeUnlockAt: (event: React.SyntheticEvent, isoValue?: string) => void
  lockAt: string | null
  lockAtDateInputRef: (el: HTMLInputElement | null) => void
  lockAtTimeInputRef: (el: HTMLInputElement | null) => void
  lockAtError: FormMessage[] | undefined
  onChangeLockAt: (event: React.SyntheticEvent, isoValue?: string) => void
}

export const DateRangeSelect = ({
  dateRangeType,
  onChangeDateRangeType,
  unlockAt,
  unlockAtDateInputRef,
  unlockAtTimeInputRef,
  unlockAtError,
  onChangeUnlockAt,
  lockAt,
  lockAtDateInputRef,
  lockAtTimeInputRef,
  lockAtError,
  onChangeLockAt,
}: DateRangeSelectProps) => {
  return (
    <>
      <View as="div" margin="small none none none">
        <SimpleSelect
          data-testid="permissions-date-range-selector"
          renderLabel={I18n.t('Set availability by')}
          value={dateRangeType?.id}
          onChange={onChangeDateRangeType}
        >
          {Object.values(DATE_RANGE_TYPE_OPTIONS).map(option => (
            <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
              {option.label}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </View>
      {isStartDateRequired(dateRangeType) && (
        <View data-testid="permissions-unlock-at" as="div" margin="small none none none">
          <DateTimeInput
            description={<></>}
            prevMonthLabel={I18n.t('Previous month')}
            nextMonthLabel={I18n.t('Next month')}
            invalidDateTimeMessage={I18n.t('Invalid date')}
            dateRenderLabel={I18n.t('Available from')}
            timeRenderLabel={I18n.t('Time')}
            layout="columns"
            value={unlockAt || undefined}
            dateInputRef={unlockAtDateInputRef}
            timeInputRef={unlockAtTimeInputRef}
            onChange={onChangeUnlockAt}
            messages={unlockAtError}
            isRequired={true}
            showMessages={false}
            timezone={ENV.TIMEZONE}
          />
        </View>
      )}

      {isEndDateRequired(dateRangeType) && (
        <View data-testid="permissions-lock-at" as="div" margin="small none none none">
          <DateTimeInput
            description={<></>}
            prevMonthLabel={I18n.t('Previous month')}
            nextMonthLabel={I18n.t('Next month')}
            invalidDateTimeMessage={I18n.t('Invalid date')}
            dateRenderLabel={I18n.t('Until')}
            timeRenderLabel={I18n.t('Time')}
            layout="columns"
            value={lockAt || undefined}
            dateInputRef={lockAtDateInputRef}
            timeInputRef={lockAtTimeInputRef}
            onChange={onChangeLockAt}
            messages={lockAtError}
            isRequired={true}
            showMessages={false}
            timezone={ENV.TIMEZONE}
          />
        </View>
      )}
    </>
  )
}
