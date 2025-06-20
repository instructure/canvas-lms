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

import {useApolloClient, useMutation} from '@apollo/client'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {
  CREATE_SUBMISSION,
  CREATE_SUBMISSION_DRAFT,
  DELETE_SUBMISSION_DRAFT,
} from '@canvas/assignments/graphql/student/Mutations'
import {
  RUBRIC_QUERY,
  STUDENT_VIEW_QUERY,
  SUBMISSION_HISTORIES_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import Confetti from '@canvas/confetti/react/Confetti'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {RubricAssessmentTray} from '@canvas/rubrics/react/RubricAssessment'
import {assignLocation} from '@canvas/util/globalUtils'
import {clearAssetProcessorReports} from '../helpers/AssetProcessorHelper'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconCheckSolid, IconEndSolid, IconRefreshSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import qs from 'qs'
import React, {useState, useEffect, useContext, useRef} from 'react'
import {
  availableAndUnavailableCounts,
  getPeerReviewButtonText,
  getPeerReviewHeaderText,
  getPeerReviewSubHeaderText,
  getRedirectUrlToFirstPeerReview,
} from '../helpers/PeerReviewHelpers'
import {transformRubricAssessmentData} from '../helpers/RubricHelpers'
import {
  friendlyTypeName,
  isSubmitted,
  multipleTypesDrafted,
  totalAllowedAttempts,
  activeTypeMeetsCriteria,
} from '../helpers/SubmissionHelpers'
import AttemptTab from './AttemptTab'
import StudentViewContext from './Context'
import MarkAsDoneButton from './MarkAsDoneButton'
import PeerReviewPromptModal from './PeerReviewPromptModal'
import SimilarityPledge from '@canvas/assignments/react/SimilarityPledge'
import StudentFooter from './StudentFooter'
import useStore from './stores/index'

const I18n = createI18nScope('assignments_2_file_upload')

function DraftStatus({status}) {
  const statusConfigs = {
    saving: {
      color: 'success',
      icon: <IconRefreshSolid color="success" />,
      text: I18n.t('Saving Draft'),
    },
    saved: {
      color: 'success',
      icon: <IconCheckSolid color="success" />,
      text: I18n.t('Draft Saved'),
    },
    error: {
      color: 'danger',
      icon: <IconEndSolid color="error" />,
      text: I18n.t('Error Saving Draft'),
    },
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
  status: PropTypes.oneOf(['saving', 'saved', 'error']),
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
    variables: {submissionId},
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
        'Canceling this attempt will permanently delete any work performed in this attempt. Do you wish to proceed and delete your work?',
      ),
      confirmColor: 'danger',
      confirmText: I18n.t('Delete Work'),
      label: I18n.t('Delete your work?'),
    })

    if (confirmed) {
      deleteDraftMutation().then(onSuccess).catch(onError)
    }
  }

  return (
    <Button
      data-testid="cancel-attempt-button"
      color="secondary"
      onClick={() => handleCancelDraft(deleteDraftMutation)}
    >
      {I18n.t('Cancel Attempt %{attempt}', {attempt})}
    </Button>
  )
}

CancelAttemptButton.propTypes = {
  handleCacheUpdate: PropTypes.func.isRequired,
  onError: PropTypes.func.isRequired,
  onSuccess: PropTypes.func.isRequired,
  submission: PropTypes.object.isRequired,
}

const SubmissionManager = ({
  assignment,
  submission,
  reviewerSubmission,
  onSuccessfulPeerReview,
}) => {
  const [draftStatus, setDraftStatus] = useState(null)
  const [editingDraft, setEditingDraft] = useState(false)
  const [focusAttemptOnInit, setFocusAttemptOnInit] = useState(false)
  const [similarityPledgeChecked, setSimilarityPledgeChecked] = useState(false)
  const [showConfetti, setShowConfetti] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [uploadingFiles, setUploadingFiles] = useState(false)
  const [peerReviewPromptModalOpen, setPeerReviewPromptModalOpen] = useState(false)
  const [activeSubmissionType, setActiveSubmissionType] = useState(null)
  const [selectedExternalTool, setSelectedExternalTool] = useState(null)
  const [rubricData, setRubricData] = useState(null)
  const [peerReviewHeaderText, setPeerReviewHeaderText] = useState([])
  const [peerReviewSubHeaderText, setPeerReviewSubHeaderText] = useState([])
  const [peerReviewButtonText, setPeerReviewButtonText] = useState('')
  const [peerReviewButtonDisabled, setPeerReviewButtonDisabled] = useState(false)
  const [peerReviewShowSubHeaderBorder, setPeerReviewShowSubHeaderBorder] = useState(false)
  const [peerReviewHeaderMargin, setPeerReviewHeaderMargin] = useState(null)
  const [isSelfAssessmentOpen, setIsSelfAssessmentOpen] = useState(null)
  const [shouldShowPledgeError, setShouldShowPledgeError] = useState(false)

  const displayedAssessment = useStore(state => state.displayedAssessment)
  const isSavingRubricAssessment = useStore(state => state.isSavingRubricAssessment)
  const selfAssessment = useStore(state => state.selfAssessment)

  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)
  const {
    allowChangesToSubmission,
    latestSubmission,
    isLatestAttempt,
    lastSubmittedSubmission,
    cancelDraftAction,
    showDraftAction,
    startNewAttemptAction,
  } = useContext(StudentViewContext)

  const apolloClient = useApolloClient()

  const similarityPledgeCheckboxRef = useRef(null)
  const submitButtonRef = useRef(null)
  const newAttemptButtonRef = useRef(null)

  const updateSubmissionDraftCache = (cache, result) => {
    if (!result.data.createSubmissionDraft.errors) {
      const newDraft = result.data.createSubmissionDraft.submissionDraft
      updateCachedSubmissionDraft(cache, newDraft)
    }
  }

  const [createSubmission] = useMutation(CREATE_SUBMISSION, {
    onCompleted: data => {
      data.createSubmission.errors
        ? setOnSuccess(I18n.t('Error sending submission'))
        : handleSuccess()
    },
    onError: () => {
      setOnFailure(I18n.t('Error sending submission'))
    },
    refetchQueries: [{query: SUBMISSION_HISTORIES_QUERY, variables: {submissionID: submission.id}}],
  })

  const [createSubmissionDraft] = useMutation(CREATE_SUBMISSION_DRAFT, {
    onCompleted: data => {
      handleDraftComplete(
        !data.createSubmissionDraft.errors,
        data.createSubmissionDraft.submissionDraft?.body,
      )
    },
    onError: () => {
      handleDraftComplete(false, null)
    },
    update: updateSubmissionDraftCache,
  })

  const fetchRubricData = async ({fromCache} = {fromCache: false}) => {
    const {data} = await apolloClient.query({
      query: RUBRIC_QUERY,
      variables: {
        assignmentLid: assignment._id,
        submissionID: submission.id,
        courseID: assignment.env.courseId,
        submissionAttempt: submission.attempt,
      },
      fetchPolicy: fromCache ? 'cache-first' : 'network-only',
    })
    setRubricData(data)
  }
  const assignedAssessments = assignment.env.peerReviewModeEnabled
    ? reviewerSubmission?.assignedAssessments
    : submission.assignedAssessments

  useEffect(() => {
    // use the draft's active type if one exists
    let activeSubmissionTypeFromProps = null
    if (submission?.submissionDraft != null) {
      activeSubmissionTypeFromProps = submission?.submissionDraft.activeSubmissionType
    }
    // default to the assignment's submission type if there's only one
    if (assignment.submissionTypes.length === 1) {
      activeSubmissionTypeFromProps = assignment.submissionTypes[0]
    }
    setActiveSubmissionType(activeSubmissionTypeFromProps)

    if (
      (assignment.env.peerReviewModeEnabled || assignment.rubricSelfAssessmentEnabled) &&
      assignment.rubric
    ) {
      fetchRubricData().catch(() => {
        setOnFailure(I18n.t('Error fetching rubric data'))
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    // Clear the "draft saved" label when switching attempts
    if (draftStatus != null) {
      setDraftStatus(null)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [submission.attempt])

  useEffect(() => {
    if (isSavingRubricAssessment && ENV.enhanced_rubrics_enabled) {
      if (isRubricComplete(displayedAssessment)) {
        handleSubmitPeerReviewButton()
      } else {
        setOnFailure(I18n.t('Invalid Rubric Submission'))
        useStore.setState({isSavingRubricAssessment: false})
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isSavingRubricAssessment])

  const isRubricComplete = assessment => {
    return (
      assessment?.data.every(criterion => {
        const points = criterion.points
        const hasPoints = points?.value !== undefined
        const hasComments = !!criterion.comments?.length
        return (hasPoints || hasComments) && points?.valid
      }) || false
    )
  }

  const updateActiveSubmissionType = (activeSubmissionType, selectedExternalTool = null) => {
    const focusAttemptOnInit = assignment.submissionTypes.length > 1
    setActiveSubmissionType(activeSubmissionType)
    setFocusAttemptOnInit(focusAttemptOnInit)
    setSelectedExternalTool(selectedExternalTool)
  }

  const updateEditingDraft = editingDraft => {
    setEditingDraft(editingDraft)
  }

  const updateUploadingFiles = uploadingFiles => {
    setUploadingFiles(uploadingFiles)
  }

  const updateCachedSubmissionDraft = (cache, newDraft) => {
    const queryResult = JSON.parse(
      JSON.stringify(
        cache.readQuery({
          query: STUDENT_VIEW_QUERY,
          variables: {
            assignmentLid: assignment._id,
            submissionID: submission.id,
          },
        }),
      ),
    )

    if (!queryResult) {
      return
    }

    const {assignment: cachedAssignment, submission: cachedSubmission} = queryResult

    cachedSubmission.submissionDraft = newDraft
    cache.writeQuery({
      query: STUDENT_VIEW_QUERY,
      variables: {
        assignmentLid: assignment._id,
        submissionID: submission.id,
      },
      data: {assignment: cachedAssignment, submission: cachedSubmission},
    })
  }

  const prepareVariables = submitVars => {
    return {
      variables: {
        assignmentLid: assignment._id,
        submissionID: submission.id,
        ...submitVars,
      },
    }
  }

  const submitAssignment = async () => {
    if (isSubmitting || activeSubmissionType === null) {
      return
    }
    setIsSubmitting(true)

    switch (activeSubmissionType) {
      case 'basic_lti_launch':
        if (submission.submissionDraft.ltiLaunchUrl) {
          await createSubmission(
            prepareVariables({
              resourceLinkLookupUuid: submission.submissionDraft.resourceLinkLookupUuid,
              url: submission.submissionDraft.ltiLaunchUrl,
              type: activeSubmissionType,
            }),
          )
        }
        break
      case 'media_recording':
        if (submission.submissionDraft.mediaObject?._id) {
          await createSubmission(
            prepareVariables({
              mediaId: submission.submissionDraft.mediaObject._id,
              type: activeSubmissionType,
            }),
          )
        }
        break
      case 'online_upload':
        if (
          submission.submissionDraft.attachments &&
          submission.submissionDraft.attachments.length > 0
        ) {
          await createSubmission(
            prepareVariables({
              fileIds: submission.submissionDraft.attachments.map(file => file._id),
              type: activeSubmissionType,
            }),
          )
        }
        break
      case 'online_text_entry':
        if (submission.submissionDraft.body && submission.submissionDraft.body.length > 0) {
          await createSubmission(
            prepareVariables({
              body: submission.submissionDraft.body,
              type: activeSubmissionType,
            }),
          )
        }
        break
      case 'online_url':
        if (submission.submissionDraft.url) {
          await createSubmission(
            prepareVariables({
              url: submission.submissionDraft.url,
              type: activeSubmissionType,
            }),
          )
        }
        break
      case 'student_annotation':
        if (submission.submissionDraft) {
          await createSubmission(
            prepareVariables({
              type: activeSubmissionType,
            }),
          )
        }
        break
      default:
        throw new Error('submission type not yet supported in A2')
    }

    setIsSubmitting(false)
  }

  const shouldRenderNewAttempt = () => {
    const allowedAttempts = totalAllowedAttempts(assignment, latestSubmission)
    return (
      !assignment.env.peerReviewModeEnabled &&
      allowChangesToSubmission &&
      !assignment.lockInfo.isLocked &&
      isSubmitted(submission) &&
      submission.gradingStatus !== 'excused' &&
      latestSubmission.state !== 'unsubmitted' &&
      (allowedAttempts == null || latestSubmission.attempt < allowedAttempts)
    )
  }

  const shouldRenderSubmit = () => {
    return (
      !assignment.env.peerReviewModeEnabled &&
      !uploadingFiles &&
      !editingDraft &&
      isLatestAttempt &&
      allowChangesToSubmission &&
      !assignment.lockInfo.isLocked &&
      !shouldRenderNewAttempt() &&
      submission.gradingStatus !== 'excused' &&
      (assignment.allowedAttempts == null || assignment.allowedAttempts >= submission.attempt) &&
      submission.state === 'unsubmitted'
    )
  }

  const shouldRenderSelfAssessment = () => {
    return (
      !assignment.env.peerReviewModeEnabled &&
      ENV.enhanced_rubrics_enabled &&
      assignment.rubric &&
      assignment.rubricSelfAssessmentEnabled &&
      allowChangesToSubmission &&
      !assignment.lockInfo.isLocked &&
      submission.gradingStatus !== 'excused'
    )
  }

  const hasSubmittedAssessment = () => {
    const assessments = rubricData?.submission?.rubricAssessmentsConnection?.nodes?.map(
      assessment => transformRubricAssessmentData(assessment),
    )
    return assessments?.some(assessment => assessment.assessor?._id === ENV.current_user.id)
  }

  const shouldRenderSubmitPeerReview = () => {
    const hasRubrics = displayedAssessment !== null
    return (
      assignment.env.peerReviewModeEnabled &&
      assignment.env.peerReviewAvailable &&
      hasRubrics &&
      !hasSubmittedAssessment() &&
      !ENV.enhanced_rubrics_enabled
    )
  }

  const handleDraftComplete = (success, body) => {
    if (!allowChangesToSubmission) {
      return
    }
    updateUploadingFiles(false)
    const element = document.createElement('div')
    if (body) {
      element.insertAdjacentHTML('beforeend', body)
    }

    if (success) {
      if (!element.querySelector(`[data-placeholder-for]`)) {
        setDraftStatus('saved')
        setOnSuccess(I18n.t('Submission draft updated'))
      }
    } else {
      setDraftStatus('error')
      setOnFailure(I18n.t('Error updating submission draft'))
    }
  }

  const handleSubmitConfirmation = () => {
    submitAssignment()
    setDraftStatus(null)
    // We clear the asset processor reports from ENV when a new attempt is submitted
    // to ensure that the reports are not shown for the new attempt.
    // User needs to reload the page to see the new reports.
    clearAssetProcessorReports()
  }

  const handleSubmitButton = async () => {
    const shouldFocus = true
    const mustAgreeToPledge = window.ENV.SIMILARITY_PLEDGE && !similarityPledgeChecked
    if (mustAgreeToPledge) {
      setShouldShowPledgeError(true)
      if (shouldFocus) {
        // focus checkbox
        similarityPledgeCheckboxRef?.current?.focus()
      }
      return
    }

    if (!activeTypeMeetsCriteria(activeSubmissionType, submission)) {
      return
    }

    if (multipleTypesDrafted(submission)) {
      const confirmed = await showConfirmationDialog({
        body: I18n.t(
          'You are submitting a %{submissionType} submission. Only one submission type is allowed. All other submission types will be deleted.',
          {submissionType: friendlyTypeName(activeSubmissionType)},
        ),
        confirmText: I18n.t('Okay'),
        label: I18n.t('Confirm Submission'),
      })

      if (!confirmed) {
        return
      }
    }

    handleSubmitConfirmation()
  }

  const parseCriterion = data => {
    const key = `criterion_${data.criterion_id}`
    const criterion = assignment.rubric.criteria.find(
      criterion => criterion.id === data.criterion_id,
    )
    const rating = criterion.ratings.find(
      criterionRatings => criterionRatings.points === data.points?.value,
    )

    return {
      [key]: {
        rating_id: rating?.id,
        points: data.points?.value,
        description: data.description,
        comments: data.comments,
        save_comment: 1,
      },
    }
  }

  const handleSubmitPeerReviewButton = async () => {
    try {
      setIsSubmitting(true)
      let params = displayedAssessment.data.reduce(
        (result, item) => {
          return {...result, ...parseCriterion(item)}
        },
        {
          assessment_type: 'peer_review',
          ...(assignment.env.revieweeId && {user_id: assignment.env.revieweeId}),
          ...(assignment.env.anonymousAssetId && {anonymous_id: assignment.env.anonymousAssetId}),
        },
      )
      params = {
        rubric_assessment: params,
        _method: 'POST',
      }

      const rubricAssociation = rubricData.assignment.rubricAssociation
      await doFetchApi({
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        path: `/courses/${ENV.COURSE_ID}/rubric_associations/${rubricAssociation._id}/assessments`,
        body: qs.stringify(params),
      })

      handleSuccess(I18n.t('Rubric was successfully submitted'))
      fetchRubricData({fromCache: false})
    } catch {
      setOnFailure(I18n.t('Error submitting rubric'))
    }
    setIsSubmitting(false)
    useStore.setState({isSavingRubricAssessment: false})
  }

  const handleSubmitSelfAssessment = async assessment => {
    if (!isRubricComplete(assessment)) {
      setOnFailure(I18n.t('Incomplete Self Assessment'))
      return
    }

    try {
      setIsSubmitting(true)
      useStore.setState({selfAssessment: assessment})
      let params = assessment.data.reduce(
        (result, item) => {
          return {...result, ...parseCriterion(item)}
        },
        {
          assessment_type: 'self_assessment',
          user_id: ENV.current_user.id,
        },
      )
      params = {
        rubric_assessment: params,
        _method: 'POST',
      }

      const rubricAssociation = rubricData.assignment.rubricAssociation
      await doFetchApi({
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        path: `/courses/${ENV.COURSE_ID}/rubric_associations/${rubricAssociation._id}/assessments`,
        body: qs.stringify(params),
      })

      setIsSelfAssessmentOpen(false)
      showFlashSuccess(I18n.t('Self Assessment was successfully submitted'))()
      fetchRubricData({fromCache: false})
    } catch (error) {
      useStore.setState({selfAssessment: null})
      showFlashError(I18n.t('Error submitting self assessment'))()
    }
    setIsSubmitting(false)
  }

  const handleSuccess = (message = I18n.t('Submission sent')) => {
    setOnSuccess(message)
    const onTime = Date.now() < Date.parse(assignment.dueAt)
    setShowConfetti(window.ENV.CONFETTI_ENABLED && onTime)
    setTimeout(() => {
      // Confetti is cleaned up after 3000.
      // Need to reset state after that in case they submit another attempt.
      setShowConfetti(false)
    }, 4000)
    if (assignedAssessments.length > 0) {
      if (assignment.env.peerReviewModeEnabled) {
        const matchingAssessment = assignedAssessments.find(x => x.assetId === submission._id)
        if (matchingAssessment) matchingAssessment.workflowState = 'completed'
        onSuccessfulPeerReview?.(assignedAssessments)
      }
      const {availableCount, unavailableCount} = availableAndUnavailableCounts(assignedAssessments)
      handlePeerReviewPromptSettings(availableCount, unavailableCount)
      handleOpenPeerReviewPromptModal()
    }
  }

  const handlePeerReviewPromptSettings = (availableCount, unavailableCount) => {
    setPeerReviewButtonDisabled(availableCount === 0)
    if (assignment.env.peerReviewModeEnabled) {
      setPeerReviewPromptOptions(availableCount, unavailableCount)
      return
    }
    setSelfSubmitPeerReviewPromptOptions(availableCount, unavailableCount)
  }

  const setPeerReviewPromptOptions = (availableCount, unavailableCount) => {
    setPeerReviewHeaderText(getPeerReviewHeaderText(availableCount, unavailableCount))
    setPeerReviewSubHeaderText(getPeerReviewSubHeaderText(availableCount, unavailableCount))
    setPeerReviewShowSubHeaderBorder(false)
    setPeerReviewButtonText(getPeerReviewButtonText(availableCount, unavailableCount))
    setPeerReviewHeaderMargin(
      availableCount === 0 && unavailableCount === 0 ? 'small 0 x-large' : 'small 0 0',
    )
  }

  const setSelfSubmitPeerReviewPromptOptions = (availableCount, unavailableCount) => {
    setPeerReviewHeaderText([
      I18n.t('Your work has been submitted.'),
      I18n.t('Check back later to view feedback.'),
    ])
    setPeerReviewSubHeaderText([
      {
        props: {size: 'large', weight: 'bold'},
        text: I18n.t(
          {
            one: 'You have 1 Peer Review to complete.',
            other: 'You have %{count} Peer Reviews to complete.',
          },
          {count: availableCount + unavailableCount},
        ),
      },
      {
        props: {size: 'medium'},
        text: I18n.t('Peer submissions ready for review: %{availableCount}', {availableCount}),
      },
    ])
    setPeerReviewShowSubHeaderBorder(true)
    setPeerReviewButtonText('Peer Review')
  }

  const handleOpenPeerReviewPromptModal = () => {
    setPeerReviewPromptModalOpen(true)
  }

  const handleClosePeerReviewPromptModal = () => {
    setPeerReviewPromptModalOpen(false)
  }

  const handleRedirectToFirstPeerReview = () => {
    const url = getRedirectUrlToFirstPeerReview(assignedAssessments)
    assignLocation(url)
  }

  const renderAttemptTab = () => {
    return (
      <View as="div" margin="auto auto large">
        <AttemptTab
          activeSubmissionType={activeSubmissionType}
          assignment={assignment}
          createSubmissionDraft={createSubmissionDraft}
          editingDraft={editingDraft}
          focusAttemptOnInit={focusAttemptOnInit}
          onContentsChanged={() => {
            setDraftStatus('saving')
          }}
          originalityReportsForA2={window.ENV.ORIGINALITY_REPORTS_FOR_A2}
          selectedExternalTool={selectedExternalTool || submission?.submissionDraft?.externalTool}
          submission={submission}
          updateActiveSubmissionType={updateActiveSubmissionType}
          updateEditingDraft={updateEditingDraft}
          updateUploadingFiles={updateUploadingFiles}
          uploadingFiles={uploadingFiles}
          submitButtonRef={submitButtonRef}
          newAttemptButtonRef={newAttemptButtonRef}
        />
      </View>
    )
  }

  const renderSimilarityPledge = () => {
    const {SIMILARITY_PLEDGE: pledgeSettings} = window.ENV
    if (pledgeSettings == null || !shouldRenderSubmit()) {
      return null
    }

    return (
      <SimilarityPledge
        eulaUrl={pledgeSettings.EULA_URL}
        checked={similarityPledgeChecked}
        comments={pledgeSettings.COMMENTS}
        onChange={() => {
          setSimilarityPledgeChecked(!similarityPledgeChecked)
        }}
        pledgeText={pledgeSettings.PLEDGE_TEXT}
        shouldShowPledgeError={shouldShowPledgeError}
        setShouldShowPledgeError={setShouldShowPledgeError}
        checkboxRef={similarityPledgeCheckboxRef}
      />
    )
  }

  const footerButtons = () => {
    return [
      {
        key: 'draft-status',
        shouldRender: () =>
          isLatestAttempt &&
          submission.state === 'unsubmitted' &&
          activeSubmissionType === 'online_text_entry' &&
          draftStatus != null,
        render: () => <DraftStatus status={draftStatus} />,
      },
      {
        key: 'cancel-draft',
        shouldRender: () =>
          submission === latestSubmission &&
          latestSubmission.state === 'unsubmitted' &&
          submission.attempt > 1,
        render: () => {
          return (
            <CancelAttemptButton
              handleCacheUpdate={cache => {
                updateCachedSubmissionDraft(cache, null)
              }}
              onError={() => setOnFailure(I18n.t('Error canceling draft'))}
              onSuccess={() => cancelDraftAction()}
              submission={latestSubmission}
            />
          )
        },
      },
      {
        key: 'back-to-draft',
        shouldRender: () =>
          submission !== latestSubmission && latestSubmission.state === 'unsubmitted',
        render: () => {
          const {attempt} = latestSubmission
          return (
            <Button data-testid="back-to-attempt-button" color="primary" onClick={showDraftAction}>
              {I18n.t('Back to Attempt %{attempt}', {attempt})}
            </Button>
          )
        },
      },
      {
        key: 'new-attempt',
        shouldRender: () => shouldRenderNewAttempt(),
        render: () => {
          return (
            <Button
              data-testid="new-attempt-button"
              color="primary"
              onClick={startNewAttemptAction}
              elementRef={element => (newAttemptButtonRef.current = element)}
            >
              {I18n.t('New Attempt')}
            </Button>
          )
        },
      },
      {
        key: 'mark-as-done',
        shouldRender: () => window.ENV.CONTEXT_MODULE_ITEM != null,
        render: () => renderMarkAsDoneButton(),
      },
      {
        key: 'submit',
        shouldRender: () => shouldRenderSubmit(),
        render: () => renderSubmitButton(),
      },
      {
        key: 'submit-self-assessment',
        shouldRender: () => shouldRenderSelfAssessment(),
        render: () => renderSelfAssessmentButton(),
      },
      {
        key: 'submit-peer-review',
        shouldRender: () => shouldRenderSubmitPeerReview(),
        render: () => renderSubmitPeerReviewButton(),
      },
    ]
  }

  const renderFooter = () => {
    const buttons = footerButtons()
      .filter(button => button.shouldRender())
      .map(button => ({
        element: button.render(),
        key: button.key,
      }))

    return (
      <StudentFooter assignmentID={ENV.ASSIGNMENT_ID} buttons={buttons} courseID={ENV.COURSE_ID} />
    )
  }

  const renderSubmitButton = () => {
    return (
      <Button
        id="submit-button"
        data-testid="submit-button"
        disabled={draftStatus === 'saving' || isSubmitting}
        color="primary"
        onClick={() => handleSubmitButton()}
        elementRef={element => (submitButtonRef.current = element)}
      >
        {I18n.t('Submit Assignment')}
      </Button>
    )
  }

  const renderSelfAssessmentButton = () => {
    return (
      <Button
        id="self-assess-button"
        data-testid="self-assess-button"
        disabled={!isSubmitted(submission)}
        color="primary"
        withBackground={false}
        onClick={() => setIsSelfAssessmentOpen(true)}
      >
        {I18n.t('Self-Assess')}
      </Button>
    )
  }

  const renderSubmitPeerReviewButton = () => {
    return (
      <Button
        id="submit-peer-review-button"
        data-testid="submit-peer-review-button"
        disabled={isSubmitting || !isRubricComplete(displayedAssessment)}
        color="primary"
        onClick={() => handleSubmitPeerReviewButton()}
      >
        {I18n.t('Submit')}
      </Button>
    )
  }

  const renderMarkAsDoneButton = () => {
    const errorMessage = I18n.t('Error updating status of module item')

    const {done, id: itemId, module_id: moduleId} = window.ENV.CONTEXT_MODULE_ITEM

    return (
      <MarkAsDoneButton
        done={!!done}
        itemId={itemId}
        moduleId={moduleId}
        onError={() => {
          setOnFailure(errorMessage)
        }}
      />
    )
  }

  const rubricTrayData = {
    title: assignment.rubric?.title,
    ratingOrder: assignment.rubric?.ratingOrder,
    freeFormCriterionComments: assignment.rubric?.free_form_criterion_comments,
    pointsPossible: assignment.rubric?.points_possible,
    criteria: (assignment.rubric?.criteria || []).map(criterion => {
      return {
        ...criterion,
        longDescription: criterion.long_description,
        criterionUseRange: criterion.criterion_use_range,
        learningOutcomeId: criterion.learning_outcome_id,
        ignoreForScoring: criterion.ignore_for_scoring,
        masteryPoints: criterion.mastery_points,
        ratings: criterion.ratings.map(rating => {
          return {
            ...rating,
            longDescription: rating.long_description,
            points: rating.points,
            criterionId: criterion.id,
          }
        }),
      }
    }),
  }

  const rubricAssessmentData = (selfAssessment?.data ?? []).map(data => {
    const points = data.points
    return {
      ...data,
      criterionId: data.criterion_id,
      points: typeof points === 'number' ? points : points.value,
    }
  })

  return (
    <>
      {isSubmitting ? <LoadingIndicator /> : renderAttemptTab()}
      <>
        {renderSimilarityPledge()}
        {renderFooter()}
      </>
      {showConfetti ? <Confetti /> : null}
      <PeerReviewPromptModal
        headerText={peerReviewHeaderText}
        headerMargin={peerReviewHeaderMargin}
        subHeaderText={peerReviewSubHeaderText}
        showSubHeaderBorder={peerReviewShowSubHeaderBorder}
        peerReviewButtonText={peerReviewButtonText}
        peerReviewButtonDisabled={peerReviewButtonDisabled}
        open={peerReviewPromptModalOpen}
        onClose={() => handleClosePeerReviewPromptModal()}
        onRedirect={() => handleRedirectToFirstPeerReview()}
      />
      <RubricAssessmentTray
        hidePoints={rubricData?.assignment?.rubricAssociation?.hide_points}
        isOpen={isSelfAssessmentOpen}
        isPreviewMode={!!selfAssessment}
        isSelfAssessment={shouldRenderSelfAssessment()}
        isPeerReview={false}
        onDismiss={() => setIsSelfAssessmentOpen(false)}
        rubricAssessmentData={rubricAssessmentData}
        rubric={rubricTrayData}
        viewModeOverride="horizontal"
        onSubmit={assessment => {
          const assessmentFormatted = {
            score: assessment.reduce((prev, curr) => prev + (curr.points ?? 0), 0),
            data: assessment.map(criterionAssessment => {
              const {points} = criterionAssessment
              const valid = !Number.isNaN(points)
              return {
                ...criterionAssessment,
                criterion_id: criterionAssessment.criterionId,
                points: {
                  text: points?.toString(),
                  valid,
                  value: points,
                },
              }
            }),
          }
          handleSubmitSelfAssessment(assessmentFormatted)
        }}
      />
    </>
  )
}

SubmissionManager.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape,
  reviewerSubmission: Submission.shape,
  onSuccessfulPeerReview: PropTypes.func,
}

export default SubmissionManager
