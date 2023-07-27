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
import {useScope as useI18nScope} from '@canvas/i18n'
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

const I18n = useI18nScope('assignments_2')

const CommentsTrayBody = lazy(() => {
  return import(
    /* webpackChunkName: "CommentsTrayBody" */
    /* webpackPrefetch: true */
    './CommentsTrayBody'
  )
})

function TrayContent(props) {
  // Case where this is backed by a submission draft, not a real submission, so
  // we can't actually save comments.
  if (props.submission.state === 'unsubmitted' && props.submission.attempt > 1) {
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
        assignment={props.assignment}
        submission={props.submission}
        reviewerSubmission={props.reviewerSubmission}
        isPeerReviewEnabled={props.isPeerReviewEnabled}
        onSuccessfulPeerReview={props.onSuccessfulPeerReview}
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

TrayContent.defaultProps = {
  isPeerReviewEnabled: false,
}

export default function CommentsTray(props) {
  // attempts 0 and 1 get combined into a single attempt
  const attempt = props.submission?.attempt || 1
  const label = props.isPeerReviewEnabled
    ? I18n.t('Peer Review Comments')
    : I18n.t('Attempt %{attempt} Feedback', {attempt})

  return (
    <Tray
      label={label}
      open={props.open}
      onDismiss={props.closeTray}
      size="regular"
      placement="end"
    >
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
                    onClick={props.closeTray}
                  />
                </Flex.Item>
              </Flex>
            </View>
          </Flex.Item>

          <Flex.Item shouldGrow={true}>
            <TrayContent
              isPeerReviewEnabled={props.isPeerReviewEnabled}
              assignment={props.assignment}
              submission={props.submission}
              reviewerSubmission={props.reviewerSubmission}
              onSuccessfulPeerReview={props.onSuccessfulPeerReview}
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

CommentsTray.defaultProps = {
  isPeerReviewEnabled: false,
}
