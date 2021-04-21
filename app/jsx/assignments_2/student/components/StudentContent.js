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
import AssignmentToggleDetails from '../../shared/AssignmentToggleDetails'
import ContentTabs from './ContentTabs'
import Header from './Header'
import I18n from 'i18n!assignments_2_student_content'
import MissingPrereqs from './MissingPrereqs'
import DateLocked from './DateLocked'
import React, {Suspense, lazy} from 'react'
import PropTypes from 'prop-types'
import {Spinner} from '@instructure/ui-spinner'
import {Submission} from '../graphqlData/Submission'
import {Text} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'

const LoggedOutTabs = lazy(() => import('./LoggedOutTabs'))

function EnrollmentConcludedNotice() {
  return (
    <View as="div" textAlign="center" margin="auto" padding="small">
      <Text fontStyle="italic" size="large">
        {I18n.t(
          'You are unable to submit to this assignment as your enrollment in this course has been concluded.'
        )}
      </Text>
    </View>
  )
}

function renderContentBaseOnAvailability({assignment, submission}) {
  if (assignment.env.modulePrereq) {
    const prereq = assignment.env.modulePrereq
    return <MissingPrereqs preReqTitle={prereq.title} preReqLink={prereq.link} />
  } else if (assignment.env.unlockDate) {
    return <DateLocked date={assignment.env.unlockDate} type="assignment" />
  } else if (submission === null) {
    // NOTE: handles case where user is not logged in, or the course hasn't started yet
    return (
      <>
        <AssignmentToggleDetails description={assignment.description} />
        <Suspense
          fallback={<Spinner renderTitle={I18n.t('Loading')} size="large" margin="0 0 0 medium" />}
        >
          <LoggedOutTabs assignment={assignment} />
        </Suspense>
      </>
    )
  } else {
    return (
      <>
        <AssignmentToggleDetails description={assignment.description} />
        <ContentTabs assignment={assignment} submission={submission} />
        {ENV.enrollment_state === 'completed' && <EnrollmentConcludedNotice />}
      </>
    )
  }
}

function StudentContent(props) {
  // TODO: Move the button provider up one level
  return (
    <div data-testid="assignments-2-student-view">
      <Header
        allSubmissions={props.allSubmissions}
        assignment={props.assignment}
        onChangeSubmission={props.onChangeSubmission}
        scrollThreshold={150}
        submission={props.submission}
      />
      {renderContentBaseOnAvailability(props)}
    </div>
  )
}

StudentContent.propTypes = {
  allSubmissions: PropTypes.arrayOf(Submission.shape),
  assignment: Assignment.shape,
  onChangeSubmission: PropTypes.func.isRequired,
  submission: Submission.shape
}

export default StudentContent
