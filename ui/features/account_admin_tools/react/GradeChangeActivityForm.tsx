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

import React, {useRef} from 'react'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import * as z from 'zod'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {zodResolver} from '@hookform/resolvers/zod'
import {
  focusFiled,
  getFormErrorMessage,
  isDateTimeInputInvalid,
} from '@canvas/forms/react/react-hook-form/utils'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import AutoCompleteSelect from './AutoCompleteSelect'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'

const I18n = useI18nScope('grade_change_logging_content')

const defaultValues = {
  grader_id: '',
  student_id: '',
  course_id: '',
  assignment_id: '',
  start_time: undefined,
  end_time: undefined,
}

const validationSchema = z
  .object({
    grader_id: z.string().optional(),
    student_id: z.string().optional(),
    course_id: z.string().optional(),
    assignment_id: z.string().optional(),
    start_time: z.string().optional(),
    end_time: z.string().optional(),
  })
  .refine(
    ({grader_id, student_id, course_id, assignment_id}) =>
      grader_id || student_id || course_id || assignment_id,
    {
      message: 'One of Grader, Student, Course, or Assignment ID is required.',
      path: ['grader_id'],
    }
  )
  .refine(
    ({start_time, end_time}) => {
      if (!start_time || !end_time) return true

      const isToDateAfterFromDate = new Date(end_time).getTime() >= new Date(start_time).getTime()

      return isToDateAfterFromDate
    },
    {
      message: 'To Date cannot come before From Date.',
      path: ['end_time'],
    }
  )

type FormValues = z.infer<typeof validationSchema>

type User = {
  id: string
  name: string
}

export interface GradeChangeActivityFormProps {
  accountId: string
  onSubmit: (data: FormValues) => void
}

const GradeChangeActivityForm = ({accountId, onSubmit}: GradeChangeActivityFormProps) => {
  const {
    control,
    formState: {errors},
    handleSubmit,
  } = useForm({defaultValues, resolver: zodResolver(validationSchema)})
  const startDateInputRef = useRef<DateTimeInput>(null)
  const endDateInputRef = useRef<DateTimeInput>(null)
  const buttonText = I18n.t('Find')

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    if (isDateTimeInputInvalid(startDateInputRef)) {
      focusFiled(control, 'start_time')
      return
    }

    if (isDateTimeInputInvalid(endDateInputRef)) {
      focusFiled(control, 'end_time')
      return
    }

    onSubmit(data)
  }

  return (
    <form
      aria-label={I18n.t('Grade Change Activity Form')}
      className="form-horizontal pad-box border border-trbl search-controls"
      noValidate={true}
      onSubmit={handleSubmit(handleFormSubmit)}
    >
      <Flex direction="column" gap="small">
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Search by')}</ScreenReaderContent>}
          messages={getFormErrorMessage(errors, 'grader_id')}
          rowSpacing="small"
        >
          <Controller
            name="grader_id"
            control={control}
            rules={{deps: ['assignment_id', 'course_id', 'student_id']}}
            render={({field: {ref, ...fieldWithoutRef}}) => (
              <AutoCompleteSelect<User>
                {...fieldWithoutRef}
                maxLength={255}
                inputRef={ref}
                renderLabel={I18n.t('Grader ID')}
                assistiveText={I18n.t('Type to search')}
                url={`/api/v1/accounts/${accountId}/users`}
                renderOptionLabel={option => option.name}
                onInputChange={event => {
                  fieldWithoutRef.onChange(event)
                }}
                onRequestSelectOption={(_, {id}) => {
                  fieldWithoutRef.onChange(id)
                }}
              />
            )}
          />
          <Controller
            name="student_id"
            control={control}
            rules={{deps: ['assignment_id', 'course_id', 'grader_id']}}
            render={({field: {ref, ...fieldWithoutRef}}) => (
              <AutoCompleteSelect<User>
                {...fieldWithoutRef}
                maxLength={255}
                inputRef={ref}
                renderLabel={I18n.t('Student ID')}
                assistiveText={I18n.t('Type to search')}
                url={`/api/v1/accounts/${accountId}/users`}
                renderOptionLabel={option => option.name}
                messages={getFormErrorMessage(errors, 'student_id')}
                onInputChange={event => {
                  fieldWithoutRef.onChange(event)
                }}
                onRequestSelectOption={(_, {id}) => {
                  fieldWithoutRef.onChange(id)
                }}
              />
            )}
          />
          <Controller
            name="course_id"
            control={control}
            rules={{deps: ['assignment_id', 'student_id', 'grader_id']}}
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('Course ID')}
                messages={getFormErrorMessage(errors, 'course_id')}
              />
            )}
          />
          <Controller
            name="assignment_id"
            control={control}
            rules={{deps: ['course_id', 'student_id', 'grader_id']}}
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('Assignment ID')}
                messages={getFormErrorMessage(errors, 'assignment_id')}
              />
            )}
          />
        </FormFieldGroup>
        <Controller
          name="start_time"
          control={control}
          rules={{deps: ['end_time']}}
          render={({field: {onChange, ref, ...rest}}) => (
            <DateTimeInput
              {...rest}
              ref={startDateInputRef}
              dateInputRef={dateInputRef => {
                dateInputRef?.setAttribute('data-testid', 'start_time-date')

                ref(dateInputRef)
              }}
              timeInputRef={timeInputRef =>
                timeInputRef?.setAttribute('data-testid', 'start_time-time')
              }
              timezone={ENV.TIMEZONE}
              locale={ENV.LOCALE}
              description={
                <ScreenReaderContent>{I18n.t('Pick a date and time')}</ScreenReaderContent>
              }
              invalidDateTimeMessage={I18n.t('Invalid date and time.')}
              dateRenderLabel={I18n.t('From Date')}
              timeRenderLabel={I18n.t('From Time')}
              prevMonthLabel={I18n.t('Previous month')}
              nextMonthLabel={I18n.t('Next month')}
              layout="columns"
              allowNonStepInput={true}
              onChange={(_, isoValue) => onChange(isoValue)}
              messages={getFormErrorMessage(errors, 'start_time')}
            />
          )}
        />
        <Controller
          name="end_time"
          control={control}
          rules={{deps: ['start_time']}}
          render={({field: {onChange, ref, ...rest}}) => (
            <DateTimeInput
              {...rest}
              ref={endDateInputRef}
              dateInputRef={dateInputRef => {
                dateInputRef?.setAttribute('data-testid', 'end_time-date')

                ref(dateInputRef)
              }}
              timeInputRef={timeInputRef =>
                timeInputRef?.setAttribute('data-testid', 'end_time-time')
              }
              timezone={ENV.TIMEZONE}
              locale={ENV.LOCALE}
              description={
                <ScreenReaderContent>{I18n.t('Pick a date and time')}</ScreenReaderContent>
              }
              invalidDateTimeMessage={I18n.t('Invalid date and time.')}
              dateRenderLabel={I18n.t('To Date')}
              timeRenderLabel={I18n.t('To Time')}
              prevMonthLabel={I18n.t('Previous month')}
              nextMonthLabel={I18n.t('Next month')}
              layout="columns"
              allowNonStepInput={true}
              onChange={(_, isoValue) => onChange(isoValue)}
              messages={getFormErrorMessage(errors, 'end_time')}
            />
          )}
        />
        <Flex justifyItems="end">
          <Button type="submit" color="primary" margin="small 0 0 0" aria-label={buttonText}>
            {buttonText}
          </Button>
        </Flex>
      </Flex>
    </form>
  )
}

export default GradeChangeActivityForm
