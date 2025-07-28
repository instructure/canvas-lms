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

import React, {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

import {FormFieldGroup, type FormMessageType} from '@instructure/ui-form-field'
import {DateTimeInput} from '@instructure/ui-date-time-input'

import {validateAvailability} from '../../util/formValidation'
import {Button} from '@instructure/ui-buttons'

const I18n = createI18nScope('discussion_create')

type Props = {
  availableFrom: string
  setAvailableFrom: (value: string | null) => void
  availableUntil: string
  setAvailableUntil: (value: string | null) => void
  isAnnouncement: boolean
  isGraded: boolean
  availabilityValidationMessages: {text: string; type: FormMessageType}[]
  setAvailabilityValidationMessages: (value: {text: string; type: string}[]) => void
  inputWidth: string
  setDateInputRef: (el: HTMLInputElement | null) => void
}

export const NonGradedDateOptions = ({
  availableFrom,
  setAvailableFrom,
  availableUntil,
  setAvailableUntil,
  isAnnouncement,
  isGraded,
  setAvailabilityValidationMessages,
  availabilityValidationMessages,
  inputWidth,
  setDateInputRef,
}: Props) => {
  const [availableFromDateRef, setAvailableFromDateRef] = useState<HTMLInputElement | null>(null)
  const [availableFromTimeRef, setAvailableFromTimeRef] = useState<HTMLInputElement | null>(null)
  const [availableUntilDateRef, setAvailableUntilDateRef] = useState<HTMLInputElement | null>(null)
  const [availableUntilTimeRef, setAvailableUntilTimeRef] = useState<HTMLInputElement | null>(null)

  const testIdPrefix = isAnnouncement ? 'announcement' : 'group-discussion'

  useEffect(() => {
    availableFromDateRef?.setAttribute('data-testid', `${testIdPrefix}-available-from-date`)
    availableFromTimeRef?.setAttribute('data-testid', `${testIdPrefix}-available-from-time`)
    availableUntilDateRef?.setAttribute('data-testid', `${testIdPrefix}-available-until-date`)
    availableUntilTimeRef?.setAttribute('data-testid', `${testIdPrefix}-available-until-time`)
  })

  return (
    <FormFieldGroup description="" width={inputWidth}>
      <DateTimeInput
        timezone={ENV.TIMEZONE}
        description={I18n.t('Available from')}
        dateRenderLabel={I18n.t('Date')}
        timeRenderLabel={I18n.t('Time')}
        prevMonthLabel={I18n.t('previous')}
        nextMonthLabel={I18n.t('next')}
        value={availableFrom}
        onChange={(_event, newAvailableFrom = '') => {
          if (newAvailableFrom === '') {
            // @ts-expect-error
            newAvailableFrom = null
          }
          validateAvailability(
            newAvailableFrom,
            availableUntil,
            isGraded,
            setAvailabilityValidationMessages,
          )
          // @ts-expect-error
          setAvailableFrom(newAvailableFrom)
        }}
        datePlaceholder={I18n.t('Select Date')}
        invalidDateTimeMessage={I18n.t('Invalid date and time')}
        layout="columns"
        allowNonStepInput={true}
        dateInputRef={ref => {
          setAvailableFromDateRef(ref)
          setDateInputRef(ref)
        }}
        timeInputRef={ref => {
          setAvailableFromTimeRef(ref)
        }}
      />
      <Button
        type="button"
        color="secondary"
        onClick={() => {
          setAvailableFrom(null)
        }}
        aria-label={I18n.t('Reset available from')}
        data-testid="reset-available-from-button"
      >
        {I18n.t('Reset')}
      </Button>
      <DateTimeInput
        timezone={ENV.TIMEZONE}
        description={I18n.t('Until')}
        dateRenderLabel={I18n.t('Date')}
        timeRenderLabel={I18n.t('Time')}
        prevMonthLabel={I18n.t('Time')}
        nextMonthLabel={I18n.t('next')}
        value={availableUntil}
        onChange={(_event, newAvailableUntil = '') => {
          if (newAvailableUntil === '') {
            // @ts-expect-error
            newAvailableUntil = null
          }
          validateAvailability(
            availableFrom,
            newAvailableUntil,
            isGraded,
            setAvailabilityValidationMessages,
          )
          // @ts-expect-error
          setAvailableUntil(newAvailableUntil)
        }}
        datePlaceholder={I18n.t('Select Date')}
        invalidDateTimeMessage={I18n.t('Invalid date and time')}
        messages={availabilityValidationMessages}
        layout="columns"
        allowNonStepInput={true}
        dateInputRef={ref => {
          setAvailableUntilDateRef(ref)
          setDateInputRef(ref)
        }}
        timeInputRef={ref => {
          setAvailableUntilTimeRef(ref)
        }}
      />
      <Button
        type="button"
        color="secondary"
        onClick={() => {
          setAvailableUntil(null)
        }}
        aria-label={I18n.t('Reset available until')}
        data-testid="reset-available-until-button"
      >
        {I18n.t('Reset')}
      </Button>
    </FormFieldGroup>
  )
}
