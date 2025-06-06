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

import React, {useEffect, useRef, useState} from 'react'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {
  validateDateTime,
  generateMessages,
  validateStartDateAfterEnd,
  END_AT_DATE,
  END_AT_TIME,
  SHORT_DATE_FORMAT,
} from '../utils'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('edit_section_end_date')

interface EndDateTimeInputProps {
  initialValue?: string
  handleDateTimeChange: (isoDate: string | undefined) => void
}

const EndDateTimeInput = ({initialValue, handleDateTimeChange}: EndDateTimeInputProps) => {
  const [messages, setMessages] = useState<FormMessage[]>(generateMessages(initialValue))
  const [value, setValue] = useState<string | undefined>(initialValue)

  const dateInputRef = useRef<HTMLInputElement | null>(null)
  const timeInputRef = useRef<HTMLInputElement | null>(null)

  const validateInputs = (isoDate: string | undefined) => {
    if (dateInputRef.current && timeInputRef.current) {
      const dateValue = dateInputRef.current.value
      let errors = validateDateTime(dateValue, END_AT_DATE)
      if (errors.length > 0) {
        setMessages(generateMessages(null, true, errors[0].message))
      } else {
        const startDateInput = document.getElementById(
          'start_datetime_value',
        ) as HTMLInputElement | null
        let startDateTimeValue
        if (startDateInput) {
          startDateTimeValue = startDateInput.value
        }
        handleDateTimeChange(isoDate)
        errors = validateStartDateAfterEnd(startDateTimeValue, isoDate)
        if (errors.length > 0) {
          setMessages(generateMessages(null, true, errors[0].message))
        } else {
          setMessages(generateMessages(isoDate))
        }
      }
    }
  }

  useEffect(() => {
    const handleValidate = () => validateInputs(value)

    document.addEventListener('validateDateInputs', handleValidate)

    return () => document.removeEventListener('validateDateInputs', handleValidate)
  }, [validateInputs])

  const handleChange = (_: React.SyntheticEvent, isoDate: string | undefined) => {
    setValue(isoDate)
    validateInputs(isoDate)
  }

  const handleBlur = () => {
    validateInputs(value)
  }

  const handleDateRef = (el: HTMLInputElement | null) => {
    dateInputRef.current = el
    if (el) {
      el.setAttribute('name', END_AT_DATE)
      el.setAttribute('data-testid', 'section-end-date')
    }
  }

  const handleTimeRef = (el: HTMLInputElement | null) => {
    timeInputRef.current = el
    if (el) {
      el.setAttribute('name', END_AT_TIME)
      el.setAttribute('data-testid', 'section-end-time')
    }
  }

  return (
    <View as="div" width="70%">
      <DateTimeInput
        description={<ScreenReaderContent>{I18n.t('Ends')}</ScreenReaderContent>}
        datePlaceholder={I18n.t('Choose a date')}
        dateRenderLabel={<ScreenReaderContent>{I18n.t('End date')}</ScreenReaderContent>}
        timeRenderLabel={<ScreenReaderContent>{I18n.t('End time')}</ScreenReaderContent>}
        prevMonthLabel={I18n.t('Previous month')}
        nextMonthLabel={I18n.t('Next month')}
        invalidDateTimeMessage={I18n.t('Invalid date and time')}
        layout="columns"
        showMessages={false}
        colSpacing="small"
        allowNonStepInput={true}
        timezone={ENV.TIMEZONE}
        locale={ENV.LOCALE}
        messages={messages}
        onChange={handleChange}
        onBlur={handleBlur}
        defaultValue={initialValue}
        dateInputRef={handleDateRef}
        timeInputRef={handleTimeRef}
        dateFormat={SHORT_DATE_FORMAT}
      />
    </View>
  )
}

export default EndDateTimeInput
