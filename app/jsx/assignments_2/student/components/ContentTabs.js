/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {Assignment} from '../graphqlData/Assignment'
import AttemptTab from './AttemptTab'
import {Badge} from '@instructure/ui-elements'
import ClosedDiscussionSVG from '../SVG/ClosedDiscussions.svg'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import {getCurrentAttempt} from './Attempt'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '../../shared/LoadingIndicator'
import React, {lazy, Suspense} from 'react'
import {Submission} from '../graphqlData/Submission'
import SVGWithTextPlaceholder from '../../shared/SVGWithTextPlaceholder'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import GradeDisplay from './GradeDisplay'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import Text from '@instructure/ui-elements/lib/components/Text'

const CommentsTab = lazy(() => import('./CommentsTab'))
const RubricTab = lazy(() => import('./RubricTab'))

ContentTabs.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}

// We should revisit this after the InstructureCon demo to ensure this is
// accessible and in a class.
function currentSubmissionGrade(assignment, submission) {
  const tabBarAlign = {
    position: 'absolute',
    right: '50px'
  }

  return (
    <div style={tabBarAlign}>
      <Text weight="bold">
        <GradeDisplay
          displaySize="medium"
          gradingType={assignment.gradingType}
          pointsPossible={assignment.pointsPossible}
          receivedGrade={submission.grade}
        />
      </Text>
      <Text size="small">
        {submission.submittedAt ? (
          <Flex justifyItems="end">
            <FlexItem padding="0 xx-small 0 0">{I18n.t('Submitted')}</FlexItem>
            <FlexItem>
              <FriendlyDatetime
                dateTime={submission.submittedAt}
                format={I18n.t('#date.formats.full')}
              />
            </FlexItem>
          </Flex>
        ) : (
          I18n.t('Not submitted')
        )}
      </Text>
    </div>
  )
}

function renderCommentsTab({assignment, submission}) {
  // Case where this is backed by a submission draft, not a real submission, so
  // we can't actually save comments.
  if (submission.state === 'unsubmitted' && submission.attempt > 1) {
    // TODO: Get design/product to get an updated SVG or something for this: COMMS-2255
    return (
      <SVGWithTextPlaceholder
        text={I18n.t('You cannot leave leave comments until you submit the assignment')}
        url={ClosedDiscussionSVG}
      />
    )
  }

  if (!submission.posted) {
    return (
      <SVGWithTextPlaceholder
        text={I18n.t(
          'You may not see all comments right now because the assignment is currently being graded.'
        )}
        url={ClosedDiscussionSVG}
      />
    )
  }

  return (
    <Suspense fallback={<LoadingIndicator />}>
      <CommentsTab assignment={assignment} submission={submission} />
    </Suspense>
  )
}

renderCommentsTab.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}

function ContentTabs(props) {
  return (
    <div data-testid="assignment-2-student-content-tabs">
      {props.submission.state === 'graded' || props.submission.state === 'submitted'
        ? currentSubmissionGrade(props.assignment, props.submission)
        : null}
      <TabList defaultSelectedIndex={0} variant="minimal">
        <TabPanel
          title={I18n.t('Attempt %{attempt}', {attempt: getCurrentAttempt(props.submission)})}
        >
          <AttemptTab assignment={props.assignment} submission={props.submission} />
        </TabPanel>
        <TabPanel
          title={
            <span>
              {I18n.t('Comments')}{' '}
              {!!props.submission.unreadCommentCount && (
                <Badge
                  count={props.submission.unreadCommentCount}
                  standalone
                  margin="0 small 0 0"
                />
              )}
            </span>
          }
        >
          {renderCommentsTab(props)}
        </TabPanel>
        {props.assignment.rubric && (
          <TabPanel title={I18n.t('Rubric')}>
            <Suspense fallback={<LoadingIndicator />}>
              <RubricTab assignment={props.assignment} />
            </Suspense>
          </TabPanel>
        )}
      </TabList>
    </div>
  )
}

export default React.memo(ContentTabs)
