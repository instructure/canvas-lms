/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState, useCallback, useEffect} from 'react'
import I18n from 'i18n!k5_course_GradesPage'
import PropTypes from 'prop-types'

import {Table} from '@instructure/ui-table'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {ToggleDetails} from '@instructure/ui-toggle-details'

import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {GradeRow} from './GradeRow'
import EmptyGradesUrl from '../images/empty-grades.svg'
import {getAssignmentGroupTotals, getAssignmentGrades} from '@canvas/k5/react/utils'

const NUM_GRADE_SKELETONS = 10

export const GradesPage = ({
  courseId,
  courseName,
  hideFinalGrades,
  currentUser,
  userIsInstructor
}) => {
  const [loadingAssignmentGroups, setLoadingAssignmentGroups] = useState(true)
  const [loadingTotalGrade, setLoadingTotalGrade] = useState(true)
  const [grades, setGrades] = useState([])
  const [assignmentGroupTotals, setAssignmentGroupTotals] = useState(null)
  const [totalGrade, setTotalGrade] = useState(null)
  const [error, setError] = useState(null)

  useFetchApi({
    path: `/api/v1/courses/${courseId}/assignment_groups`,
    loading: setLoadingAssignmentGroups,
    success: useCallback(data => {
      setAssignmentGroupTotals(getAssignmentGroupTotals(data))
      setGrades(getAssignmentGrades(data))
    }, []),
    error: setError,
    fetchAllPages: true,
    params: {
      include: ['assignments', 'submission', 'read_state']
    }
  })

  useFetchApi({
    path: `/api/v1/courses/${courseId}/enrollments`,
    loading: setLoadingTotalGrade,
    success: useCallback(
      data => {
        const score = data.find(({user_id}) => user_id === currentUser.id)?.grades?.current_score
        setTotalGrade(
          score == null ? I18n.t('n/a') : I18n.n(score, {percentage: true, precision: 2})
        )
      },
      [currentUser]
    ),
    error: setError
  })

  useEffect(() => {
    if (error) {
      showFlashError(I18n.t('Failed to load grades for %{courseName}', {courseName}))(error)
      setError(null)
    }
  }, [error, courseName])

  const gradeSkeletons = []
  for (let i = 0; i < NUM_GRADE_SKELETONS; i++) {
    gradeSkeletons.push(
      <Table.Row key={`grade-skeleton-${i}`}>
        <Table.Cell colSpan={4}>
          <LoadingSkeleton
            height="2.5em"
            width="100%"
            screenReaderLabel={I18n.t('Loading grades for %{courseName}', {courseName})}
          />
        </Table.Cell>
      </Table.Row>
    )
  }

  return userIsInstructor || (!loadingAssignmentGroups && grades?.length === 0) ? (
    <Flex direction="column" alignItems="center" margin="x-large large">
      <Img src={EmptyGradesUrl} margin="0 0 medium 0" data-testid="empty-grades-panda" />
      {userIsInstructor ? (
        <>
          <Text size="large">{I18n.t('Students see their grades here.')}</Text>
          <Button href={`/courses/${courseId}/gradebook`} margin="small 0 0 0">
            {I18n.t('View Gradebook')}
          </Button>
        </>
      ) : (
        <Text size="large">{I18n.t("You don't have any grades yet.")}</Text>
      )}
    </Flex>
  ) : (
    <>
      {!hideFinalGrades && (
        <>
          {loadingTotalGrade ? (
            <LoadingSkeleton
              height="1.8em"
              width="10em"
              margin="medium 0 small"
              screenReaderLabel={I18n.t('Loading total grade for %{courseName}', {courseName})}
            />
          ) : (
            <Heading level="h2" margin="medium 0 small">
              {totalGrade && I18n.t('Total: %{grade}', {grade: totalGrade})}
            </Heading>
          )}
          {loadingAssignmentGroups ? (
            <LoadingSkeleton
              height="1.5em"
              width="18em"
              screenReaderLabel={I18n.t('Loading assignment group totals')}
            />
          ) : (
            <ToggleDetails summary={I18n.t('View Assignment Group Totals')}>
              {assignmentGroupTotals.map(group => (
                <Text as="div" margin="small 0" key={group.id}>
                  {I18n.t('%{groupName}: %{score}', {groupName: group.name, score: group.score})}
                </Text>
              ))}
            </ToggleDetails>
          )}
        </>
      )}
      <Table caption={I18n.t('Grades for %{courseName}', {courseName})} margin="medium 0">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="assignment">{I18n.t('Assignment')}</Table.ColHeader>
            <Table.ColHeader id="dueDate">{I18n.t('Due Date')}</Table.ColHeader>
            <Table.ColHeader id="assignmentGroup">{I18n.t('Assignment Group')}</Table.ColHeader>
            <Table.ColHeader id="score">{I18n.t('Score')}</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {loadingAssignmentGroups
            ? gradeSkeletons
            : grades.map(assignment => <GradeRow key={assignment.id} {...assignment} />)}
        </Table.Body>
      </Table>
    </>
  )
}

GradesPage.propTypes = {
  courseId: PropTypes.string.isRequired,
  courseName: PropTypes.string.isRequired,
  hideFinalGrades: PropTypes.bool.isRequired,
  currentUser: PropTypes.object.isRequired,
  userIsInstructor: PropTypes.bool.isRequired
}

export default GradesPage
