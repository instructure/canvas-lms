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
import AssigneeSelector from '../AssigneeSelector'
import type {FormMessage} from '@instructure/ui-form-field'
import ContextModuleLink from './ContextModuleLink'
import type {AssigneeOption, DateLockTypes} from './types'
import {
  arrayEquals,
  generateWrapperStyleProps,
  setEquals,
  useDates,
  generateCardActionLabels,
} from './utils'
import {DueDateTimeInput} from './DueDateTimeInput'
import {ReplyToTopicDueDateTimeInput} from './ReplyToTopicDueDateTimeInput'
import {RequiredRepliesDueDateTimeInput} from './RequiredRepliesDueDateTimeInput'
import {AvailableFromDateTimeInput} from './AvailableFromDateTimeInput'
import {AvailableToDateTimeInput} from './AvailableToDateTimeInput'
import {Text} from '@instructure/ui-text'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'

const I18n = useI18nScope('differentiated_modules')

export interface DateValidatorInputArgs {
  required_replies_due_at: string | null
  reply_to_topic_due_at: string | null
  lock_at: string | null
  unlock_at: string | null
  due_at: string | null
  set_type?: string
  course_section_id?: string | null
  student_ids?: string[]
  persisted?: boolean
  skip_grading_periods?: boolean
}

export type ItemAssignToCardProps = {
  courseId: string
  cardId: string
  contextModuleId?: string | null
  contextModuleName?: string | null
  required_replies_due_at: string | null
  reply_to_topic_due_at: string | null
  due_at: string | null
  original_due_at: string | null
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
  isCheckpointed?: boolean
  blueprintDateLocks?: DateLockTypes[]
  postToSIS?: boolean
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
    isCheckpointed,
    original_due_at,
    postToSIS,
  } = props
  const [
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
  ] = useDates(props)

  const [showValidations, setShowValidations] = useState<boolean>(false)
  const [error, setError] = useState<FormMessage[]>([])
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({})
  const [unparsedFieldKeys, setUnparsedFieldKeys] = useState<Set<string>>(new Set())

  const deleteCardButtonRef = useRef<Element | null>(null)
  const assigneeSelectorRef = useRef<HTMLInputElement | null>(null)
  const dateInputRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const timeInputRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const dateValidator = useRef<DateValidator>(
    new DateValidator({
      date_range: {...ENV.VALID_DATE_RANGE},
      hasGradingPeriods: ENV.HAS_GRADING_PERIODS,
      gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods),
      userIsAdmin: ENV.current_user_is_admin,
      postToSIS,
    })
  )

  const cardActionLabels = useMemo(
    () =>
      generateCardActionLabels(
        customAllOptions
          ?.filter(option => selectedAssigneeIds.includes(option.id))
          .map(({value}) => value) ?? []
      ),
    [customAllOptions, selectedAssigneeIds]
  )

  const dueAtHasChanged = () => {
    // console.log('>> dates', original_due_at, dueDate)
    const originalDueAt = new Date(original_due_at || 0)
    const newDueAt = new Date(dueDate || 0)
    // Since a user can't edit the seconds field in the UI and the form also
    // thinks that the seconds is always set to 00, we compare by everything
    // except seconds.
    originalDueAt.setSeconds(0)
    newDueAt.setSeconds(0)
    return originalDueAt.getTime() !== newDueAt.getTime()
  }

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
      required_replies_due_at: requiredRepliesDueDate,
      reply_to_topic_due_at: replyToTopicDueDate,
      due_at: dueDate,
      unlock_at: availableFromDate,
      lock_at: availableToDate,
      student_ids: [],
      course_section_id: '2',
      persisted: !dueAtHasChanged(),
      skip_grading_periods: dueDate === null,
    }
    const newErrors = dateValidator.current.validateDatetimes(data)
    const newBadDates = Object.keys(newErrors)
    const oldBadDates = Object.keys(validationErrors)
    if (!arrayEquals(newBadDates, oldBadDates)) setValidationErrors(newErrors)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dueDate, availableFromDate, availableToDate, replyToTopicDueDate, requiredRepliesDueDate])

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

      const dateInputKeys = [
        'required_replies_due_at',
        'reply_to_topic_due_at',
        'due_at',
        'unlock_at',
        'lock_at',
      ]
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

      const dateField = dateInputRefs.current[unparsedFieldKey]
      const isEmpty = dateField.value.trim() === ''
      const isValid = moment(dateField.value, 'll').isValid()
      const unparsedFieldExists = unparsedFieldKeys.has(unparsedFieldKey)
      const newUnparsedFieldKeys = new Set(Array.from(unparsedFieldKeys))

      // e.target is not working in the onBlur event from the DateTimeInput component.
      // so if we get a null target, we asumme it's the time field
      if (!target && timeInputRefs.current[unparsedFieldKey].value.length > 0) {
        if (isEmpty && !unparsedFieldExists) {
          newUnparsedFieldKeys.add(unparsedFieldKey)
        }
      }

      if (target && target === dateInputRefs.current[unparsedFieldKey]) {
        if ((isEmpty || isValid) && unparsedFieldExists) {
          newUnparsedFieldKeys.delete(unparsedFieldKey)
        } else if (!isEmpty && !isValid && !unparsedFieldExists) {
          newUnparsedFieldKeys.add(unparsedFieldKey)
        }
      }

      if (!setEquals(newUnparsedFieldKeys, unparsedFieldKeys))
        setUnparsedFieldKeys(newUnparsedFieldKeys)
    },
    [unparsedFieldKeys]
  )

  const handleDelete = useCallback(() => onDelete?.(cardId), [cardId, onDelete])

  const wrapperProps = useMemo(() => generateWrapperStyleProps(highlightCard), [highlightCard])

  const isInClosedGradingPeriod =
    dateValidator.current.isDateInClosedGradingPeriod(dueDate) && !dueAtHasChanged()

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
              data-testid="delete-card-button"
              color="danger"
              screenReaderLabel={cardActionLabels.removeCard}
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
          disabledWithGradingPeriod={isInClosedGradingPeriod}
        />
        {!removeDueDateInput && !isCheckpointed && (
          <DueDateTimeInput
            {...{
              dueDate,
              setDueDate,
              validationErrors,
              unparsedFieldKeys,
              blueprintDateLocks,
              dateInputRefs: dateInputRefs.current,
              timeInputRefs: timeInputRefs.current,
              handleBlur,
              clearButtonAltLabel: cardActionLabels.clearDueAt,
            }}
            {...commonDateTimeInputProps}
            handleDueDateChange={handleDueDateChange(timeInputRefs.current.due_at?.value || '')}
            disabledWithGradingPeriod={isInClosedGradingPeriod}
          />
        )}
        {isCheckpointed && (
          <ReplyToTopicDueDateTimeInput
            {...{
              replyToTopicDueDate,
              setReplyToTopicDueDate,
              validationErrors,
              unparsedFieldKeys,
              blueprintDateLocks,
              dateInputRefs: dateInputRefs.current,
              timeInputRefs: timeInputRefs.current,
              handleBlur,
              clearButtonAltLabel: cardActionLabels.clearReplyToTopicDueAt,
            }}
            {...commonDateTimeInputProps}
            handleReplyToTopicDueDateChange={handleReplyToTopicDueDateChange(
              timeInputRefs.current.reply_to_topic_due_at?.value || ''
            )}
            disabledWithGradingPeriod={isInClosedGradingPeriod}
          />
        )}
        {isCheckpointed && (
          <RequiredRepliesDueDateTimeInput
            {...{
              requiredRepliesDueDate,
              setRequiredRepliesDueDate,
              validationErrors,
              unparsedFieldKeys,
              blueprintDateLocks,
              dateInputRefs: dateInputRefs.current,
              timeInputRefs: timeInputRefs.current,
              handleBlur,
              clearButtonAltLabel: cardActionLabels.clearRequiredRepliesDueAt,
            }}
            {...commonDateTimeInputProps}
            handleRequiredRepliesDueDateChange={handleRequiredRepliesDueDateChange(
              timeInputRefs.current.required_replies_due_at?.value || ''
            )}
            disabledWithGradingPeriod={isInClosedGradingPeriod}
          />
        )}
        <AvailableFromDateTimeInput
          {...{
            availableFromDate,
            setAvailableFromDate,
            validationErrors,
            unparsedFieldKeys,
            blueprintDateLocks,
            dateInputRefs: dateInputRefs.current,
            timeInputRefs: timeInputRefs.current,
            handleBlur,
            clearButtonAltLabel: cardActionLabels.clearAvailableFrom,
          }}
          {...commonDateTimeInputProps}
          handleAvailableFromDateChange={handleAvailableFromDateChange(
            timeInputRefs.current.unlock_at?.value || ''
          )}
          disabledWithGradingPeriod={isInClosedGradingPeriod}
        />
        <AvailableToDateTimeInput
          {...{
            availableToDate,
            setAvailableToDate,
            validationErrors,
            unparsedFieldKeys,
            blueprintDateLocks,
            dateInputRefs: dateInputRefs.current,
            timeInputRefs: timeInputRefs.current,
            handleBlur,
            clearButtonAltLabel: cardActionLabels.clearAvailableTo,
          }}
          {...commonDateTimeInputProps}
          handleAvailableToDateChange={handleAvailableToDateChange(
            timeInputRefs.current.lock_at?.value || ''
          )}
          disabledWithGradingPeriod={isInClosedGradingPeriod}
        />
        <ContextModuleLink
          courseId={courseId}
          contextModuleId={contextModuleId}
          contextModuleName={contextModuleName}
        />
        {isInClosedGradingPeriod && (
          <Text size="small">{I18n.t('Due date falls in a closed Grading Period.')}</Text>
        )}
      </View>
    </View>
  )
})
