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
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import DateValidator from '@canvas/datetime/DateValidator'
// import AssigneeSelector from '../AssigneeSelector'

const I18n = useI18nScope('differentiated_modules')

// TODO: until we resolve how to handle queries (which wreak havoc on specs)
function AssigneeSelector({cardId}: {cardId: string}) {
  return (
    <View as="div" borderWidth="small" padding="small" margin="medium 0 0 0">
      Assign To goes here (cardId: {cardId})
    </View>
  )
}

function arrayEquals(a: any[], b: any[]) {
  return a.length === b.length && a.every((v, i) => v === b[i])
}

export interface DateValidatorInputArgs {
  lock_at?: string
  unlock_at?: string
  due_at?: string
  set_type?: string
  course_section_id?: string
  student_ids?: string[]
}

export type ItemAssignToCardProps = {
  cardId: string
  onDelete?: (cardId: string) => void
  onValidityChange?: (cardId: string, isValid: boolean) => void
}

export default function ItemAssignToCard({
  cardId,
  onDelete,
  onValidityChange,
}: ItemAssignToCardProps) {
  const [dateValidator] = useState<DateValidator>(
    new DateValidator({
      date_range: {...ENV.VALID_DATE_RANGE},
      hasGradingPeriods: ENV.HAS_GRADING_PERIODS,
      gradingPeriods: ENV.active_grading_periods,
      userIsAdmin: (ENV.current_user_roles || []).includes('admin'),
      postToSIS: ENV.POST_TO_SIS && ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT,
    })
  )
  const [dueDate, setDueDate] = useState<string | undefined>(new Date().toISOString())
  const [availableFromDate, setAvailableFromDate] = useState<string | undefined>(
    new Date().toISOString()
  )
  const [availableToDate, setAvailableToDate] = useState<string | undefined>(
    new Date().toISOString()
  )
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({})

  const handleDelete = useCallback(() => {
    onDelete?.(cardId)
  }, [cardId, onDelete])

  const handleDueDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      setDueDate(value)
    },
    []
  )

  const handleAvailableFromDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      setAvailableFromDate(value)
    },
    []
  )

  const handleAvailableToDateChange = useCallback(
    (_event: React.SyntheticEvent, value: string | undefined) => {
      setAvailableToDate(value)
    },
    []
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

  return (
    <View
      data-testid="item-assign-to-card"
      as="div"
      position="relative"
      padding="medium small small small"
      borderWidth="small"
      borderColor="primary"
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
      <AssigneeSelector cardId={cardId} />

      <View as="div" margin="small none">
        <DateTimeInput
          allowNonStepInput={true}
          dateFormat="MMM D, YYYY"
          description={
            <ScreenReaderContent>{I18n.t('Choose a due date and time')}</ScreenReaderContent>
          }
          dateRenderLabel={I18n.t('Due Date')}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          value={dueDate}
          layout="columns"
          messages={validationErrors.due_at ? [{type: 'error', text: validationErrors.due_at}] : []}
          onChange={handleDueDateChange}
        />
      </View>
      <View as="div" margin="small none">
        <DateTimeInput
          allowNonStepInput={true}
          dateFormat="MMM D, YYYY"
          description={
            <ScreenReaderContent>
              {I18n.t('Choose an available from date and time')}
            </ScreenReaderContent>
          }
          dateRenderLabel={I18n.t('Available from')}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          value={availableFromDate}
          layout="columns"
          messages={
            validationErrors.unlock_at ? [{type: 'error', text: validationErrors.unlock_at}] : []
          }
          onChange={handleAvailableFromDateChange}
        />
      </View>
      <View as="div" margin="small none">
        <DateTimeInput
          allowNonStepInput={true}
          dateFormat="MMM D, YYYY"
          description={
            <ScreenReaderContent>
              {I18n.t('Choose an available to date and time')}
            </ScreenReaderContent>
          }
          dateRenderLabel={I18n.t('Until')}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          value={availableToDate}
          layout="columns"
          messages={
            validationErrors.lock_at ? [{type: 'error', text: validationErrors.lock_at}] : []
          }
          onChange={handleAvailableToDateChange}
        />
      </View>
    </View>
  )
}
