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

type PeerReviewAvailableToDateTimeInputProps = CustomDateTimeInputProps & {
  peerReviewAvailableToDate: string | null
  setPeerReviewAvailableToDate: (date: string | null) => void
  handlePeerReviewAvailableToDateChange: (
    _event: React.SyntheticEvent,
    value: string | undefined,
  ) => void
  clearButtonAltLabel: string
  disabled: boolean
}

const PeerReviewAvailableToDateTimeInput = ({
  peerReviewAvailableToDate,
  setPeerReviewAvailableToDate,
  handlePeerReviewAvailableToDateChange,
  handleBlur,
  dateInputRefs,
  timeInputRefs,
  validationErrors,
  unparsedFieldKeys,
  disabled,
  ...rest
}: PeerReviewAvailableToDateTimeInputProps) => {
  const key = 'peer_review_available_to'

  const handleClear = useCallback(
    () => setPeerReviewAvailableToDate(null),
    [setPeerReviewAvailableToDate],
  )

  const dateInputRef = useCallback(
    // @ts-expect-error
    el => (dateInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  )
  const timeInputRef = useCallback(
    // @ts-expect-error
    el => (timeInputRefs[key] = el),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  )
  const onBlur = useMemo(() => handleBlur(key), [handleBlur])
  const messages = useMemo(
    () =>
      generateMessages(
        peerReviewAvailableToDate,
        validationErrors[key] ?? null,
        unparsedFieldKeys.has(key),
      ),
    [peerReviewAvailableToDate, validationErrors, key, unparsedFieldKeys],
  )

  return (
    <ClearableDateTimeInput
      id={key}
      disabled={disabled}
      description={I18n.t('Choose a peer review available to date and time')}
      dateRenderLabel={I18n.t('Until')}
      value={peerReviewAvailableToDate}
      onChange={handlePeerReviewAvailableToDateChange}
      onClear={handleClear}
      messages={messages}
      onBlur={onBlur}
      dateInputRef={dateInputRef}
      timeInputRef={timeInputRef}
      {...rest}
    />
  )
}

export default PeerReviewAvailableToDateTimeInput
