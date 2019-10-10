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
import {Button} from '@instructure/ui-buttons'
import {CREATE_SUBMISSION, CREATE_SUBMISSION_DRAFT} from '../graphqlData/Mutations'
import I18n from 'i18n!assignments_2_file_upload'
import LoadingIndicator from '../../shared/LoadingIndicator'
import {Mutation} from 'react-apollo'
import React, {Component} from 'react'
import {STUDENT_VIEW_QUERY, SUBMISSION_HISTORIES_QUERY} from '../graphqlData/Queries'
import {Submission} from '../graphqlData/Submission'
import theme from '@instructure/canvas-theme'

export default class SubmissionManager extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    submission: Submission.shape
  }

  state = {
    editingDraft: false,
    submittingAssignment: false,
    uploadingFiles: false
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

  submitToGraphql = async (submitMutation, submitVars) => {
    await submitMutation({
      variables: {
        assignmentLid: this.props.assignment._id,
        submissionID: this.props.submission.id,
        ...submitVars
      }
    })
  }

  submitAssignment = async submitMutation => {
    if (this.state.submittingAssignment) {
      return
    }
    this.setState({submittingAssignment: true})

    await Promise.all(
      this.props.assignment.submissionTypes.map(async type => {
        switch (type) {
          case 'online_upload':
            if (
              this.props.submission.submissionDraft.attachments &&
              this.props.submission.submissionDraft.attachments.length > 0
            ) {
              this.submitToGraphql(submitMutation, {
                type,
                fileIds: this.props.submission.submissionDraft.attachments.map(file => file._id)
              })
            }
            break
          case 'online_text_entry':
            if (
              this.props.submission.submissionDraft.body &&
              this.props.submission.submissionDraft.body.length > 0
            ) {
              this.submitToGraphql(submitMutation, {
                type,
                body: this.props.submission.submissionDraft.body
              })
            }
        }
      })
    )

    this.setState({submittingAssignment: false})
  }

  shouldRenderSubmit = () => {
    return (
      this.props.submission.submissionDraft &&
      this.props.submission.submissionDraft.meetsAssignmentCriteria &&
      !this.state.uploadingFiles &&
      !this.state.editingDraft
    )
  }

  handleDraftComplete = success => {
    this.updateUploadingFiles(false)

    if (success) {
      this.context.setOnSuccess(I18n.t('Submission draft updated'))
    } else {
      this.context.setOnFailure(I18n.t('Error updating submission draft'))
    }
  }

  renderAttemptTab = () => {
    return (
      <Mutation
        mutation={CREATE_SUBMISSION_DRAFT}
        onCompleted={data => this.handleDraftComplete(!data.createSubmissionDraft.errors)}
        onError={() => this.handleDraftComplete(false)}
        update={this.updateSubmissionDraftCache}
      >
        {createSubmissionDraft => (
          <AttemptTab
            assignment={this.props.assignment}
            createSubmissionDraft={createSubmissionDraft}
            editingDraft={this.state.editingDraft}
            submission={this.props.submission}
            updateEditingDraft={this.updateEditingDraft}
            updateUploadingFiles={this.updateUploadingFiles}
            uploadingFiles={this.state.uploadingFiles}
          />
        )}
      </Mutation>
    )
  }

  renderSubmitButton = () => {
    const outerFooterStyle = {
      position: 'fixed',
      bottom: '0',
      left: '0',
      right: '0',
      maxWidth: '1366px',
      margin: '0 0 0 84px',
      zIndex: '5'
    }

    // TODO: Delete this once the better global footers are implemented. This
    //       is some pretty ghetto stuff to handle the fixed buttom bars (for
    //       masquarading and beta instances) that would otherwise hide the
    //       submit button.
    let paddingOffset = 0
    if (document.getElementById('masquerade_bar')) {
      paddingOffset += 52
    }
    if (document.getElementById('element_toggler_0')) {
      paddingOffset += 63
    }

    const innerFooterStyle = {
      backgroundColor: theme.variables.colors.white,
      borderColor: theme.variables.colors.borderMedium,
      borderTop: `1px solid ${theme.variables.colors.borderMedium}`,
      textAlign: 'right',
      margin: `0 ${theme.variables.spacing.medium}`,
      paddingBottom: `${paddingOffset}px`
    }

    return (
      <div style={outerFooterStyle}>
        <div style={innerFooterStyle}>
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
              <Button
                id="submit-button"
                data-testid="submit-button"
                disabled={this.state.submittingAssignment}
                variant="primary"
                margin="xx-small 0"
                onClick={() => this.submitAssignment(submitMutation)}
              >
                {I18n.t('Submit')}
              </Button>
            )}
          </Mutation>
        </div>
      </div>
    )
  }

  render() {
    return (
      <>
        {this.state.submittingAssignment ? <LoadingIndicator /> : this.renderAttemptTab()}
        {this.shouldRenderSubmit() && this.renderSubmitButton()}
      </>
    )
  }
}

SubmissionManager.contextType = AlertManagerContext
