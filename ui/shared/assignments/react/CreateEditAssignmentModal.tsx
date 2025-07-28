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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState, useEffect} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Flex} from '@instructure/ui-flex'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconXSolid} from '@instructure/ui-icons'
import {NumberInput} from '@instructure/ui-number-input'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import type {FormMessage} from '@instructure/ui-form-field'
import DateValidator from '@canvas/grading/DateValidator'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'
import useInputFocus from '@canvas/outcomes/react/hooks/useInputFocus'

const I18n = createI18nScope('CreateEditAssignmentModal')

export type ModalAssignment = {
  type: string
  name: string
  dueAt: string | undefined
  lockAt: string | undefined
  unlockAt: string | undefined
  allDates: any | undefined
  points: number
  isPublished: boolean
  multipleDueDates: boolean
  differentiatedAssignment: boolean
  frozenFields: string[] | undefined
}

export type SaveProps = {
  type: string
  name: string
  dueAt: string | undefined
  points: number
  syncToSIS: boolean
  publish: boolean
}

export type MoreOptionsProps = {
  type: string
  name: string
  dueAt: string
  points: number
  syncToSIS: boolean
}

export type CreateEditAssignmentModalProps = {
  assignment: ModalAssignment | undefined
  userIsAdmin: boolean
  onCloseHandler: () => void
  onSaveHandler: (data: SaveProps, isNewAssignment: boolean) => Promise<void>
  onMoreOptionsHandler: (data: MoreOptionsProps, isNewAssignment: boolean) => void
  timezone: string
  validDueAtRange: any | undefined
  defaultDueTime: string
  dueDateRequired: boolean
  maxNameLength: number
  minNameLength: number
  syncGradesToSISFF: boolean
  shouldSyncGradesToSIS: boolean
  courseHasGradingPeriods: boolean
  activeGradingPeriods: any[] | undefined
}

type AssignmentTypeIndex = {
  [type: string]: string
}

const assignmentTypeOptions = ENV.horizon_course
  ? ['none', 'external_tool', 'not_graded']
  : ['none', 'discussion_topic', 'online_quiz', 'external_tool', 'not_graded']

const CreateEditAssignmentModal = ({
  assignment,
  userIsAdmin,
  onCloseHandler,
  onSaveHandler,
  onMoreOptionsHandler,
  timezone,
  validDueAtRange,
  defaultDueTime = '23:59',
  dueDateRequired = false,
  maxNameLength = 255,
  minNameLength = 1,
  syncGradesToSISFF = false,
  shouldSyncGradesToSIS = false,
  courseHasGradingPeriods = false,
  activeGradingPeriods,
}: CreateEditAssignmentModalProps) => {
  const isEditMode = !!assignment

  // Modal state values
  const [assignmentType, setAssignmentType] = useState<string>(
    isEditMode ? assignment.type : 'none',
  )
  const [name, setName] = useState<string>(isEditMode ? assignment.name : '')
  const [dueAt, setDueAt] = useState<string>(isEditMode && assignment.dueAt ? assignment.dueAt : '')
  const [points, setPoints] = useState<string>(isEditMode ? String(assignment.points) : '0')
  const [syncToSIS, setSyncToSIS] = useState<boolean>(shouldSyncGradesToSIS)

  const [saveDisabled, setSaveDisabled] = useState<boolean>(false)

  const MAX_POINTS_ALLOWED_FOR_ASSIGNMENT = 999999999

  // Modal input refs (only those that can show errors)
  const fields = ['name', 'due_at', 'points']
  const [fieldWithError, setFieldWithError] = useState<string | null>(null)
  const {inputElRefs, setInputElRef} = useInputFocus(fields)

  const setNameRef = (el: HTMLInputElement | null) => setInputElRef(el, 'name')
  const setDueAtRef = (el: HTMLInputElement | null) => setInputElRef(el, 'due_at')
  const setPointsRef = (el: HTMLInputElement | null) => setInputElRef(el, 'points')

  // Error Messages for inputs
  const [nameInputMessage, setNameInputMessage] = useState<FormMessage[]>([])
  const [dueDateInputMessage, setDueDateInputMessage] = useState<FormMessage[]>([])
  const [pointsInputMessage, setPointsInputMessage] = useState<FormMessage[]>([])

  const assignmentTypeLabels: AssignmentTypeIndex = {
    none: I18n.t('Assignment'),
    discussion_topic: I18n.t('Discussion'),
    online_quiz: I18n.t('Quiz'),
    external_tool: I18n.t('External Tool'),
    not_graded: I18n.t('Not Graded'),
  }

  const modalLabel = isEditMode ? I18n.t('Edit Assignment') : I18n.t('Create Assignment')
  const showSaveAndPublishButton = !isEditMode || (assignment && !assignment.isPublished)

  // Enable/Show certain fields
  const enableNameInput = !assignment?.frozenFields?.includes('name')
  const enablePointsInput = !assignment?.frozenFields?.includes('points')
  const enableDueDateInput = !assignment?.frozenFields?.includes('due_at')

  const showDueDateInput = !assignment?.differentiatedAssignment
  const [showDueDatePreviewMessage, setShowDueDatePreviewMessage] = useState<boolean>(true)

  // Sanatize default due time (remove milliseconds if present)
  const sanitizeDefaultDueTime = (time: string) => {
    const splitTime = time.split(':')
    if (splitTime.length === 3) {
      // There are milliseconds present, so just return HH:MM
      return splitTime[0] + ':' + splitTime[1]
    }

    return time
  }

  const validateAssignmentType = (type: string) => {
    return assignmentTypeOptions.includes(type)
  }

  const validateAssignmentName = (value: string) => {
    if (value.length >= minNameLength && value.length <= maxNameLength) {
      setNameInputMessage([])
      return true
    }
    if (value.length === 0) {
      setNameInputMessage([{text: I18n.t('Please enter a name.'), type: 'newError'}])
    } else if (value.length < minNameLength) {
      setNameInputMessage([
        {
          text: I18n.t('Name must be at least %{num} characters.', {num: minNameLength}),
          type: 'newError',
        },
      ])
    } else if (value.length > maxNameLength) {
      setNameInputMessage([
        {
          text: I18n.t('Name cannot exceed %{num} characters.', {num: maxNameLength}),
          type: 'newError',
        },
      ])
    }

    return false
  }

  const validateAssignmentDueAt = (dueDate: string | undefined) => {
    // Delegate this to the jquery DateValidator
    const data = {
      due_at: dueDate,
      unlock_at: assignment?.unlockAt,
      lock_at: assignment?.lockAt,
    }
    const dateValidator = new DateValidator({
      date_range: {...validDueAtRange},
      hasGradingPeriods: courseHasGradingPeriods,
      gradingPeriods: GradingPeriodsAPI.deserializePeriods(activeGradingPeriods || []),
      userIsAdmin,
      postToSIS: syncToSIS,
    })
    const errors = dateValidator.validateDatetimes(data)
    // If errors are empty, then we have a valid due date
    if (Object.keys(errors).length === 0) {
      setDueDateInputMessage([])
      return true
    }

    // Report any errors to the DateTimeInput messages prop
    // It is possible to have more than one error at a time
    // So we will proritize accordingly
    if (errors.unlock_at) {
      setDueDateInputMessage([
        {text: I18n.t('Due date cannot be before unlock date'), type: 'newError'},
      ])
    }
    if (errors.lock_at) {
      setDueDateInputMessage([
        {text: I18n.t('Due date cannot be after lock date'), type: 'newError'},
      ])
    }
    if (errors.due_at) {
      setDueDateInputMessage([{text: errors.due_at, type: 'newError'}])
    }

    return false
  }

  const validateAssignmentPoints = () => {
    const pointValue = Number(points)
    if (pointValue < 0) {
      setPointsInputMessage([{text: I18n.t('Points must be zero or greater.'), type: 'newError'}])
      return false
    } else if (pointValue > MAX_POINTS_ALLOWED_FOR_ASSIGNMENT) {
      setPointsInputMessage([
        {
          text: I18n.t('Points cannot exceed %{num}.', {num: MAX_POINTS_ALLOWED_FOR_ASSIGNMENT}),
          type: 'newError',
        },
      ])
      return false
    }

    return true
  }

  const validateForSIS = () => {
    if (!syncGradesToSISFF || !syncToSIS) return true

    // The only thing we must check is if a due date is is required
    if (dueDateRequired && !assignment?.multipleDueDates && (dueAt === '' || dueAt === undefined)) {
      setDueDateInputMessage([
        {text: I18n.t('Due date is required to enable "Sync to SIS"'), type: 'newError'},
      ])
      return false
    }

    return true
  }

  const setFocusToErrorField = (validName: boolean, validDueAt: boolean, validPoints: boolean) => {
    let errorField = null

    if (!validName) errorField = 'name'
    else if (!validDueAt) errorField = 'due_at'
    else if (!validPoints) errorField = 'points'

    setFieldWithError(errorField)
  }

  useEffect(() => {
    if (fieldWithError) {
      inputElRefs.get(fieldWithError)?.current?.focus()
      setFieldWithError(null)
    }
  }, [fieldWithError, inputElRefs])

  const validForm = () => {
    const validType = isEditMode ? true : validateAssignmentType(assignmentType)
    const validName = validateAssignmentName(name)
    const validDueAt = validateAssignmentDueAt(dueAt)
    const validPoints = validateAssignmentPoints()

    const valid = validType && validName && validDueAt && validPoints && validateForSIS()

    // Put focus on inputs with errors if any
    if (!valid) {
      setFocusToErrorField(validName, validDueAt, validPoints)
    }

    return valid
  }

  useEffect(() => {
    setShowDueDatePreviewMessage(dueDateInputMessage.length === 0)
  }, [dueDateInputMessage])

  const showInvalidDateMessage = (rawDateValue: string) => {
    return I18n.t('Invalid date: %{rawDateValue}', {rawDateValue})
  }

  const onAssignmentTypeInputChange = (
    _event: React.SyntheticEvent,
    {value}: {value?: string | number},
  ) => {
    setAssignmentType(String(value))
    // reset the points input if the assignment changes to not graded
    if (String(value) === 'not_graded') {
      setPoints('')
      setPointsInputMessage([])
    }
  }

  const onNameInputChange = (_event: React.SyntheticEvent, value: string) => {
    if (value.length === 0) setName('')
    else setName(value)

    // Don't validate if there is no error message present
    if (nameInputMessage.length > 0) {
      validateAssignmentName(value)
    }
  }

  const onDateInputChange = (_event: React.SyntheticEvent, isoValue?: string) => {
    setDueAt(isoValue || '')

    // Don't validate if there is no error message present
    if (dueDateInputMessage.length > 0) {
      validateAssignmentDueAt(dueAt)
    }
  }

  const onPointsInputChange = (_event: React.SyntheticEvent, value: string) => {
    setPointsInputMessage([])
    setPoints(value)
  }

  const onNameInputBlur = (_event: React.FocusEvent) => {
    // Don't validate if there is no error message yet
    if (nameInputMessage.length > 0) {
      validateAssignmentName(name)
    }
  }

  const onDateInputBlur = (_event: React.SyntheticEvent) => {
    // Don't validate if there is no error message yet
    if (dueDateInputMessage.length > 0) {
      validateAssignmentDueAt(dueAt)
    }
  }

  // More Options
  const onMoreOptions = () => {
    const isNewAssignment = !isEditMode
    onMoreOptionsHandler(
      {
        type: assignmentType,
        points: Number(points),
        name,
        dueAt,
        syncToSIS,
      },
      isNewAssignment,
    )
  }

  // Save Assignment
  const onSaveButton = async () => {
    if (!validForm()) {
      return
    }

    setSaveDisabled(true)

    await onSaveHandler(
      {
        type: assignmentType,
        points: Number(points),
        name,
        dueAt,
        syncToSIS,
        publish: false,
      },
      !isEditMode,
    )

    onCloseHandler()
  }

  const onSaveAndPublishButton = async () => {
    if (!validForm()) {
      return
    }

    setSaveDisabled(true)

    await onSaveHandler(
      {
        type: assignmentType,
        points: Number(points),
        name,
        dueAt,
        syncToSIS,
        publish: true,
      },
      !isEditMode,
    )

    onCloseHandler()
  }

  return (
    <Modal
      size="small"
      open={true}
      onDismiss={onCloseHandler}
      shouldCloseOnDocumentClick={false}
      overflow="scroll"
      label={modalLabel}
      data-testid="create-edit-assignment-modal"
    >
      <Modal.Header>
        <Flex width="100%" justifyItems="space-between">
          <Heading level="h3" data-testid="modal-title">
            {modalLabel}
          </Heading>
          <IconButton
            size="small"
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Close')}
            onClick={onCloseHandler}
            data-testid="close-button"
          >
            <IconXSolid />
          </IconButton>
        </Flex>
      </Modal.Header>

      <Modal.Body>
        {!isEditMode && (
          <View as="div">
            <SimpleSelect
              renderLabel={I18n.t('Type')}
              value={assignmentType}
              defaultValue={I18n.t('Assignment')}
              onChange={onAssignmentTypeInputChange}
              data-testid="assignment-type-select"
            >
              {assignmentTypeOptions.map((opt, index) => (
                <SimpleSelect.Option
                  key={opt}
                  id={`opt-${index}`}
                  value={opt}
                  data-testid="assignment-type-option"
                >
                  {assignmentTypeLabels[opt]}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>
            <br />
          </View>
        )}
        <View as="div">
          <TextInput
            renderLabel={I18n.t('Name')}
            inputRef={setNameRef}
            isRequired={true}
            interaction={enableNameInput ? 'enabled' : 'disabled'}
            value={name}
            onChange={onNameInputChange}
            onBlur={onNameInputBlur}
            messages={nameInputMessage}
            data-testid="assignment-name-input"
          />
          <br />
        </View>
        <View as="div" width="100%">
          {showDueDateInput && (
            <View data-testid="due-date-container">
              <DateTimeInput
                timezone={timezone}
                layout="columns"
                interaction={enableDueDateInput ? 'enabled' : 'disabled'}
                description={I18n.t('Due at')}
                datePlaceholder={I18n.t('Choose a date')}
                dateRenderLabel={I18n.t('Date')}
                dateInputRef={setDueAtRef}
                timeRenderLabel={I18n.t('Time')}
                allowNonStepInput={true}
                invalidDateTimeMessage={showInvalidDateMessage}
                messages={dueDateInputMessage}
                showMessages={showDueDatePreviewMessage}
                prevMonthLabel={I18n.t('Previous month')}
                nextMonthLabel={I18n.t('Next month')}
                value={dueAt}
                onChange={onDateInputChange}
                onBlur={onDateInputBlur}
                initialTimeForNewDate={sanitizeDefaultDueTime(defaultDueTime)}
              />
            </View>
          )}
          {/*  This should be changed for a better experience. But this matches previous modal  */}
          {!showDueDateInput && (
            <TextInput
              renderLabel={I18n.t('Due at')}
              interaction="disabled"
              value={
                assignment.multipleDueDates
                  ? I18n.t('Multiple Due Dates')
                  : I18n.t('Differentiated Due Date')
              }
              onChange={() => {}}
              data-testid="multiple-due-dates-message"
            />
          )}
          <br />
        </View>
        {assignmentType !== 'not_graded' && (
          <View as="div">
            <NumberInput
              renderLabel={I18n.t('Points')}
              inputRef={setPointsRef}
              showArrows={false}
              interaction={enablePointsInput ? 'enabled' : 'disabled'}
              value={points ? points : ''}
              onChange={onPointsInputChange}
              messages={pointsInputMessage}
              data-testid="points-input"
            />
          </View>
        )}
        {syncGradesToSISFF && (
          <View>
            <hr />
            <Checkbox
              variant="toggle"
              label={I18n.t('Sync to SIS')}
              checked={syncToSIS}
              onChange={event => setSyncToSIS(!!event.target.checked)}
              data-testid="sync-sis-toggle"
            />
          </View>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Flex width="100%" justifyItems="space-between">
          <Flex.Item>
            <Button margin="xxx-small" data-testid="more-options-button" onClick={onMoreOptions}>
              {I18n.t('More Options')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            {showSaveAndPublishButton && (
              <Button
                margin="xxx-small"
                data-testid="save-and-publish-button"
                disabled={saveDisabled}
                onClick={onSaveAndPublishButton}
              >
                {I18n.t('Save and Publish')}
              </Button>
            )}
            <Button
              margin="xxx-small"
              color="primary"
              data-testid="save-button"
              disabled={saveDisabled}
              onClick={onSaveButton}
            >
              {I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default CreateEditAssignmentModal
