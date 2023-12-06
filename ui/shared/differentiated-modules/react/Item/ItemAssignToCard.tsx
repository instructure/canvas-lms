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

import React, {useCallback, useEffect, useState} from 'react'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import DateValidator from '@canvas/datetime/DateValidator'
import ClearableDateTimeInput from './ClearableDateTimeInput'
import moment from 'moment'
import AssigneeSelector, {type AssigneeOption} from '../AssigneeSelector'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = useI18nScope('differentiated_modules')

function arrayEquals(a: any[], b: any[]) {
  return a.length === b.length && a.every((v, i) => v === b[i])
}

export interface DateValidatorInputArgs {
  lock_at: string | null
  unlock_at: string | null
  due_at: string | null
  set_type?: string
  course_section_id?: string
  student_ids?: string[]
}

export type ItemAssignToCardProps = {
  courseId: string
  cardId: string
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
  disabledOptionIds: string[]
  selectedAssigneeIds: string[]
  isOpen?: boolean
  everyoneOption?: AssigneeOption
  customAllOptions?: AssigneeOption[]
  customIsLoading?: boolean
  customSetSearchTerm?: (term: string) => void
}

export default function ItemAssignToCard({
  courseId,
  cardId,
  due_at,
  unlock_at,
  lock_at,
  onDelete,
  onValidityChange,
  onCardAssignmentChange,
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
  const [error, setError] = useState<FormMessage[]>([])

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

  const handleDelete = useCallback(() => {
    onDelete?.(cardId)
  }, [cardId, onDelete])

  const handleDueDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      const defaultDueTime = ENV.DEFAULT_DUE_TIME ?? '23:59:00'
      if (dueDate === null) {
        const [hour, minute, second] = defaultDueTime.split(':').map(Number)
        const chosenDate = moment(value)
        chosenDate.set({hour, minute, second})
        const newDueDate = chosenDate.isValid() ? chosenDate.toISOString() : value
        setDueDate(newDueDate || null)
      } else {
        setDueDate(value || null)
      }
    },
    [dueDate]
  )

  const handleAvailableFromDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      setAvailableFromDate(value || null)
    },
    []
  )

  const handleAvailableToDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      if (availableToDate === null) {
        const chosenDate = moment(value)
        chosenDate.set({hour: 23, minute: 59, second: 0})
        const newAvailableToDate = chosenDate.isValid() ? chosenDate.toISOString() : value
        setAvailableToDate(newAvailableToDate || null)
      } else {
        setAvailableToDate(value || null)
      }
    },
    [availableToDate]
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

  const dateTimeInputs = [
    {
      key: 'due_at',
      description: I18n.t('Choose a due date and time'),
      dateRenderLabel: I18n.t('Due Date'),
      value: dueDate,
      onChange: handleDueDateChange,
      onClear: () => setDueDate(null),
    },
    {
      key: 'unlock_at',
      description: I18n.t('Choose an available from date and time'),
      dateRenderLabel: I18n.t('Available from'),
      value: availableFromDate,
      onChange: handleAvailableFromDateChange,
      onClear: () => setAvailableFromDate(null),
    },
    {
      key: 'lock_at',
      description: I18n.t('Choose an available to date and time'),
      dateRenderLabel: I18n.t('Until'),
      value: availableToDate,
      onChange: handleAvailableToDateChange,
      onClear: () => setAvailableToDate(null),
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
      {dateTimeInputs.map(props => (
        <ClearableDateTimeInput
          breakpoints={{}}
          {...props}
          messages={
            // eslint-disable-next-line react/prop-types
            validationErrors[props.key] ? [{type: 'error', text: validationErrors[props.key]}] : []
          }
        />
      ))}
    </View>
  )
}
