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
  DELETE_SUBMISSION_DRAFT
} from '@canvas/assignments/graphql/student/Mutations'
import {Flex} from '@instructure/ui-flex'
import {
  friendlyTypeName,
  multipleTypesDrafted,
  totalAllowedAttempts
} from '../helpers/SubmissionHelpers'
import I18n from 'i18n!assignments_2_file_upload'
import {IconCheckSolid, IconEndSolid, IconRefreshSolid} from '@instructure/ui-icons'
import LoadingIndicator from '@canvas/loading-indicator'
import MarkAsDoneButton from './MarkAsDoneButton'
import {Modal} from '@instructure/ui-modal'
import {Mutation, useMutation} from 'react-apollo'
import PropTypes from 'prop-types'
import React, {Component} from 'react'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import SimilarityPledge from './SimilarityPledge'
import StudentFooter from './StudentFooter'
import {
  STUDENT_VIEW_QUERY,
  SUBMISSION_HISTORIES_QUERY
} from '@canvas/assignments/graphql/student/Queries'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

function DraftStatus({status}) {
  const statusConfigs = {
    saving: {
      color: 'success',
      icon: <IconRefreshSolid color="success" />,
      text: I18n.t('Saving Draft')
    },
    saved: {
      color: 'success',
      icon: <IconCheckSolid color="success" />,
      text: I18n.t('Draft Saved')
    },
    error: {
      color: 'danger',
      icon: <IconEndSolid color="error" />,
      text: I18n.t('Error Saving Draft')
    }
  }

  const config = statusConfigs[status]
  if (config == null) {
    return null
  }

  return (
    <Flex as="div">
      <Flex.Item>{config.icon}</Flex.Item>
      <Flex.Item margin="0 small 0 x-small">
        <Text color={config.color} weight="bold">
          {config.text}
        </Text>
      </Flex.Item>
    </Flex>
  )
}

DraftStatus.propTypes = {
  status: PropTypes.oneOf(['saving', 'saved', 'error'])
}

function CancelAttemptButton({handleCacheUpdate, onError, onSuccess, submission}) {
  const {attempt, id: submissionId, submissionDraft} = submission

  const [deleteDraftMutation] = useMutation(DELETE_SUBMISSION_DRAFT, {
    onCompleted: data => {
      if (data.deleteSubmissionDraft.errors != null) {
        onError()
      }
    },
    onError: () => {
      onError()
    },
    update: (cache, result) => {
      if (!result.data.deleteSubmissionDraft.errors) {
        handleCacheUpdate(cache)
      }
    },
    variables: {submissionId}
  })

  const handleCancelDraft = async () => {
    if (submissionDraft == null) {
      // If the user hasn't added any content to this draft yet, we don't need to run the
      // mutation since there's no draft object to delete
      onSuccess()
      return
    }

    const confirmed = await showConfirmationDialog({
      body: I18n.t(
        'Canceling this attempt will permanently delete any work performed in this attempt. Do you wish to proceed and delete your work?'
      ),
      confirmColor: 'danger',
      confirmText: I18n.t('Delete Work'),
      label: I18n.t('Delete your work?')
    })

    if (confirmed) {
      deleteDraftMutation().then(onSuccess).catch(onError)
    }
  }

  return (
    <Button color="secondary" onClick={() => handleCancelDraft(deleteDraftMutation)}>
      {I18n.t('Cancel Attempt %{attempt}', {attempt})}
    </Button>
  )
}

CancelAttemptButton.propTypes = {
  handleCacheUpdate: PropTypes.func.isRequired,
  onError: PropTypes.func.isRequired,
  onSuccess: PropTypes.func.isRequired,
  submission: PropTypes.shape.isRequired
}

export default class SubmissionManager extends Component {
  static propTypes = {
    assignment: Assignment.shape,
    submission: Submission.shape
  }

  state = {
    draftStatus: null,
    editingDraft: false,
    openSubmitModal: false,
    similarityPledgeChecked: false,
    showConfetti: false,
    submittingAssignment: false,
    uploadingFiles: false
  }

  componentDidMount() {
    this.setState({
      activeSubmissionType: this.getActiveSubmissionTypeFromProps()
    })
  }

  componentDidUpdate(prevProps) {
    // Clear the "draft saved" label when switching attempts
    if (
      this.props.submission.attempt !== prevProps.submission.attempt &&
      this.state.draftStatus != null
    ) {
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({draftStatus: null})
    }
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
    if (!result.data.createSubmissionDraft.errors) {
      const newDraft = result.data.createSubmissionDraft.submissionDraft
      this.updateCachedSubmissionDraft(cache, newDraft)
    }
  }

  updateCachedSubmissionDraft = (cache, newDraft) => {
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
    this.setState({submittingAssignment: true})

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

  shouldRenderNewAttempt(context) {
    const {assignment, submission} = this.props
    const allowedAttempts = totalAllowedAttempts({assignment, submission})
    return (
      context.allowChangesToSubmission &&
      !assignment.lockInfo.isLocked &&
      (submission.state === 'graded' || submission.state === 'submitted') &&
      submission.gradingStatus !== 'excused' &&
      context.latestSubmission.state !== 'unsubmitted' &&
      (allowedAttempts == null || submission.attempt < allowedAttempts)
    )
  }

  shouldRenderSubmit(context) {
    return (
      !this.state.uploadingFiles &&
      !this.state.editingDraft &&
      context.isLatestAttempt &&
      context.allowChangesToSubmission &&
      !this.props.assignment.lockInfo.isLocked &&
      !this.shouldRenderNewAttempt(context)
    )
  }

  handleDraftComplete(success) {
    this.updateUploadingFiles(false)

    if (success) {
      this.setState({draftStatus: 'saved'})
      this.context.setOnSuccess(I18n.t('Submission draft updated'))
    } else {
      this.setState({draftStatus: 'error'})
      this.context.setOnFailure(I18n.t('Error updating submission draft'))
    }
  }

  handleSubmitConfirmation(submitMutation) {
    this.submitAssignment(submitMutation)
    this.setState({openSubmitModal: false, draftStatus: null})
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
              onContentsChanged={() => {
                this.setState({draftStatus: 'saving'})
              }}
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
        key: 'draft-status',
        shouldRender: context =>
          context.isLatestAttempt &&
          this.props.submission.state === 'unsubmitted' &&
          this.state.activeSubmissionType === 'online_text_entry' &&
          this.state.draftStatus != null,
        render: _context => <DraftStatus status={this.state.draftStatus} />
      },
      {
        key: 'cancel-draft',
        shouldRender: context =>
          this.props.submission === context.latestSubmission &&
          context.latestSubmission.state === 'unsubmitted' &&
          this.props.submission.attempt > 1,
        render: context => {
          return (
            <CancelAttemptButton
              handleCacheUpdate={cache => {
                this.updateCachedSubmissionDraft(cache, null)
              }}
              onError={() => context.setOnFailure(I18n.t('Error canceling draft'))}
              onSuccess={() => context.cancelDraftAction()}
              submission={context.latestSubmission}
            />
          )
        }
      },
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
        shouldRender: context => this.shouldRenderNewAttempt(context),
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
              disabled={
                !this.props.submission.submissionDraft ||
                this.state.draftStatus === 'saving' ||
                this.state.submittingAssignment ||
                mustAgreeToPledge ||
                !activeTypeMeetsCriteria
              }
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

    const {done, id: itemId, module_id: moduleId} = window.ENV.CONTEXT_MODULE_ITEM

    return (
      <MarkAsDoneButton
        done={!!done}
        itemId={itemId}
        moduleId={moduleId}
        onError={() => {
          this.context.setOnFailure(errorMessage)
        }}
      />
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
