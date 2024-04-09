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

type DueDateTimeInputProps = CustomDateTimeInputProps & {
  dueDate: string | null
  setDueDate: (dueDate: string | null) => void
  handleDueDateChange: (_event: React.SyntheticEvent, value: string | undefined) => void
}

export function DueDateTimeInput({
  dueDate,
  setDueDate,
  handleDueDateChange,
  validationErrors,
  unparsedFieldKeys,
  blueprintDateLocks,
  dateInputRefs,
  handleBlur,
  ...otherProps
}: DueDateTimeInputProps) {
  const key = 'due_at'
  const handleClear = useCallback(() => setDueDate(null), [setDueDate])
  const dateInputRef = useCallback(
    el => (dateInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  )
  const onBlur = useMemo(() => handleBlur(key), [handleBlur])
  const messages = useMemo(
    () => generateMessages(dueDate, validationErrors[key] ?? null, unparsedFieldKeys.has(key)),
    [dueDate, validationErrors, unparsedFieldKeys]
  )

  const dueDateProps = {
    key,
    id: key,
    disabled: Boolean(blueprintDateLocks?.includes('due_dates')),
    description: I18n.t('Choose a due date and time'),
    dateRenderLabel: I18n.t('Due Date'),
    value: dueDate,
    onChange: handleDueDateChange,
    onClear: handleClear,
    messages,
    onBlur,
    dateInputRef,
  }

  return <ClearableDateTimeInput {...dueDateProps} {...otherProps} />
}
