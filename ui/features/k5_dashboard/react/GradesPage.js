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

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!dashboard_grades_page'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'

import {fetchGrades, fetchGradesForGradingPeriod} from '@canvas/k5/react/utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import GradesSummary from './GradesSummary'
import GradingPeriodSelect from './GradingPeriodSelect'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'

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
      if (!course.gradingPeriods.some(({id}) => id === selectedGradingPeriodId)) return null
      // The course has this grading period, so override the current scores with
      // those from the selected grading period
      const gradingPeriod = specificPeriodGrades.find(gp => gp.courseId === course.courseId)
      if (gradingPeriod) {
        return {
          ...course,
          grade: gradingPeriod.grade,
          score: gradingPeriod.score
        }
      }
      return course
    })
    // Filter out nulls
    .filter(c => c)

export const GradesPage = ({visible, currentUserRoles}) => {
  const [courses, setCourses] = useState(null)
  const [gradingPeriods, setGradingPeriods] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedGradingPeriodId, selectGradingPeriodId] = useState('')
  const [specificPeriodGrades, setSpecificPeriodGrades] = useState([])

  const loadCourses = () => {
    setLoading(true)
    fetchGrades()
      .then(results => results.filter(c => !c.isHomeroom))
      .then(results => {
        setCourses(results)
        setGradingPeriods(getGradingPeriodsFromCourses(results))
        setLoading(false)
      })
      .catch(err => {
        showFlashError(I18n.t('Failed to load the grades tab'))(err)
        setLoading(false)
      })
  }

  useEffect(() => {
    if (!courses && visible) {
      loadCourses()
    }
  }, [courses, visible])

  const loadSpecificPeriodGrades = gradingPeriodId => {
    if (gradingPeriodId) {
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
    courses,
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
        skeletonsCount={selectedCourses?.length || 3}
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
  currentUserRoles: PropTypes.arrayOf(PropTypes.string).isRequired
}

export default GradesPage
