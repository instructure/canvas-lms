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

import moment from 'moment'
import type React from 'react'
import {useState, useCallback, useEffect, type SyntheticEvent} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = useI18nScope('differentiated_modules')

type UseDatesHookArgs = {
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  cardId: string
  onCardDatesChange?: (cardId: string, dateAttribute: string, dateValue: string | null) => void
}

type UseDatesHookResult = [
  string | null,
  (dueDate: string | null) => void,
  (_event: React.SyntheticEvent, value: string | undefined) => void,
  string | null,
  (availableFromDate: string | null) => void,
  (_event: React.SyntheticEvent, value: string | undefined) => void,
  string | null,
  (availableToDate: string | null) => void,
  (_event: React.SyntheticEvent, value: string | undefined) => void
]

function setTimeToStringDate(time: string, date: string | undefined): string | undefined {
  const [hour, minute, second] = time.split(':').map(Number)
  const chosenDate = moment.tz(date, ENV.TIMEZONE)
  chosenDate.set({hour, minute, second})
  return chosenDate.isValid() ? chosenDate.utc().toISOString() : date
}

export function generateMessages(
  value: string | null,
  error: string | null,
  unparsed: boolean
): FormMessage[] {
  if (unparsed) return [{type: 'error', text: I18n.t('Invalid date')}]
  if (error) return [{type: 'error', text: error}]
  if (
    ENV.CONTEXT_TIMEZONE &&
    ENV.TIMEZONE !== ENV.CONTEXT_TIMEZONE &&
    ENV.context_asset_string.startsWith('course') &&
    moment(value).isValid()
  ) {
    return [
      {
        type: 'hint',
        text: I18n.t('Local: %{datetime}', {
          datetime: moment.tz(value, ENV.TIMEZONE).format('ddd, MMM D, YYYY, h:mm A'),
        }),
      },
      {
        type: 'hint',
        text: I18n.t('Course: %{datetime}', {
          datetime: moment.tz(value, ENV.CONTEXT_TIMEZONE).format('ddd, MMM D, YYYY, h:mm A'),
        }),
      },
    ]
  }
  return []
}

export function generateWrapperStyleProps(
  highlightCard: boolean | undefined
): Record<string, string> {
  return highlightCard
    ? {
        borderWidth: 'none none none large' as const,
        'data-testid': 'highlighted_card',
        borderColor: 'brand' as const,
        borderRadius: 'medium' as const,
      }
    : {
        borderWidth: 'none' as const,
        borderColor: 'primary' as const,
        borderRadius: 'medium' as const,
      }
}

export function useDates({
  due_at,
  unlock_at,
  lock_at,
  cardId,
  onCardDatesChange,
}: UseDatesHookArgs): UseDatesHookResult {
  const [dueDate, setDueDate] = useState<string | null>(due_at)
  const [availableFromDate, setAvailableFromDate] = useState<string | null>(unlock_at)
  const [availableToDate, setAvailableToDate] = useState<string | null>(lock_at)

  useEffect(() => {
    onCardDatesChange?.(cardId, 'due_at', dueDate)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dueDate])

  useEffect(() => {
    onCardDatesChange?.(cardId, 'unlock_at', availableFromDate)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [availableFromDate])

  useEffect(() => {
    onCardDatesChange?.(cardId, 'lock_at', availableToDate)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [availableToDate])

  const handleDueDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const defaultDueTime = ENV.DEFAULT_DUE_TIME ?? '23:59:00'
      const newDueDate = dueDate ? value : setTimeToStringDate(defaultDueTime, value)
      // When user uses calendar pop-up type is "click", but for KB is "blur"
      if (_event.type !== 'blur') {
        setDueDate(newDueDate || null)
      } else {
        setTimeout(() => setDueDate(newDueDate || null), 0)
      }
    },
    [dueDate]
  )

  const handleAvailableFromDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const newAvailableFromDate = availableFromDate
        ? value
        : setTimeToStringDate('00:00:00', value)
      // When user uses calendar pop-up type is "click", but for KB is "blur"
      if (_event.type !== 'blur') {
        setAvailableFromDate(newAvailableFromDate || null)
      } else {
        setTimeout(() => setAvailableFromDate(newAvailableFromDate || null), 0)
      }
    },
    [availableFromDate]
  )

  const handleAvailableToDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const newAvailableToDate = availableToDate ? value : setTimeToStringDate('23:59:00', value)
      // When user uses calendar pop-up type is "click", but for KB is "blur"
      if (_event.type !== 'blur') {
        setAvailableToDate(newAvailableToDate || null)
      } else {
        setTimeout(() => setAvailableToDate(newAvailableToDate || null), 0)
      }
    },
    [availableToDate]
  )

  return [
    dueDate,
    setDueDate,
    handleDueDateChange,
    availableFromDate,
    setAvailableFromDate,
    handleAvailableFromDateChange,
    availableToDate,
    setAvailableToDate,
    handleAvailableToDateChange,
  ]
}

export function arrayEquals(a: any[], b: any[]) {
  return a.length === b.length && a.every((v, i) => v === b[i])
}

export function setEquals(a: Set<any>, b: Set<any>) {
  return a.size === b.size && Array.from(a).every(x => b.has(x))
}
