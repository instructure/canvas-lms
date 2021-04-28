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
import CreateTicketForm from './CreateTicketForm'
import TeacherFeedbackForm from './TeacherFeedbackForm'
import HelpLinks from './HelpLinks'

class HelpDialog extends React.Component {
  static propTypes = {
    links: HelpLinks.propTypes.links,
    hasLoaded: PropTypes.bool,
    onFormSubmit: PropTypes.func
  }

  static defaultProps = {
    hasLoaded: false,
    links: [],
    onFormSubmit() {}
  }

  state = {
    view: 'links'
  }

  handleLinkClick = url => {
    this.setState({view: url})
  }

  handleCancelClick = () => {
    this.setState({view: 'links'})
  }

  render() {
    switch (this.state.view) {
      case '#create_ticket':
        return (
          <CreateTicketForm onCancel={this.handleCancelClick} onSubmit={this.props.onFormSubmit} />
        )
      case '#teacher_feedback':
        return (
          <TeacherFeedbackForm
            onCancel={this.handleCancelClick}
            onSubmit={this.props.onFormSubmit}
          />
        )
      default:
        return (
          <HelpLinks
            links={this.props.links}
            hasLoaded={this.props.hasLoaded}
            onClick={this.handleLinkClick}
          />
        )
    }
  }
}

export default HelpDialog
