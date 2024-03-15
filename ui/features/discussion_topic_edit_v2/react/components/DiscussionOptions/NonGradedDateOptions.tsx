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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

import {FormFieldGroup, type FormMessageType} from '@instructure/ui-form-field'
import {DateTimeInput} from '@instructure/ui-date-time-input'

import {validateAvailability} from '../../util/formValidation'

const I18n = useI18nScope('discussion_create')

type Props = {
  availableFrom: string
  setAvailableFrom: (value: string) => void
  availableUntil: string
  setAvailableUntil: (value: string) => void
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
  isGraded,
  setAvailabilityValidationMessages,
  availabilityValidationMessages,
  inputWidth,
  setDateInputRef,
}: Props) => {
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
          validateAvailability(
            newAvailableFrom,
            availableUntil,
            isGraded,
            setAvailabilityValidationMessages
          )
          setAvailableFrom(newAvailableFrom)
        }}
        datePlaceholder={I18n.t('Select Date')}
        invalidDateTimeMessage={I18n.t('Invalid date and time')}
        layout="columns"
      />
      <DateTimeInput
        timezone={ENV.TIMEZONE}
        description={I18n.t('Until')}
        dateRenderLabel={I18n.t('Date')}
        timeRenderLabel={I18n.t('Time')}
        prevMonthLabel={I18n.t('Time')}
        nextMonthLabel={I18n.t('next')}
        value={availableUntil}
        onChange={(_event, newAvailableUntil = '') => {
          validateAvailability(
            availableFrom,
            newAvailableUntil,
            isGraded,
            setAvailabilityValidationMessages
          )
          setAvailableUntil(newAvailableUntil)
        }}
        datePlaceholder={I18n.t('Select Date')}
        invalidDateTimeMessage={I18n.t('Invalid date and time')}
        messages={availabilityValidationMessages}
        layout="columns"
        dateInputRef={setDateInputRef}
      />
    </FormFieldGroup>
  )
}
