/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useEffect} from 'react'
import {useQueryClient} from '@tanstack/react-query'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Tabs} from '@instructure/ui-tabs'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import numberFormat from '@canvas/i18n/numberFormat'
import ErrorShip from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page/react'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import AssignmentDescription from '@canvas/assignments/react/AssignmentDescription'
import NeedsSubmissionPeerReview from '@canvas/assignments/react/NeedsSubmissionPeerReview'
import {useAssignmentQuery} from '../hooks/useAssignmentQuery'
import {useAllocatePeerReviews} from '../hooks/useAllocatePeerReviews'
import {useReviewerSubmissionQuery} from '../hooks/useReviewerSubmissionQuery'
import {PeerReviewSelector} from './PeerReviewSelector'
import AssignmentSubmission from './AssignmentSubmission'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints/src'
import theme from '@instructure/canvas-theme'
import {isPeerReviewLocked, isPeerReviewPastLockDate} from '../utils/peerReviewLockUtils'
import LockedPeerReview from './LockedPeerReview'
import UnavailablePeerReview from './UnavailablePeerReview'
import PeerReviewPromptModal from '@canvas/assignments/react/PeerReviewPromptModal'
import {COMPLETED_PEER_REVIEW_TEXT} from '@canvas/assignments/helpers/PeerReviewHelpers'

const I18n = createI18nScope('peer_reviews_student')

export interface PeerReviewsStudentViewProps {
  assignmentId: string
  breakpoints: Breakpoints
}

const Divider = () => (
  <View as="div" margin="small none">
    <hr style={{border: 'none', borderBottom: `1px solid ${theme.colors.contrasts.grey1214}`}} />
  </View>
)

const PeerReviewsStudentView: React.FC<PeerReviewsStudentViewProps> = ({
  assignmentId,
  breakpoints,
}) => {
  const [selectedTab, setSelectedTab] = useState<'details' | 'submission'>('details')
  const [selectedAssessmentIndex, setSelectedAssessmentIndex] = useState(0)
  const [hasCalledAllocate, setHasCalledAllocate] = useState(false)
  const [shouldNavigateToNext, setShouldNavigateToNext] = useState(false)
  const [peerReviewModalOpen, setPeerReviewModalOpen] = useState(false)
  const [hasSeenPeerReviewModal, setHasSeenPeerReviewModal] = useState(false)

  const userId = ENV.current_user_id || ''

  const queryClient = useQueryClient()
  const {data, isLoading, isError} = useAssignmentQuery(assignmentId, userId)
  const {mutate: allocatePeerReviews} = useAllocatePeerReviews()
  const {data: reviewerSubmission} = useReviewerSubmissionQuery(assignmentId, userId || '')
  const isMobile = breakpoints.mobileOnly

  useEffect(() => {
    if (data?.assignment && !hasCalledAllocate) {
      const assignment = data.assignment
      const isLocked = isPeerReviewLocked(assignment)
      const isPastLockDate = isPeerReviewPastLockDate(assignment)

      // Don't allocate if the peer review is locked or past the lock date
      if (isLocked || isPastLockDate) {
        return
      }

      const assessmentRequestsCount = assignment.assessmentRequestsForCurrentUser?.length || 0
      const peerReviewsRequired = assignment.peerReviews?.count || 0
      const submissionRequired = assignment.peerReviews?.submissionRequired ?? false
      const hasSubmitted =
        assignment.submissionsConnection?.nodes &&
        assignment.submissionsConnection.nodes.length > 0 &&
        assignment.submissionsConnection.nodes[0]?.submittedAt
      const showSubmissionRequiredView = submissionRequired && !hasSubmitted

      if (!showSubmissionRequiredView && assessmentRequestsCount < peerReviewsRequired) {
        setHasCalledAllocate(true)
        allocatePeerReviews({
          courseId: assignment.courseId,
          assignmentId: assignment._id,
        })
      }
    }
  }, [data, allocatePeerReviews, hasCalledAllocate])

  useEffect(() => {
    const assessmentRequests = data?.assignment?.assessmentRequestsForCurrentUser
    if (shouldNavigateToNext && assessmentRequests) {
      const currentReview = assessmentRequests[selectedAssessmentIndex]

      const nextAssignedReview = assessmentRequests.find(
        assessment =>
          assessment.workflowState === 'assigned' &&
          assessment.available === true &&
          assessment._id !== currentReview?._id,
      )

      if (nextAssignedReview) {
        const nextIndex = assessmentRequests.indexOf(nextAssignedReview)
        setSelectedAssessmentIndex(nextIndex)
      } else {
        const requiredCount = data?.assignment?.peerReviews?.count || 0
        const allocatedCount = assessmentRequests.length

        if (allocatedCount >= requiredCount) {
          setPeerReviewModalOpen(true)
          setHasSeenPeerReviewModal(true)
        } else {
          const availableCount = assessmentRequests.filter(a => a.available).length
          setSelectedAssessmentIndex(availableCount)
        }
      }

      setShouldNavigateToNext(false)
    }
  }, [shouldNavigateToNext, data, selectedAssessmentIndex])

  const handleNextPeerReview = () => {
    setShouldNavigateToNext(true)
  }

  const handlePeerReviewSubmitted = () => {
    queryClient.invalidateQueries({queryKey: ['peerReviewAssignment', assignmentId]})
  }

  const isUnavailableReviewSelected = () => {
    const availableCount = assessmentRequestsForCurrentUser?.filter(a => a.available)?.length || 0
    return selectedAssessmentIndex >= availableCount
  }

  const getUnavailableReason = () => {
    const selectedAssessment = assessmentRequestsForCurrentUser?.[selectedAssessmentIndex]

    // If the assessment request exists but submission hasn't been submitted yet
    if (selectedAssessment && !selectedAssessment.submission?.submittedAt) {
      return I18n.t('This student has not yet submitted their work.')
    }
  }

  if (isLoading) {
    return (
      <View as="div" padding="medium" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading assignment details')} size="large" />
      </View>
    )
  }

  if (isError || !data?.assignment) {
    return (
      <GenericErrorPage
        imageUrl={ErrorShip}
        errorSubject={I18n.t('Student Peer Review Assignment error')}
        errorCategory={I18n.t('Student Peer Review Assignment Error Page.')}
        errorMessage={I18n.t('Failed to load assignment details.')}
      />
    )
  }

  const {
    assessmentRequestsForCurrentUser,
    name,
    description,
    peerReviews,
    submissionsConnection,
    assignedToDates,
  } = data.assignment
  const submissionRequired = peerReviews?.submissionRequired ?? false
  const hasSubmitted =
    submissionsConnection?.nodes &&
    submissionsConnection.nodes.length > 0 &&
    submissionsConnection.nodes[0]?.submittedAt
  const showSubmissionRequiredView = submissionRequired && !hasSubmitted
  const isLocked = isPeerReviewLocked(data.assignment)
  const isPastLockDate = isPeerReviewPastLockDate(data.assignment)
  const peerReviewDueAt = assignedToDates?.[0]?.peerReviewDates?.dueAt
  const isAnonymous = data.assignment.peerReviews?.anonymousReviews ?? false

  const renderHeader = () => {
    return (
      <Flex justifyItems="space-between">
        <Flex.Item shouldGrow={true}>
          <Flex direction="column">
            <Flex.Item>
              <Text
                size="x-large"
                wrap="break-word"
                data-testid="title"
                weight={isMobile ? 'normal' : 'light'}
              >
                {I18n.t('%{name} Peer Review', {name: name})}
              </Text>
            </Flex.Item>
            {peerReviewDueAt && (
              <Flex.Item>
                <Text size="medium" weight="bold">
                  <FriendlyDatetime
                    data-testid="due-date"
                    prefix={I18n.t('Due:')}
                    format={I18n.t('#date.formats.full_with_weekday')}
                    dateTime={peerReviewDueAt}
                  />
                </Text>
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
        {!ENV.restrict_quantitative_data && peerReviews?.pointsPossible != null && (
          <Flex.Item>
            <Text size="x-large" data-testid="total-points">
              {I18n.t(
                {one: '1 Point Possible', other: '%{formattedPoints} Points Possible'},
                {
                  count: peerReviews.pointsPossible,
                  formattedPoints: numberFormat._format(peerReviews.pointsPossible, {
                    precision: 2,
                    strip_insignificant_zeros: true,
                  }),
                },
              )}
            </Text>
          </Flex.Item>
        )}
      </Flex>
    )
  }

  const renderBody = () => {
    if (showSubmissionRequiredView) {
      return (
        <View as="div" margin="xx-large 0 0">
          <NeedsSubmissionPeerReview />
        </View>
      )
    }

    if (isLocked) {
      return <LockedPeerReview assignment={data.assignment} />
    }

    const hasAssessmentRequests =
      assessmentRequestsForCurrentUser && assessmentRequestsForCurrentUser.length > 0
    // Only hide Submission tab if past lock date AND no peer reviews were assigned (since no more allocations will happen)
    const showSubmissionTab = !isPastLockDate || hasAssessmentRequests

    return (
      <Tabs
        margin="x-small 0"
        onRequestTabChange={(_event, {index}) => {
          setSelectedTab(index === 0 ? 'details' : 'submission')
        }}
      >
        <Tabs.Panel
          id="assignment-details"
          renderTitle={isMobile ? I18n.t('Assignment') : I18n.t('Assignment Details')}
          isSelected={selectedTab === 'details'}
        >
          <View as="div" padding="medium 0">
            <AssignmentDescription description={description ?? undefined} />
          </View>
        </Tabs.Panel>
        {showSubmissionTab && (
          <Tabs.Panel
            id="submission"
            renderTitle={isMobile ? I18n.t('Peer Review') : I18n.t('Submission')}
            isSelected={selectedTab === 'submission'}
            padding="0"
            data-testid="submission-tab"
          >
            {isUnavailableReviewSelected() ||
            !assessmentRequestsForCurrentUser?.[selectedAssessmentIndex]?.submission
              ?.submittedAt ? (
              <UnavailablePeerReview reason={getUnavailableReason()} />
            ) : (
              <AssignmentSubmission
                submission={assessmentRequestsForCurrentUser[selectedAssessmentIndex].submission!}
                isPeerReviewCompleted={
                  assessmentRequestsForCurrentUser[selectedAssessmentIndex].workflowState ===
                  'completed'
                }
                rubricAssessment={
                  assessmentRequestsForCurrentUser[selectedAssessmentIndex].rubricAssessment
                }
                assignment={data.assignment}
                reviewerSubmission={reviewerSubmission}
                isMobile={isMobile}
                handleNextPeerReview={handleNextPeerReview}
                onPeerReviewSubmitted={handlePeerReviewSubmitted}
                hasSeenPeerReviewModal={hasSeenPeerReviewModal}
                isReadOnly={isPastLockDate}
                isAnonymous={isAnonymous}
              />
            )}
          </Tabs.Panel>
        )}
      </Tabs>
    )
  }

  return (
    <>
      <View as="div">
        {renderHeader()}
        <Divider />
        {isPastLockDate && <LockedPeerReview assignment={data.assignment} isPastLockDate={true} />}
        {data.assignment && !showSubmissionRequiredView && !isLocked && (
          <View as="div">
            <PeerReviewSelector
              key={`${assessmentRequestsForCurrentUser?.length || 0}-peer-reviews`}
              assessmentRequests={assessmentRequestsForCurrentUser || []}
              selectedIndex={selectedAssessmentIndex}
              onSelectionChange={setSelectedAssessmentIndex}
              requiredPeerReviewCount={peerReviews?.count || 0}
            />
            {!isAnonymous &&
              assessmentRequestsForCurrentUser &&
              assessmentRequestsForCurrentUser[selectedAssessmentIndex]?.anonymizedUser && (
                <View as="div" margin="x-small 0 0 xx-small">
                  <Text size="medium" weight="bold">
                    {I18n.t('Peer: %{peerName}', {
                      peerName:
                        assessmentRequestsForCurrentUser[selectedAssessmentIndex].anonymizedUser
                          ?.displayName,
                    })}
                  </Text>
                </View>
              )}
          </View>
        )}
        {renderBody()}
        <PeerReviewPromptModal
          headerText={[COMPLETED_PEER_REVIEW_TEXT]}
          headerMargin={'small 0 x-large'}
          peerReviewButtonText={null}
          open={peerReviewModalOpen}
          onClose={() => setPeerReviewModalOpen(false)}
          onRedirect={() => {}}
        />
      </View>
    </>
  )
}

export default WithBreakpoints(PeerReviewsStudentView)
