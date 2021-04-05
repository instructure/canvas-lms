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
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '@canvas/loading-indicator'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex, View} from '@instructure/ui-layout'
import React, {Suspense, lazy} from 'react'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import ClosedDiscussionSVG from '../../../images/ClosedDiscussions.svg'
import SVGWithTextPlaceholder from '../../SVGWithTextPlaceholder'
import {Tray} from '@instructure/ui-overlays'
import {Heading} from '@instructure/ui-heading'
import {bool, func} from 'prop-types'

const CommentsTrayBody = lazy(() => import('./CommentsTrayBody'))

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

  if (props.submission.gradeHidden) {
    return (
      <SVGWithTextPlaceholder
        text={I18n.t(
          'You may not see all comments right now because the assignment is currently being graded.'
        )}
        url={ClosedDiscussionSVG}
        addMargin
      />
    )
  }

  return (
    <Suspense fallback={<LoadingIndicator />}>
      <CommentsTrayBody assignment={props.assignment} submission={props.submission} />
    </Suspense>
  )
}

TrayContent.propTypes = {
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired
}

export default function CommentsTray(props) {
  // attempts 0 and 1 get combined into a single attempt
  const attempt = props.submission?.attempt || 1

  return (
    <Tray
      label={I18n.t('Attempt %{attempt} Feedback', {attempt})}
      open={props.open}
      onDismiss={props.closeTray}
      size="regular"
      placement="end"
      shouldCloseOnDocumentClick
    >
      <div style={{position: 'absolute', top: 0, bottom: 0, width: '100%'}}>
        <Flex direction="column" height="100%">
          <Flex.Item>
            <View as="div" padding="medium">
              <Flex>
                <Flex.Item shouldGrow shouldShrink>
                  <Heading>{I18n.t('Attempt %{attempt} Feedback', {attempt})}</Heading>
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

          <Flex.Item grow>
            <TrayContent assignment={props.assignment} submission={props.submission} />
          </Flex.Item>
        </Flex>
      </div>
    </Tray>
  )
}

CommentsTray.propTypes = {
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired,
  closeTray: func.isRequired,
  open: bool.isRequired
}
