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

import React, {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
  type ForwardedRef,
  type SyntheticEvent,
} from 'react'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import DateValidator from '@canvas/grading/DateValidator'
import moment from 'moment'
import AssigneeSelector, {type AssigneeOption} from '../AssigneeSelector'
import type {FormMessage} from '@instructure/ui-form-field'
import ContextModuleLink from './ContextModuleLink'
import type {DateLockTypes} from './types'
import {arrayEquals, generateWrapperStyleProps, setEquals, useDates} from './utils'
import {DueDateTimeInput} from './DueDateTimeInput'
import {AvailableFromDateTimeInput} from './AvailableFromDateTimeInput'
import {AvailableToDateTimeInput} from './AvailableToDateTimeInput'

const I18n = useI18nScope('differentiated_modules')

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
  highlightCard?: boolean
  removeDueDateInput?: boolean
  blueprintDateLocks?: DateLockTypes[]
}

export type ItemAssignToCardRef = {
  showValidations: () => void
  focusDeleteButton: () => void
  focusInputs: () => void
}

export default forwardRef(function ItemAssignToCard(
  props: ItemAssignToCardProps,
  ref: ForwardedRef<ItemAssignToCardRef>
) {
  const {
    courseId,
    contextModuleId,
    contextModuleName,
    cardId,
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
    highlightCard,
    blueprintDateLocks,
    removeDueDateInput,
  } = props
  const [
    dueDate,
    setDueDate,
    handleDueDateChange,
    availableFromDate,
    setAvailableFromDate,
    handleAvailableFromDateChange,
    availableToDate,
    setAvailableToDate,
    handleAvailableToDateChange,
  ] = useDates(props)

  const [showValidations, setShowValidations] = useState<boolean>(false)
  const [error, setError] = useState<FormMessage[]>([])
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({})
  const [unparsedFieldKeys, setUnparsedFieldKeys] = useState<Set<string>>(new Set())

  const deleteCardButtonRef = useRef<Element | null>(null)
  const assigneeSelectorRef = useRef<HTMLInputElement | null>(null)
  const dateInputRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const dateValidator = useRef<DateValidator>(
    new DateValidator({
      date_range: {...ENV.VALID_DATE_RANGE},
      hasGradingPeriods: ENV.HAS_GRADING_PERIODS,
      gradingPeriods: ENV.active_grading_periods,
      userIsAdmin: ENV.current_user_is_admin,
      postToSIS: ENV.POST_TO_SIS && ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT,
    })
  )

  useEffect(() => {
    onValidityChange?.(
      cardId,
      error.length === 0 &&
        Object.keys(validationErrors).length === 0 &&
        unparsedFieldKeys.size === 0
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [error.length, Object.keys(validationErrors).length, unparsedFieldKeys.size])

  useEffect(() => {
    const data: DateValidatorInputArgs = {
      due_at: dueDate,
      unlock_at: availableFromDate,
      lock_at: availableToDate,
      student_ids: [],
      course_section_id: '2',
    }
    const newErrors = dateValidator.current.validateDatetimes(data)
    const newBadDates = Object.keys(newErrors)
    const oldBadDates = Object.keys(validationErrors)
    if (!arrayEquals(newBadDates, oldBadDates)) setValidationErrors(newErrors)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dueDate, availableFromDate, availableToDate])

  useEffect(() => {
    const errorMessage: FormMessage = {
      text: I18n.t('A student or section must be selected'),
      type: 'error',
    }
    const newError = selectedAssigneeIds.length > 0 ? [] : [errorMessage]
    if (newError.length !== error.length) setError(newError)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedAssigneeIds.length])

  useImperativeHandle(ref, () => ({
    showValidations() {
      setShowValidations(true)
    },
    focusDeleteButton() {
      if (deleteCardButtonRef?.current instanceof HTMLButtonElement) {
        deleteCardButtonRef.current.focus()
      }
    },
    focusInputs() {
      if (error.length > 0) {
        assigneeSelectorRef.current?.focus()
        return
      }

      const dateInputKeys = ['due_at', 'unlock_at', 'lock_at']
      let key
      if (Object.keys(validationErrors).length > 0) {
        key = dateInputKeys.find(k => validationErrors[k] !== undefined)
      } else if (unparsedFieldKeys.size > 0) {
        key = dateInputKeys.find(k => unparsedFieldKeys.has(k))
      }
      if (key) dateInputRefs.current[key]?.focus()
    },
  }))

  const handleSelect = useCallback(
    (newSelectedAssignees: AssigneeOption[]) => {
      const deletedAssigneeIds = selectedAssigneeIds.filter(
        assigneeId => newSelectedAssignees.find(({id}) => id === assigneeId) === undefined
      )
      onCardAssignmentChange?.(cardId, newSelectedAssignees, deletedAssigneeIds)
    },
    [cardId, selectedAssigneeIds, onCardAssignmentChange]
  )

  const handleBlur = useCallback(
    (unparsedFieldKey: string) => (e: SyntheticEvent) => {
      const target = e.target as HTMLInputElement
      if (!target || target !== dateInputRefs.current[unparsedFieldKey]) return
      const unparsedFieldExists = unparsedFieldKeys.has(unparsedFieldKey)
      const isEmpty = target.value.trim() === ''
      const isValid = moment(target.value, 'll').isValid()
      const newUnparsedFieldKeys = new Set(Array.from(unparsedFieldKeys))
      if ((isEmpty || isValid) && unparsedFieldExists) {
        newUnparsedFieldKeys.delete(unparsedFieldKey)
      } else if (!isEmpty && !isValid && !unparsedFieldExists) {
        newUnparsedFieldKeys.add(unparsedFieldKey)
      }
      if (!setEquals(newUnparsedFieldKeys, unparsedFieldKeys))
        setUnparsedFieldKeys(newUnparsedFieldKeys)
    },
    [unparsedFieldKeys]
  )

  const handleDelete = useCallback(() => onDelete?.(cardId), [cardId, onDelete])

  const wrapperProps = useMemo(() => generateWrapperStyleProps(highlightCard), [highlightCard])

  const commonDateTimeInputProps = {
    breakpoints: {},
    showMessages: false,
    locale: ENV.LOCALE || 'en',
    timezone: ENV.TIMEZONE || 'UTC',
  }

  return (
    <View as="div" {...wrapperProps}>
      <View
        data-testid="item-assign-to-card"
        as="div"
        position="relative"
        padding="medium small small small"
        borderWidth="small"
        borderColor="primary"
        borderRadius="none medium medium none"
      >
        {highlightCard && <View height="100%" background="brand" width="1rem" />}
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
              elementRef={el => (deleteCardButtonRef.current = el)}
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
          messages={showValidations ? error : []}
          disabledOptionIds={disabledOptionIds}
          disableFetch={!isOpen}
          customAllOptions={customAllOptions}
          customIsLoading={customIsLoading}
          customSetSearchTerm={customSetSearchTerm}
          inputRef={el => (assigneeSelectorRef.current = el)}
          onBlur={() => setShowValidations(true)}
        />
        {!removeDueDateInput && (
          <DueDateTimeInput
            {...{
              dueDate,
              setDueDate,
              handleDueDateChange,
              validationErrors,
              unparsedFieldKeys,
              blueprintDateLocks,
              dateInputRefs: dateInputRefs.current,
              handleBlur,
            }}
            {...commonDateTimeInputProps}
          />
        )}
        <AvailableFromDateTimeInput
          {...{
            availableFromDate,
            setAvailableFromDate,
            handleAvailableFromDateChange,
            validationErrors,
            unparsedFieldKeys,
            blueprintDateLocks,
            dateInputRefs: dateInputRefs.current,
            handleBlur,
          }}
          {...commonDateTimeInputProps}
        />
        <AvailableToDateTimeInput
          {...{
            availableToDate,
            setAvailableToDate,
            handleAvailableToDateChange,
            validationErrors,
            unparsedFieldKeys,
            blueprintDateLocks,
            dateInputRefs: dateInputRefs.current,
            handleBlur,
          }}
          {...commonDateTimeInputProps}
        />
        <ContextModuleLink
          courseId={courseId}
          contextModuleId={contextModuleId}
          contextModuleName={contextModuleName}
        />
      </View>
    </View>
  )
})
