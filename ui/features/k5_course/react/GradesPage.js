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
import moment from 'moment-timezone'

import {Table} from '@instructure/ui-table'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'

import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {GradeRow} from './GradeRow'
import EmptyGradesUrl from '../images/empty-grades.svg'

const NUM_LOADING_SKELETONS = 10

export const GradesPage = ({courseId, courseName, userIsInstructor}) => {
  const [loading, setLoading] = useState(true)
  const [grades, setGrades] = useState([])
  const [error, setError] = useState(null)

  useFetchApi({
    path: `/api/v1/courses/${courseId}/assignment_groups`,
    loading: setLoading,
    success: useCallback(data => {
      setGrades(
        data
          .map(group =>
            group.assignments.map(a => ({
              id: a.id,
              assignmentName: a.name,
              url: a.html_url,
              dueDate: a.due_at,
              assignmentGroupName: group.name,
              assignmentGroupId: group.id,
              pointsPossible: a.points_possible,
              gradingType: a.grading_type,
              score: a.submission?.score,
              grade: a.submission?.grade,
              submissionDate: a.submission?.submitted_at,
              late: a.submission?.late,
              excused: a.submission?.excused,
              missing: a.submission?.missing
            }))
          )
          .flat(1)
          .sort((a, b) => {
            if (a.dueDate == null) return 1
            if (b.dueDate == null) return -1
            return moment(a.dueDate).diff(moment(b.dueDate))
          })
      )
    }, []),
    error: setError,
    fetchAllPages: true,
    params: {
      include: ['assignments', 'submission']
    }
  })

  useEffect(() => {
    if (error) {
      showFlashError(I18n.t('Failed to load grades for %{courseName}', {courseName}))(error)
      setError(null)
    }
  }, [error, courseName])

  const loadingSkeletons = []
  for (let i = 0; i < NUM_LOADING_SKELETONS; i++) {
    loadingSkeletons.push(
      <Table.Row key={`skeleton-${i}`}>
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

  return userIsInstructor || (!loading && grades?.length === 0) ? (
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
        {loading
          ? loadingSkeletons
          : grades.map(assignment => <GradeRow key={assignment.id} {...assignment} />)}
      </Table.Body>
    </Table>
  )
}

GradesPage.propTypes = {
  courseId: PropTypes.string.isRequired,
  courseName: PropTypes.string.isRequired,
  userIsInstructor: PropTypes.bool.isRequired
}

export default GradesPage
