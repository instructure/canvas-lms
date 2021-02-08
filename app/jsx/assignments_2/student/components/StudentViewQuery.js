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

import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import GenericErrorPage from '../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2_initial_query'
import {LOGGED_OUT_STUDENT_VIEW_QUERY, STUDENT_VIEW_QUERY} from '../graphqlData/Queries'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import {useQuery} from 'react-apollo'
import React from 'react'
import {string} from 'prop-types'
import StudentContent from './StudentContent'
import SubmissionHistoriesQuery from './SubmissionHistoriesQuery'

function getAssignmentEnvVariables() {
  const baseUrl = `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
    ENV.context_asset_string.split('_')[1]
  }`

  const env = {
    assignmentUrl: `${baseUrl}/assignments`,
    courseId: ENV.context_asset_string.split('_')[1],
    currentUser: ENV.current_user,
    enrollmentState: ENV.enrollment_state,
    modulePrereq: null,
    moduleUrl: `${baseUrl}/modules`
  }

  if (ENV.PREREQS?.items?.[0]?.prev) {
    const prereq = ENV.PREREQS.items[0].prev
    env.modulePrereq = {
      title: prereq.title,
      link: prereq.html_url,
      __typename: 'modulePrereq'
    }
  }

  return env
}

const ErrorPage = () => {
  return (
    <GenericErrorPage
      imageUrl={errorShipUrl}
      errorSubject={I18n.t('Assignments 2 Student initial query error')}
      errorCategory={I18n.t('Assignments 2 Student Error Page')}
    />
  )
}

const LoggedInStudentViewQuery = props => {
  const {loading, error, data} = useQuery(STUDENT_VIEW_QUERY, {
    variables: {assignmentLid: props.assignmentLid, submissionID: props.submissionID}
  })

  if (loading) return <LoadingIndicator />
  if (error) return <ErrorPage />

  document.title = data.assignment.name
  const dataWithEnv = JSON.parse(JSON.stringify(data))
  dataWithEnv.assignment.env = getAssignmentEnvVariables()
  return <SubmissionHistoriesQuery initialQueryData={dataWithEnv} />
}

const LoggedOutStudentViewQuery = props => {
  const {loading, error, data} = useQuery(LOGGED_OUT_STUDENT_VIEW_QUERY, {
    variables: {assignmentLid: props.assignmentLid}
  })

  if (loading) return <LoadingIndicator />
  if (error) return <ErrorPage />

  document.title = data.assignment.name
  const dataWithEnv = JSON.parse(JSON.stringify(data))
  dataWithEnv.assignment.env = getAssignmentEnvVariables()
  return <StudentContent assignment={dataWithEnv.assignment} />
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
  submissionID: string
}

export default StudentViewQuery
