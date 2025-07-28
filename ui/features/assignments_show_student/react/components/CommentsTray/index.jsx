/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {Suspense, lazy} from 'react'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import ClosedDiscussionSVG from '../../../images/ClosedDiscussions.svg'
import SVGWithTextPlaceholder from '../../SVGWithTextPlaceholder'
import {Tray} from '@instructure/ui-tray'
import {Heading} from '@instructure/ui-heading'
import {bool, func} from 'prop-types'

const I18n = createI18nScope('assignments_2')

const CommentsTrayBody = lazy(() => {
  return import(
    /* webpackChunkName: "CommentsTrayBody" */
    /* webpackPrefetch: true */
    './CommentsTrayBody'
  )
})

function TrayContent({
  assignment,
  submission,
  reviewerSubmission,
  isPeerReviewEnabled = false,
  onSuccessfulPeerReview,
}) {
  // Case where this is backed by a submission draft, not a real submission, so
  // we can't actually save comments.
  if (submission.state === 'unsubmitted' && submission.attempt > 1) {
    // TODO: Get design/product to get an updated SVG or something for this: COMMS-2255
    return (
      <SVGWithTextPlaceholder
        text={I18n.t('You cannot leave comments until you submit the assignment.')}
        url={ClosedDiscussionSVG}
      />
    )
  }

  return (
    <Suspense fallback={<LoadingIndicator />}>
      <CommentsTrayBody
        assignment={assignment}
        submission={submission}
        reviewerSubmission={reviewerSubmission}
        isPeerReviewEnabled={isPeerReviewEnabled}
        onSuccessfulPeerReview={onSuccessfulPeerReview}
      />
    </Suspense>
  )
}

TrayContent.propTypes = {
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired,
  reviewerSubmission: Submission.shape,
  isPeerReviewEnabled: bool,
  onSuccessfulPeerReview: func,
}

export default function CommentsTray({
  assignment,
  submission,
  reviewerSubmission,
  closeTray,
  open,
  isPeerReviewEnabled = false,
  onSuccessfulPeerReview,
}) {
  // attempts 0 and 1 get combined into a single attempt
  const attempt = submission?.attempt || 1
  const label = isPeerReviewEnabled
    ? I18n.t('Peer Review Comments')
    : I18n.t('Attempt %{attempt} Feedback', {attempt})

  return (
    <Tray label={label} open={open} onDismiss={closeTray} size="regular" placement="end">
      <div id="comments-tray">
        <Flex direction="column" height="100%">
          <Flex.Item>
            <View as="div" padding="medium">
              <Flex>
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Heading>{label}</Heading>
                </Flex.Item>

                <Flex.Item>
                  <CloseButton
                    data-testid="tray-close-button"
                    placement="end"
                    offset="medium"
                    screenReaderLabel="Close"
                    size="small"
                    onClick={closeTray}
                  />
                </Flex.Item>
              </Flex>
            </View>
          </Flex.Item>

          <Flex.Item shouldGrow={true}>
            <TrayContent
              isPeerReviewEnabled={isPeerReviewEnabled}
              assignment={assignment}
              submission={submission}
              reviewerSubmission={reviewerSubmission}
              onSuccessfulPeerReview={onSuccessfulPeerReview}
            />
          </Flex.Item>
        </Flex>
      </div>
    </Tray>
  )
}

CommentsTray.propTypes = {
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired,
  reviewerSubmission: Submission.shape,
  closeTray: func.isRequired,
  open: bool.isRequired,
  isPeerReviewEnabled: bool,
  onSuccessfulPeerReview: func,
}
