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

import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '../../index'
import React from 'react'
import ReactDOM from 'react-dom'

const I18n = useI18nScope('renderDatepickerTime')

const STRINGS = {
  get timeLabel() {
    return I18n.beforeLabel(I18n.t('Time'))
  },
  get hourTitle() {
    return I18n.t('datepicker.titles.hour', 'hr')
  },
  get minuteTitle() {
    return I18n.t('datepicker.titles.minute', 'min')
  },
  get selectTitle() {
    return I18n.t('datepicker.titles.am_pm', 'am/pm')
  },
  get AM() {
    return I18n.t('#time.am', 'am')
  },
  get PM() {
    return I18n.t('#time.pm', 'pm')
  },
  get doneButton() {
    return I18n.t('#buttons.done', 'Done')
  },
}

function renderDatepickerTime($input) {
  const data = {
    hour: ($input.data('time-hour') || '').replace(/'/g, ''),
    minute: ($input.data('time-minute') || '').replace(/'/g, ''),
    ampm: $input.data('time-ampm') || '',
  }

  const label = <label htmlFor="ui-datepicker-time-hour">{STRINGS.timeLabel}</label>

  const hourInput = (
    <input
      id="ui-datepicker-time-hour"
      type="text"
      defaultValue={data.hour}
      title={STRINGS.hourTitle}
      className="ui-datepicker-time-hour"
      style={{width: '20px'}}
    />
  )

  const minuteInput = (
    <input
      type="text"
      defaultValue={data.minute}
      title={STRINGS.minuteTitle}
      className="ui-datepicker-time-minute"
      style={{width: '20px'}}
    />
  )

  let meridianSelect = ''
  if (tz.hasMeridiem()) {
    meridianSelect = (
      <select
        defaultValue={data.ampm.toLowerCase()}
        className="ui-datepicker-time-ampm un-bootrstrapify"
        title={STRINGS.selectTitle}
      >
        <option value="" key="unset">
          &nbsp;
        </option>
        <option value={STRINGS.AM} key="am">
          {STRINGS.AM}
        </option>
        <option value={STRINGS.PM} key="pm">
          {STRINGS.PM}
        </option>
      </select>
    )
  }

  const containingDiv = document.createElement('div')

  ReactDOM.render(
    <div className="ui-datepicker-time ui-corner-bottom">
      {label}{' '}
      <span dir="ltr">
        {hourInput}:{minuteInput}
      </span>{' '}
      {meridianSelect}
      <button type="button" className="btn btn-mini ui-datepicker-ok">
        {STRINGS.doneButton}
      </button>
    </div>,
    containingDiv
  )
  return containingDiv.innerHTML
}

export default renderDatepickerTime
