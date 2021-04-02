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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import AttemptTab from './AttemptTab'
import {Button, CloseButton} from '@instructure/ui-buttons'
import Confetti from '@canvas/confetti/react/Confetti'
import {
  CREATE_SUBMISSION,
  CREATE_SUBMISSION_DRAFT,
  SET_MODULE_ITEM_COMPLETION
} from '@canvas/assignments/graphql/student/Mutations'
import {friendlyTypeName, multipleTypesDrafted} from '../helpers/SubmissionHelpers'
import {IconCompleteLine, IconEmptyLine} from '@instructure/ui-icons'
import I18n from 'i18n!assignments_2_file_upload'
import LoadingIndicator from '@canvas/loading-indicator'
import {Modal} from '@instructure/ui-modal'
import {Mutation} from 'react-apollo'
import PropTypes from 'prop-types'
import React, {Component} from 'react'
import SimilarityPledge from './SimilarityPledge'
import StudentFooter from './StudentFooter'
import {STUDENT_VIEW_QUERY, SUBMISSION_HISTORIES_QUERY} from '@canvas/assignments/graphql/student/Queries'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {View} from '@instructure/ui-view'

function MarkAsDoneButton({done, onToggle}) {
  return (
    <Button
      color={done ? 'success' : 'secondary'}
      data-testid="set-module-item-completion-button"
      id="set-module-item-completion-button"
      onClick={onToggle}
      renderIcon={done ? IconCompleteLine : IconEmptyLine}
    >
      {done ? I18n.t('Done') : I18n.t('Mark as done')}
    </Button>
  )
}

MarkAsDoneButton.propTypes = {
  done: PropTypes.bool.isRequired,
  onToggle: PropTypes.func.isRequired
}

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
    moduleItemDone: false,
    openSubmitModal: false,
    similarityPledgeChecked: false,
    showConfetti: false,
    submittingAssignment: false,
    uploadingFiles: false
  }

  componentDidMount() {
    this.setState({
      activeSubmissionType: this.getActiveSubmissionTypeFromProps(),
      moduleItemDone: !!window.ENV.CONTEXT_MODULE_ITEM?.done
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
      context.isLatestAttempt &&
      context.allowChangesToSubmission &&
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

  handleSuccess() {
    this.context.setOnSuccess(I18n.t('Submission sent'))
    const onTime = Date.now() < Date.parse(this.props.assignment.dueAt)
    this.setState({showConfetti: window.ENV.CONFETTI_ENABLED && onTime})
    setTimeout(() => {
      // Confetti is cleaned up after 3000.
      // Need to reset state after that in case they submit another attempt.
      this.setState({showConfetti: false})
    }, 4000)
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
          <View as="div" margin="auto auto large">
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
          </View>
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

  renderSimilarityPledge(context) {
    const {SIMILARITY_PLEDGE: pledgeSettings} = window.ENV
    if (pledgeSettings == null || !this.shouldRenderSubmit(context)) {
      return null
    }

    return (
      <SimilarityPledge
        eulaUrl={pledgeSettings.EULA_URL}
        checked={this.state.similarityPledgeChecked}
        comments={pledgeSettings.COMMENTS}
        onChange={() => {
          this.setState(oldState => ({
            similarityPledgeChecked: !oldState.similarityPledgeChecked
          }))
        }}
        pledgeText={pledgeSettings.PLEDGE_TEXT}
      />
    )
  }

  footerButtons() {
    return [
      {
        key: 'back-to-draft',
        shouldRender: context =>
          this.props.submission !== context.latestSubmission &&
          context.latestSubmission.state === 'unsubmitted',
        render: context => {
          const {attempt} = context.latestSubmission
          return (
            <Button color="primary" onClick={context.showDraftAction}>
              {I18n.t('Back to Attempt %{attempt}', {attempt})}
            </Button>
          )
        }
      },
      {
        key: 'new-attempt',
        shouldRender: context => {
          const {assignment, submission} = this.props

          return (
            context.allowChangesToSubmission &&
            !assignment.lockInfo.isLocked &&
            (submission.state === 'graded' || submission.state === 'submitted') &&
            submission.gradingStatus !== 'excused' &&
            context.latestSubmission.state !== 'unsubmitted' &&
            (assignment.allowedAttempts == null || submission.attempt < assignment.allowedAttempts)
          )
        },
        render: context => {
          return (
            <Button color="primary" onClick={context.startNewAttemptAction}>
              {I18n.t('Try Again')}
            </Button>
          )
        }
      },
      {
        key: 'mark-as-done',
        shouldRender: _context => window.ENV.CONTEXT_MODULE_ITEM != null,
        render: _context => this.renderMarkAsDoneButton()
      },
      {
        key: 'submit',
        shouldRender: context => this.shouldRenderSubmit(context),
        render: _context => this.renderSubmitButton()
      }
    ]
  }

  renderFooter(context) {
    const buttons = this.footerButtons()
      .filter(button => button.shouldRender(context))
      .map(button => ({
        element: button.render(context),
        key: button.key
      }))

    return buttons.length > 0 ? <StudentFooter buttons={buttons} /> : null
  }

  renderSubmitButton() {
    const mustAgreeToPledge =
      window.ENV.SIMILARITY_PLEDGE != null && !this.state.similarityPledgeChecked

    return (
      <Mutation
        mutation={CREATE_SUBMISSION}
        onCompleted={data =>
          data.createSubmission.errors
            ? this.context.setOnFailure(I18n.t('Error sending submission'))
            : this.handleSuccess()
        }
        onError={() => this.context.setOnFailure(I18n.t('Error sending submission'))}
        // refetch submission histories so we don't lose the currently
        // displayed submission when a new submission is created and the current
        // submission gets transitioned over to a submission history.
        refetchQueries={() => [
          {query: SUBMISSION_HISTORIES_QUERY, variables: {submissionID: this.props.submission.id}}
        ]}
      >
        {submitMutation => (
          <>
            <Button
              id="submit-button"
              data-testid="submit-button"
              disabled={this.state.submittingAssignment || mustAgreeToPledge}
              color="primary"
              margin="auto auto auto small"
              onClick={() => this.handleSubmitButton(submitMutation)}
            >
              {I18n.t('Submit Assignment')}
            </Button>
            {this.state.openSubmitModal && this.renderSubmitConfirmation(submitMutation)}
          </>
        )}
      </Mutation>
    )
  }

  renderMarkAsDoneButton() {
    const errorMessage = I18n.t('Error updating status of module item')
    const updateDoneStatus = () => {
      this.setState(state => ({
        moduleItemDone: !state.moduleItemDone
      }))
    }

    const {id: itemId, module_id: moduleId} = window.ENV.CONTEXT_MODULE_ITEM
    const {moduleItemDone} = this.state

    return (
      <Mutation
        mutation={SET_MODULE_ITEM_COMPLETION}
        onCompleted={data => {
          data.setModuleItemCompletion.errors
            ? this.context.setOnFailure(errorMessage)
            : updateDoneStatus()
        }}
        onError={() => {
          this.context.setOnFailure(errorMessage)
        }}
        variables={{itemId, moduleId, done: !moduleItemDone}}
      >
        {mutation => <MarkAsDoneButton done={moduleItemDone} onToggle={mutation} />}
      </Mutation>
    )
  }

  render() {
    return (
      <>
        {this.state.submittingAssignment ? <LoadingIndicator /> : this.renderAttemptTab()}
        <StudentViewContext.Consumer>
          {context => (
            <>
              {this.renderSimilarityPledge(context)}
              {this.renderFooter(context)}
            </>
          )}
        </StudentViewContext.Consumer>
        {this.state.showConfetti ? <Confetti /> : null}
      </>
    )
  }
}

SubmissionManager.contextType = AlertManagerContext
