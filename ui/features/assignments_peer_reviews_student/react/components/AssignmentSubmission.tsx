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

import React, {useState, useEffect, useRef} from 'react'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import ErrorShip from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {
  Submission,
  Assignment,
  ReviewerSubmission,
} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import CommentsTrayContentWithApollo from './CommentsTrayContentWithApollo'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconDiscussionLine} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
import {calculateMasqueradeHeight} from '@canvas/context-modules/differentiated-modules/utils/miscHelpers'
import UrlSubmissionDisplay from '@canvas/assignments/react/UrlSubmissionDisplay'
import FileSubmissionPreview from '@canvas/assignments/react/FileSubmissionPreview'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('peer_reviews_student')

interface AssignmentSubmissionProps {
  submission: Submission
  assignment: Assignment
  isPeerReviewCompleted: boolean
  reviewerSubmission?: ReviewerSubmission | null
  isMobile?: boolean
  handleNextPeerReview: () => void
  onCommentSubmitted: () => void
  hasSeenPeerReviewModal: boolean
}

const AssignmentSubmission: React.FC<AssignmentSubmissionProps> = ({
  submission,
  assignment,
  isPeerReviewCompleted,
  reviewerSubmission,
  handleNextPeerReview,
  onCommentSubmitted,
  isMobile = false,
  hasSeenPeerReviewModal,
}) => {
  const [viewMode, setViewMode] = useState<'paper' | 'plain_text'>('paper')
  const [showComments, setShowComments] = useState(false)
  const [peerReviewCommentCompleted, setPeerReviewCommentCompleted] =
    useState(isPeerReviewCompleted)
  const [initialIsPeerReviewCompleted, setInitialIsPeerReviewCompleted] =
    useState(isPeerReviewCompleted)
  const previousSubmissionIdRef = useRef(submission._id)

  useEffect(() => {
    if (submission._id !== previousSubmissionIdRef.current) {
      // reset initialIsPeerReviewCompleted value
      setInitialIsPeerReviewCompleted(isPeerReviewCompleted)
      previousSubmissionIdRef.current = submission._id
    }
  }, [submission._id, isPeerReviewCompleted])

  const handleToggleComments = () => {
    setShowComments(!showComments)
  }

  const handlePeerReviewCompletion = () => {
    if (peerReviewCommentCompleted) {
      // reset the value
      setPeerReviewCommentCompleted(false)
      handleNextPeerReview()
    } else {
      showFlashAlert({
        message: I18n.t(
          'Before you can submit this peer review, you must leave a comment for your peer.',
        ),
        type: 'error',
      })
    }
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
        return <FileSubmissionPreview submission={submission} />
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
      height="calc(100vh - 22rem)"
      overflowY="hidden"
    >
      <Flex as="div" height="100%" alignItems="start">
        <Flex.Item as="div" height="100%" shouldGrow>
          {renderSubmissionType()}
        </Flex.Item>
        {showComments && (
          <Flex.Item
            as="div"
            direction="column"
            size="327px"
            height="100%"
            padding="small"
            overflowY="auto"
          >
            <Flex as="div" direction="column" justifyItems="space-between" height="100%">
              <Flex.Item>
                <Flex as="div" direction="row" justifyItems="space-between">
                  <Flex.Item>
                    <Heading variant="titleModule" level="h2">
                      {I18n.t('Peer Comments')}
                    </Heading>
                  </Flex.Item>
                  <Flex.Item>
                    <CloseButton
                      screenReaderLabel={I18n.t('Close Peer Comments')}
                      size="small"
                      onClick={() => setShowComments(false)}
                      data-testid="close-comments-button"
                    />
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item>
                <CommentsTrayContentWithApollo
                  submission={submission}
                  assignment={assignment}
                  isPeerReviewEnabled={true}
                  reviewerSubmission={reviewerSubmission}
                  renderTray={isMobile}
                  closeTray={() => setShowComments(false)}
                  open={showComments}
                  onSuccessfulPeerReview={() => {
                    setPeerReviewCommentCompleted(true)
                    onCommentSubmitted()
                  }}
                  usePeerReviewModal={false}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )}
      </Flex>
      <footer
        style={{
          position: 'fixed',
          right: 0,
          left: isMobile ? '0px' : '275px',
          bottom: `${calculateMasqueradeHeight()}px`,
          padding: isMobile ? '0px' : '0px 24px 8px 0px',
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
              <Button
                renderIcon={<IconDiscussionLine />}
                onClick={handleToggleComments}
                data-testid="toggle-comments-button"
                size={isMobile ? 'small' : 'medium'}
              >
                {showComments ? I18n.t('Hide Comments') : I18n.t('Show Comments')}
              </Button>
            </Flex.Item>
            {!initialIsPeerReviewCompleted && !hasSeenPeerReviewModal && (
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
