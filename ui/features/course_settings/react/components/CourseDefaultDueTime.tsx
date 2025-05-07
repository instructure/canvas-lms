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

import React, {useRef, useState} from 'react'
import {TimeSelect} from '@instructure/ui-time-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_default_due_time')

const FORM_ID = 'course'
const FORM_FIELD_ID = 'default_due_time'

const stringTimeToDate = (timeString: string): string => {
  const currentDate = new Date()
  if (!timeString) return currentDate.toISOString()

  const [hours, minutes, seconds] = timeString.split(':').map(Number)

  currentDate.setHours(hours || 0)
  currentDate.setMinutes(minutes || 0)
  currentDate.setSeconds(seconds || 0)
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
interface CourseDefaultDueTimeProps {
  canManage: boolean // TimeInput will be disabled unless this permission is true
  value: string // Initial value in hh:mm:ss format
  container: HTMLElement // The div that this component was rendered in
  locale?: string // Optional locale for the TimeInput
  timezone?: string // Optional timezone for the TimeInput
}

export default function CourseDefaultDueTime(props: CourseDefaultDueTimeProps): JSX.Element {
  const initialValueRef = useRef<string>(props.value)
  const formFieldRef = useRef<HTMLInputElement | null>(null)
  const [dueDate, setDueDate] = useState<string>(props.value)

  function setFormValue(value: string): void {
    if (formFieldRef.current === null) {
      const field = document.createElement('input')
      field.setAttribute('type', 'hidden')
      field.setAttribute('id', `${FORM_ID}_${FORM_FIELD_ID}`)
      field.setAttribute('name', `${FORM_ID}[${FORM_FIELD_ID}]`)
      props.container.appendChild(field)
      formFieldRef.current = field
    }
    formFieldRef.current.setAttribute('value', value)
  }

  function clearFormValue(): void {
    if (!formFieldRef.current) return
    props.container.removeChild(formFieldRef.current)
    formFieldRef.current = null
  }

  function handleChange(isoString: string | undefined): void {
    const newValue = isoToStringTime(isoString) ?? dueDate
    if (newValue === initialValueRef.current) {
      clearFormValue()
    } else {
      setFormValue(newValue)
    }
    setDueDate(newValue)
  }

  return (
    <FormFieldGroup
      description={<ScreenReaderContent>{I18n.t('Default Due Time')}</ScreenReaderContent>}
      rowSpacing="small"
      layout="stacked"
    >
      <TimeSelect
        renderLabel={I18n.t('Choose a time')}
        onChange={(_e, {value}) => handleChange(value)}
        onInputChange={(_e, _value, isoValue) => handleChange(isoValue)}
        value={stringTimeToDate(dueDate)}
        allowNonStepInput={true}
        interaction={props.canManage ? 'enabled' : 'disabled'}
        locale={props.locale}
        timezone={props.timezone}
        data-testid="course-default-due-time"
      />
    </FormFieldGroup>
  )
}
