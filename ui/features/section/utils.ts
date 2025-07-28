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

import moment from 'moment'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'

export const START_AT_DATE = 'start_at_date'
export const START_AT_TIME = 'start_at_time'
export const END_AT_DATE = 'end_at_date'
export const END_AT_TIME = 'end_at_time'

export const SHORT_DATE_FORMAT = 'll' // e.g., 'Jan 1, 2025'

const I18n = createI18nScope('edit_section_dates')

interface Error {
  containerName: string
  instUIControlled: boolean
  message: string
}

export function generateMessages(
  value: string | null = null,
  error: boolean = false,
  errorMessage: string = '',
): FormMessage[] {
  if (error) {
    return [
      {
        type: 'newError',
        text: errorMessage,
      },
    ]
  } else if (
    ENV.CONTEXT_TIMEZONE &&
    ENV.TIMEZONE !== ENV.CONTEXT_TIMEZONE &&
    ENV.context_asset_string.startsWith('course') &&
    moment(value).isValid()
  ) {
    const format = 'ddd, MMM D, YYYY, h:mm A'
    return [
      {
        type: 'hint',
        text: I18n.t('Local: %{datetime}', {
          datetime: moment.tz(value, ENV.TIMEZONE).format(format),
        }),
      },
      {
        type: 'hint',
        text: I18n.t('Course: %{datetime}', {
          datetime: moment.tz(value, ENV.CONTEXT_TIMEZONE).format(format),
        }),
      },
    ]
  }
  return []
}

export function validateDateTime(
  dateValue: string,
  field: string,
  format: string = SHORT_DATE_FORMAT,
): Error[] {
  const errors: Error[] = []
  if (!dateValue) return errors

  if (!isValidDate(dateValue, format)) {
    errors.push({
      containerName: field,
      instUIControlled: true,
      message: I18n.t('Please enter a valid format for a date'),
    })
    return errors
  }

  return errors
}

export function validateStartDateAfterEnd(
  isoStartDateTime: string | undefined,
  isoEndDateTime: string | undefined,
): Error[] {
  const errors: Error[] = []
  if (!isValidDate(isoStartDateTime) || !isValidDate(isoStartDateTime)) {
    return errors
  }

  const startDateTimeMoment = moment(isoStartDateTime)
  const endDateTimeMoment = moment(isoEndDateTime)

  if (startDateTimeMoment.isAfter(endDateTimeMoment)) {
    errors.push({
      containerName: END_AT_DATE,
      instUIControlled: true,
      message: I18n.t('End date cannot be before start date'),
    })
  }
  return errors
}

function isValidDate(
  dateString: string | undefined,
  format: string | moment.MomentBuiltinFormat = moment.ISO_8601,
): boolean {
  return moment(dateString, format, ENV.LOCALE).isValid()
}
