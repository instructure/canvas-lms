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
import {Badge, Text} from '@instructure/ui-elements'
import ClosedDiscussionSVG from '../SVG/ClosedDiscussions.svg'
import {Flex} from '@instructure/ui-layout'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import {getCurrentAttempt} from './Attempt'
import GradeDisplay from './GradeDisplay'
import I18n from 'i18n!assignments_2'

import LoadingIndicator from '../../shared/LoadingIndicator'
import React, {lazy, Suspense, useState} from 'react'
import SubmissionManager from './SubmissionManager'
import {Submission} from '../graphqlData/Submission'
import SVGWithTextPlaceholder from '../../shared/SVGWithTextPlaceholder'
import {Tabs} from '@instructure/ui-tabs'

const CommentsTab = lazy(() => import('./CommentsTab'))
const RubricsQuery = lazy(() => import('./RubricsQuery'))
const RubricTab = lazy(() => import('./RubricTab'))

ContentTabs.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}

function currentSubmissionGrade(assignment, submission) {
  const tabBarAlign = {
    position: 'absolute',
    right: '50px'
  }

  const currentGrade = submission.state === 'graded' ? submission.grade : null

  return (
    <div style={tabBarAlign}>
      <Text weight="bold">
        <GradeDisplay
          displaySize="medium"
          gradingType={assignment.gradingType}
          pointsPossible={assignment.pointsPossible}
          receivedGrade={currentGrade}
        />
      </Text>
      <Text size="small">
        {submission.submittedAt ? (
          <Flex justifyItems="end">
            <Flex.Item padding="0 xx-small 0 0">{I18n.t('Submitted:')}</Flex.Item>
            <Flex.Item>
              <FriendlyDatetime
                dateTime={submission.submittedAt}
                format={I18n.t('#date.formats.full')}
              />
            </Flex.Item>
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

  if (submission.gradeHidden) {
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

function LoggedInContentTabs(props) {
  const [selectedTabIndex, setSelectedTabIndex] = useState(0)
  const [submissionFocus, setSubmissionFocus] = useState(null)

  function handleTabChange(event, {index}) {
    setSelectedTabIndex(index)
  }

  const noRightLeftPadding = 'small none' // to make "submit" button edge line up with moduleSequenceFooter "next" button edge

  return (
    <div data-testid="assignment-2-student-content-tabs">
      {props.submission.state === 'graded' || props.submission.state === 'submitted'
        ? currentSubmissionGrade(props.assignment, props.submission)
        : null}
      <Tabs
        onRequestTabChange={handleTabChange}
        ref={el => {
          setSubmissionFocus(el)
        }}
        variant="default"
      >
        <Tabs.Panel
          key="attempt-tab"
          padding={noRightLeftPadding}
          renderTitle={I18n.t('Attempt %{attempt}', {attempt: getCurrentAttempt(props.submission)})}
          selected={selectedTabIndex === 0}
        >
          <SubmissionManager
            assignment={props.assignment}
            focusElement={submissionFocus}
            submission={props.submission}
          />
        </Tabs.Panel>
        <Tabs.Panel
          key="comments-tab"
          padding={noRightLeftPadding}
          selected={selectedTabIndex === 1}
          renderTitle={
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
        </Tabs.Panel>
        {props.assignment.rubric && (
          <Tabs.Panel
            key="rubrics-tab"
            padding={noRightLeftPadding}
            renderTitle={I18n.t('Rubric')}
            selected={selectedTabIndex === 2}
          >
            <Suspense fallback={<LoadingIndicator />}>
              <RubricsQuery assignment={props.assignment} submission={props.submission} />
            </Suspense>
          </Tabs.Panel>
        )}
      </Tabs>
    </div>
  )
}

function LoggedOutContentTabs(props) {
  // Note that for not logged in users we already have the rubrics data available
  // on the assignment, and don't need to do a seperate query to get that data.
  // This is to avoid a large time watching loading spinners on the default tab
  // which we want to render as fast as possible.
  return (
    <div data-testid="assignment-2-student-content-tabs">
      {props.assignment.rubric && (
        <Tabs variant="default">
          <Tabs.Panel renderTitle={I18n.t('Rubric')} selected>
            <Suspense fallback={<LoadingIndicator />}>
              <RubricTab rubric={props.assignment.rubric} />
            </Suspense>
          </Tabs.Panel>
        </Tabs>
      )}
    </div>
  )
}

export default function ContentTabs(props) {
  if (props.submission) {
    return <LoggedInContentTabs {...props} />
  } else {
    return <LoggedOutContentTabs {...props} />
  }
}
