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
import {string, bool} from 'prop-types'
import I18n from 'i18n!assignments_2'

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import {queryAssignment, setWorkflow} from '../api'
import Header from './Header'
import ContentTabs from './ContentTabs'

import ConfirmDialog from './ConfirmDialog'
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
      assignment: {},
      confirmDelete: false,
      deletingNow: false,
      loading: true,
      errors: [],
      // for now, put "#edit" in the URL and it will turn off readOnly
      readOnly: window.location.hash.indexOf('edit') < 0
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
    let assignment = {}
    try {
      const {errors, data} = await queryAssignment(this.props.assignmentLid)
      if (errors) loadingErrors.push(...errors)
      if (data.assignment) assignment = data.assignment
    } catch (error) {
      loadingErrors.push(error.message)
    }
    this.setState({assignment, loading: false, errors: loadingErrors})
  }

  assignmentStateUpdate(state, updates) {
    return {assignment: {...state.assignment, ...updates}}
  }

  async setWorkflowApiCall(assignment, newAssignmentState) {
    const errors = []
    try {
      const {errors: graphqlErrors} = await setWorkflow(assignment, newAssignmentState)
      if (graphqlErrors) errors.push(...graphqlErrors)
    } catch (error) {
      errors.push(error)
    }
    return errors
  }

  // newAssignmentState is oneOf(['published', 'unpublished']) (but can be set to 'deleted'
  // to soft-delete the assignmet). This is not TeacherView's React state
  handlePublishChange = async newAssignmentState => {
    const oldAssignmentState = this.state.assignment.state

    // be optimistic
    this.setState(state => this.assignmentStateUpdate(state, {state: newAssignmentState}))
    const errors = await this.setWorkflowApiCall(this.state.assignment, newAssignmentState)
    if (errors.length > 0) {
      this.setState(state => ({
        errors,
        ...this.assignmentStateUpdate(state, {state: oldAssignmentState})
      }))
    } // else setWorkflow succeeded
  }

  handleUnsubmittedClick = () => {
    this.setState({messageStudentsWhoOpen: true})
  }

  handleDismissMessageStudentsWho = () => {
    this.setState({messageStudentsWhoOpen: false})
  }

  handleDeleteButtonPressed = () => {
    this.setState({confirmDelete: true})
  }

  handleCancelDelete = () => {
    this.setState({confirmDelete: false})
  }

  handleReallyDelete = async () => {
    this.setState({deletingNow: true})
    const errors = await this.setWorkflowApiCall(this.state.assignment, 'deleted')
    if (errors.length === 0) {
      this.handleDeleteSuccess()
    } else {
      this.handleDeleteError(errors)
    }
  }

  handleDeleteSuccess = () => {
    // reloading a deleted assignment has the effect of redirecting to the
    // assignments index page with a flash message indicating the assignment
    // has been deleted.
    window.location.reload()
  }

  handleDeleteError = errors => {
    this.setState({errors, confirmDelete: false, deletingNow: false})
  }

  renderErrors() {
    return <pre>Error: {JSON.stringify(this.state.errors, null, 2)}</pre>
  }

  renderLoading() {
    return <div>Loading...</div>
  }

  renderConfirmDialog() {
    return (
      <ConfirmDialog
        open={this.state.confirmDelete}
        working={this.state.deletingNow}
        modalLabel={I18n.t('confirm delete')}
        heading={I18n.t('Delete')}
        message={I18n.t('Are you sure you want to delete this assignment?')}
        confirmLabel={I18n.t('Delete')}
        cancelLabel={I18n.t('Cancel')}
        closeLabel={I18n.t('close')}
        spinnerLabel={I18n.t('deleting assignment')}
        onClose={this.handleCancelDelete}
        onCancel={this.handleCancelDelete}
        onConfirm={this.handleReallyDelete}
      />
    )
  }

  render() {
    if (this.state.loading) return this.renderLoading()
    if (this.state.errors.length > 0) return this.renderErrors()
    const assignment = this.state.assignment
    return (
      <TeacherViewContext.Provider value={this.contextValue}>
        <div>
          {this.renderConfirmDialog()}
          <ScreenReaderContent>
            <h1>{assignment.name}</h1>
          </ScreenReaderContent>
          <Header
            assignment={assignment}
            onUnsubmittedClick={this.handleUnsubmittedClick}
            onPublishChange={this.handlePublishChange}
            onDelete={this.handleDeleteButtonPressed}
            readOnly={this.state.readOnly}
          />
          <ContentTabs assignment={assignment} readOnly={this.state.readOnly} />
          <MessageStudentsWho
            open={this.state.messageStudentsWhoOpen}
            onDismiss={this.handleDismissMessageStudentsWho}
          />
        </div>
      </TeacherViewContext.Provider>
    )
  }
}
