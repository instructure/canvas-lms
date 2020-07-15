/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {AlertManagerContext} from '../../../shared/components/AlertManager'
import {Assignment} from '../graphqlData/Assignment'
import AttemptTab from './AttemptTab'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {CREATE_SUBMISSION, CREATE_SUBMISSION_DRAFT} from '../graphqlData/Mutations'
import {friendlyTypeName, multipleTypesDrafted} from '../helpers/SubmissionHelpers'
import I18n from 'i18n!assignments_2_file_upload'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import {Modal} from '@instructure/ui-overlays'
import {Mutation} from 'react-apollo'
import PropTypes from 'prop-types'
import React, {Component} from 'react'
import {STUDENT_VIEW_QUERY, SUBMISSION_HISTORIES_QUERY} from '../graphqlData/Queries'
import StudentViewContext from './Context'
import {Submission} from '../graphqlData/Submission'
import {direction} from '../../../shared/helpers/rtlHelper'

export default class SubmissionManager extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    focusElement: PropTypes.oneOfType([
      PropTypes.func,
      PropTypes.shape({current: PropTypes.instanceOf(Component)})
    ]),
    submission: Submission.shape
  }

  state = {
    editingDraft: false,
    openSubmitModal: false,
    submittingAssignment: false,
    uploadingFiles: false
  }

  componentDidMount() {
    this.setState({
      activeSubmissionType: this.getActiveSubmissionTypeFromProps()
    })
  }

  getActiveSubmissionTypeFromProps() {
    if (this.props.assignment.submissionTypes.length > 1) {
      return this.props.submission?.submissionDraft?.activeSubmissionType || null
    } else {
      return this.props.assignment.submissionTypes[0]
    }
  }

  updateActiveSubmissionType = activeSubmissionType => {
    this.setState({activeSubmissionType})
  }

  updateEditingDraft = editingDraft => {
    this.setState({editingDraft})
  }

  updateUploadingFiles = uploadingFiles => {
    this.setState({uploadingFiles})
  }

  updateSubmissionDraftCache = (cache, result) => {
    if (result.data.createSubmissionDraft.errors) {
      return
    }

    const {assignment} = JSON.parse(
      JSON.stringify(
        cache.readQuery({
          query: STUDENT_VIEW_QUERY,
          variables: {
            assignmentLid: this.props.assignment._id,
            submissionID: this.props.submission.id
          }
        })
      )
    )

    const newDraft = result.data.createSubmissionDraft.submissionDraft
    assignment.submissionsConnection.nodes[0].submissionDraft = newDraft

    cache.writeQuery({
      query: STUDENT_VIEW_QUERY,
      variables: {assignmentLid: this.props.assignment._id, submissionID: this.props.submission.id},
      data: {assignment}
    })
  }

  clearSubmissionHistoriesCache = (cache, result) => {
    if (result.data.createSubmission.errors) {
      return
    }

    // Clear the submission histories cache so that we don't lose the currently
    // displayed submission when a new submission is created and the current
    // submission gets transitioned over to a submission history.
    //
    // We can't set set the data back to null because apollo doesn't support that:
    // https://github.com/apollographql/apollo-feature-requests/issues/4
    // Instead, setting it to a `blank` state is as close as we can come.
    const node = {
      submissionHistoriesConnection: {
        nodes: [],
        pageInfo: {
          startCursor: null,
          hasPreviousPage: true,
          __typename: 'PageInfo'
        },
        __typename: 'SubmissionHistoryConnection'
      },
      __typename: 'Submission'
    }

    cache.writeQuery({
      query: SUBMISSION_HISTORIES_QUERY,
      variables: {submissionID: this.props.submission.id},
      data: {node}
    })
  }

  submitToGraphql(submitMutation, submitVars) {
    return submitMutation({
      variables: {
        assignmentLid: this.props.assignment._id,
        submissionID: this.props.submission.id,
        ...submitVars
      }
    })
  }

  async submitAssignment(submitMutation) {
    if (this.state.submittingAssignment || this.state.activeSubmissionType === null) {
      return
    }
    this.setState({submittingAssignment: true}, () => {
      if (this.props.focusElement) {
        this.props.focusElement.focus()
      }
    })

    switch (this.state.activeSubmissionType) {
      case 'media_recording':
        if (this.props.submission.submissionDraft.mediaObject?._id) {
          await this.submitToGraphql(submitMutation, {
            mediaId: this.props.submission.submissionDraft.mediaObject._id,
            type: this.state.activeSubmissionType
          })
        }
        break
      case 'online_upload':
        if (
          this.props.submission.submissionDraft.attachments &&
          this.props.submission.submissionDraft.attachments.length > 0
        ) {
          await this.submitToGraphql(submitMutation, {
            fileIds: this.props.submission.submissionDraft.attachments.map(file => file._id),
            type: this.state.activeSubmissionType
          })
        }
        break
      case 'online_text_entry':
        if (
          this.props.submission.submissionDraft.body &&
          this.props.submission.submissionDraft.body.length > 0
        ) {
          await this.submitToGraphql(submitMutation, {
            body: this.props.submission.submissionDraft.body,
            type: this.state.activeSubmissionType
          })
        }
        break
      case 'online_url':
        if (this.props.submission.submissionDraft.url) {
          await this.submitToGraphql(submitMutation, {
            url: this.props.submission.submissionDraft.url,
            type: this.state.activeSubmissionType
          })
        }
        break
      default:
        throw new Error('submission type not yet supported in A2')
    }

    this.setState({submittingAssignment: false})
  }

  shouldRenderSubmit(context) {
    let activeTypeMeetsCriteria = false
    switch (this.state.activeSubmissionType) {
      case 'media_recording':
        activeTypeMeetsCriteria = this.props.submission?.submissionDraft
          ?.meetsMediaRecordingCriteria
        break
      case 'online_text_entry':
        activeTypeMeetsCriteria = this.props.submission?.submissionDraft?.meetsTextEntryCriteria
        break
      case 'online_upload':
        activeTypeMeetsCriteria = this.props.submission?.submissionDraft?.meetsUploadCriteria
        break
      case 'online_url':
        activeTypeMeetsCriteria = this.props.submission?.submissionDraft?.meetsUrlCriteria
    }

    return (
      this.props.submission.submissionDraft &&
      activeTypeMeetsCriteria &&
      !this.state.uploadingFiles &&
      !this.state.editingDraft &&
      !context.nextButtonEnabled &&
      !this.props.assignment.lockInfo.isLocked
    )
  }

  handleDraftComplete(success) {
    this.updateUploadingFiles(false)

    if (success) {
      this.context.setOnSuccess(I18n.t('Submission draft updated'))
    } else {
      this.context.setOnFailure(I18n.t('Error updating submission draft'))
    }
  }

  handleSubmitConfirmation(submitMutation) {
    this.submitAssignment(submitMutation)
    this.setState({openSubmitModal: false})
  }

  handleSubmitButton(submitMutation) {
    if (multipleTypesDrafted(this.props.submission)) {
      this.setState({openSubmitModal: true})
    } else {
      this.handleSubmitConfirmation(submitMutation)
    }
  }

  renderAttemptTab() {
    return (
      <Mutation
        mutation={CREATE_SUBMISSION_DRAFT}
        onCompleted={data => this.handleDraftComplete(!data.createSubmissionDraft.errors)}
        onError={() => this.handleDraftComplete(false)}
        update={this.updateSubmissionDraftCache}
      >
        {createSubmissionDraft => (
          <AttemptTab
            activeSubmissionType={this.state.activeSubmissionType}
            assignment={this.props.assignment}
            createSubmissionDraft={createSubmissionDraft}
            editingDraft={this.state.editingDraft}
            submission={this.props.submission}
            updateActiveSubmissionType={this.updateActiveSubmissionType}
            updateEditingDraft={this.updateEditingDraft}
            updateUploadingFiles={this.updateUploadingFiles}
            uploadingFiles={this.state.uploadingFiles}
          />
        )}
      </Mutation>
    )
  }

  renderSubmitConfirmation(submitMutation) {
    return (
      <Modal
        data-testid="submission-confirmation-modal"
        label={I18n.t('Submit Confirmation')}
        onDismiss={() => this.setState({openSubmitModal: false})}
        open={this.state.openSubmitModal}
        size="small"
      >
        <Modal.Body>
          <CloseButton
            offset="x-small"
            onClick={() => this.setState({openSubmitModal: false})}
            placement="end"
            variant="icon"
          >
            {I18n.t('Close')}
          </CloseButton>
          {I18n.t(
            'You are submitting a %{submissionType} submission. Only one submission type is allowed. All other submission types will be deleted.',
            {submissionType: friendlyTypeName(this.state.activeSubmissionType)}
          )}
          <div>
            <Button
              data-testid="cancel-submit"
              margin="x-small x-small 0 0"
              onClick={() => this.setState({openSubmitModal: false})}
            >
              {I18n.t('Cancel')}
            </Button>
            <Button
              data-testid="confirm-submit"
              margin="x-small 0 0 0"
              onClick={() => this.handleSubmitConfirmation(submitMutation)}
              variant="primary"
            >
              {I18n.t('Okay')}
            </Button>
          </div>
        </Modal.Body>
      </Modal>
    )
  }

  renderSubmitButton() {
    return (
      <div style={{textAlign: direction('right')}}>
        <Mutation
          mutation={CREATE_SUBMISSION}
          onCompleted={data =>
            data.createSubmission.errors
              ? this.context.setOnFailure(I18n.t('Error sending submission'))
              : this.context.setOnSuccess(I18n.t('Submission sent'))
          }
          onError={() => this.context.setOnFailure(I18n.t('Error sending submission'))}
          update={this.clearSubmissionHistoriesCache}
        >
          {submitMutation => (
            <>
              <Button
                id="submit-button"
                data-testid="submit-button"
                disabled={this.state.submittingAssignment}
                variant="primary"
                margin="xx-small 0"
                onClick={() => this.handleSubmitButton(submitMutation)}
              >
                {I18n.t('Submit')}
              </Button>
              {this.state.openSubmitModal && this.renderSubmitConfirmation(submitMutation)}
            </>
          )}
        </Mutation>
      </div>
    )
  }

  render() {
    return (
      <>
        {this.state.submittingAssignment ? <LoadingIndicator /> : this.renderAttemptTab()}
        <StudentViewContext.Consumer>
          {context => {
            return this.shouldRenderSubmit(context) ? this.renderSubmitButton() : null
          }}
        </StudentViewContext.Consumer>
      </>
    )
  }
}

SubmissionManager.contextType = AlertManagerContext
