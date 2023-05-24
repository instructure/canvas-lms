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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'

import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {
  getAssignmentGrades,
  getAssignmentGroupTotals,
  getTotalGradeStringFromEnrollments,
} from '@canvas/k5/react/utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {GradeRow} from './GradeRow'
import GradesEmptyPage from './GradesEmptyPage'

const I18n = useI18nScope('grade_details')

const NUM_GRADE_SKELETONS = 10

const GradeDetails = ({
  courseId,
  courseName,
  selectedGradingPeriodId,
  showTotals,
  currentUser,
  loadingGradingPeriods,
  userIsCourseAdmin,
  observedUserId,
  gradingScheme,
  restrictQuantitativeData,
}) => {
  const [loadingTotalGrade, setLoadingTotalGrade] = useState(true)
  const [loadingAssignmentGroups, setLoadingAssignmentGroups] = useState(true)
  const [error, setError] = useState(null)
  const [mqList] = useState(() => window.matchMedia('(max-width: 767px)')) // keep in sync with k5_theme.scss
  const [isStacked, setIsStacked] = useState(mqList.matches)
  const [enrollments, setEnrollments] = useState([])
  const [assignmentGroups, setAssignmentGroups] = useState([])

  // This hook has to get called here even though it's used only in GradeRow
  // because GradeRow isn't a "real" React component so can't call a hook itself
  const dateFormatter = useDateTimeFormat('date.formats.full_with_weekday')

  const gradingPeriodParam = {}
  const assignmentGroupTotals = getAssignmentGroupTotals(
    assignmentGroups,
    selectedGradingPeriodId,
    observedUserId,
    restrictQuantitativeData,
    gradingScheme
  )
  const grades = getAssignmentGrades(assignmentGroups, observedUserId)
  const totalGrade = getTotalGradeStringFromEnrollments(
    enrollments,
    currentUser.id,
    observedUserId,
    restrictQuantitativeData,
    gradingScheme
  )
  const include = ['assignments', 'submission', 'read_state', 'submission_comments']
  if (selectedGradingPeriodId) {
    gradingPeriodParam.grading_period_id = selectedGradingPeriodId
  }
  if (observedUserId) {
    include.push('observed_users')
  }

  useEffect(() => {
    mqList.onchange = event => setIsStacked(event.matches)
  }, [mqList])

  useFetchApi({
    path: `/api/v1/courses/${courseId}/assignment_groups`,
    loading: setLoadingAssignmentGroups,
    success: useCallback(data => {
      // filtering possible null values
      setAssignmentGroups(data.filter(g => g))
    }, []),
    error: setError,
    // wait until grading periods are loaded before firing this request, to prevent it from being immediately cancelled
    forceResult: loadingGradingPeriods ? [] : undefined,
    fetchAllPages: true,
    params: {
      include,
      ...gradingPeriodParam,
    },
  })

  useFetchApi({
    path: `/api/v1/courses/${courseId}/enrollments`,
    loading: setLoadingTotalGrade,
    success: useCallback(data => {
      setEnrollments(data.filter(e => e))
    }, []),
    error: setError,
    // wait until grading periods are loaded before firing this request, to prevent it from being immediately cancelled
    forceResult: loadingGradingPeriods ? [] : undefined,
    params: {
      user_id: currentUser.id,
      ...(observedUserId && {include: 'observed_users'}),
      ...gradingPeriodParam,
    },
  })

  useEffect(() => {
    if (error) {
      showFlashError(I18n.t('Failed to load grade details for %{courseName}', {courseName}))(error)
      setError(null)
    }
  }, [error, courseName])

  const gradeRowSkeleton = props => (
    <Table.Row {...props}>
      <Table.Cell colSpan={4}>
        <LoadingSkeleton
          height="2.5em"
          width="100%"
          screenReaderLabel={I18n.t('Loading grades for %{courseName}', {courseName})}
        />
      </Table.Cell>
    </Table.Row>
  )

  const gradesDetailsTable = content => (
    <div className={isStacked ? 'grade-details narrow' : 'grade-details'}>
      <Table
        caption={I18n.t('Grades for %{courseName}', {courseName})}
        margin="medium 0"
        layout={isStacked ? 'stacked' : 'auto'}
      >
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="assignment">{I18n.t('Assignment')}</Table.ColHeader>
            <Table.ColHeader id="dueDate">{I18n.t('Due Date')}</Table.ColHeader>
            <Table.ColHeader id="assignmentGroup">{I18n.t('Assignment Group')}</Table.ColHeader>
            <Table.ColHeader id="score">{I18n.t('Score')}</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>{content}</Table.Body>
      </Table>
    </div>
  )

  return !loadingAssignmentGroups && grades?.length === 0 ? (
    <GradesEmptyPage
      userIsCourseAdmin={userIsCourseAdmin}
      courseId={courseId}
      courseName={courseName}
    />
  ) : (
    <>
      {showTotals && (
        <>
          <LoadingWrapper
            id="total-grades"
            isLoading={loadingTotalGrade || loadingGradingPeriods}
            height="1.8em"
            width="10em"
            margin="medium 0 0"
            screenReaderLabel={I18n.t('Loading total grade for %{courseName}', {courseName})}
          >
            {totalGrade && (
              <Heading data-testid="grades-total" level="h2" margin="medium 0 0">
                <AccessibleContent
                  alt={I18n.t('%{courseName} Total: %{grade}', {courseName, grade: totalGrade})}
                >
                  {I18n.t('Total: %{grade}', {grade: totalGrade})}
                </AccessibleContent>
              </Heading>
            )}
          </LoadingWrapper>
          <View as="div" margin="x-small 0">
            <Text as="div" size="small">
              {I18n.t('Totals are calculated based only on graded assignments.')}
            </Text>
          </View>
          <LoadingWrapper
            id="assignment-groups"
            isLoading={loadingAssignmentGroups || loadingGradingPeriods}
            margin="none"
            height="1.5em"
            width="18em"
            screenReaderLabel={I18n.t('Loading assignment group totals')}
          >
            {assignmentGroupTotals && (
              <ToggleDetails
                data-testid="assignment-group-toggle"
                summary={
                  <AccessibleContent
                    alt={I18n.t("View %{courseName}'s Assignment Group Totals", {courseName})}
                  >
                    {I18n.t('View Assignment Group Totals')}
                  </AccessibleContent>
                }
              >
                {assignmentGroupTotals.map(group => (
                  <Text
                    data-testid="assignment-group-totals"
                    as="div"
                    margin="small 0"
                    key={group.id}
                  >
                    {I18n.t('%{groupName}: %{score}', {groupName: group.name, score: group.score})}
                  </Text>
                ))}
              </ToggleDetails>
            )}
          </LoadingWrapper>
        </>
      )}
      <LoadingWrapper
        id={`course-${courseId}-grades`}
        isLoading={loadingAssignmentGroups || loadingGradingPeriods}
        skeletonsNum={grades.length}
        defaultSkeletonsNum={NUM_GRADE_SKELETONS}
        renderCustomSkeleton={gradeRowSkeleton}
        renderSkeletonsContainer={gradesDetailsTable}
        renderLoadedContainer={gradesDetailsTable}
      >
        {grades.map(assignment =>
          GradeRow({
            dateFormatter,
            isStacked,
            currentUserId: observedUserId || currentUser.id,
            ...assignment,
          })
        )}
      </LoadingWrapper>
    </>
  )
}

GradeDetails.propTypes = {
  courseId: PropTypes.string.isRequired,
  courseName: PropTypes.string.isRequired,
  selectedGradingPeriodId: PropTypes.string,
  showTotals: PropTypes.bool.isRequired,
  currentUser: PropTypes.object.isRequired,
  loadingGradingPeriods: PropTypes.bool.isRequired,
  userIsCourseAdmin: PropTypes.bool.isRequired,
  observedUserId: PropTypes.string,
  gradingScheme: PropTypes.array,
  restrictQuantitativeData: PropTypes.bool,
}

export default GradeDetails
