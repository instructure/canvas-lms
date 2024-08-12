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
import {bool, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Mutation} from 'react-apollo'
import classnames from 'classnames'
import produce from 'immer'
import get from 'lodash/get'
import set from 'lodash/set'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

import {Alert} from '@instructure/ui-alerts'
import {Mask} from '@instructure/ui-overlays'
import {Portal} from '@instructure/ui-portal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'

import {TeacherAssignmentShape, SAVE_ASSIGNMENT} from '../assignmentData'
import Header from './Header'
import ContentTabs from './ContentTabs'
import TeacherFooter from './TeacherFooter'

import ConfirmDialog from './ConfirmDialog'
import MessageStudentsWhoDialog from './MessageStudentsWhoDialog'
import TeacherViewContext, {TeacherViewContextDefaults} from './TeacherViewContext'
import AssignmentFieldValidator from '../AssignentFieldValidator'

const I18n = useI18nScope('assignments_2')

const pathToOverrides = /assignmentOverrides\.nodes\.\d+/

export default class TeacherView extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape,
    messageAttachmentUploadFolderId: string,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: window.location.hash.indexOf('readOnly') >= 0,
  }

  constructor(props) {
    super(props)
    this.state = {
      messageStudentsWhoOpen: false,
      sendingMessageStudentsWhoNow: false,
      confirmDelete: false,
      deletingNow: false,
      workingAssignment: props.assignment, // the assignment with updated fields while editing
      isDirty: false, // has the user changed anything?
      isSaving: false, // is save assignment in-flight?
      isUnpublishing: false, // is saving just the unpublished state in-flight?
      invalids: {}, // keys are the  paths to invalid fields
    }

    // TODO: reevaluate if the context is still needed. <FriendlyDateTime> pulls the data
    // directly from ENV, so unless its replacement is different, this might be unnecessary.
    this.contextValue = {
      locale: (window.ENV && window.ENV.MOMENT_LOCALE) || TeacherViewContextDefaults.locale,
      timeZone: (window.ENV && window.ENV.TIMEZONE) || TeacherViewContextDefaults.timeZone,
    }

    this.fieldValidator = new AssignmentFieldValidator()
  }

  componentDidMount() {
    window.addEventListener('beforeunload', this.handleBeforeUnload)
  }

  handleBeforeUnload = event => {
    if (this.state.isDirty) {
      event.preventDefault()
      event.returnValue = ''
    }
  }

  // @param value: the new value. may be a scalar, an array, or an object.
  // @param path: where w/in the assignment it should go as a string representing
  //     the dot-separated path (e.g. 'assignmentOverrides.nodes.0`) to the value
  updateWorkingAssignment(path, value) {
    const old = get(this.state.workingAssignment, path)
    if (old === value) {
      return this.state.workingAssignment
    }
    const updatedAssignment = produce(this.state.workingAssignment, draft => {
      set(draft, path, value)
    })
    return updatedAssignment
  }

  // add or remove path from the set of invalid fields based on the new value
  // returns the updated set
  updateInvalids(path, value) {
    this.validate(path, value)
    return this.fieldValidator.invalidFields()
  }

  // if the new value is different from the existing value, update TeacherView's react state
  // returns a boolean indicating if the value was valid and set on the working assignment
  handleChangeAssignment = (path, value) => {
    const updatedAssignment = this.updateWorkingAssignment(path, value)
    if (updatedAssignment !== this.state.workingAssignment) {
      const updatedInvalids = this.updateInvalids(path, value)
      this.setState({
        workingAssignment: updatedAssignment,
        isDirty: true,
        invalids: updatedInvalids,
      })
    }
  }

  // validate the value at the path
  // if path points into an override, extract the override from the assignment
  // and pass it as the context in which to validate the value
  validate = (path, value) => {
    let context = this.state.workingAssignment
    const match = pathToOverrides.exec(path)
    if (match) {
      // extract the override
      context = get(this.state.workingAssignment, match[0])
    }
    const isValid = this.fieldValidator.validate(path, value, context)
    return isValid
  }

  invalidMessage = path => this.fieldValidator.errorMessage(path)

  isAssignmentValid = () => Object.keys(this.state.invalids).length === 0

  handleMessageStudentsClick = () => {
    this.setState({messageStudentsWhoOpen: true})
  }

  handleCloseMessageStudentsWho = () => {
    this.setState({messageStudentsWhoOpen: false, sendingMessageStudentsWhoNow: false})
  }

  handleSendMessageStudentsWho = () => {}

  handleDeleteButtonPressed = () => {
    this.setState({confirmDelete: true})
  }

  handleCancelDelete = () => {
    this.setState({confirmDelete: false})
  }

  handleReallyDelete(deleteAssignment) {
    this.setState({deletingNow: true})
    deleteAssignment({
      variables: {
        id: this.props.assignment.lid,
        state: 'deleted',
      },
    })
  }

  handleDeleteSuccess = () => {
    // reloading a deleted assignment has the effect of redirecting to the
    // assignments index page with a flash message indicating the assignment
    // has been deleted.
    window.location.reload()
  }

  handleDeleteError = apolloErrors => {
    showFlashAlert({
      message: I18n.t('Unable to delete assignment'),
      err: new Error(apolloErrors),
      type: 'error',
    })
    this.setState({confirmDelete: false, deletingNow: false})
  }

  handleCancel = () => {
    this.setState((state, props) => {
      // revalidate the current invalid fields with the original values
      Object.keys(state.invalids).forEach(path => this.validate(path, get(props.assignment, path)))
      return {
        workingAssignment: this.props.assignment,
        isDirty: false,
        invalids: this.fieldValidator.invalidFields(),
      }
    })
  }

  handleSave(saveAssignment) {
    if (this.isAssignmentValid()) {
      this.setState(
        (state, props) => {
          return {
            isSaving: true,
            isTogglingWorkstate: state.workingAssignment.state !== props.assignment.state,
          }
        },
        () => {
          const assignment = this.state.workingAssignment
          saveAssignment({
            variables: {
              id: assignment.lid,
              name: assignment.name,
              description: assignment.description,
              state: assignment.state,
              pointsPossible: parseFloat(assignment.pointsPossible),
              dueAt: assignment.dueAt && new Date(assignment.dueAt).toISOString(), // convert to iso8601 in UTC
              unlockAt: assignment.unlockAt && new Date(assignment.unlockAt).toISOString(),
              lockAt: assignment.lockAt && new Date(assignment.lockAt).toISOString(),
              assignmentOverrides: assignment.assignmentOverrides.nodes.map(o => ({
                id: o.lid,
                dueAt: o.dueAt && new Date(o.dueAt).toISOString(),
                lockAt: o.lockAt && new Date(o.lockAt).toISOString(),
                unlockAt: o.unlockAt && new Date(o.unlockAt).toISOString(),
                sectionId: o.set.__typename === 'Section' ? o.set.lid : undefined,
                groupId: o.set.__typename === 'Group' ? o.set.lid : undefined,
                studentIds:
                  o.set.__typename === 'AdhocStudents' ? o.set.students.map(s => s.lid) : undefined,
              })),
            },
          })
        }
      )
    } else {
      showFlashAlert({
        message: I18n.t('You cannot save while there are errors'),
        type: 'info',
      })
    }
  }

  // if the last save was just to unpublish,
  // then we don't change the isDirty state
  handleSaveSuccess = () => {
    this.setState((state, _props) => ({
      isSaving: false,
      isUnpublishing: false,
      isDirty: state.isUnpublishing ? state.isDirty : false,
      isTogglingWorkstate: false,
    }))
  }

  handleSaveError = apolloErrors => {
    // TODO: something better
    showFlashAlert({
      message: I18n.t('An error occured saving the assignment'),
      err: new Error(apolloErrors),
      type: 'error',
    })

    this.setState((state, _props) => {
      // reset the published toggle if necessary
      let workingAssignment = state.workingAssignment
      if (state.isTogglingWorkstate) {
        workingAssignment = this.updateWorkingAssignment(
          'state',
          workingAssignment.state === 'published' ? 'unpublished' : 'published'
        )
      }
      return {
        isSaving: false,
        isTogglingWorkstate: false,
        workingAssignment,
      }
    })
  }

  handlePublish(saveAssignment) {
    if (this.isAssignmentValid()) {
      // while the user can unpublish w/o saving anything,
      // publishing implies saving any pending edits.
      const updatedAssignment = this.updateWorkingAssignment('state', 'published')
      this.setState({workingAssignment: updatedAssignment}, () => this.handleSave(saveAssignment))
    } else {
      showFlashAlert({
        message: I18n.t('You cannot publish this assignment while there are errors'),
        type: 'info',
      })
    }
  }

  deleteDialogButtonProps = deleteAssignment => [
    {
      children: I18n.t('Cancel'),
      onClick: this.handleCancelDelete,
      'data-testid': 'delete-dialog-cancel-button',
    },
    {
      children: I18n.t('Delete'),
      variant: 'danger',
      onClick: () => this.handleReallyDelete(deleteAssignment),
      'data-testid': 'delete-dialog-confirm-button',
    },
  ]

  renderDeleteDialogBody = () => (
    <Alert variant="warning">
      <Text size="large">{I18n.t('Are you sure you want to delete this assignment?')}</Text>
    </Alert>
  )

  handleSetWorkstate(saveAssignment, newState) {
    if (this.isAssignmentValid() || newState === 'unpublished') {
      const updatedAssignment = this.updateWorkingAssignment('state', newState)
      this.setState(
        {
          workingAssignment: updatedAssignment,
          isSaving: true,
          isDirty: true,
          isTogglingWorkstate: true,
        },
        () => {
          if (newState === 'unpublished') {
            // just update the state
            this.setState({isSaving: true, isUnpublishing: true}, () => {
              saveAssignment({
                variables: {
                  id: this.state.workingAssignment.lid,
                  state: this.state.workingAssignment.state,
                },
              })
            })
          } else {
            // save everything
            this.handleSave(saveAssignment)
          }
        }
      )
    } else {
      showFlashAlert({
        message: I18n.t('You cannot publish this assignment while there are errors'),
        type: 'info',
      })
    }
  }

  renderDeleteDialog() {
    return (
      <Mutation
        mutation={SAVE_ASSIGNMENT}
        onCompleted={this.handleDeleteSuccess}
        onError={this.handleDeleteError}
      >
        {deleteAssignment => (
          <ConfirmDialog
            open={this.state.confirmDelete}
            working={this.state.deletingNow}
            disabled={this.state.deletingNow}
            modalLabel={I18n.t('confirm delete')}
            heading={I18n.t('Delete')}
            body={this.renderDeleteDialogBody}
            buttons={() => this.deleteDialogButtonProps(deleteAssignment)}
            spinnerLabel={I18n.t('deleting assignment')}
            onDismiss={this.handleCancelDelete}
          />
        )}
      </Mutation>
    )
  }

  // At the moment the MessageStudentsWhoDialog doesn't have
  // busy, onSend, messageAttachmentUploadFolderId props
  // these props needs to be reviewed in the future
  renderMessageStudentsWhoDialog = () => (
    <MessageStudentsWhoDialog
      assignment={this.props.assignment}
      open={this.state.messageStudentsWhoOpen}
      busy={this.state.sendingMessageStudentsWhoNow}
      onClose={this.handleCloseMessageStudentsWho}
      onSend={this.handleSendMessageStudentsWho}
      messageAttachmentUploadFolderId={this.props.messageAttachmentUploadFolderId}
    />
  )

  render() {
    const dirty = this.state.isDirty
    const assignment = this.state.workingAssignment
    const clazz = classnames('assignments-teacher', {dirty})
    return (
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorCategory={I18n.t('Assignments 2 Teacher View Error Page')}
          />
        }
      >
        <TeacherViewContext.Provider value={this.contextValue}>
          <div className={clazz}>
            {this.renderDeleteDialog()}
            <ScreenReaderContent>
              <h1>{assignment.name}</h1>
            </ScreenReaderContent>
            <Mutation
              mutation={SAVE_ASSIGNMENT}
              onCompleted={this.handleSaveSuccess}
              onError={this.handleSaveError}
            >
              {saveAssignment => (
                <>
                  <Header
                    assignment={assignment}
                    onChangeAssignment={this.handleChangeAssignment}
                    onValidate={this.validate}
                    invalidMessage={this.invalidMessage}
                    onSetWorkstate={newState => this.handleSetWorkstate(saveAssignment, newState)}
                    onDelete={this.handleDeleteButtonPressed}
                    readOnly={this.props.readOnly}
                  />
                  <ContentTabs
                    assignment={assignment}
                    onChangeAssignment={this.handleChangeAssignment}
                    onMessageStudentsClick={this.handleMessageStudentsClick}
                    onValidate={this.validate}
                    invalidMessage={this.invalidMessage}
                    readOnly={this.props.readOnly}
                  />
                  {this.renderMessageStudentsWhoDialog()}
                  {dirty || !this.isAssignmentValid() ? (
                    <TeacherFooter
                      onCancel={this.handleCancel}
                      onSave={() => this.handleSave(saveAssignment)}
                      onPublish={() => this.handlePublish(saveAssignment)}
                    />
                  ) : null}
                </>
              )}
            </Mutation>
            <Portal open={this.state.isSaving}>
              <Mask fullscreen={true}>
                <Spinner size="large" renderTitle={I18n.t('Saving assignment')} />
              </Mask>
            </Portal>
          </div>
        </TeacherViewContext.Provider>
      </ErrorBoundary>
    )
  }
}
