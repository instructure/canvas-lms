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

type RequiredRepliesDueDateTimeInputProps = CustomDateTimeInputProps & {
  requiredRepliesDueDate: string | null
  setRequiredRepliesDueDate: (requiredRepliesDueDate: string | null) => void
  handleRequiredRepliesDueDateChange: (_event: React.SyntheticEvent, value: string | undefined) => void
  disabledWithGradingPeriod?: boolean
  clearButtonAltLabel: string
}

export function RequiredRepliesDueDateTimeInput({
  requiredRepliesDueDate,
  setRequiredRepliesDueDate,
  handleRequiredRepliesDueDateChange,
  validationErrors,
  unparsedFieldKeys,
  blueprintDateLocks,
  dateInputRefs,
  timeInputRefs,
  handleBlur,
  disabledWithGradingPeriod,
  clearButtonAltLabel,
  ...otherProps
}: RequiredRepliesDueDateTimeInputProps) {
  const key = 'required_replies_due_at'
  const handleClear = useCallback(() => setRequiredRepliesDueDate(null), [setRequiredRepliesDueDate])
  const dateInputRef = useCallback(
    el => (dateInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )
  const timeInputRef = useCallback(
    el => (timeInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )
  const onBlur = useMemo(() => handleBlur(key), [handleBlur])
  const messages = useMemo(
    () =>
      generateMessages(
        requiredRepliesDueDate,
        validationErrors[key] ?? null,
        unparsedFieldKeys.has(key)
      ),
    [requiredRepliesDueDate, validationErrors, unparsedFieldKeys]
  )

  const requiredRepliesDueDateProps = {
    key,
    id: key,
    disabled:
      Boolean(blueprintDateLocks?.includes('availability_dates')) || disabledWithGradingPeriod,
    description: I18n.t('Choose an required replies due date and time'),
    dateRenderLabel: I18n.t('Required Replies Due Date'),
    value: requiredRepliesDueDate,
    onChange: handleRequiredRepliesDueDateChange,
    onClear: handleClear,
    messages,
    onBlur,
    dateInputRef,
    timeInputRef,
    clearButtonAltLabel,
  }

  return <ClearableDateTimeInput {...requiredRepliesDueDateProps} {...otherProps} />
}
