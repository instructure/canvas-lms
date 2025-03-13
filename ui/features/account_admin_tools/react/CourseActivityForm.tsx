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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {zodResolver} from '@hookform/resolvers/zod'
import {
  getFormErrorMessage,
  isDateTimeInputInvalid,
} from '@canvas/forms/react/react-hook-form/utils'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import AutoCompleteSelect from '../../../shared/auto-complete-select/react/AutoCompleteSelect'

const I18n = createI18nScope('course_logging_content')

const defaultValues = {course_id: '', start_time: undefined, end_time: undefined}

const createValidationSchema = () =>
  z
    .object({
      course_id: z.string().min(1, {message: I18n.t('Course ID is required.')}),
      start_time: z.string().optional(),
      end_time: z.string().optional(),
    })
    .refine(
      ({start_time, end_time}) => {
        if (!start_time || !end_time) return true

        const isToDateAfterFromDate = new Date(end_time).getTime() >= new Date(start_time).getTime()

        return isToDateAfterFromDate
      },
      () => ({
        message: I18n.t('To Date cannot come before From Date.'),
        path: ['end_time'],
      }),
    )

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

type Course = {
  id: string
  name: string
  course_code: string
}

export interface CourseActivityFormProps {
  accountId: string
  onSubmit: (data: FormValues) => void
}

const CourseActivityForm = ({accountId, onSubmit}: CourseActivityFormProps) => {
  const {
    control,
    formState: {errors},
    handleSubmit,
    setFocus,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})
  const startDateInputRef = useRef<DateTimeInput>(null)
  const endDateInputRef = useRef<DateTimeInput>(null)
  const buttonText = I18n.t('Find')

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    if (isDateTimeInputInvalid(startDateInputRef)) {
      setFocus('start_time')
      return
    }

    if (isDateTimeInputInvalid(endDateInputRef)) {
      setFocus('end_time')
      return
    }

    onSubmit(data)
  }

  return (
    <form
      aria-label={I18n.t('Course Activity Form')}
      className="form-horizontal pad-box border border-trbl search-controls"
      noValidate={true}
      onSubmit={handleSubmit(handleFormSubmit)}
    >
      <Flex direction="column" gap="small">
        <Controller
          name="course_id"
          control={control}
          render={({field: {ref, ...fieldWithoutRef}}) => (
            <AutoCompleteSelect<Course>
              {...fieldWithoutRef}
              maxLength={255}
              inputRef={ref}
              isRequired={true}
              renderLabel={I18n.t('Course ID')}
              assistiveText={I18n.t('Type to search')}
              url={`/api/v1/accounts/${accountId}/courses`}
              renderOptionLabel={option => `${option.id} - ${option.name} - ${option.course_code}`}
              messages={getFormErrorMessage(errors, 'course_id')}
              fetchParams={{'state[]': 'all'}}
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

export default CourseActivityForm
