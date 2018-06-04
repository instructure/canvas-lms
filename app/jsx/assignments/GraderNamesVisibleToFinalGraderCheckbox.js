/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {bool} from 'prop-types'
import React from 'react'
import I18n from 'i18n!assignments'

export default class GraderNamesVisibleToFinalGraderCheckbox extends React.Component {
  static propTypes = {checked: bool.isRequired}

  constructor(props) {
    super(props)
    this.handleChange = this.handleChange.bind(this)
    this.state = {checked: props.checked}
  }

  handleChange({target: checkbox}) {
    this.setState({checked: checkbox.checked})
  }

  render() {
    return (
      <label
        className="GraderNamesVisibleToFinalGrader__CheckboxLabel"
        htmlFor="assignment_grader_names_visible_to_final_grader"
      >
        <input
          type="hidden"
          name="grader_names_visible_to_final_grader"
          value={this.state.checked}
        />

        <input
          className="Assignment__Checkbox"
          checked={this.state.checked}
          id="assignment_grader_names_visible_to_final_grader"
          onChange={this.handleChange}
          type="checkbox"
        />

        <span className="GraderNamesVisibleToFinalGrader__CheckboxLabelText">
          {I18n.t('Final grader can view other grader names')}
        </span>
      </label>
    )
  }
}
