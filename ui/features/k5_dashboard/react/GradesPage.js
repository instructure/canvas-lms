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
 *
 */

import React, {useEffect, useState, useRef, useCallback} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'

import {fetchGradesForGradingPeriod, getCourseGrades, transformGrades} from '@canvas/k5/react/utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import GradesSummary from './GradesSummary'
import GradingPeriodSelect, {ALL_PERIODS_OPTION} from './GradingPeriodSelect'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import useFetchApi from '@canvas/use-fetch-api-hook'

const I18n = useI18nScope('dashboard_grades_page')

export const getGradingPeriodsFromCourses = courses =>
  courses
    .flatMap(course => course.gradingPeriods)
    .reduce((acc, gradingPeriod) => {
      if (!acc.find(({id}) => gradingPeriod.id === id)) {
        acc.push(gradingPeriod)
      }
      return acc
    }, [])

export const overrideCourseGradingPeriods = (
  courses,
  selectedGradingPeriodId,
  specificPeriodGrades
) =>
  courses &&
  courses
    .map(course => {
      // No grading period selected, show all courses
      if (!selectedGradingPeriodId) return course
      // The course isn't associated with this grading period, filter it out
      if (
        selectedGradingPeriodId !== ALL_PERIODS_OPTION &&
        !course.gradingPeriods.some(({id}) => id === selectedGradingPeriodId)
      )
        return null
      // The course has this grading period, so override the current scores with
      // those from the selected grading period
      const gradingPeriod = specificPeriodGrades.find(gp => gp.courseId === course.courseId)
      if (gradingPeriod) {
        return {
          ...course,
          grade: gradingPeriod.grade,
          score: gradingPeriod.score,
          showingAllGradingPeriods: selectedGradingPeriodId === ALL_PERIODS_OPTION,
        }
      }
      return course
    })
    // Filter out nulls
    .filter(c => c)

export const getCoursesByObservee = (courses, observedUserId, currentUser) => {
  // All courses will be shown by default
  let coursesByObservee = courses
  const currentUserId = currentUser?.id
  if (observedUserId && observedUserId === currentUserId) {
    // If the observed user is the current user, only non-observer enrollments
    // will be considered
    coursesByObservee = courses.filter(c =>
      c.enrollments?.find(e => e.type !== 'observer' && e.user_id === currentUserId)
    )
  } else if (observedUserId) {
    // Filtering courses by the observed User
    coursesByObservee = courses
      .filter(c =>
        c.enrollments?.find(
          e =>
            e.type === 'observer' &&
            e.user_id === currentUserId &&
            e.associated_user_id === observedUserId
        )
      )
      .map(course => {
        // observer enrollments don't include observee grades information,
        // so we need to regenerate the course information based on the student enrollment
        // to present the observee grades
        return getCourseGrades(course, observedUserId)
      })
  }
  return coursesByObservee
}

export const GradesPage = ({visible, currentUserRoles, observedUserId, currentUser}) => {
  const [courses, setCourses] = useState(null)
  const [coursesByUser, setCoursesByUser] = useState(null)
  const [gradingPeriods, setGradingPeriods] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedGradingPeriodId, selectGradingPeriodId] = useState('')
  const [specificPeriodGrades, setSpecificPeriodGrades] = useState([])
  const userRef = useRef(null)
  const includeObservedUsers = currentUserRoles.includes('observer')
  const include = [
    'total_scores',
    'current_grading_period_scores',
    'grading_periods',
    'course_image',
    'grading_scheme',
    'restrict_quantitative_data',
  ]
  if (includeObservedUsers) {
    include.push('observed_users')
  }

  useFetchApi({
    success: useCallback(
      results => {
        if (results) {
          const subjects = transformGrades(results).filter(c => !c.isHomeroom)
          setCourses(subjects)
          setCoursesByUser(getCoursesByObservee(subjects, observedUserId, currentUser))
          setGradingPeriods(getGradingPeriodsFromCourses(subjects))
          setLoading(false)
        }
      },
      [currentUser] // eslint-disable-line react-hooks/exhaustive-deps
    ),
    error: useCallback(err => {
      showFlashError(I18n.t('Failed to load the grades tab'))(err)
      setLoading(false)
    }, []),
    loading: setLoading,
    path: '/api/v1/users/self/courses',
    fetchAllPages: true,
    params: {
      enrollment_state: 'active',
      per_page: '100',
      include,
    },
    forceResult: visible ? undefined : false,
  })
  useEffect(() => {
    if (visible && courses && userRef.current !== observedUserId) {
      setCoursesByUser(getCoursesByObservee(courses, observedUserId, currentUser))
      userRef.current = observedUserId
    }
  }, [courses, visible, observedUserId, currentUser])

  const loadSpecificPeriodGrades = gradingPeriodId => {
    if (gradingPeriodId === ALL_PERIODS_OPTION) {
      const allGrades = coursesByUser.map(course => ({
        courseId: course.courseId,
        score: course.totalScoreForAllGradingPeriods,
        grade: course.totalGradeForAllGradingPeriods,
      }))
      setSpecificPeriodGrades(allGrades)
    } else if (gradingPeriodId) {
      setLoading(true)
      fetchGradesForGradingPeriod(gradingPeriodId)
        .then(results => {
          setSpecificPeriodGrades(results)
          setLoading(false)
        })
        .catch(err => {
          showFlashError(I18n.t('Failed to load grades for the requested grading period'))(err)
          setLoading(false)
        })
    } else {
      setSpecificPeriodGrades([])
    }
  }

  const handleSelectGradingPeriod = (_, {value}) => {
    selectGradingPeriodId(value)
    loadSpecificPeriodGrades(value)
  }

  // Override current grading period grades with selected period if they exist
  const selectedCourses = overrideCourseGradingPeriods(
    coursesByUser,
    selectedGradingPeriodId,
    specificPeriodGrades
  )

  // Only show the grading period selector if the user has student role
  const hasStudentRole = currentUserRoles?.some(r => ['student', 'observer'].includes(r))

  return (
    <section
      id="dashboard_page_grades"
      style={{display: visible ? 'block' : 'none', margin: '1.5rem 0'}}
      aria-hidden={!visible}
    >
      {hasStudentRole && (
        <>
          <LoadingWrapper
            id="grading-periods"
            isLoading={loading && gradingPeriods.length === 0}
            width="20rem"
            height="4.4rem"
            margin="0"
            screenReaderLabel={I18n.t('Loading grading periods...')}
          >
            {gradingPeriods.length > 1 && (
              <GradingPeriodSelect
                gradingPeriods={gradingPeriods}
                handleSelectGradingPeriod={handleSelectGradingPeriod}
                selectedGradingPeriodId={selectedGradingPeriodId}
              />
            )}
          </LoadingWrapper>
          {(selectedCourses?.length > 0 || loading) && (
            <>
              <View as="div" margin="small 0">
                <Text as="div" size="small">
                  {I18n.t('Totals are calculated based only on graded assignments.')}
                </Text>
              </View>
              <PresentationContent>
                <hr />
              </PresentationContent>
            </>
          )}
        </>
      )}
      <LoadingWrapper
        id="grades"
        isLoading={loading}
        skeletonsNum={selectedCourses?.length} // null is passed until the courses are loaded
        defaultSkeletonsNum={3}
        width="100%"
        height="8.5rem"
        margin="none none medium"
        screenReaderLabel={I18n.t('Loading grades...')}
      >
        {selectedCourses && <GradesSummary courses={selectedCourses} />}
      </LoadingWrapper>
    </section>
  )
}

GradesPage.displayName = 'GradesPage'
GradesPage.propTypes = {
  visible: PropTypes.bool.isRequired,
  currentUserRoles: PropTypes.arrayOf(PropTypes.string).isRequired,
  observedUserId: PropTypes.string,
  currentUser: PropTypes.shape({
    id: PropTypes.string,
    display_name: PropTypes.string,
    avatar_image_url: PropTypes.string,
  }).isRequired,
}
