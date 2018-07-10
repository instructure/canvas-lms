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
import React from 'react'
import PropTypes from 'prop-types'
import accessibleDateFormat from '../shared/helpers/accessibleDateFormat'
import shortId from '../shared/shortid'
import tz from 'timezone'
import 'jquery.instructure_forms'
import cx from 'classnames'

const { string, func, bool, instanceOf, oneOfType } = PropTypes;

  const DueDateCalendarPicker = React.createClass({

    propTypes: {
      dateType: string.isRequired,
      handleUpdate: func.isRequired,
      rowKey: string.isRequired,
      labelledBy: string.isRequired,
      inputClasses: string.isRequired,
      disabled: bool.isRequired,
      isFancyMidnight: bool.isRequired,
      dateValue: oneOfType([instanceOf(Date), string]).isRequired,
      labelText: string.isRequired,
      labelClasses: string,
      name: string,
      readonly: bool
    },

    getDefaultProps () {
      return {
        readonly: false,
        labelClasses: '',
      };
    },

    getInitialState () {
      this.uniqueId = shortId()
      return {}
    },

    // ---------------
    //    Lifecycle
    // ---------------

    componentDidMount() {
      const dateInput = this.refs.dateInput

      $(dateInput).datetime_field().change( (e) => {
        const trimmedInput = $.trim(e.target.value)

        let newDate = $(dateInput).data('unfudged-date')
        newDate     = (trimmedInput === "") ? null : newDate
        newDate     = this.changeToFancyMidnightIfNeeded(newDate)

        this.props.handleUpdate(newDate)
      })
    },

    // ensure jquery UI updates (as react doesn't know about it)
    componentDidUpdate() {
      const dateInput = this.refs.dateInput
      $(dateInput).val(this.formattedDate())
    },

    changeToFancyMidnightIfNeeded(date) {
      if (this.props.isFancyMidnight && tz.isMidnight(date)) {
        return tz.changeToTheSecondBeforeMidnight(date);
      }

      return date;
    },
    // ---------------
    //    Rendering
    // ---------------

    formattedDate() {
      // make this match the format used by the datepicker
      const dateStr = $.dateString(this.props.dateValue)
      const timeStr = $.timeString(this.props.dateValue)
      return `${dateStr} ${timeStr}`
    },

    wrapperClassName() {
      return this.props.dateType == "due_at" ?
        "DueDateInput__Container" :
        "DueDateRow__LockUnlockInput"
    },

    render() {
      if (this.props.disabled || this.props.readonly) {
        const className = cx('ic-Form-control', {readonly: this.props.readonly});
        return (
          <div className={className}>
            <label className={`${this.props.labelClasses} ic-Label`} htmlFor={this.props.dateType}>{this.props.labelText}</label>
            <div className="ic-Input-group">
              <input
                id={this.props.dateType}
                name={this.props.name}
                readOnly
                type="text"
                className={`ic-Input ${this.props.inputClasses}`}
                defaultValue={this.formattedDate()}
              />
              {
                this.props.readonly ? null :
                <div className="ic-Input-group__add-on" role="presentation" aria-hidden="true" tabIndex="-1">
                  <button className="Button Button--icon-action disabled" aria-disabled="true" type="button">
                    <i className="icon-calendar-month" role="presentation" />
                  </button>
                </div>
              }
            </div>
          </div>
        );
      }

      return (
        <div>
          <label
            id={this.props.labelledBy}
            className={`${this.props.labelClasses} Date__label`}
            htmlFor={this.uniqueId}
          >{this.props.labelText}</label>
          <div
            ref="datePickerWrapper"
            className={this.wrapperClassName()}
          >
            <input
              id              = {this.uniqueId}
              name            = {this.props.name}
              type            = "text"
              ref             = "dateInput"
              title           = {accessibleDateFormat()}
              data-tooltip    = ""
              className       = {this.props.inputClasses}
              aria-labelledby = {this.props.labelledBy}
              data-row-key    = {this.props.rowKey}
              data-date-type  = {this.props.dateType}
              defaultValue    = {this.formattedDate()}
            />
          </div>
        </div>
      )
    }
  });

export default DueDateCalendarPicker
