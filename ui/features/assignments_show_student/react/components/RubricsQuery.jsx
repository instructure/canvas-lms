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
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import React from 'react'
import RubricTab from './RubricTab'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {useQuery} from 'react-apollo'
import {transformRubricData, transformRubricAssessmentData} from '../helpers/RubricHelpers'
import useStore from './stores/index'
import {fillAssessment} from '@canvas/rubrics/react/helpers'

const I18n = useI18nScope('assignments_2')

export default function RubricsQuery(props) {
  const {loading, error, data} = useQuery(RUBRIC_QUERY, {
    variables: {
      assignmentLid: props.assignment._id,
      submissionID: props.submission.id,
      courseID: props.assignment.env.courseId,
      submissionAttempt: props.submission.attempt,
    },
    fetchPolicy: 'network-only',
    onCompleted: data => {
      const parsedAssessments = data.submission?.rubricAssessmentsConnection?.nodes?.map(
        assessment => transformRubricAssessmentData(assessment)
      )
      const parsedRubric = transformRubricData(data.assignment.rubric)

      const assessment = props.assignment.env.peerReviewModeEnabled
        ? parsedAssessments?.find(assessment => assessment.assessor?._id === ENV.current_user.id)
        : parsedAssessments?.[0]
      const filledAssessment = fillAssessment(parsedRubric, assessment || {})

      useStore.setState({
        displayedAssessment: filledAssessment,
      })
    },
  })

  if (loading) {
    return <LoadingIndicator />
  }

  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Assignments 2 Student initial query error')}
        errorCategory={I18n.t('Assignments 2 Student Error Page')}
        errorMessage={error.message}
      />
    )
  }

  return (
    <RubricTab
      assessments={data.submission?.rubricAssessmentsConnection?.nodes?.map(assessment =>
        transformRubricAssessmentData(assessment)
      )}
      key={props.submission.attempt}
      proficiencyRatings={
        data.course.account?.outcomeProficiency?.proficiencyRatingsConnection?.nodes
      }
      rubric={transformRubricData(data.assignment.rubric)}
      rubricAssociation={data.assignment.rubricAssociation}
      peerReviewModeEnabled={props.assignment.env.peerReviewModeEnabled}
    />
  )
}

RubricsQuery.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape,
}
