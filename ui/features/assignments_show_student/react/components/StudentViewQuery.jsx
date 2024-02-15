/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  LOGGED_OUT_STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY,
  STUDENT_VIEW_QUERY_WITH_REVIEWER_SUBMISSION,
} from '@canvas/assignments/graphql/student/Queries'
import LoadingIndicator from '@canvas/loading-indicator'
import {useQuery} from 'react-apollo'
import React from 'react'
import {string} from 'prop-types'
import StudentContent from './StudentContent'
import SubmissionHistoriesQuery from './SubmissionHistoriesQuery'
import {transformRubricData} from '../helpers/RubricHelpers'

const I18n = useI18nScope('assignments_2_initial_query')

function getAssignmentEnvVariables() {
  const baseUrl = `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
    ENV.context_asset_string.split('_')[1]
  }`

  const env = {
    assignmentUrl: `${baseUrl}/assignments`,
    courseId: ENV.context_asset_string.split('_')[1],
    currentUser: ENV.current_user,
    enrollmentState: ENV.enrollment_state,
    unlockDate: null,
    modulePrereq: null,
    moduleUrl: `${baseUrl}/modules`,
    belongsToUnpublishedModule: ENV.belongs_to_unpublished_module,
    originalityReportsForA2Enabled: ENV.originality_reports_for_a2_enabled,
    peerReviewModeEnabled: ENV.peer_review_mode_enabled,
    peerReviewAvailable: ENV.peer_review_available,
    peerDisplayName: ENV.peer_display_name,
    revieweeId: ENV.reviewee_id,
    anonymousAssetId: ENV.anonymous_asset_id,
  }

  if (ENV.PREREQS?.items?.[0]?.prev) {
    const prereq = ENV.PREREQS.items[0].prev
    env.modulePrereq = {
      title: prereq.title,
      link: prereq.html_url,
      __typename: 'modulePrereq',
    }
  } else if (ENV.PREREQS?.unlock_at) {
    env.unlockDate = ENV.PREREQS.unlock_at
  }

  return env
}

const ErrorPage = ({error}) => {
  return (
    <GenericErrorPage
      imageUrl={errorShipUrl}
      errorSubject={I18n.t('Assignments 2 Student initial query error')}
      errorCategory={I18n.t('Assignments 2 Student Error Page')}
      errorMessage={error.message}
    />
  )
}

const LoggedInStudentViewQuery = props => {
  const query =
    props.reviewerSubmissionID === undefined
      ? STUDENT_VIEW_QUERY
      : STUDENT_VIEW_QUERY_WITH_REVIEWER_SUBMISSION
  const {loading, error, data} = useQuery(query, {
    variables: {
      assignmentLid: props.assignmentLid,
      submissionID: props.submissionID,
      reviewerSubmissionID: props.reviewerSubmissionID,
    },
  })

  if (loading) return <LoadingIndicator />
  if (error) return <ErrorPage error={error} />

  document.title = data.assignment.name
  const dataWithEnv = JSON.parse(JSON.stringify(data))
  dataWithEnv.assignment.env = getAssignmentEnvVariables()
  dataWithEnv.assignment.rubric = transformRubricData(dataWithEnv.assignment.rubric)
  return <SubmissionHistoriesQuery initialQueryData={dataWithEnv} />
}

const LoggedOutStudentViewQuery = props => {
  const {loading, error, data} = useQuery(LOGGED_OUT_STUDENT_VIEW_QUERY, {
    variables: {assignmentLid: props.assignmentLid},
  })

  if (loading) return <LoadingIndicator />
  if (error) return <ErrorPage />

  document.title = data.assignment.name
  const dataWithEnv = JSON.parse(JSON.stringify(data))
  dataWithEnv.assignment.env = getAssignmentEnvVariables()
  dataWithEnv.assignment.rubric = transformRubricData(dataWithEnv.assignment.rubric)
  return <StudentContent onChangeSubmission={() => {}} assignment={dataWithEnv.assignment} />
}

const StudentViewQuery = props => {
  if (props.submissionID) {
    return <LoggedInStudentViewQuery {...props} />
  } else {
    return <LoggedOutStudentViewQuery {...props} />
  }
}

StudentViewQuery.propTypes = {
  assignmentLid: string.isRequired,
  submissionID: string,
}

export default StudentViewQuery
