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

import React, {useState, useCallback, useEffect, useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import useFetchApi from '@canvas/use-fetch-api-hook'
import GradingPeriodSelect from './GradingPeriodSelect'
import GradesEmptyPage from './GradesEmptyPage'
import GradeDetails from './GradeDetails'
import IndividualStudentMastery from '@canvas/grade-summary'
import {outcomeProficiencyShape} from '@canvas/grade-summary/react/IndividualStudentMastery/shapes'

const I18n = useI18nScope('course_grades_page')

export const GradesPage = ({
  courseId,
  courseName,
  hideFinalGrades,
  currentUser,
  userIsStudent,
  userIsCourseAdmin,
  showLearningMasteryGradebook,
  outcomeProficiency,
  observedUserId,
  gradingScheme,
  restrictQuantitativeData,
}) => {
  const [loadingGradingPeriods, setLoadingGradingPeriods] = useState(true)
  const [error, setError] = useState(null)
  const [gradingPeriods, setGradingPeriods] = useState(null)
  const [currentGradingPeriodId, setCurrentGradingPeriodId] = useState(null)
  const [allowTotalsForAllPeriods, setAllowTotalsForAllPeriods] = useState(true)
  const [selectedGradingPeriodId, setSelectedGradingPeriodId] = useState(null)
  const [selectedTab, setSelectedTab] = useState('assignments')
  const [enrollments, setEnrollments] = useState([])
  const observedUserRef = useRef(null)
  const include = ['grading_periods', 'current_grading_period_scores', 'total_scores']
  if (observedUserId) {
    include.push('observed_users')
  }
  useFetchApi({
    path: `/api/v1/courses/${courseId}`,
    loading: setLoadingGradingPeriods,
    success: useCallback(data => {
      setGradingPeriods(data.grading_periods)
      setEnrollments(data.enrollments)
      setCurrentGradingPeriodId(data.enrollments[0]?.current_grading_period_id)
      setAllowTotalsForAllPeriods(data.enrollments[0]?.totals_for_all_grading_periods_option)
    }, []),
    error: setError,
    params: {
      include,
    },
  })

  useEffect(() => {
    if (error) {
      showFlashError(I18n.t('Failed to load grading periods for %{courseName}', {courseName}))(
        error
      )
      setError(null)
    }
  }, [error, courseName])

  useEffect(() => {
    if (enrollments.length > 0 && observedUserId && observedUserRef.current !== observedUserId) {
      const enrollment = enrollments.find(
        e => e.user_id === observedUserId && e.type !== 'observer'
      )
      setCurrentGradingPeriodId(enrollment?.current_grading_period_id)
      setAllowTotalsForAllPeriods(enrollment?.totals_for_all_grading_periods_option)
      observedUserRef.current = observedUserId
    }
  }, [observedUserId, enrollments])

  const allGradingPeriodsSelected = gradingPeriods?.length > 0 && selectedGradingPeriodId === null
  const showTotals = !hideFinalGrades && !(allGradingPeriodsSelected && !allowTotalsForAllPeriods)

  const renderAssignments = () => (
    <>
      {(gradingPeriods?.length > 0 || loadingGradingPeriods) && (
        <GradingPeriodSelect
          loadingGradingPeriods={loadingGradingPeriods}
          gradingPeriods={gradingPeriods}
          onGradingPeriodSelected={setSelectedGradingPeriodId}
          currentGradingPeriodId={currentGradingPeriodId}
          courseName={courseName}
        />
      )}
      <GradeDetails
        courseId={courseId}
        courseName={courseName}
        selectedGradingPeriodId={selectedGradingPeriodId}
        showTotals={showTotals}
        currentUser={currentUser}
        loadingGradingPeriods={loadingGradingPeriods}
        userIsCourseAdmin={userIsCourseAdmin}
        observedUserId={observedUserId}
        gradingScheme={gradingScheme}
        restrictQuantitativeData={restrictQuantitativeData}
      />
    </>
  )

  const renderOutcomes = () => (
    <>
      <ScreenReaderContent>
        {I18n.t('Learning outcome gradebook for %{courseName}', {courseName})}
      </ScreenReaderContent>
      <div id="outcomes">
        <IndividualStudentMastery
          courseId={courseId}
          studentId={currentUser.id}
          outcomeProficiency={outcomeProficiency}
        />
      </div>
    </>
  )

  if (!userIsStudent && !observedUserId) {
    return (
      <GradesEmptyPage
        userIsCourseAdmin={userIsCourseAdmin}
        courseId={courseId}
        courseName={courseName}
      />
    )
  } else if (showLearningMasteryGradebook) {
    return (
      <Tabs
        variant="secondary"
        onRequestTabChange={(_e, {id}) => setSelectedTab(id)}
        margin="medium 0 0"
      >
        <Tabs.Panel
          renderTitle={<Text size="small">{I18n.t('Assignments')}</Text>}
          id="k5-assignments"
          isSelected={selectedTab === 'k5-assignments'}
          padding="small 0"
        >
          {renderAssignments()}
        </Tabs.Panel>
        <Tabs.Panel
          renderTitle={<Text size="small">{I18n.t('Learning Mastery')}</Text>}
          id="k5-outcomes"
          isSelected={selectedTab === 'k5-outcomes'}
          padding="small 0"
        >
          {renderOutcomes()}
        </Tabs.Panel>
      </Tabs>
    )
  } else {
    return renderAssignments()
  }
}

GradesPage.propTypes = {
  courseId: PropTypes.string.isRequired,
  courseName: PropTypes.string.isRequired,
  hideFinalGrades: PropTypes.bool.isRequired,
  currentUser: PropTypes.object.isRequired,
  userIsStudent: PropTypes.bool.isRequired,
  userIsCourseAdmin: PropTypes.bool.isRequired,
  showLearningMasteryGradebook: PropTypes.bool.isRequired,
  outcomeProficiency: outcomeProficiencyShape,
  observedUserId: PropTypes.string,
  gradingScheme: PropTypes.array,
  restrictQuantitativeData: PropTypes.bool,
}

export default GradesPage
