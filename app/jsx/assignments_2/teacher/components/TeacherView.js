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

import React from 'react'
import {bool, shape, string} from 'prop-types'
import {graphql} from 'react-apollo'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import {TEACHER_QUERY, TeacherAssignmentShape} from '../assignmentData'
import Header from './Header'
import ContentTabs from './ContentTabs'
import MessageStudentsWho from './MessageStudentsWho'
import TeacherViewContext, {TeacherViewContextDefaults} from './TeacherViewContext'

export class CoreTeacherView extends React.Component {
  static propTypes = {
    data: shape({
      assignment: TeacherAssignmentShape,
      loading: bool,
      error: string
    }).isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      messageStudentsWhoOpen: false
    }

    this.contextValue = {
      locale: (window.ENV && window.ENV.MOMENT_LOCALE) || TeacherViewContextDefaults.locale,
      timeZone: (window.ENV && window.ENV.TIMEZONE) || TeacherViewContextDefaults.timeZone
    }
  }

  handlePublishChange = () => {
    alert('publish toggle clicked')
  }

  handleUnsubmittedClick = () => {
    this.setState({messageStudentsWhoOpen: true})
  }

  handleDismissMessageStudentsWho = () => {
    this.setState({messageStudentsWhoOpen: false})
  }

  renderError(error) {
    return <pre>Error: {JSON.stringify(error, null, 2)}</pre>
  }

  renderLoading() {
    return <div>Loading...</div>
  }

  render() {
    const {
      data: {assignment, loading, error}
    } = this.props
    if (error) return this.renderError(error)
    else if (loading) return this.renderLoading()

    return (
      <TeacherViewContext.Provider value={this.contextValue}>
        <div>
          <ScreenReaderContent>
            <h1>{assignment.name}</h1>
          </ScreenReaderContent>
          <Header
            assignment={assignment}
            onUnsubmittedClick={this.handleUnsubmittedClick}
            onPublishChange={this.handlePublishChange}
          />
          <ContentTabs assignment={assignment} />
          <MessageStudentsWho
            open={this.state.messageStudentsWhoOpen}
            onDismiss={this.handleDismissMessageStudentsWho}
          />
        </div>
      </TeacherViewContext.Provider>
    )
  }
}

const TeacherView = graphql(TEACHER_QUERY, {
  options: ({assignmentLid}) => ({
    variables: {
      assignmentLid
    }
  })
})(CoreTeacherView)

TeacherView.propTypes = {
  assignmentLid: string.isRequired,
  ...TeacherView.propTypes
}

export default TeacherView
