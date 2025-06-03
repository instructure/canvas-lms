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
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import RubricTab from './RubricTab'
import {
  RUBRIC_QUERY,
  COURSE_PROFICIENCY_RATINGS_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {useQuery} from '@apollo/client'
import {transformRubricData, transformRubricAssessmentData} from '../helpers/RubricHelpers'
import useStore from './stores/index'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import {useAllPages} from '@canvas/query'
import {executeQuery} from '@canvas/graphql'
import {Assignment, Submission} from './RubricsQuery.types'

const I18n = createI18nScope('assignments_2')

const queryFn = ({queryKey, pageParam}: {queryKey: string[]; pageParam: unknown}) => {
  return executeQuery(COURSE_PROFICIENCY_RATINGS_QUERY, {
    courseID: queryKey[1],
    cursor: pageParam,
  })
}

type Props = {
  assignment: Assignment
  submission: Submission
  rubricExpanded: boolean
  toggleRubricExpanded: () => void
}

export default function RubricsQuery({
  assignment,
  submission,
  rubricExpanded,
  toggleRubricExpanded,
}: Props) {
  const {loading, error, data} = useQuery(RUBRIC_QUERY, {
    variables: {
      assignmentLid: assignment._id,
      submissionID: submission.id,
      courseID: assignment.env.courseId,
      submissionAttempt: submission.attempt,
    },
    fetchPolicy: 'network-only',
    nextFetchPolicy: 'cache-first',
    onCompleted: data => {
      const allAssessments = data.submission?.rubricAssessmentsConnection?.nodes ?? []

      const {parsedAssessments, selfAssessment} = allAssessments.reduce(
        // @ts-expect-error
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

      const assessment = assignment.env.peerReviewModeEnabled
        ? // @ts-expect-error
          parsedAssessments?.find(assessment => assessment.assessor?._id === ENV.current_user.id)
        : parsedAssessments?.[0]
      const filledAssessment = fillAssessment(parsedRubric, assessment || {})

      useStore.setState({
        displayedAssessment: filledAssessment,
        selfAssessment,
      })
    },
  })

  const {
    data: ratingsData,
    isError: ratingsError,
    isLoading: ratingsLoading,
  } = useAllPages({
    queryKey: ['courseProficiencyRatings', assignment.env.courseId],
    queryFn,
    getNextPageParam: lastPage => {
      const pageInfo =
        // @ts-expect-error
        lastPage?.course?.account?.outcomeProficiency?.proficiencyRatingsConnection?.pageInfo
      return pageInfo?.hasNextPage ? pageInfo.endCursor : null
    },
    initialPageParam: null,
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
      // @ts-expect-error
      assessments={data.submission?.rubricAssessmentsConnection?.nodes?.map(assessment =>
        transformRubricAssessmentData(assessment),
      )}
      key={submission.attempt}
      // @ts-expect-error
      proficiencyRatings={ratingsData.pages.reduce((acc, page) => {
        const nodes = page?.course?.account?.outcomeProficiency?.proficiencyRatingsConnection?.nodes
        if (nodes) {
          return acc.concat(nodes)
        }
        return acc
      }, [])}
      rubric={transformRubricData(data.assignment.rubric)}
      rubricAssociation={data.assignment.rubricAssociation}
      peerReviewModeEnabled={assignment.env.peerReviewModeEnabled}
      rubricExpanded={rubricExpanded}
      toggleRubricExpanded={toggleRubricExpanded}
    />
  )
}
