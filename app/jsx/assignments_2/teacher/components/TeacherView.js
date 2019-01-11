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
import {string} from 'prop-types'
import {fromJS, Map} from 'immutable'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import {queryAssignment, setWorkflow} from '../api'
import Header from './Header'
import ContentTabs from './ContentTabs'
import MessageStudentsWho from './MessageStudentsWho'
import TeacherViewContext, {TeacherViewContextDefaults} from './TeacherViewContext'

export default class TeacherView extends React.Component {
  static propTypes = {
    assignmentLid: string
  }

  constructor(props) {
    super(props)
    this.state = {
      messageStudentsWhoOpen: false,
      assignment: Map(),
      loading: true,
      errors: []
    }

    this.contextValue = {
      locale: (window.ENV && window.ENV.MOMENT_LOCALE) || TeacherViewContextDefaults.locale,
      timeZone: (window.ENV && window.ENV.TIMEZONE) || TeacherViewContextDefaults.timeZone
    }
  }

  componentDidMount() {
    this.loadAssignment()
  }

  async loadAssignment() {
    const loadingErrors = []
    let assignment = Map()
    try {
      const {errors, data} = await queryAssignment(this.props.assignmentLid)
      if (errors) loadingErrors.push(...errors)
      if (data.assignment) assignment = fromJS(data.assignment)
    } catch (error) {
      loadingErrors.push(error.message)
    }
    this.setState({assignment, loading: false, errors: loadingErrors})
  }

  assignmentWorkflowUpdate(nextAssignmentWorkflow, additionalUpdates = {}) {
    return state => ({
      assignment: state.assignment.set('state', nextAssignmentWorkflow),
      ...additionalUpdates
    })
  }

  async setWorkflowApiCall(newAssignmentState) {
    const errors = []
    try {
      const {graphqlErrors} = await setWorkflow(this.state.assignment.toJS(), newAssignmentState)
      if (graphqlErrors) errors.push(...graphqlErrors)
    } catch (error) {
      errors.push(error)
    }
    return errors
  }

  handlePublishChange = async newAssignmentWorkflow => {
    const oldAssignmentWorkflow = this.state.assignment.get('state')

    // be optimistic
    this.setState(this.assignmentWorkflowUpdate(newAssignmentWorkflow))
    const errors = await this.setWorkflowApiCall(newAssignmentWorkflow)
    if (errors.length > 0) {
      this.setState(this.assignmentWorkflowUpdate(oldAssignmentWorkflow, {errors}))
    } // else setWorkflow succeeded
  }

  handleUnsubmittedClick = () => {
    this.setState({messageStudentsWhoOpen: true})
  }

  handleDismissMessageStudentsWho = () => {
    this.setState({messageStudentsWhoOpen: false})
  }

  renderErrors() {
    return <pre>Error: {JSON.stringify(this.state.errors, null, 2)}</pre>
  }

  renderLoading() {
    return <div>Loading...</div>
  }

  render() {
    if (this.state.loading) return this.renderLoading()
    if (this.state.errors.length > 0) return this.renderErrors()
    const assignment = this.state.assignment
    return (
      <TeacherViewContext.Provider value={this.contextValue}>
        <div>
          <ScreenReaderContent>
            <h1>{assignment.get('name')}</h1>
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
