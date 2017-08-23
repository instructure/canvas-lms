/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import I18n from 'i18n!assignments'

export default class OriginalityReportVisibilityPicker extends React.Component {
  static propTypes = {
    isEnabled: PropTypes.bool.isRequired,
    selectedOption: PropTypes.string
  };

  static defaultProps = {
    selectedOption: null
  };

  constructor(props) {
    super(props);
    this.state = {
      selectedOption: props.selectedOption
    };
  }

  setSelectedOption = (e) => {
    this.setState({selectedOption: e.target.value});
  }

  render() {
    return (
      <div>
        <hr />
        <label id="report_visibility_picker_label" htmlFor="report_visibility_picker_select">
          {I18n.t('Show originality report to students')}
        </label>
        <div id="report_visibility_picker">
          <select
            id="report_visibility_picker_select"
            name="report_visibility"
            ref={(c) => { this.visibilityPicker = c; }}
            disabled={!this.props.isEnabled}
            value={this.state.selectedOption}
            onChange={this.setSelectedOption}
          >
            <option title={I18n.t('Immediately')} value="immediate" >
              {I18n.t('Immediately')}
            </option>
            <option title={I18n.t('After the assignment is graded')} value="after_grading">
              {I18n.t('After the assignment is graded')}
            </option>
            <option title={I18n.t('After the due date')} value="after_due_date">
              {I18n.t('After the due date')}
            </option>
            <option title={I18n.t('Never')} value="never">
              {I18n.t('Never')}
            </option>
          </select>
        </div>
      </div>
    );
  }
}
