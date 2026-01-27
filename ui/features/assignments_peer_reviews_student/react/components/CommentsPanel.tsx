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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import CommentsTrayContentWithApollo from './CommentsTrayContentWithApollo'
import type {
  Submission,
  Assignment,
  ReviewerSubmission,
} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

interface CommentsPanelProps {
  submission: Submission
  assignment: Assignment
  reviewerSubmission?: ReviewerSubmission | null
  isMobile: boolean
  isOpen: boolean
  onClose: () => void
  onSuccessfulPeerReview: () => void
  isReadOnly?: boolean
  suppressSuccessAlert?: boolean
}

export const CommentsPanel: React.FC<CommentsPanelProps> = ({
  submission,
  assignment,
  reviewerSubmission,
  isMobile,
  isOpen,
  onClose,
  onSuccessfulPeerReview,
  isReadOnly = false,
  suppressSuccessAlert = false,
}) => {
  return (
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
                onClick={onClose}
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
            closeTray={onClose}
            open={isOpen}
            onSuccessfulPeerReview={onSuccessfulPeerReview}
            usePeerReviewModal={false}
            isReadOnly={isReadOnly}
            suppressSuccessAlert={suppressSuccessAlert}
          />
        </Flex.Item>
      </Flex>
    </Flex.Item>
  )
}
