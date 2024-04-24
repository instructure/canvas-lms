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

import React, {useCallback, useMemo} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import ClearableDateTimeInput from './ClearableDateTimeInput'
import type {CustomDateTimeInputProps} from './types'
import {generateMessages} from './utils'

const I18n = useI18nScope('differentiated_modules')

type AvailableToDateTimeInputProps = CustomDateTimeInputProps & {
  availableToDate: string | null
  setAvailableToDate: (availableToDate: string | null) => void
  handleAvailableToDateChange: (_event: React.SyntheticEvent, value: string | undefined) => void
}

export function AvailableToDateTimeInput({
  availableToDate,
  setAvailableToDate,
  handleAvailableToDateChange,
  validationErrors,
  unparsedFieldKeys,
  blueprintDateLocks,
  dateInputRefs,
  handleBlur,
  ...otherProps
}: AvailableToDateTimeInputProps) {
  const key = 'lock_at'
  const handleClear = useCallback(() => setAvailableToDate(null), [setAvailableToDate])
  const dateInputRef = useCallback(
    el => (dateInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )
  const onBlur = useMemo(() => handleBlur(key), [handleBlur])
  const messages = useMemo(
    () =>
      generateMessages(availableToDate, validationErrors[key] ?? null, unparsedFieldKeys.has(key)),
    [availableToDate, validationErrors, unparsedFieldKeys]
  )

  const availableToDateProps = {
    key,
    id: key,
    disabled: Boolean(blueprintDateLocks?.includes('availability_dates')),
    description: I18n.t('Choose an available to date and time'),
    dateRenderLabel: I18n.t('Until'),
    value: availableToDate,
    onChange: handleAvailableToDateChange,
    onClear: handleClear,
    messages,
    onBlur,
    dateInputRef,
  }

  return <ClearableDateTimeInput {...availableToDateProps} {...otherProps} />
}
