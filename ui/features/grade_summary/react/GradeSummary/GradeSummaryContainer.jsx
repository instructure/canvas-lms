/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useContext, useState, useEffect} from 'react'
import {useQuery as useApolloQuery, useMutation} from '@apollo/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

import SubmissionCommentsTray from '../SubmissionCommentsTray'

import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {GRADE_SUMMARY} from '../../graphql/GradeSummary'
import {
  UPDATE_SUBMISSIONS_READ_STATE,
  UPDATE_RUBRIC_ASSESSMENT_READ_STATE,
} from '../../graphql/Mutations'

import AssignmentTable from './AssignmentTable'
import {getGradingPeriodID} from './utils'
import {GradeSummaryContext} from './context'
import {useAssignments} from '../../graphql/Assignments'

const I18n = createI18nScope('grade_summary')

const GradeSummaryContainer = () => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [submissionIdsForUpdate, setSubmissionIdsForUpdate] = useState([])
  const [submissionIdsForRubricUpdate, setSubmissionIdsForRubricUpdate] = useState([])
  const [submissionAssignmentId, setSubmissionAssignmentId] = useState('')

  if (!ENV?.student_id) {
    throw new Error('No student_id found')
  }

  const gradingPeriod = ENV?.grading_period?.id || getGradingPeriodID()
  const viewingUserId = ENV?.student_id
  const hideTotalRow = ENV?.hide_final_grades

  const gradeSummaryVariables = {
    courseID: ENV.course_id,
    studentId: viewingUserId,
  }

  const gradeSummaryQuery = useApolloQuery(GRADE_SUMMARY, {
    variables: gradeSummaryVariables,
  })

  const assignmentsVariables = {
    courseID: ENV.course_id,
    studentId: viewingUserId,
  }

  if (gradingPeriod !== undefined) {
    assignmentsVariables.gradingPeriodId =
      gradingPeriod && gradingPeriod !== '0' ? gradingPeriod : null
  }

  const assignmentsResult = useAssignments(assignmentsVariables)

  const [readStateChangeSubmission] = useMutation(UPDATE_SUBMISSIONS_READ_STATE, {
    onCompleted(data) {
      if (data.updateSubmissionsReadState.errors) {
        setOnFailure(I18n.t('Read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Read state Changed!',
              other: 'Read states Changed!',
            },
            {count: '1000'},
          ),
        )
        setSubmissionIdsForUpdate([])
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    },
  })

  const [readStateChangeRubric] = useMutation(UPDATE_RUBRIC_ASSESSMENT_READ_STATE, {
    onCompleted(data) {
      if (data.updateRubricAssessmentReadState.errors) {
        setOnFailure(I18n.t('Rubric read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Rubric read state Changed!',
              other: 'Rubric read states Changed!',
            },
            {count: '1000'},
          ),
        )
        setSubmissionIdsForRubricUpdate([])
      }
    },
    onError() {
      setOnFailure(I18n.t('Rubric read state change failed'))
    },
  })

  useEffect(() => {
    const interval = setInterval(() => {
      if (submissionIdsForUpdate.length > 0) {
        readStateChangeSubmission({
          variables: {
            submissionIds: submissionIdsForUpdate,
            read: true,
          },
        })
      }
    }, 3000)

    return () => clearInterval(interval)
  }, [submissionIdsForUpdate, readStateChangeSubmission])

  useEffect(() => {
    const interval = setInterval(() => {
      if (submissionIdsForRubricUpdate.length > 0) {
        readStateChangeRubric({
          variables: {
            submissionIds: submissionIdsForRubricUpdate,
          },
        })
      }
    }, 3000)

    return () => clearInterval(interval)
  }, [submissionIdsForRubricUpdate, readStateChangeRubric])

  if (gradeSummaryQuery.loading || assignmentsResult.isLoading) {
    return (
      <Flex alignItems="center" justifyItems="center" width="100%">
        <Flex.Item>
          <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
        </Flex.Item>
      </Flex>
    )
  }

  if (gradeSummaryQuery.error || !gradeSummaryQuery?.data?.legacyNode) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Grade Summary initial query error')}
        errorCategory={I18n.t('Grade Summary Error Page')}
      />
    )
  }

  if (assignmentsResult.isError) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Failed to load assignments data')}
        errorCategory={I18n.t('Grade Summary Error Page')}
        errorMessage={
          assignmentsResult.error?.message ||
          I18n.t('An error occurred while fetching assignments. Please try refreshing the page.')
        }
      />
    )
  }

  if (!assignmentsResult?.data?.assignments) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Assignments data is missing or invalid')}
        errorCategory={I18n.t('Grade Summary Error Page')}
        errorMessage={I18n.t(
          'The assignments data structure is invalid. This could be due to a server-side issue.',
        )}
      />
    )
  }

  const gradeSummaryContext = {
    assignmentSortBy: document.querySelector('#assignment_sort_order_select_menu').value,
  }

  const handleReadStateChange = submissionID => {
    if (!submissionID) return
    const arr = [...submissionIdsForUpdate, submissionID]
    setSubmissionIdsForUpdate(
      arr.filter(
        (item, index) => item !== null && item !== undefined && arr.indexOf(item) === index,
      ),
    )
  }

  const handleRubricReadStateChange = submissionID => {
    if (!submissionID) return
    const arr = [...submissionIdsForRubricUpdate, submissionID]
    setSubmissionIdsForRubricUpdate(
      arr.filter(
        (item, index) => item !== null && item !== undefined && arr.indexOf(item) === index,
      ),
    )
  }

  return (
    <Responsive
      query={{
        small: {maxWidth: '40rem'},
        large: {minWidth: '41rem'},
      }}
      props={{
        small: {layout: 'stacked'},
        large: {layout: 'fixed'},
      }}
    >
      {({layout}) => (
        <GradeSummaryContext.Provider value={gradeSummaryContext}>
          <View as="div" padding="medium">
            <AssignmentTable
              queryData={gradeSummaryQuery?.data?.legacyNode}
              assignmentsData={assignmentsResult?.data}
              layout={layout}
              handleReadStateChange={handleReadStateChange}
              handleRubricReadStateChange={handleRubricReadStateChange}
              setSubmissionAssignmentId={setSubmissionAssignmentId}
              submissionAssignmentId={submissionAssignmentId}
              hideTotalRow={hideTotalRow}
            />
            <SubmissionCommentsTray
              onDismiss={() => {
                document
                  .querySelector(`[data-testid="submission_comment_tray_${submissionAssignmentId}"`)
                  .focus()
                setSubmissionAssignmentId('')
              }}
            />
          </View>
        </GradeSummaryContext.Provider>
      )}
    </Responsive>
  )
}

export default GradeSummaryContainer
