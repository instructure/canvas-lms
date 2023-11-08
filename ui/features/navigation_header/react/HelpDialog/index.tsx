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
import CreateTicketForm from './CreateTicketForm'
import TeacherFeedbackForm from './TeacherFeedbackForm'
import HelpLinks from './HelpLinks'
import type {HelpLink} from '../../../../api.d'

type Props = {
  links: HelpLink[]
  hasLoaded: boolean
  onFormSubmit: (event: Event) => void
}

type State = {
  view: string
}

class HelpDialog extends React.Component<Props, State> {
  static defaultProps = {
    hasLoaded: false,
    links: [],
    onFormSubmit() {},
  }

  state = {
    view: 'links',
  }

  handleLinkClick = (url: string) => {
    this.setState({view: url})
  }

  handleCancelClick = () => {
    this.setState({view: 'links'})
  }

  render() {
    switch (this.state.view) {
      case '#create_ticket':
        return (
          // @ts-expect-error
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
