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

import React, {useCallback, useEffect, useRef, useState, type SyntheticEvent} from 'react'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import DateValidator from '@canvas/grading/DateValidator'
import ClearableDateTimeInput from './ClearableDateTimeInput'
import moment from 'moment'
import AssigneeSelector, {type AssigneeOption} from '../AssigneeSelector'
import type {FormMessage} from '@instructure/ui-form-field'
import ContextModuleLink from './ContextModuleLink'

const I18n = useI18nScope('differentiated_modules')

function arrayEquals(a: any[], b: any[]) {
  return a.length === b.length && a.every((v, i) => v === b[i])
}

export interface DateValidatorInputArgs {
  lock_at: string | null
  unlock_at: string | null
  due_at: string | null
  set_type?: string
  course_section_id?: string | null
  student_ids?: string[]
}

export type ItemAssignToCardProps = {
  courseId: string
  cardId: string
  contextModuleId?: string | null
  contextModuleName?: string | null
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  onDelete?: (cardId: string) => void
  onValidityChange?: (cardId: string, isValid: boolean) => void
  onCardAssignmentChange?: (
    cardId: string,
    assignees: AssigneeOption[],
    deletedAssignees: string[]
  ) => void
  onCardDatesChange?: (cardId: string, dateAttribute: string, dateValue: string | null) => void
  disabledOptionIds: string[]
  selectedAssigneeIds: string[]
  isOpen?: boolean
  everyoneOption?: AssigneeOption
  customAllOptions?: AssigneeOption[]
  customIsLoading?: boolean
  customSetSearchTerm?: (term: string) => void
}

function setTimeToStringDate(time: string, date: string | undefined): string | undefined {
  const [hour, minute, second] = time.split(':').map(Number)
  const chosenDate = moment.tz(date, ENV.TIMEZONE)
  chosenDate.set({hour, minute, second})
  return chosenDate.isValid() ? chosenDate.utc().toISOString() : date
}

function generateMessages(
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

export default function ItemAssignToCard({
  courseId,
  contextModuleId,
  contextModuleName,
  cardId,
  due_at = null,
  unlock_at = null,
  lock_at = null,
  onDelete,
  onValidityChange,
  onCardAssignmentChange,
  onCardDatesChange,
  disabledOptionIds,
  selectedAssigneeIds,
  isOpen,
  everyoneOption,
  customAllOptions,
  customIsLoading,
  customSetSearchTerm,
}: ItemAssignToCardProps) {
  const [dateValidator] = useState<DateValidator>(
    new DateValidator({
      date_range: {...ENV.VALID_DATE_RANGE},
      hasGradingPeriods: ENV.HAS_GRADING_PERIODS,
      gradingPeriods: ENV.active_grading_periods,
      userIsAdmin: ENV.current_user_is_admin,
      postToSIS: ENV.POST_TO_SIS && ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT,
    })
  )
  const [dueDate, setDueDate] = useState<string | null>(due_at)
  const [availableFromDate, setAvailableFromDate] = useState<string | null>(unlock_at)
  const [availableToDate, setAvailableToDate] = useState<string | null>(lock_at)
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({})
  const [unparsedFieldKeys, setUnparsedFieldKeys] = useState<Set<string>>(new Set())
  const [error, setError] = useState<FormMessage[]>([])
  const dateInputRefs = useRef<Record<string, HTMLInputElement | null>>({})

  const handleSelect = (newSelectedAssignees: AssigneeOption[]) => {
    const errorMessage: FormMessage = {
      text: I18n.t('A student or section must be selected'),
      type: 'error',
    }
    const deletedAssigneeIds = selectedAssigneeIds.filter(
      assigneeId => newSelectedAssignees.find(({id}) => id === assigneeId) === undefined
    )
    setError(newSelectedAssignees.length > 0 ? [] : [errorMessage])
    onCardAssignmentChange?.(cardId, newSelectedAssignees, deletedAssigneeIds)
  }

  const handleBlur = useCallback(
    (unparsedFieldKey: string) => (e: SyntheticEvent) => {
      const target = e.target as HTMLInputElement
      if (!target || target !== dateInputRefs.current[unparsedFieldKey]) return
      const unparsedFieldExists = unparsedFieldKeys.has(unparsedFieldKey)
      const isEmpty = target.value.trim() === ''
      const isValid = moment(target.value).isValid()
      if ((isEmpty || isValid) && unparsedFieldExists) {
        unparsedFieldKeys.delete(unparsedFieldKey)
        setUnparsedFieldKeys(new Set([...unparsedFieldKeys]))
      } else if (!isEmpty && !isValid && !unparsedFieldExists) {
        setUnparsedFieldKeys(new Set([unparsedFieldKey, ...unparsedFieldKeys]))
      }
    },
    [unparsedFieldKeys]
  )

  const handleDelete = useCallback(() => {
    onDelete?.(cardId)
  }, [cardId, onDelete])

  const handleDueAtChange = useCallback(
    (newDate: string | null) => {
      setDueDate(newDate)
      onCardDatesChange?.(cardId, 'due_at', newDate)
    },
    [cardId, onCardDatesChange]
  )

  const handleDueDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const defaultDueTime = ENV.DEFAULT_DUE_TIME ?? '23:59:00'
      const newDueDate = dueDate ? value : setTimeToStringDate(defaultDueTime, value)
      handleDueAtChange(newDueDate || null)
    },
    [dueDate, handleDueAtChange]
  )

  const handleUnlockAtChange = useCallback(
    (newDate: string | null) => {
      setAvailableFromDate(newDate)
      onCardDatesChange?.(cardId, 'unlock_at', newDate)
    },
    [cardId, onCardDatesChange]
  )

  const handleAvailableFromDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const newAvailableFromDate = availableFromDate
        ? value
        : setTimeToStringDate('00:00:00', value)
      handleUnlockAtChange(newAvailableFromDate || null)
    },
    [availableFromDate, handleUnlockAtChange]
  )

  const handleLockAtChange = useCallback(
    (newDate: string | null) => {
      setAvailableToDate(newDate)
      onCardDatesChange?.(cardId, 'lock_at', newDate)
    },
    [cardId, onCardDatesChange]
  )

  const handleAvailableToDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const newAvailableToDate = availableToDate ? value : setTimeToStringDate('23:59:00', value)
      handleLockAtChange(newAvailableToDate || null)
    },
    [availableToDate, handleLockAtChange]
  )

  useEffect(() => {
    const data: DateValidatorInputArgs = {
      due_at: dueDate,
      unlock_at: availableFromDate,
      lock_at: availableToDate,
      student_ids: [],
      course_section_id: '2',
    }
    const newErrors = dateValidator.validateDatetimes(data)
    const newBadDates = Object.keys(newErrors)
    const oldBadDates = Object.keys(validationErrors)
    if (!arrayEquals(newBadDates, oldBadDates)) {
      onValidityChange?.(cardId, newBadDates.length === 0)
      setValidationErrors(newErrors)
    }
  }, [
    availableFromDate,
    availableToDate,
    cardId,
    dateValidator,
    dueDate,
    onValidityChange,
    validationErrors,
  ])

  type DateTimeInput = {
    key: string
    description: string
    dateRenderLabel: string
    value: string | null
    onChange: (event: React.SyntheticEvent, value: string | undefined) => void
    onClear: () => void
    messages: FormMessage[]
  }

  const dateTimeInputs: DateTimeInput[] = [
    {
      key: 'due_at',
      description: I18n.t('Choose a due date and time'),
      dateRenderLabel: I18n.t('Due Date'),
      value: dueDate,
      onChange: handleDueDateChange,
      onClear: () => handleDueAtChange(null),
      messages: generateMessages(
        dueDate,
        validationErrors.due_at ?? null,
        unparsedFieldKeys.has('due_at')
      ),
    },
    {
      key: 'unlock_at',
      description: I18n.t('Choose an available from date and time'),
      dateRenderLabel: I18n.t('Available from'),
      value: availableFromDate,
      onChange: handleAvailableFromDateChange,
      onClear: () => handleUnlockAtChange(null),
      messages: generateMessages(
        availableFromDate,
        validationErrors.unlock_at ?? null,
        unparsedFieldKeys.has('unlock_at')
      ),
    },
    {
      key: 'lock_at',
      description: I18n.t('Choose an available to date and time'),
      dateRenderLabel: I18n.t('Until'),
      value: availableToDate,
      onChange: handleAvailableToDateChange,
      onClear: () => handleLockAtChange(null),
      messages: generateMessages(
        availableToDate,
        validationErrors.lock_at ?? null,
        unparsedFieldKeys.has('lock_at')
      ),
    },
  ]

  return (
    <View
      data-testid="item-assign-to-card"
      as="div"
      position="relative"
      padding="medium small small small"
      borderWidth="small"
      borderColor="primary"
      borderRadius="medium"
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
      <AssigneeSelector
        onSelect={handleSelect}
        selectedOptionIds={selectedAssigneeIds}
        everyoneOption={everyoneOption}
        courseId={courseId}
        defaultValues={[]}
        clearAllDisabled={true}
        size="medium"
        messages={error}
        disabledOptionIds={disabledOptionIds}
        disableFetch={!isOpen}
        customAllOptions={customAllOptions}
        customIsLoading={customIsLoading}
        customSetSearchTerm={customSetSearchTerm}
      />
      {dateTimeInputs.map((props: DateTimeInput) => (
        <ClearableDateTimeInput
          breakpoints={{}}
          {...props}
          showMessages={false}
          locale={ENV.LOCALE || 'en'}
          timezone={ENV.TIMEZONE || 'UTC'}
          onBlur={handleBlur(props.key)}
          dateInputRef={el => (dateInputRefs.current[props.key] = el)}
        />
      ))}
      <ContextModuleLink
        courseId={courseId}
        contextModuleId={contextModuleId}
        contextModuleName={contextModuleName}
      />
    </View>
  )
}
