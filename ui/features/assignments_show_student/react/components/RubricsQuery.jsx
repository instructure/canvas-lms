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
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import RubricTab from './RubricTab'
import {RUBRIC_QUERY, COURSE_PROFICIENCY_RATINGS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {useQuery} from '@apollo/client'
import {transformRubricData, transformRubricAssessmentData} from '../helpers/RubricHelpers'
import useStore from './stores/index'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import {bool, func} from 'prop-types'
import { useAllPages } from '@canvas/query'
import { executeQuery } from '@canvas/query/graphql'

const I18n = createI18nScope('assignments_2')

export default function RubricsQuery(props) {
  const {loading, error, data} = useQuery(RUBRIC_QUERY, {
    variables: {
      assignmentLid: props.assignment._id,
      submissionID: props.submission.id,
      courseID: props.assignment.env.courseId,
      submissionAttempt: props.submission.attempt,
    },
    fetchPolicy: 'network-only',
    nextFetchPolicy: 'cache-first',
    onCompleted: data => {
      const allAssessments = data.submission?.rubricAssessmentsConnection?.nodes ?? []

      const {parsedAssessments, selfAssessment} = allAssessments.reduce(
        (prev, curr) => {
          if (curr.assessment_type === 'self_assessment') {
            return {...prev, selfAssessment: transformRubricAssessmentData(curr)}
          }

          const parsedAssessment = transformRubricAssessmentData(curr)

          return {...prev, parsedAssessments: [...prev.parsedAssessments, parsedAssessment]}
        },
        {parsedAssessments: [], selfAssessment: null},
      )

      const parsedRubric = transformRubricData(data.assignment.rubric)

      const assessment = props.assignment.env.peerReviewModeEnabled
        ? parsedAssessments?.find(assessment => assessment.assessor?._id === ENV.current_user.id)
        : parsedAssessments?.[0]
      const filledAssessment = fillAssessment(parsedRubric, assessment || {})

      useStore.setState({
        displayedAssessment: filledAssessment,
        selfAssessment,
      })
    },
  })

  const {data: ratingsData, isError: ratingsError, isLoading: ratingsLoading} = useAllPages({
    queryKey:  ['courseProficiencyRatings', props.assignment.env.courseId],
    queryFn: ({pageParam}) => {
      return executeQuery(COURSE_PROFICIENCY_RATINGS_QUERY, {
        courseID: props.assignment.env.courseId,
        cursor: pageParam,
      })
    },
    getNextPageParam: lastPage => {
      const pageInfo = lastPage?.course?.account?.outcomeProficiency?.proficiencyRatingsConnection?.pageInfo
      return pageInfo?.hasNextPage ? pageInfo.endCursor : null
    },
    meta: {
      fetchAtLeastOnce: true,
    },
  })

  if (loading || ratingsLoading) {
    return <LoadingIndicator />
  }

  if (error || ratingsError) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Assignments 2 Student initial query error')}
        errorCategory={I18n.t('Assignments 2 Student Error Page')}
        errorMessage={error?.message || error}
      />
    )
  }

  return (
    <RubricTab
      assessments={data.submission?.rubricAssessmentsConnection?.nodes?.map(assessment =>
        transformRubricAssessmentData(assessment),
      )}
      key={props.submission.attempt}
      proficiencyRatings={
        ratingsData.pages.reduce((acc, page) => {
          const nodes = page?.course?.account?.outcomeProficiency?.proficiencyRatingsConnection?.nodes
          if (nodes) {
            return acc.concat(nodes)
          }
          return acc
        }, [])
      }
      rubric={transformRubricData(data.assignment.rubric)}
      rubricAssociation={data.assignment.rubricAssociation}
      peerReviewModeEnabled={props.assignment.env.peerReviewModeEnabled}
      rubricExpanded={props.rubricExpanded}
      toggleRubricExpanded={props.toggleRubricExpanded}
    />
  )
}

RubricsQuery.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape,
  rubricExpanded: bool,
  toggleRubricExpanded: func,
}
