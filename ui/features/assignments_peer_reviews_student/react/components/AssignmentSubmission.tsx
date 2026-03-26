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

import React, {useState, useEffect, useRef, useCallback} from 'react'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import ErrorShip from '@instructure/platform-images/assets/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {
  Submission,
  Assignment,
  ReviewerSubmission,
  RubricAssessmentRating,
} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {IconDiscussionLine, IconRubricLine} from '@instructure/ui-icons'
import {calculateMasqueradeHeight} from '@canvas/context-modules/differentiated-modules/utils/miscHelpers'
import UrlSubmissionDisplay from '@canvas/assignments/react/UrlSubmissionDisplay'
import FileSubmissionPreview from '@canvas/assignments/react/FileSubmissionPreview'
import StudentAnnotationPreview from '@canvas/assignments/react/StudentAnnotationPreview'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useRubricAssessment} from '../hooks/useRubricAssessment'
import {RubricPanel} from './RubricPanel'
import {CommentsPanel} from './CommentsPanel'
import {MediaRecordingSubmissionDisplay} from './MediaRecordingSubmissionDisplay'

const I18n = createI18nScope('peer_reviews_student')

interface AssignmentSubmissionProps {
  submission: Submission
  assignment: Assignment
  isPeerReviewCompleted: boolean
  rubricAssessment?: {
    _id: string
    assessmentRatings: RubricAssessmentRating[]
  } | null
  reviewerSubmission?: ReviewerSubmission | null
  isMobile?: boolean
  handleNextPeerReview: () => void
  onPeerReviewSubmitted: () => void
  hasSeenPeerReviewModal: boolean
  isReadOnly?: boolean
  isAnonymous: boolean
  submissionUserId?: string
}

const AssignmentSubmission: React.FC<AssignmentSubmissionProps> = ({
  submission,
  assignment,
  isPeerReviewCompleted,
  rubricAssessment,
  reviewerSubmission,
  handleNextPeerReview,
  onPeerReviewSubmitted,
  isMobile = false,
  hasSeenPeerReviewModal,
  isReadOnly = false,
  isAnonymous,
  submissionUserId,
}) => {
  const [viewMode, setViewMode] = useState<'paper' | 'plain_text'>('paper')
  const [showComments, setShowComments] = useState(true)
  const [showRubric, setShowRubric] = useState(false)
  const [peerReviewCommentCompleted, setPeerReviewCommentCompleted] =
    useState(isPeerReviewCompleted)
  const [initialIsPeerReviewCompleted, setInitialIsPeerReviewCompleted] =
    useState(isPeerReviewCompleted)
  const previousSubmissionIdRef = useRef(submission._id)
  const commentsButtonRef = useRef<HTMLButtonElement | null>(null)
  const rubricButtonRef = useRef<HTMLButtonElement | null>(null)
  const pendingFocusPanel = useRef<'comments' | 'rubric' | null>(null)

  useEffect(() => {
    if (submission._id !== previousSubmissionIdRef.current) {
      // reset initialIsPeerReviewCompleted value
      setInitialIsPeerReviewCompleted(isPeerReviewCompleted)
      previousSubmissionIdRef.current = submission._id
    }
  }, [submission._id, isPeerReviewCompleted])

  const {
    rubricAssessmentData,
    rubricAssessmentCompleted,
    rubricViewMode,
    setRubricViewMode,
    handleRubricSubmit,
    resetRubricAssessment,
  } = useRubricAssessment({
    assignment,
    submissionId: submission._id,
    submissionUserId: submission.user?._id,
    submissionAnonymousId: submission.anonymousId,
    rubricAssessment,
    isPeerReviewCompleted,
    onRubricSubmitted: onPeerReviewSubmitted,
  })

  useEffect(() => {
    setPeerReviewCommentCompleted(isPeerReviewCompleted)
  }, [isPeerReviewCompleted])

  const handleToggleComments = useCallback(() => {
    if (!showComments) {
      pendingFocusPanel.current = 'comments'
      setShowRubric(false)
    }
    setShowComments(!showComments)
  }, [showComments])

  const handleToggleRubric = useCallback(() => {
    if (!showRubric) {
      pendingFocusPanel.current = 'rubric'
      setShowComments(false)
    }
    setShowRubric(!showRubric)
  }, [showRubric])

  const handleCloseComments = useCallback(() => {
    setShowComments(false)
    commentsButtonRef.current?.focus()
  }, [])

  const handleCloseRubric = useCallback(() => {
    setShowRubric(false)
    rubricButtonRef.current?.focus()
  }, [])

  const handlePeerReviewCompletion = () => {
    if (assignment.rubric && !rubricAssessmentCompleted) {
      showFlashAlert({
        message: I18n.t('You must fill out the rubric in order to submit your peer review.'),
        type: 'error',
      })
      return
    }

    if (!assignment.rubric && !peerReviewCommentCompleted) {
      showFlashAlert({
        message: I18n.t(
          'Before you can submit this peer review, you must leave a comment for your peer.',
        ),
        type: 'error',
      })
      return
    }

    // reset the values
    setPeerReviewCommentCompleted(false)
    resetRubricAssessment()
    handleNextPeerReview()
  }

  const renderTextEntry = () => {
    const submissionClass = `user_content ${viewMode}`

    return (
      <View
        as="div"
        height="100%"
        background="secondary"
        padding="small"
        overflowY={isMobile ? 'auto' : 'hidden'}
      >
        <Flex as="div" textAlign="end" margin="0 0 small 0">
          <SimpleSelect
            renderLabel=""
            value={viewMode}
            onChange={(_e, {value}) => setViewMode(value as 'paper' | 'plain_text')}
            data-testid="view-mode-selector"
          >
            <SimpleSelect.Option id="paper" value="paper">
              {I18n.t('Paper View')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="plain_text" value="plain_text">
              {I18n.t('Plain Text View')}
            </SimpleSelect.Option>
          </SimpleSelect>
        </Flex>
        <div
          id="submission_preview"
          className={submissionClass}
          data-testid="text-entry-content"
          role="document"
          style={{maxHeight: isMobile ? undefined : '43vh', overflow: 'auto'}}
          dangerouslySetInnerHTML={{
            __html: apiUserContent.convert(submission.body || ''),
          }}
        />
      </View>
    )
  }

  const renderUrlEntry = () => {
    if (!submission.url) {
      return renderError(
        I18n.t('URL Submission Error'),
        I18n.t('Student Peer Review Submission Error Page.'),
        I18n.t('The URL submission is missing or invalid.'),
      )
    }

    return (
      <View
        as="div"
        height="100%"
        background="secondary"
        padding="small"
        overflowY={isMobile ? 'auto' : 'hidden'}
        data-testid="url-entry-content"
      >
        <UrlSubmissionDisplay url={submission.url} />
      </View>
    )
  }

  const renderError = (subject: string, category: string, message: string) => {
    return (
      <GenericErrorPage
        imageUrl={ErrorShip}
        errorSubject={subject}
        errorCategory={category}
        errorMessage={message}
      />
    )
  }

  const renderSubmissionType = () => {
    switch (submission.submissionType) {
      case 'online_text_entry':
        return renderTextEntry()
      case 'online_url':
        return renderUrlEntry()
      case 'online_upload':
        return (
          <FileSubmissionPreview
            submission={submission}
            assignment={assignment}
            userId={submissionUserId}
          />
        )
      case 'student_annotation':
        return <StudentAnnotationPreview submission={submission} />
      case 'media_recording': {
        if (!submission.mediaObject?._id) {
          return renderError(
            I18n.t('Media Recording Error'),
            I18n.t('Student Peer Review Submission Error Page.'),
            I18n.t('The media recording is missing or unavailable.'),
          )
        }
        return <MediaRecordingSubmissionDisplay mediaObject={submission.mediaObject} />
      }
      default:
        return renderError(
          I18n.t('Submission type error'),
          I18n.t('Student Peer Review Submission Error Page.'),
          I18n.t('Submission type not yet supported.'),
        )
    }
  }

  return (
    <View
      as="div"
      minHeight="calc(720px - 10.75rem)"
      height={
        isAnonymous
          ? `calc(100vh - 22rem - ${calculateMasqueradeHeight() + 65}px)`
          : `calc(100vh - 24rem - ${calculateMasqueradeHeight() + 65}px)`
      }
      overflowY="hidden"
    >
      <Flex as="div" height="100%" alignItems="start">
        <Flex.Item as="div" height="100%" shouldGrow>
          {renderSubmissionType()}
        </Flex.Item>
        {showRubric && assignment.rubric && (
          <RubricPanel
            assignment={assignment}
            rubricAssessmentData={rubricAssessmentData}
            rubricViewMode={rubricViewMode}
            isPeerReviewCompleted={isPeerReviewCompleted}
            rubricAssessmentCompleted={rubricAssessmentCompleted}
            onClose={handleCloseRubric}
            onSubmit={handleRubricSubmit}
            onViewModeChange={setRubricViewMode}
            isReadOnly={isReadOnly}
            autoFocusCloseButton={pendingFocusPanel.current === 'rubric'}
            isMobile={isMobile}
          />
        )}
        {showComments && (
          <CommentsPanel
            submission={submission}
            assignment={assignment}
            reviewerSubmission={reviewerSubmission}
            isMobile={isMobile}
            isOpen={showComments}
            onClose={handleCloseComments}
            onSuccessfulPeerReview={() => {
              setPeerReviewCommentCompleted(true)
              onPeerReviewSubmitted()
            }}
            isReadOnly={isReadOnly}
            suppressSuccessAlert={true}
            autoFocusCloseButton={pendingFocusPanel.current === 'comments'}
          />
        )}
      </Flex>
      <footer
        style={{
          position: 'fixed',
          right: 0,
          left: isMobile ? '0px' : '275px',
          bottom: `${calculateMasqueradeHeight()}px`,
          padding: isMobile ? '0px' : '0px 24px 0px 0px',
          zIndex: '999',
        }}
        data-testid="peer-review-footer"
      >
        <View
          as="div"
          borderWidth="small 0 0 0"
          borderColor="primary"
          padding="small"
          background="primary"
        >
          <Flex
            direction={isMobile ? 'column' : 'row'}
            justifyItems={isMobile ? 'start' : 'space-between'}
          >
            <Flex.Item margin={isMobile ? '0 0 small 0' : '0'}>
              <Flex gap="small">
                {assignment.rubric && (
                  <Flex.Item>
                    <Button
                      elementRef={(el: Element | null) => {
                        rubricButtonRef.current = el as HTMLButtonElement
                      }}
                      renderIcon={<IconRubricLine />}
                      onClick={handleToggleRubric}
                      data-testid="toggle-rubric-button"
                      size={isMobile ? 'small' : 'medium'}
                      aria-expanded={showRubric}
                      aria-controls="rubric-panel"
                      aria-haspopup="dialog"
                    >
                      {showRubric ? I18n.t('Hide Rubric') : I18n.t('Show Rubric')}
                    </Button>
                  </Flex.Item>
                )}
                <Flex.Item>
                  <Button
                    elementRef={(el: Element | null) => {
                      commentsButtonRef.current = el as HTMLButtonElement
                    }}
                    renderIcon={<IconDiscussionLine />}
                    onClick={handleToggleComments}
                    data-testid="toggle-comments-button"
                    size={isMobile ? 'small' : 'medium'}
                    aria-expanded={showComments}
                    aria-controls="comments-panel"
                    aria-haspopup="dialog"
                  >
                    {showComments ? I18n.t('Hide Comments') : I18n.t('Show Comments')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            {!isReadOnly && !initialIsPeerReviewCompleted && !hasSeenPeerReviewModal && (
              <Flex.Item>
                <Button
                  color="primary"
                  data-testid="submit-peer-review-button"
                  size={isMobile ? 'small' : 'medium'}
                  onClick={handlePeerReviewCompletion}
                >
                  {I18n.t('Submit Peer Review')}
                </Button>
              </Flex.Item>
            )}
          </Flex>
        </View>
      </footer>
    </View>
  )
}

export default AssignmentSubmission
