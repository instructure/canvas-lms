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
import {useState, useCallback, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('differentiated_modules')

const fancyMidnightDueTime = '23:59:00'

type UseDatesHookArgs = {
  required_replies_due_at: string | null
  reply_to_topic_due_at: string | null
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  cardId: string
  onCardDatesChange?: (cardId: string, dateAttribute: string, dateValue: string | null) => void
}

type UseDatesHookResult = [
  string | null,
  (requiredRepliesDueDate: string | null) => void,
  (replyToTopicDueDate: string | null) => void,
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
  const chosenDate = moment.tz(date, ENV.TIMEZONE || 'UTC')
  chosenDate.set({hour, minute, second})
  return chosenDate.isValid() ? chosenDate.utc().toISOString() : date
}

function isFancyMidnightNeeded(value: string | undefined) {
  const chosenDueTime = moment
    .utc(value)
    .tz(ENV.TIMEZONE || 'UTC')
    .format('HH:mm:00')
  return chosenDueTime === '00:00:00' && chosenDueTime !== fancyMidnightDueTime
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
  required_replies_due_at,
  reply_to_topic_due_at,
  due_at,
  unlock_at,
  lock_at,
  cardId,
  onCardDatesChange,
}: UseDatesHookArgs): UseDatesHookResult {
  const [requiredRepliesDueDate, setRequiredRepliesDueDate] = useState<string | null>(
    required_replies_due_at
  )
  const [replyToTopicDueDate, setReplyToTopicDueDate] = useState<string | null>(
    reply_to_topic_due_at
  )
  const [dueDate, setDueDate] = useState<string | null>(due_at)
  const [availableFromDate, setAvailableFromDate] = useState<string | null>(unlock_at)
  const [availableToDate, setAvailableToDate] = useState<string | null>(lock_at)

  useEffect(() => {
    onCardDatesChange?.(cardId, 'required_replies_due_at', requiredRepliesDueDate)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [requiredRepliesDueDate])

  useEffect(() => {
    onCardDatesChange?.(cardId, 'reply_to_topic_due_at', replyToTopicDueDate)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [replyToTopicDueDate])

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

  const handleRequiredRepliesDueDateChange = useCallback(
    (timeValue: String) => (_event: React.SyntheticEvent, value: string | undefined) => {
      const defaultRequiredRepliesDueDate = ENV.DEFAULT_DUE_TIME ?? '23:59:00'
      const newRequiredRepliesDueDate = requiredRepliesDueDate
        ? value
        : timeValue === ''
        ? setTimeToStringDate(defaultRequiredRepliesDueDate, value)
        : value
      // When user uses calendar pop-up type is "click", but for KB is "blur"
      if (_event.type !== 'blur') {
        setRequiredRepliesDueDate(newRequiredRepliesDueDate || null)
      } else {
        setTimeout(() => setRequiredRepliesDueDate(newRequiredRepliesDueDate || null), 0)
      }
    },
    [requiredRepliesDueDate]
  )

  const handleReplyToTopicDueDateChange = useCallback(
    (timeValue: String) => (_event: React.SyntheticEvent, value: string | undefined) => {
      const defaultReplyToTopicDueDate = ENV.DEFAULT_DUE_TIME ?? '23:59:00'
      const newReplyToTopicDueDate = replyToTopicDueDate
        ? value
        : timeValue === ''
        ? setTimeToStringDate(defaultReplyToTopicDueDate, value)
        : value
      // When user uses calendar pop-up type is "click", but for KB is "blur"
      if (_event.type !== 'blur') {
        setReplyToTopicDueDate(newReplyToTopicDueDate || null)
      } else {
        setTimeout(() => setReplyToTopicDueDate(newReplyToTopicDueDate || null), 0)
      }
    },
    [replyToTopicDueDate]
  )

  const handleDueDateChange = useCallback(
    (timeValue: String) => (_event: React.SyntheticEvent, value: string | undefined) => {
      const defaultDueTime = ENV.DEFAULT_DUE_TIME ?? '23:59:00'
      const newDueDate = dueDate
        ? value
        : timeValue === ''
        ? setTimeToStringDate(defaultDueTime, value)
        : value
      // When user uses calendar pop-up type is "click", but for KB is "blur"
      if (_event.type !== 'blur') {
        setDueDate(newDueDate || null)
      } else {
        setTimeout(() => setDueDate(newDueDate || null), 0)
      }

      if (isFancyMidnightNeeded(newDueDate)) {
        showFlashAlert({
          message: I18n.t('Due date was automatically changed to 11:59 PM'),
          type: 'info',
          srOnly: true,
          politeness: 'polite',
        })
        setTimeout(() => {
          setDueDate(setTimeToStringDate(fancyMidnightDueTime, newDueDate) || null)
        }, 200)
      }
    },
    [dueDate]
  )

  const handleAvailableFromDateChange = useCallback(
    (timeValue: String) => (_event: React.SyntheticEvent, value: string | undefined) => {
      const newAvailableFromDate = availableFromDate
        ? value
        : timeValue === ''
        ? setTimeToStringDate('00:00:00', value)
        : value
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
    (timeValue: String) => (_event: React.SyntheticEvent, value: string | undefined) => {
      const newAvailableToDate = availableToDate
        ? value
        : timeValue === ''
        ? setTimeToStringDate('23:59:00', value)
        : value
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
    requiredRepliesDueDate,
    setRequiredRepliesDueDate,
    handleRequiredRepliesDueDateChange,
    replyToTopicDueDate,
    setReplyToTopicDueDate,
    handleReplyToTopicDueDateChange,
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

export const generateCardActionLabels = (selected: string[]) => {
  switch (selected?.length) {
    case 0: {
      return {
        removeCard: I18n.t('Remove card'),
        clearDueAt: I18n.t('Clear due date/time'),
        clearReplyToTopicDueAt: I18n.t('Clear reply to topic due date/time'),
        clearRequiredRepliesDueAt: I18n.t('Clear required replies due date/time'),
        clearAvailableFrom: I18n.t('Clear available from date/time'),
        clearAvailableTo: I18n.t('Clear until date/time'),
      }
    }
    case 1:
      return {
        removeCard: I18n.t('Remove card for %{pillA}', {pillA: selected[0]}),
        clearDueAt: I18n.t('Clear due date/time for %{pillA}', {pillA: selected[0]}),
        clearReplyToTopicDueAt: I18n.t('Clear reply to topic due date/time for %{pillA}', {
          pillA: selected[0],
        }),
        clearRequiredRepliesDueAt: I18n.t('Clear required replies due date/time for %{pillA}', {
          pillA: selected[0]
        }),
        clearAvailableFrom: I18n.t('Clear available from date/time for %{pillA}', {
          pillA: selected[0],
        }),
        clearAvailableTo: I18n.t('Clear until date/time for %{pillA}', {pillA: selected[0]}),
      }
    case 2:
      return {
        removeCard: I18n.t('Remove card for %{pillA} and %{pillB}', {
          pillA: selected[0],
          pillB: selected[1],
        }),
        clearDueAt: I18n.t('Clear due date/time for %{pillA} and %{pillB}', {
          pillA: selected[0],
          pillB: selected[1],
        }),
        clearReplyToTopicDueAt: I18n.t(
          'Clear reply to topic due date/time for %{pillA} and %{pillB}',
          {
            pillA: selected[0],
            pillB: selected[1],
          }
        ),
        clearRequiredRepliesDueAt: I18n.t(
          'Clear required replies due date/time for %{pillA} and %{pillB}', 
          {
            pillA: selected[0],
            pillB: selected[1],
          }
        ),
        clearAvailableFrom: I18n.t('Clear available from date/time for %{pillA} and %{pillB}', {
          pillA: selected[0],
          pillB: selected[1],
        }),
        clearAvailableTo: I18n.t('Clear until date/time for %{pillA} and %{pillB}', {
          pillA: selected[0],
          pillB: selected[1],
        }),
      }
    case 3:
      return {
        removeCard: I18n.t('Remove card for %{pillA}, %{pillB}, and %{pillC}', {
          pillA: selected[0],
          pillB: selected[1],
          pillC: selected[2],
        }),
        clearDueAt: I18n.t('Clear due date/time for %{pillA}, %{pillB}, and %{pillC}', {
          pillA: selected[0],
          pillB: selected[1],
          pillC: selected[2],
        }),
        clearReplyToTopicDueAt: I18n.t(
          'Clear reply to topic due date/time for %{pillA}, %{pillB}, and %{pillC}',
          {
            pillA: selected[0],
            pillB: selected[1],
            pillC: selected[2],
          }
        ),
        clearRequiredRepliesDueAt: I18n.t(
          'Clear required replies due date/time for %{pillA}, %{pillB}, and %{pillC}', 
          {
            pillA: selected[0],
            pillB: selected[1],
            pillC: selected[2],
          }
        ),
        clearAvailableFrom: I18n.t(
          'Clear available from date/time for %{pillA}, %{pillB}, and %{pillC}',
          {pillA: selected[0], pillB: selected[1], pillC: selected[2]}
        ),
        clearAvailableTo: I18n.t('Clear until date/time for %{pillA}, %{pillB}, and %{pillC}', {
          pillA: selected[0],
          pillB: selected[1],
          pillC: selected[2],
        }),
      }
    default:
      return {
        removeCard: I18n.t('Remove card for %{pillA}, %{pillB}, and %{n} others', {
          pillA: selected[0],
          pillB: selected[1],
          n: selected.length - 2,
        }),
        clearDueAt: I18n.t('Clear due date/time for %{pillA}, %{pillB}, and %{n} others', {
          pillA: selected[0],
          pillB: selected[1],
          n: selected.length - 2,
        }),
        clearReplyToTopicDueAt: I18n.t(
          'Clear reply to topic due date/time for %{pillA}, %{pillB}, and %{n} others',
          {
            pillA: selected[0],
            pillB: selected[1],
            n: selected.length - 2,
          }
        ),
        clearRequiredRepliesDueAt: I18n.t(
          'Clear required replies due date/time for %{pillA}, %{pillB}, and %{n} others', 
          {
            pillA: selected[0],
            pillB: selected[1],
            n: selected.length - 2,
          }
        ),
        clearAvailableFrom: I18n.t(
          'Clear available from date/time for %{pillA}, %{pillB}, and %{n} others',
          {pillA: selected[0], pillB: selected[1], n: selected.length - 2}
        ),
        clearAvailableTo: I18n.t('Clear until date/time for %{pillA}, %{pillB}, and %{n} others', {
          pillA: selected[0],
          pillB: selected[1],
          n: selected.length - 2,
        }),
      }
  }
}
