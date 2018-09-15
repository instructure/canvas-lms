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

import I18n from 'i18n!instructure'
import tz from 'timezone'
import React from 'react'
import ReactDOM from 'react-dom'

  var STRINGS = {
    timeLabel: I18n.beforeLabel(I18n.t('Time')),
    hourTitle: I18n.t('datepicker.titles.hour', 'hr'),
    minuteTitle: I18n.t('datepicker.titles.minute', 'min'),
    selectTitle: I18n.t('datepicker.titles.am_pm', 'am/pm'),
    AM: I18n.t('#time.am'),
    PM: I18n.t('#time.pm'),
    doneButton: I18n.t('#buttons.done', 'Done')
  };

  function renderDatepickerTime($input) {
    var data = {
      hour:   ($input.data('time-hour')   || "").replace(/'/g, ""),
      minute: ($input.data('time-minute') || "").replace(/'/g, ""),
      ampm:   ($input.data('time-ampm')   || ""),
    };

    var label = (
      <label htmlFor='ui-datepicker-time-hour'>{STRINGS.timeLabel}</label>
    );

    var hourInput = (
      <input id='ui-datepicker-time-hour' type='text'
        defaultValue={data.hour} title={STRINGS.hourTitle}
        className='ui-datepicker-time-hour' style={{width: '20px'}} />
    );

    var minuteInput = (
      <input type='text'
        defaultValue={data.minute} title={STRINGS.minuteTitle}
        className='ui-datepicker-time-minute' style={{width: '20px'}} />
    );

    var meridianSelect = '';
    if (tz.useMeridian()) {
      // TODO: Change this select to work as described here:
      // http://facebook.github.io/react/docs/forms.html#why-select-value
      //
      // As of React 0.13.3 this issue: https://github.com/facebook/react/issues/1398
      // has not been fixed and released, which makes React.renderToStaticMarkup not
      // carry things through properly. So once that is done, we can fix the warning
      // here.
      meridianSelect = (
        <select className='ui-datepicker-time-ampm un-bootrstrapify' title={STRINGS.selectTitle}>
          <option value='' key='unset'>&nbsp;</option>
          <option value={STRINGS.AM} selected={data.ampm == 'am'} key='am'>{STRINGS.AM}</option>
          <option value={STRINGS.PM} selected={data.ampm == 'pm'} key='pm'>{STRINGS.PM}</option>
        </select>
      );
    }

    const containingDiv = document.createElement("div")

    ReactDOM.render(
      <div className='ui-datepicker-time ui-corner-bottom'>
        {label} <span dir="ltr">{hourInput}:{minuteInput}</span> {meridianSelect}
        <button type='button' className='btn btn-mini ui-datepicker-ok'>{STRINGS.doneButton}</button>
      </div>, containingDiv
    );
    return containingDiv.innerHTML
  };

export default renderDatepickerTime
