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
import DueDateCalendarPicker from '../due_dates/DueDateCalendarPicker'
import I18n from 'i18n!assignments'
import cx from 'classnames'

  var DueDateCalendars = React.createClass({

    propTypes: {
      dates: PropTypes.object.isRequired,
      rowKey: PropTypes.string.isRequired,
      overrides: PropTypes.array.isRequired,
      replaceDate: PropTypes.func.isRequired,
      sections: PropTypes.object.isRequired,
      disabled: PropTypes.bool.isRequired
    },

    // -------------------
    //      Rendering
    // -------------------

    labelledByForType(dateType){
      return "label-for-" + dateType + "-" + this.props.rowKey;
    },

    datePicker (dateType, labelText, disabled, readonly) {
      const isNotUnlockAt = dateType !== "unlock_at";

      return (
        <DueDateCalendarPicker
          dateType        = {dateType}
          handleUpdate    = {this.props.replaceDate.bind(this, dateType)}
          rowKey          = {this.props.rowKey}
          labelledBy      = {this.labelledByForType(dateType)}
          dateValue       = {this.props.dates[dateType]}
          inputClasses    = {this.inputClasses(dateType)}
          disabled        = {disabled}
          labelText       = {labelText}
          isFancyMidnight = {isNotUnlockAt}
          readonly        = {readonly}
        />
      );
    },

    inputClasses (dateType) {
      return cx({
        date_field: true,
        datePickerDateField: true,
        DueDateInput: dateType === "due_at",
        UnlockLockInput: dateType !== "due_at"
      });
    },

    render(){
      return (
        <div>
          <div className="ic-Form-group">
            <div className="ic-Form-control">
              {this.datePicker("due_at", I18n.t("Due"), this.props.disabled, this.props.dueDatesReadonly)}
            </div>
          </div>
          <div className="ic-Form-group">
            <div className="ic-Form-control">
              <div className="Available-from-to">
                <div className="from">
                  {this.datePicker("unlock_at", I18n.t("Available from"), this.props.disabled, this.props.availabilityDatesReadonly)}
                </div>
                <div className="to">
                  {this.datePicker("lock_at", I18n.t("Until"), this.props.disabled, this.props.availabilityDatesReadonly)}
                </div>
              </div>
            </div>
          </div>
        </div>
      );
    }
  });

export default DueDateCalendars
