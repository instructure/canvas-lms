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
import errorShipUrl from '../SVG/ErrorShip.svg'
import {fillAssessment} from '../../../rubrics/helpers'
import GenericErrorPage from '../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '../../shared/LoadingIndicator'
import {Query} from 'react-apollo'
import React from 'react'
import Rubric from '../../../rubrics/Rubric'
import {RUBRIC_QUERY} from '../graphqlData/Queries'
import {Submission} from '../graphqlData/Submission'

function transformRubricData(rubric) {
  const rubricCopy = JSON.parse(JSON.stringify(rubric))
  rubricCopy.criteria.forEach(criterion => {
    if (criterion.outcome) {
      criterion.learning_outcome_id = criterion.outcome._id
    }
    delete criterion.outcome
  })
  return rubricCopy
}

function transformRubricAssessmentData(rubricAssessment) {
  const assessmentCopy = JSON.parse(JSON.stringify(rubricAssessment))
  assessmentCopy.data.forEach(rating => {
    rating.criterion_id = rating.criterion.id
    rating.learning_outcome_id = rating.outcome ? rating.outcome._id : null
    delete rating.criterion
    delete rating.outcome
  })
  return assessmentCopy
}

export default function RubricTab(props) {
  return (
    <Query
      query={RUBRIC_QUERY}
      variables={{
        rubricID: props.assignment.rubric.id,
        submissionID: props.submission.id,
        courseID: props.assignment.env.courseId
      }}
    >
      {({loading, error, data}) => {
        if (loading) return <LoadingIndicator />
        if (error) {
          return (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('Assignments 2 Student initial query error')}
              errorCategory={I18n.t('Assignments 2 Student Error Page')}
            />
          )
        }

        const customRatings = data.course.account.proficiencyRatingsConnection
          ? data.course.account.proficiencyRatingsConnection.nodes
          : null

        // TODO: Need to handle the case where there are multiple rubric assessments
        //       here. Need designs, probably a dropdown to select the target assessment
        const rubric = transformRubricData(data.rubric)
        let rubricAssessment = null
        let rubricAssociation = null
        if (
          data.submission &&
          data.submission.rubricAssessmentsConnection &&
          data.submission.rubricAssessmentsConnection.nodes &&
          data.submission.rubricAssessmentsConnection.nodes.length !== 0
        ) {
          const assessmentData = data.submission.rubricAssessmentsConnection.nodes[0]
          rubricAssessment = transformRubricAssessmentData(assessmentData)
          rubricAssociation = rubricAssessment.rubric_association
        }

        return (
          <Rubric
            customRatings={customRatings}
            rubric={rubric}
            rubricAssessment={fillAssessment(rubric, rubricAssessment || {})}
            rubricAssociation={rubricAssociation}
          />
        )
      }}
    </Query>
  )
}

RubricTab.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}
