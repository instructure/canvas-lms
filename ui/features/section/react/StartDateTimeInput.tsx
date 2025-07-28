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

import React, {useRef, useState} from 'react'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  generateMessages,
  validateDateTime,
  START_AT_DATE,
  START_AT_TIME,
  SHORT_DATE_FORMAT,
} from '../utils'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('edit_section_start_date')

interface StartDateTimeInputProps {
  initialValue?: string
  handleDateTimeChange: (isoDate: string | undefined) => void
}

const StartDateTimeInput = ({initialValue, handleDateTimeChange}: StartDateTimeInputProps) => {
  const [messages, setMessages] = useState<FormMessage[]>(generateMessages(initialValue))
  const [value, setValue] = useState<string | undefined>(initialValue)

  const dateInputRef = useRef<HTMLInputElement | null>(null)
  const timeInputRef = useRef<HTMLInputElement | null>(null)

  const validateInputs = (isoDate: string | undefined) => {
    if (dateInputRef.current && timeInputRef.current) {
      const dateValue = dateInputRef.current.value

      const errors = validateDateTime(dateValue, START_AT_DATE)

      if (errors.length > 0) {
        setMessages(generateMessages(null, true, errors[0].message))
      } else {
        setMessages(generateMessages(isoDate))
        handleDateTimeChange(isoDate)
        document.dispatchEvent(new CustomEvent('validateDateInputs'))
      }
    }
  }

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
      el.setAttribute('name', START_AT_DATE)
      el.setAttribute('data-testid', 'section-start-date')
    }
  }

  const handleTimeRef = (el: HTMLInputElement | null) => {
    timeInputRef.current = el
    if (el) {
      el.setAttribute('name', START_AT_TIME)
      el.setAttribute('data-testid', 'section-start-time')
    }
  }

  return (
    <View as="div" width="70%" margin="0 0 small 0">
      <DateTimeInput
        description={<ScreenReaderContent>{I18n.t('Starts')}</ScreenReaderContent>}
        datePlaceholder={I18n.t('Choose a date')}
        dateRenderLabel={<ScreenReaderContent>{I18n.t('Start date')}</ScreenReaderContent>}
        timeRenderLabel={<ScreenReaderContent>{I18n.t('Start time')}</ScreenReaderContent>}
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

export default StartDateTimeInput
