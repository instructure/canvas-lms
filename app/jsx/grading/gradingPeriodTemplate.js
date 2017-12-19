/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import tz from 'timezone'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import I18n from 'i18n!external_tools'
import _ from 'underscore'
import DateHelper from '../shared/helpers/dateHelper'
import 'jquery.instructure_date_and_time'
  const Types = PropTypes;

  const postfixId = (text, { props }) => {
    return text + props.id;
  };

  const isEditable = ({ props }) => {
    return props.permissions.update && !props.readOnly;
  };

  const tabbableDate = (ref, date) => {
    const formattedDate = DateHelper.formatDateForDisplay(date);
    return <span ref={ref} className="GradingPeriod__Action">{ formattedDate }</span>;
  };

  const renderActions = ({ props, onDeleteGradingPeriod }) => {
    if (props.permissions.delete && !props.readOnly) {
      let cssClasses = "Button Button--icon-action icon-delete-grading-period";
      if (props.disabled) cssClasses += " disabled";
      return (
        <div className="GradingPeriod__Actions content-box">
          <button ref="deleteButton"
                  role="button"
                  className={cssClasses}
                  aria-disabled={props.disabled}
                  onClick={onDeleteGradingPeriod}>
            <i className="icon-x icon-delete-grading-period"/>
            <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
          </button>
        </div>
      );
    }
  };

  let GradingPeriodTemplate = React.createClass({
    propTypes: {
      title: Types.string.isRequired,
      weight: Types.number,
      weighted: Types.bool.isRequired,
      startDate: Types.instanceOf(Date).isRequired,
      endDate: Types.instanceOf(Date).isRequired,
      closeDate: Types.instanceOf(Date).isRequired,
      id: Types.string.isRequired,
      permissions: Types.shape({
        update: Types.bool.isRequired,
        delete: Types.bool.isRequired,
      }).isRequired,
      readOnly: Types.bool.isRequired,
      requiredPropsIfEditable: function(props) {
        if (!props.permissions.update && !props.permissions.delete) return;

        const requiredProps = {
          disabled: 'boolean',
          onDeleteGradingPeriod: 'function',
          onDateChange: 'function',
          onTitleChange: 'function'
        };

        let invalidProps = [];
        _.each(requiredProps, (propType, propName) => {
          let invalidProp = _.isUndefined(props[propName]) || typeof props[propName] !== propType;
          if (invalidProp) invalidProps.push(propName);
        });

        if (invalidProps.length > 0) {
          let prefix = "GradingPeriodTemplate: required prop";
          if (invalidProps.length > 1) prefix += "s";
          const errorMessage = prefix + " " + invalidProps.join(", ") + " not provided or of wrong type.";
          return new Error(errorMessage);
        }
      }
    },

    componentDidMount: function() {
      if (this.isNewGradingPeriod()) {
        this.refs.title.focus();
      }
      let dateField = $(ReactDOM.findDOMNode(this)).find('.date_field');
      dateField.datetime_field();
      dateField.on('change', this.onDateChange);
    },

    onDateChange: function(event) {
      this.props.onDateChange(event.target.name, event.target.id);
    },

    isNewGradingPeriod: function() {
      return this.props.id.indexOf('new') > -1;
    },

    onDeleteGradingPeriod: function() {
      if (!this.props.disabled) {
        this.props.onDeleteGradingPeriod(this.props.id);
      }
    },

    renderTitle: function() {
      if (isEditable(this)) {
        return (
          <input id={postfixId("period_title_", this)}
                 type="text"
                 className="GradingPeriod__Detail ic-Input"
                 onChange={this.props.onTitleChange}
                 value={this.props.title}
                 disabled={this.props.disabled}
                 ref="title"/>
        );
      } else {
        return (
          <div>
            <span className="screenreader-only">{I18n.t("Grading Period Name")}</span>
            <span ref="title">{this.props.title}</span>
          </div>
        );
      }
    },

    renderWeight: function () {
      if (this.props.weighted) {
        return (
          <div className="col-xs-12 col-md-8 col-lg-2">
            <label className="ic-Label" htmlFor={postfixId('period_title_', this)}>
              {I18n.t('Weight')}
            </label>
            <div>
              <span className="screenreader-only">{I18n.t('Grading Period Weight')}</span>
              <span ref="weight">{I18n.n(this.props.weight, {percentage: true})}</span>
            </div>
          </div>
        );
      }
    },

    renderStartDate: function() {
      if (isEditable(this)) {
        return (
          <input id={postfixId("period_start_date_", this)}
                 type="text"
                 ref="startDate"
                 name="startDate"
                 className="GradingPeriod__Detail ic-Input input-grading-period-date date_field"
                 defaultValue={DateHelper.formatDateForDisplay(this.props.startDate)}
                 disabled={this.props.disabled}/>
        );
      } else {
        return (
          <div>
            <span className="screenreader-only">{I18n.t("Start Date")}</span>
            { tabbableDate("startDate", this.props.startDate) }
          </div>
        );
      }
    },

    renderEndDate: function() {
      if (isEditable(this)) {
        return (
          <input id={postfixId("period_end_date_", this)} type="text"
                 className="GradingPeriod__Detail ic-Input input-grading-period-date date_field"
                 ref="endDate"
                 name="endDate"
                 defaultValue={DateHelper.formatDateForDisplay(this.props.endDate)}
                 disabled={this.props.disabled}/>
        );
      } else {
        return (
          <div>
            <span className="screenreader-only">{I18n.t("End Date")}</span>
            { tabbableDate("endDate", this.props.endDate) }
          </div>
        );
      }
    },

    renderCloseDate: function() {
      let closeDate = isEditable(this) ? this.props.endDate : this.props.closeDate;
      return (
        <div>
          <span className="screenreader-only">{I18n.t("Close Date")}</span>
          { tabbableDate("closeDate", closeDate || this.props.endDate) }
        </div>
      );
    },

    render: function () {
      return (
        <div id={postfixId("grading-period-", this)} className="grading-period pad-box-mini border border-trbl border-round">
          <div className="GradingPeriod__Details pad-box-micro">
            <div className="grid-row">
              <div className="col-xs-12 col-md-8 col-lg-4">
                <label className="ic-Label" htmlFor={postfixId("period_title_", this)}>
                  {I18n.t("Grading Period Name")}
                </label>
                {this.renderTitle()}
              </div>
              <div className="col-xs-12 col-md-8 col-lg-2">
                <label className="ic-Label" htmlFor={postfixId("period_start_date_", this)}>
                  {I18n.t("Start Date")}
                </label>
                {this.renderStartDate()}
              </div>
              <div className="col-xs-12 col-md-8 col-lg-2">
                <label className="ic-Label" htmlFor={postfixId("period_end_date_", this)}>
                  {I18n.t("End Date")}
                </label>
                {this.renderEndDate()}
              </div>
              <div className="col-xs-12 col-md-8 col-lg-2">
                <label className="ic-Label" id={postfixId("period_close_date_", this)}>
                  {I18n.t("Close Date")}
                </label>
                {this.renderCloseDate()}
              </div>
              {this.renderWeight()}
            </div>
          </div>

          {renderActions(this)}
        </div>
      );
    }
  });

export default GradingPeriodTemplate
