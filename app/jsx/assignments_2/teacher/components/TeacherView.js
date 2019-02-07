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
import I18n from 'i18n!assignments_2'
import {Mutation} from 'react-apollo'

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import {TeacherAssignmentShape, SET_WORKFLOW} from '../assignmentData'
import Header from './Header'
import ContentTabs from './ContentTabs'

import ConfirmDialog from './ConfirmDialog'
import MessageStudentsWho from './MessageStudentsWho'
import TeacherViewContext, {TeacherViewContextDefaults} from './TeacherViewContext'

export default class TeacherView extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape
  }

  constructor(props) {
    super(props)
    this.state = {
      messageStudentsWhoOpen: false,
      confirmDelete: false,
      deletingNow: false,
      // for now, put "#edit" in the URL and it will turn off readOnly
      readOnly: window.location.hash.indexOf('edit') < 0
    }

    this.contextValue = {
      locale: (window.ENV && window.ENV.MOMENT_LOCALE) || TeacherViewContextDefaults.locale,
      timeZone: (window.ENV && window.ENV.TIMEZONE) || TeacherViewContextDefaults.timeZone
    }
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

  handleReallyDelete(mutate) {
    this.setState({deletingNow: true})
    mutate({
      variables: {
        id: this.props.assignment.lid,
        workflow: 'deleted'
      }
    })
  }

  handleDeleteSuccess = () => {
    // reloading a deleted assignment has the effect of redirecting to the
    // assignments index page with a flash message indicating the assignment
    // has been deleted.
    window.location.reload()
  }

  handleDeleteError = _apolloErrors => {
    // TODO: properly handle this error
    // this.setState({errors, confirmDelete: false, deletingNow: false})
  }

  renderLoading() {
    return <div>Loading...</div>
  }

  renderConfirmDialog() {
    return (
      <Mutation
        mutation={SET_WORKFLOW}
        onCompleted={this.handleDeleteSuccess}
        onError={this.handleDeleteError}
      >
        {deleteAssignment => (
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
            onConfirm={() => this.handleReallyDelete(deleteAssignment)}
          />
        )}
      </Mutation>
    )
  }

  render() {
    return (
      <TeacherViewContext.Provider value={this.contextValue}>
        <div>
          {this.renderConfirmDialog()}
          <ScreenReaderContent>
            <h1>{this.props.assignment.name}</h1>
          </ScreenReaderContent>
          <Header
            assignment={this.props.assignment}
            onUnsubmittedClick={this.handleUnsubmittedClick}
            onDelete={this.handleDeleteButtonPressed}
            readOnly={this.state.readOnly}
          />
          <ContentTabs assignment={this.props.assignment} readOnly={this.state.readOnly} />
          <MessageStudentsWho
            open={this.state.messageStudentsWhoOpen}
            onDismiss={this.handleDismissMessageStudentsWho}
          />
        </div>
      </TeacherViewContext.Provider>
    )
  }
}
