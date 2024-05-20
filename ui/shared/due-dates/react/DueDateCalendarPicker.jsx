/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import React, {useEffect, useRef} from 'react'
import {string, func, bool, instanceOf, oneOfType} from 'prop-types'
import accessibleDateFormat from '@canvas/datetime/accessibleDateFormat'
import shortId from '@canvas/shortid'
import * as tz from '@canvas/datetime'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import '@canvas/jquery/jquery.instructure_forms'
import cx from 'classnames'

function DueDateCalendarPicker(props) {
  const dateInput = useRef(null)
  const uniqueId = useRef(shortId())
  const oldDate = useRef(props.dateValue)
  const formatDate = useDateTimeFormat('date.formats.full')

  useEffect(() => {
    const field = $(dateInput.current)
    field
      .data('inputdate', props.dateValue)
      .datetime_field({contextLabel: props.contextLabel})
      .change(e => {
        const trimmedInput = $.trim(e.target.value)

        let newDate = field.data('unfudged-date')
        newDate = trimmedInput === '' ? null : newDate
        newDate = applyDefaultTimeIfNeeded(newDate)
        newDate = changeToFancyMidnightIfNeeded(newDate)
        newDate = setToEndOfMinuteIfNeeded(newDate)

        field.data('inputdate', props.dateValue).val(formatDate(props.dateValue))
        props.handleUpdate(newDate)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (props.dateValue === oldDate.current) return
    oldDate.current = props.dateValue
    $(dateInput.current).data('inputdate', props.dateValue).val(formatDate(props.dateValue))
    dateInput.current.setSelectionRange(0, 0)
  }, [formatDate, props.dateValue])

  function applyDefaultTimeIfNeeded(date) {
    if (props.defaultTime && tz.isMidnight(date)) {
      return tz.parse(tz.format(date, `%F ${props.defaultTime}`))
    }
    return date
  }

  function changeToFancyMidnightIfNeeded(date) {
    if (props.isFancyMidnight && tz.isMidnight(date)) {
      return tz.changeToTheSecondBeforeMidnight(date)
    }
    return date
  }

  function setToEndOfMinuteIfNeeded(date) {
    if (props.defaultToEndOfMinute && tz.format(date, '%S') === '00') {
      return tz.setToEndOfMinute(date)
    }
    return date
  }

  const wrapperClassName = () =>
    props.dateType === 'due_at' ? 'DueDateInput__Container' : 'DueDateRow__LockUnlockInput'

  if (props.disabled || props.readonly) {
    const className = cx('ic-Form-control', {readonly: props.readonly})
    return (
      <div className={className}>
        <label className={`${props.labelClasses} ic-Label`} htmlFor={props.dateType}>
          {props.labelText}
        </label>
        <div className="ic-Input-group">
          <input
            id={props.dateType}
            name={props.name}
            readOnly={true}
            type="text"
            className={`ic-Input ${props.inputClasses}`}
            defaultValue={formatDate(props.dateValue)}
          />
          {props.readonly ? null : (
            <div
              className="ic-Input-group__add-on"
              role="presentation"
              aria-hidden="true"
              tabIndex="-1"
            >
              <button
                className="Button Button--icon-action disabled"
                aria-disabled="true"
                type="button"
              >
                <i className="icon-calendar-month" role="presentation" />
              </button>
            </div>
          )}
        </div>
      </div>
    )
  }

  return (
    <div>
      <label
        id={props.labelledBy}
        className={`${props.labelClasses} Date__label`}
        htmlFor={uniqueId.current}
      >
        {props.labelText}
      </label>
      <div className={wrapperClassName()}>
        <input
          id={uniqueId.current}
          name={props.name}
          type="text"
          ref={dateInput}
          title={accessibleDateFormat()}
          data-tooltip=""
          className={props.inputClasses}
          aria-labelledby={props.labelledBy}
          data-row-key={props.rowKey}
          data-date-type={props.dateType}
          defaultValue={formatDate(props.dateValue)}
        />
      </div>
    </div>
  )
}

DueDateCalendarPicker.propTypes = {
  dateType: string.isRequired,
  handleUpdate: func.isRequired,
  rowKey: string.isRequired,
  labelledBy: string.isRequired,
  inputClasses: string.isRequired,
  disabled: bool.isRequired,
  isFancyMidnight: bool.isRequired,
  defaultToEndOfMinute: bool,
  defaultTime: string,
  dateValue: oneOfType([instanceOf(Date), string]),
  contextLabel: string,
  labelText: string,
  labelClasses: string,
  name: string,
  readonly: bool,
}

DueDateCalendarPicker.defaultProps = {
  readonly: false,
  defaultToEndOfMinute: false,
  labelClasses: '',
}

export default DueDateCalendarPicker
