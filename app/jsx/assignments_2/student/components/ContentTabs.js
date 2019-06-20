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

import {AssignmentShape, SubmissionShape} from '../assignmentData'
import AttemptTab from './AttemptTab'
import ClosedDiscussionSVG from '../SVG/ClosedDiscussions.svg'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import {getCurrentAttempt} from './Attempt'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '../../shared/LoadingIndicator'
import React, {lazy, Suspense} from 'react'
import SVGWithTextPlaceholder from '../../shared/SVGWithTextPlaceholder'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import GradeDisplay from './GradeDisplay'
import {Img} from '@instructure/ui-elements'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import Text from '@instructure/ui-elements/lib/components/Text'

const CommentsTab = lazy(() => import('./CommentsTab'))

ContentTabs.propTypes = {
  assignment: AssignmentShape,
  submission: SubmissionShape
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
        <TabPanel title={I18n.t('Comments')}>
          {!props.assignment.muted ? (
            <Suspense fallback={<LoadingIndicator />}>
              <CommentsTab assignment={props.assignment} submission={props.submission} />
            </Suspense>
          ) : (
            <SVGWithTextPlaceholder
              text={I18n.t(
                'You may not see all comments right now because the assignment is currently being graded.'
              )}
              url={ClosedDiscussionSVG}
            />
          )}
        </TabPanel>
        <TabPanel title={I18n.t('Rubric')}>
          <Img src="/images/assignments2_rubric_student_static.png" />
        </TabPanel>
      </TabList>
    </div>
  )
}

export default React.memo(ContentTabs)
