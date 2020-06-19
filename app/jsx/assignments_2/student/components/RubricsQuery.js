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
import {Assignment} from '../graphqlData/Assignment'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import GenericErrorPage from '../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import React from 'react'
import RubricTab from './RubricTab'
import {RUBRIC_QUERY} from '../graphqlData/Queries'
import {Submission} from '../graphqlData/Submission'
import {useQuery} from 'react-apollo'

export default function RubricsQuery(props) {
  const {loading, error, data} = useQuery(RUBRIC_QUERY, {
    variables: {
      assignmentLid: props.assignment._id,
      submissionID: props.submission.id,
      courseID: props.assignment.env.courseId,
      submissionAttempt: props.submission.attempt
    }
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
      />
    )
  }

  return (
    <RubricTab
      assessments={data.submission?.rubricAssessmentsConnection?.nodes}
      key={props.submission.attempt}
      proficiencyRatings={data.course.account?.proficiencyRatingsConnection?.nodes}
      rubric={data.assignment.rubric}
    />
  )
}

RubricsQuery.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}
