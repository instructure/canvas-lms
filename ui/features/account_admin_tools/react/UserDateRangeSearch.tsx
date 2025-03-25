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
import {zodResolver} from '@hookform/resolvers/zod'
import * as z from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {
  getFormErrorMessage,
  isDateTimeInputInvalid,
} from '@canvas/forms/react/react-hook-form/utils'

const I18n = createI18nScope('user_date_range_search')

const defaultValues = {
  from: undefined,
  to: undefined,
}

const validationSchema = z
  .object({
    from: z.string().optional(),
    to: z.string().optional(),
  })
  .refine(
    ({from, to}) => {
      if (!from || !to) return true

      const isToDateAfterFromDate = new Date(to).getTime() >= new Date(from).getTime()

      return isToDateAfterFromDate
    },
    () => ({
      message: I18n.t('To Date cannot come before From Date.'),
      path: ['to'],
    }),
  )

type FormValues = z.infer<typeof validationSchema>

export interface UserDateRangeSearchProps {
  userName: string
  onSubmit: (data: FormValues) => void
  isOpen: boolean
  onClose: () => void
}

const UserDateRangeSearch = ({
  userName,
  onSubmit,
  isOpen = true,
  onClose,
}: UserDateRangeSearchProps) => {
  const {
    formState: {errors},
    control,
    handleSubmit,
    setFocus,
  } = useForm({
    defaultValues,
    resolver: zodResolver(validationSchema),
  })
  const fromInputRef = useRef<DateTimeInput>(null)
  const toInputRef = useRef<DateTimeInput>(null)
  const title = I18n.t('Generate Activity for %{userName}', {userName})
  const buttonText = I18n.t('Find')

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    if (isDateTimeInputInvalid(fromInputRef)) {
      setFocus('from')
      return
    }

    if (isDateTimeInputInvalid(toInputRef)) {
      setFocus('to')
      return
    }

    onSubmit(data)
  }

  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={onClose}
      size="medium"
      label={title}
      shouldCloseOnDocumentClick={false}
      onSubmit={handleSubmit(handleFormSubmit)}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="medium" padding="small 0 0 0">
          <Controller
            name="from"
            control={control}
            rules={{deps: ['to']}}
            render={({field: {onChange, ref, ...rest}}) => (
              <DateTimeInput
                {...rest}
                ref={fromInputRef}
                dateInputRef={dateInputRef => {
                  dateInputRef?.setAttribute('data-testid', 'from-date')

                  ref(dateInputRef)
                }}
                timeInputRef={timeInputRef =>
                  timeInputRef?.setAttribute('data-testid', 'from-time')
                }
                timezone={ENV.TIMEZONE}
                locale={ENV.LOCALE}
                datePlaceholder={I18n.t('From Date')}
                timePlaceholder={I18n.t('From Time')}
                description={
                  <ScreenReaderContent>
                    {I18n.t('Limit search to activity after.')}
                  </ScreenReaderContent>
                }
                invalidDateTimeMessage={I18n.t('Invalid date and time.')}
                dateRenderLabel={I18n.t('From Date')}
                timeRenderLabel={I18n.t('From Time')}
                prevMonthLabel={I18n.t('Previous month')}
                nextMonthLabel={I18n.t('Next month')}
                layout="columns"
                allowNonStepInput={true}
                onChange={(_, isoValue) => onChange(isoValue)}
                messages={getFormErrorMessage(errors, 'from')}
              />
            )}
          />
          <Controller
            name="to"
            control={control}
            rules={{deps: ['from']}}
            render={({field: {onChange, ref, ...rest}}) => (
              <DateTimeInput
                {...rest}
                ref={toInputRef}
                dateInputRef={dateInputRef => {
                  dateInputRef?.setAttribute('data-testid', 'to-date')

                  ref(dateInputRef)
                }}
                timeInputRef={timeInputRef => timeInputRef?.setAttribute('data-testid', 'to-time')}
                timezone={ENV.TIMEZONE}
                locale={ENV.LOCALE}
                datePlaceholder={I18n.t('To Date')}
                timePlaceholder={I18n.t('To Time')}
                description={
                  <ScreenReaderContent>
                    {I18n.t('Limit search to activity before.')}
                  </ScreenReaderContent>
                }
                invalidDateTimeMessage={I18n.t('Invalid date and time.')}
                dateRenderLabel={I18n.t('To Date')}
                timeRenderLabel={I18n.t('To Time')}
                prevMonthLabel={I18n.t('Previous month')}
                nextMonthLabel={I18n.t('Next month')}
                layout="columns"
                allowNonStepInput={true}
                onChange={(_, isoValue) => onChange(isoValue)}
                messages={getFormErrorMessage(errors, 'to')}
              />
            )}
          />
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="x-small">
          <Button type="button" color="secondary" onClick={onClose}>
            {I18n.t('Cancel')}
          </Button>
          <Button type="submit" color="primary" aria-label={buttonText}>
            {buttonText}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default UserDateRangeSearch
