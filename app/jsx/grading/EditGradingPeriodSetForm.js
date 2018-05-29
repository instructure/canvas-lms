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

import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import _ from 'underscore'
import $ from 'jquery'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import I18n from 'i18n!grading_periods'
import EnrollmentTermInput from '../grading/EnrollmentTermInput'
import 'compiled/jquery.rails_flash_notifications'

  const { array, bool, func, shape, string } = PropTypes;

  const buildSet = function(attr = {}) {
    return {
      id: attr.id,
      title: attr.title || "",
      weighted: !!attr.weighted,
      displayTotalsForAllGradingPeriods: !!attr.displayTotalsForAllGradingPeriods,
      enrollmentTermIDs: attr.enrollmentTermIDs || []
    };
  };

  const validateSet = function(set) {
    if (!(set.title || "").trim()) {
      return [I18n.t('All grading period sets must have a title')];
    }
    return [];
  };

  function replaceSetAttr (set, key, val) {
    return { set: { ...set, [key]: val } };
  }

  let GradingPeriodSetForm = React.createClass({
    propTypes: {
      set: shape({
        id: string,
        title: string,
        displayTotalsForAllGradingPeriods: bool,
        weighted: bool,
        enrollmentTermIDs: array
      }).isRequired,
      enrollmentTerms: array.isRequired,
      disabled: bool,
      onSave: func.isRequired,
      onCancel: func.isRequired
    },

    getInitialState() {
      let setId = parseInt(this.props.set.id, 10);
      let associatedEnrollmentTerms = _.where(this.props.enrollmentTerms, { gradingPeriodGroupId: this.props.set.id });
      let set = _.extend({}, this.props.set, {
        enrollmentTermIDs: _.pluck(associatedEnrollmentTerms, "id")
      });

      return { set: buildSet(set) };
    },

    componentDidMount() {
      ReactDOM.findDOMNode(this.refs.title).focus();
    },

    changeTitle(e) {
      this.setState(replaceSetAttr(this.state.set, 'title', e.target.value));
    },

    changeWeighted(e) {
      this.setState(replaceSetAttr(this.state.set, 'weighted', e.target.checked));
    },

    changeDisplayTotals (e) {
      this.setState(
        replaceSetAttr(this.state.set, 'displayTotalsForAllGradingPeriods', e.target.checked)
      );
    },

    changeEnrollmentTermIDs(termIDs) {
      const set = { ...this.state.set, enrollmentTermIDs: termIDs };
      this.setState({ set });
    },

    triggerSave: function(e) {
      e.preventDefault();
      if (this.props.onSave) {
        let validations = validateSet(this.state.set);
        if (_.isEmpty(validations)) {
          this.props.onSave(this.state.set);
        } else {
          _.each(validations, function(message) {
            $.flashError(message);
          });
        }
      }
    },

    triggerCancel: function(e) {
      e.preventDefault();
      if (this.props.onCancel) {
        this.setState({ set: buildSet() }, this.props.onCancel);
      }
    },

    renderSaveAndCancelButtons: function() {
      return (
        <div className="ic-Form-actions below-line">
          <Button disabled      = {this.props.disabled}
                  onClick       = {this.triggerCancel}
                  ref           = "cancelButton">
            {I18n.t("Cancel")}
          </Button>
          &nbsp;
          <Button variant       = "primary"
                  disabled      = {this.props.disabled}
                  aria-label    = {I18n.t("Save Grading Period Set")}
                  onClick       = {this.triggerSave}
                  ref           = "saveButton">
            {I18n.t("Save")}
          </Button>
        </div>
      );
    },

    render() {
      return (
        <div className="GradingPeriodSetForm pad-box">
          <form className="ic-Form-group ic-Form-group--horizontal">
            <div className="grid-row">
              <div className="col-xs-12 col-lg-6">
                <div className="ic-Form-control">
                  <label className="ic-Label" htmlFor="set-name">
                    {I18n.t("Set name")}
                  </label>
                  <input id="set-name"
                         ref="title"
                         className="ic-Input"
                         placeholder={I18n.t("Set name...")}
                         title={I18n.t('Grading Period Set Title')}
                         defaultValue={this.state.set.title}
                         onChange={this.changeTitle}
                         type="text"/>
                </div>

                <EnrollmentTermInput
                  enrollmentTerms              = {this.props.enrollmentTerms}
                  selectedIDs                  = {this.state.set.enrollmentTermIDs}
                  setSelectedEnrollmentTermIDs = {this.changeEnrollmentTermIDs} />

                <div className="ic-Input pad-box top-only">
                  <Checkbox
                    ref={(ref) => { this.weightedCheckbox = ref }}
                    label={I18n.t('Weighted grading periods')}
                    value="weighted"
                    checked={this.state.set.weighted}
                    onChange={this.changeWeighted}
                  />
                </div>
                <div className="ic-Input pad-box top-only">
                  <Checkbox
                    ref={(ref) => { this.displayTotalsCheckbox = ref; }}
                    label={I18n.t('Display totals for All Grading Periods option')}
                    value="totals"
                    checked={this.state.set.displayTotalsForAllGradingPeriods}
                    onChange={this.changeDisplayTotals}
                  />
                </div>
              </div>
            </div>

            <div className="grid-row">
              <div className="col-xs-12 col-lg-12">
                {this.renderSaveAndCancelButtons()}
              </div>
            </div>
          </form>
        </div>
      );
    }
  });

export default GradingPeriodSetForm
