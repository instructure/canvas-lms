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

import React, {useState, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Flex} from '@instructure/ui-flex'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import moment from 'moment-timezone'

const I18n = createI18nScope('widget_dashboard')

const MAX_TITLE_LENGTH = 255
const MAX_DETAILS_LENGTH = 10000

export interface Course {
  id: string
  longName?: string
  long_name?: string
  enrollmentType?: string
  is_student?: boolean
}

interface CreateTodoModalProps {
  open: boolean
  onDismiss: () => void
  onSubmit: (data: {title: string; todo_date: string; details?: string; course_id?: string}) => void
  isCreating: boolean
  courses: Course[]
  locale: string
  timeZone: string
}

const CreateTodoModal: React.FC<CreateTodoModalProps> = ({
  open,
  onDismiss,
  onSubmit,
  isCreating,
  courses,
  locale,
  timeZone,
}) => {
  const [title, setTitle] = useState('')
  const [todoDate, setTodoDate] = useState<moment.Moment | null>(moment.tz(timeZone).endOf('day'))
  const [details, setDetails] = useState('')
  const [courseId, setCourseId] = useState<string | undefined>(undefined)
  const [titleError, setTitleError] = useState('')
  const [dateError, setDateError] = useState('')
  const [detailsError, setDetailsError] = useState('')

  const handleSubmit = () => {
    let hasError = false

    if (!title.trim()) {
      setTitleError(I18n.t('Title is required'))
      hasError = true
    } else if (title.length > MAX_TITLE_LENGTH) {
      setTitleError(I18n.t('Title must be %{max} characters or less', {max: MAX_TITLE_LENGTH}))
      hasError = true
    } else {
      setTitleError('')
    }

    if (!todoDate || !todoDate.isValid()) {
      setDateError(I18n.t('Date is required'))
      hasError = true
    } else {
      setDateError('')
    }

    if (details.length > MAX_DETAILS_LENGTH) {
      setDetailsError(
        I18n.t('Details must be %{max} characters or less', {max: MAX_DETAILS_LENGTH}),
      )
      hasError = true
    } else {
      setDetailsError('')
    }

    if (hasError) return

    onSubmit({
      title: title.trim(),
      todo_date: todoDate!.toISOString(),
      details: details.trim() || undefined,
      course_id: courseId,
    })

    resetForm()
  }

  const resetForm = () => {
    setTitle('')
    setTodoDate(moment.tz(timeZone).endOf('day'))
    setDetails('')
    setCourseId(undefined)
    setTitleError('')
    setDateError('')
    setDetailsError('')
  }

  const handleClose = () => {
    resetForm()
    onDismiss()
  }

  const handleDateChange = (_e: React.SyntheticEvent, isoDate?: string) => {
    const value = isoDate || ''
    setTodoDate(moment.tz(value, timeZone))
    if (dateError && value) {
      setDateError('')
    }
  }

  const handleCourseIdChange = (
    _e: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => {
    const value = typeof data.value === 'string' ? data.value : undefined
    if (!value) return
    if (value === 'none') {
      setCourseId(undefined)
    } else {
      setCourseId(value)
    }
  }

  const invalidDateTimeMessage = (rawDateValue?: string, _rawTimeValue?: string) => {
    if (rawDateValue) {
      return I18n.t('%{date} is not a valid date.', {date: rawDateValue})
    } else {
      return I18n.t('You must provide a date and time.')
    }
  }

  const isFormValid = title.trim().length > 0 && todoDate && todoDate.isValid()

  const noneOption = {
    value: 'none',
    label: I18n.t('Optional: Add Course'),
  }

  const courseOptions = useMemo(
    () =>
      (courses || [])
        .filter(course => course.enrollmentType === 'StudentEnrollment' || course.is_student)
        .map(course => ({
          value: course.id,
          label: course.longName || course.long_name || '',
        })),
    [courses],
  )

  const selectedCourseValue = courseId || 'none'

  return (
    <Modal
      open={open}
      onDismiss={handleClose}
      size="medium"
      label={I18n.t('Add To Do')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          data-testid="create-todo-close-button"
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
          interaction={isCreating ? 'disabled' : 'enabled'}
        />
        <Heading>{I18n.t('Add To Do')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="medium">
          <Flex.Item overflowX="visible" overflowY="visible">
            <TextInput
              data-testid="create-todo-title-input"
              renderLabel={I18n.t('Title')}
              value={title}
              onChange={(_e, value) => {
                setTitle(value)
                if (titleError && value.trim() && value.length <= MAX_TITLE_LENGTH) {
                  setTitleError('')
                }
              }}
              messages={titleError ? [{type: 'error', text: titleError}] : []}
              interaction={isCreating ? 'disabled' : 'enabled'}
              maxLength={MAX_TITLE_LENGTH}
            />
          </Flex.Item>
          <Flex.Item data-testid="create-todo-date-input" overflowX="visible" overflowY="visible">
            <DateTimeInput
              description={
                <ScreenReaderContent>
                  {I18n.t('The date and time this to do is due')}
                </ScreenReaderContent>
              }
              messages={dateError ? [{type: 'error', text: dateError}] : []}
              dateRenderLabel={I18n.t('Date')}
              nextMonthLabel={I18n.t('Next Month')}
              prevMonthLabel={I18n.t('Previous Month')}
              timeRenderLabel={I18n.t('Time')}
              timeStep={30}
              locale={locale}
              timezone={timeZone}
              value={todoDate && todoDate.isValid() ? todoDate.toISOString() : undefined}
              layout="stacked"
              onChange={handleDateChange}
              invalidDateTimeMessage={invalidDateTimeMessage}
              allowNonStepInput={true}
              interaction={isCreating ? 'disabled' : 'enabled'}
            />
          </Flex.Item>
          <Flex.Item overflowX="visible" overflowY="visible">
            <SimpleSelect
              renderLabel={I18n.t('Course')}
              assistiveText={I18n.t('Use arrow keys to navigate options.')}
              data-testid="create-todo-course-select"
              value={selectedCourseValue}
              onChange={handleCourseIdChange}
              interaction={isCreating ? 'disabled' : 'enabled'}
            >
              {[noneOption, ...courseOptions].map(props => (
                <SimpleSelect.Option key={props.value} id={props.value} value={props.value}>
                  {props.label}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>
          </Flex.Item>
          <Flex.Item overflowX="visible" overflowY="visible">
            <TextArea
              data-testid="create-todo-details-input"
              label={I18n.t('Details')}
              value={details}
              onChange={e => {
                setDetails(e.target.value)
                if (detailsError && e.target.value.length <= MAX_DETAILS_LENGTH) {
                  setDetailsError('')
                }
              }}
              messages={detailsError ? [{type: 'error', text: detailsError}] : []}
              height="10rem"
              disabled={isCreating}
              maxHeight="10rem"
            />
          </Flex.Item>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end" gap="small">
          <Flex.Item overflowX="visible" overflowY="visible">
            <Button
              data-testid="create-todo-cancel-button"
              onClick={handleClose}
              interaction={isCreating ? 'disabled' : 'enabled'}
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item overflowX="visible" overflowY="visible">
            <Button
              data-testid="create-todo-submit-button"
              onClick={handleSubmit}
              color="primary"
              interaction={isCreating || !isFormValid ? 'disabled' : 'enabled'}
            >
              {isCreating ? I18n.t('Creating...') : I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default CreateTodoModal
