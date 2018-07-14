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

import {bool, func} from 'prop-types'
import React from 'react'
import I18n from 'i18n!assignments'

export default class GraderCommentVisibilityCheckbox extends React.Component {
  static propTypes = {
    checked: bool.isRequired,
    onChange: func.isRequired
  }

  constructor(props) {
    super(props)
    this.handleChange = this.handleChange.bind(this)
    this.state = {checked: props.checked}
  }

  componentDidUpdate(_, prevState) {
    if (this.state.checked !== prevState.checked) {
      this.props.onChange(this.state.checked)
    }
  }

  handleChange({target: checkbox}) {
    this.setState({checked: checkbox.checked})
  }

  render() {
    return (
      <label
        className="GraderCommentVisibility__CheckboxLabel"
        htmlFor="assignment_grader_comment_visibility"
      >
        <input type="hidden" name="grader_comments_visible_to_graders" value={this.state.checked} />

        <input
          className="Assignment__Checkbox"
          checked={this.state.checked}
          id="assignment_grader_comment_visibility"
          onChange={this.handleChange}
          type="checkbox"
        />

        <span className="GraderCommentVisibility__CheckboxLabelText">
          {I18n.t("Graders can view each other's comments")}
        </span>
      </label>
    )
  }
}
