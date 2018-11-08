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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!help_dialog'
import 'jquery.instructure_forms'
import 'compiled/jquery.rails_flash_notifications'

class TeacherFeedbackForm extends React.Component {
  static propTypes = {
    onCancel: PropTypes.func,
    onSubmit: PropTypes.func
  }

  static defaultProps = {
    onCancel() {},
    onSubmit() {}
  }

  state = {
    coursesLoaded: false,
    courses: []
  }

  componentWillMount() {
    $.getJSON('/api/v1/courses.json?enrollment_state=active&per_page=100', courses => {
      this.setState({
        coursesLoaded: true,
        courses
      })
    })
  }

  componentDidMount() {
    this.focus()

    $(this.form).formSubmit({
      formErrors: false,
      disableWhileLoading: true,
      required: ['recipients[]', 'body'],
      success: () => {
        $.flashMessage(I18n.t('Message sent.'))
        this.props.onSubmit()
      },
      error: response => {
        this.form.formErrors(JSON.parse(response.responseText))
        this.focus()
      }
    })
  }

  focus = () => {
    this.recipients.focus()
  }

  handleCancelClick = () => {
    this.form.reset()
    this.props.onCancel()
  }

  renderCourseOptions = () => {
    const options = this.state.courses.filter(c => !c.access_restricted_by_date).map(c => {
      const value = `course_${c.id}_admins`

      return (
        <option key={value} value={value} selected={window.ENV.context_id == c.id}>
          {c.name}
        </option>
      )
    })

    if (!this.state.coursesLoaded) {
      options.push(<option key="loading">{I18n.t('Loading courses...')}</option>)
    }

    return options
  }

  render() {
    return (
      <form ref={c => (this.form = c)} action="/api/v1/conversations" method="POST">
        <fieldset className="ic-Form-group ic-HelpDialog__form-fieldset">
          <legend className="screenreader-only">{I18n.t('Ask your instructor a question')}</legend>
          <label className="ic-Form-control">
            <span className="ic-Label">{I18n.t('Which course is this question about?')}</span>
            <select
              ref={c => (this.recipients = c)}
              className="ic-Input"
              required
              aria-required="true"
              name="recipients[]"
            >
              {this.renderCourseOptions()}
            </select>
            <span className="ic-Form-help-text">
              {I18n.t(
                'Message will be sent to all the teachers and teaching assistants in the course.'
              )}
            </span>
          </label>
          <label className="ic-Form-control">
            <span className="ic-Label">{I18n.t('Message')}</span>
            <textarea className="ic-Input" required aria-required="true" name="body" />
          </label>
          <div className="ic-HelpDialog__form-actions">
            <button type="button" className="Button" onClick={this.handleCancelClick}>
              {I18n.t('Cancel')}
            </button>
            &nbsp;
            <button
              type="submit"
              disabled={!this.state.coursesLoaded}
              className="Button Button--primary"
            >
              <i className="icon-message" aria-hidden="true" />
              &nbsp;&nbsp;
              {I18n.t('Send Message')}
            </button>
          </div>
          <input type="hidden" name="group_conversation" value="true" />
        </fieldset>
      </form>
    )
  }
}

export default TeacherFeedbackForm
