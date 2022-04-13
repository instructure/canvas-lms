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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import AssignmentToggleDetails from '../AssignmentToggleDetails'
import AvailabilityDates from '@canvas/assignments/react/AvailabilityDates'
import ContentTabs from './ContentTabs'
import Header from './Header'
import {useScope as useI18nScope} from '@canvas/i18n'
import MarkAsDoneButton from './MarkAsDoneButton'
import LoadingIndicator from '@canvas/loading-indicator'
import MissingPrereqs from './MissingPrereqs'
import DateLocked from '../DateLocked'
import React, {Suspense, lazy, useContext, useEffect} from 'react'
import PropTypes from 'prop-types'
import {Spinner} from '@instructure/ui-spinner'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import StudentFooter from './StudentFooter'
import {Text} from '@instructure/ui-text'
import {totalAllowedAttempts} from '../helpers/SubmissionHelpers'
import {View} from '@instructure/ui-view'
import UnpublishedModule from '../UnpublishedModule'
import VisualOnFocusMessage from './VisualOnFocusMessage'

const I18n = useI18nScope('assignments_2_student_content')

const LoggedOutTabs = lazy(() => import('./LoggedOutTabs'))

const RubricsQuery = lazy(() => import('./RubricsQuery'))

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

function SubmissionlessFooter({onMarkAsDoneError}) {
  // If this assignment has digital submissions, the SubmissionManager
  // component will handle rendering the footer.  If not, we still need to show
  // the "Mark as Done" button for assignments that belong to modules.
  const moduleItem = window.ENV.CONTEXT_MODULE_ITEM

  const buttons = []
  if (moduleItem != null) {
    buttons.push({
      element: (
        <MarkAsDoneButton
          done={moduleItem.done}
          itemId={moduleItem.id}
          moduleId={moduleItem.module_id}
          onError={onMarkAsDoneError}
        />
      ),
      key: 'mark-as-done'
    })
  }

  return (
    <StudentFooter assignmentID={ENV.ASSIGNMENT_ID} buttons={buttons} courseID={ENV.COURSE_ID} />
  )
}

function renderAttemptsAndAvailability({assignment, submission}) {
  return (
    <View as="div" margin="medium 0">
      {assignment.expectsSubmission && (
        <Text as="div" weight="bold">
          {I18n.t(
            {
              zero: 'Unlimited Attempts Allowed',
              one: '1 Attempt Allowed',
              other: '%{count} Attempts Allowed'
            },
            {count: totalAllowedAttempts({assignment, submission}) || 0}
          )}
        </Text>
      )}
      <Text as="div">
        <AvailabilityDates assignment={assignment} formatStyle="long" />
      </Text>
    </View>
  )
}

function renderContentBaseOnAvailability({assignment, submission}, alertContext) {
  if (assignment.env.modulePrereq) {
    return <MissingPrereqs moduleUrl={assignment.env.moduleUrl} />
  } else if (assignment.env.unlockDate) {
    return <DateLocked date={assignment.env.unlockDate} type="assignment" />
  } else if (ENV.belongs_to_unpublished_module) {
    return <UnpublishedModule />
  } else if (submission == null) {
    // NOTE: handles case where user is not logged in, or the course hasn't started yet
    return (
      <>
        {renderAttemptsAndAvailability({assignment})}
        <AssignmentToggleDetails description={assignment.description} />
        <Suspense
          fallback={<Spinner renderTitle={I18n.t('Loading')} size="large" margin="0 0 0 medium" />}
        >
          <LoggedOutTabs assignment={assignment} />
        </Suspense>
      </>
    )
  } else {
    const onMarkAsDoneError = () =>
      alertContext.setOnFailure(I18n.t('Error updating status of module item'))

    return (
      <>
        {renderAttemptsAndAvailability({assignment, submission})}
        {assignment.submissionTypes.includes('student_annotation') && (
          <VisualOnFocusMessage
            message={I18n.t(
              'Warning: For improved accessibility with Annotated Assignments, please use File Upload or Text Entry to leave comments.'
            )}
          />
        )}
        <AssignmentToggleDetails description={assignment.description} />
        {assignment.rubric && (
          <Suspense fallback={<LoadingIndicator />}>
            <RubricsQuery assignment={assignment} submission={submission} />
          </Suspense>
        )}
        {assignment.expectsSubmission ? (
          <ContentTabs assignment={assignment} submission={submission} />
        ) : (
          <SubmissionlessFooter onMarkAsDoneError={onMarkAsDoneError} />
        )}
        {ENV.enrollment_state === 'completed' && <EnrollmentConcludedNotice />}
      </>
    )
  }
}

function StudentContent(props) {
  const alertContext = useContext(AlertManagerContext)

  const {description, name} = props.assignment
  useEffect(() => {
    const setUpImmersiveReader = async () => {
      const mountPoints = [
        document.getElementById('immersive_reader_mount_point'),
        document.getElementById('immersive_reader_mobile_mount_point')
      ].filter(element => element != null)

      if (mountPoints.length === 0) {
        return
      }

      import('../../../../shared/immersive-reader/ImmersiveReader')
        .then(ImmersiveReader => {
          mountPoints.forEach(mountPoint => {
            ImmersiveReader.initializeReaderButton(mountPoint, {
              content: () =>
                description || I18n.t('No additional details were added for this assignment.'),
              title: name
            })
          })
        })
        .catch(e => {
          console.log('Error loading immersive readers.', e) // eslint-disable-line no-console
        })
    }

    setUpImmersiveReader()
  }, [description, name])

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
      {renderContentBaseOnAvailability(props, alertContext)}
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
