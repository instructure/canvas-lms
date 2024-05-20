/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {TimeSelect} from '@instructure/ui-time-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_default_due_time')

export default function CourseDefaultDueTime() {
  const FORM_IDS = {
    COURSE_DEFAULT_DUE_TIME: 'course_default_due_time',
  }

  const setFormValue = (id: string, value: string): void => {
    const field = document.getElementById(id) as HTMLInputElement
    if (field) {
      field.value = value
    }
  }

  const getFormValue = (id: string): string => {
    const field = document.getElementById(id) as HTMLInputElement
    return field ? field.value : ''
  }

  const [defaultValue] = useState<string>(getFormValue(FORM_IDS.COURSE_DEFAULT_DUE_TIME))

  const stringTimeToDate = (timeString: string): string => {
    const currentDate = new Date()
    if (!timeString) {
      return currentDate.toISOString()
    }

    const [hours, minutes, seconds] = timeString.split(':').map(Number)

    currentDate.setHours(hours)
    currentDate.setMinutes(minutes)
    currentDate.setSeconds(seconds)
    return currentDate.toISOString()
  }

  const isoToStringTime = (isoString: string | undefined): string | null => {
    if (!isoString) return null

    const date = new Date(isoString)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    const seconds = date.getSeconds().toString().padStart(2, '0')

    return `${hours}:${minutes}:${seconds}`
  }

  const handleChange = (isoString: string | undefined): void => {
    const parsedValue = isoToStringTime(isoString)
    if (parsedValue) {
      setFormValue(FORM_IDS.COURSE_DEFAULT_DUE_TIME, parsedValue)
    } else {
      setFormValue(FORM_IDS.COURSE_DEFAULT_DUE_TIME, defaultValue)
    }
  }

  return (
    <FormFieldGroup
      description={<ScreenReaderContent>{I18n.t('Default Due Time')}</ScreenReaderContent>}
      rowSpacing="small"
      layout="inline"
    >
      <TimeSelect
        renderLabel={I18n.t('Choose a time')}
        onChange={(e, {value}) => handleChange(value)}
        onInputChange={(e, value, isoValue) => handleChange(isoValue)}
        defaultValue={stringTimeToDate(defaultValue)}
        allowNonStepInput={true}
      />
    </FormFieldGroup>
  )
}
