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

import React, {useCallback, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import ClearableDateTimeInput from '../ClearableDateTimeInput'
import type {CustomDateTimeInputProps} from '../types'
import {generateMessages} from '../utils'

const I18n = createI18nScope('differentiated_modules')

type PeerReviewDueDateTimeInputProps = CustomDateTimeInputProps & {
  peerReviewDueDate: string | null
  setPeerReviewDueDate: (date: string | null) => void
  handlePeerReviewDueDateChange: (_event: React.SyntheticEvent, value: string | undefined) => void
  clearButtonAltLabel: string
  disabled: boolean
}

const PeerReviewDueDateTimeInput = ({
  peerReviewDueDate,
  setPeerReviewDueDate,
  handlePeerReviewDueDateChange,
  handleBlur,
  dateInputRefs,
  timeInputRefs,
  validationErrors,
  unparsedFieldKeys,
  disabled,
  ...rest
}: PeerReviewDueDateTimeInputProps) => {
  const key = 'peer_review_due_at'

  const handleClear = useCallback(() => setPeerReviewDueDate(null), [setPeerReviewDueDate])

  const dateInputRef = useCallback(
    (el: HTMLInputElement | null) => (dateInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  )
  const timeInputRef = useCallback(
    (el: HTMLInputElement | null) => (timeInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  )

  const onBlur = useMemo(() => handleBlur(key), [handleBlur])

  const messages = useMemo(
    () =>
      generateMessages(
        peerReviewDueDate,
        validationErrors[key] ?? null,
        unparsedFieldKeys.has(key),
      ),
    [peerReviewDueDate, validationErrors, key, unparsedFieldKeys],
  )

  return (
    <ClearableDateTimeInput
      id={key}
      disabled={disabled}
      description={I18n.t('Choose a peer review due date and time')}
      dateRenderLabel={I18n.t('Review Due Date')}
      value={peerReviewDueDate}
      onChange={handlePeerReviewDueDateChange}
      onClear={handleClear}
      messages={messages}
      onBlur={onBlur}
      dateInputRef={dateInputRef}
      timeInputRef={timeInputRef}
      {...rest}
    />
  )
}

export default PeerReviewDueDateTimeInput
