/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseGradeCard from './CourseGradeCard'
import type {BaseWidgetProps} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {createGradebookHandler} from './utils'
import {COURSE_GRADES_WIDGET} from '../../../constants'

const I18n = createI18nScope('widget_dashboard')

const CourseGradesWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  dragHandleProps,
}) => {
  const [gradeVisibilities, setGradeVisibilities] = useState<{[key: string]: boolean}>({})
  const [globalGradeVisibility, setGlobalGradeVisibility] = useState(true)

  const {
    data: courseGrades,
    isLoading,
    error,
    goToPage,
    currentPage,
    totalPages,
  } = useSharedCourses({
    limit: COURSE_GRADES_WIDGET.MAX_GRID_ITEMS,
  })

  const displayedGrades = courseGrades

  // Initialize visibilities for new courses using the global visibility state
  useEffect(() => {
    displayedGrades.forEach(grade => {
      if (!(grade.courseId in gradeVisibilities)) {
        setGradeVisibilities(prev => ({...prev, [grade.courseId]: globalGradeVisibility}))
      }
    })
  }, [displayedGrades, gradeVisibilities, globalGradeVisibility])

  // Calculate if any grades are visible based on current global state
  const hasVisibleGrades = globalGradeVisibility

  const handleGradeVisibilityChange = (courseId: string, visible: boolean) => {
    setGradeVisibilities(prev => ({...prev, [courseId]: visible}))
  }

  const handleToggleAllGrades = () => {
    const newVisibility = !globalGradeVisibility
    setGlobalGradeVisibility(newVisibility)
    // Update visibilities for all currently displayed grades
    const newVisibilities = {...gradeVisibilities}
    displayedGrades.forEach(grade => {
      newVisibilities[grade.courseId] = newVisibility
    })
    setGradeVisibilities(newVisibilities)
  }

  const paginationProps = {
    currentPage,
    totalPages,
    onPageChange: goToPage,
    ariaLabel: I18n.t('Course grades pagination'),
  }

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course grades. Please try again.') : null}
      loadingText={I18n.t('Loading course grades...')}
      pagination={paginationProps}
      headerActions={
        <Checkbox
          label={I18n.t('Show all grades')}
          variant="toggle"
          value="showGrades"
          checked={hasVisibleGrades}
          onChange={handleToggleAllGrades}
          data-testid={hasVisibleGrades ? 'hide-all-grades-checkbox' : 'show-all-grades-checkbox'}
        />
      }
    >
      <div
        role="list"
        aria-label={I18n.t('Course grades')}
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(262px, 262px))',
          gridAutoRows: '1fr',
          gap: '1rem',
          padding: '0.75rem',
          justifyContent: 'center',
        }}
      >
        {displayedGrades.map((grade, gradeIndex) => (
          <CourseGradeCard
            key={grade.courseId}
            courseId={grade.courseId}
            courseCode={grade.courseCode}
            courseName={grade.courseName}
            originalName={grade.originalName}
            currentGrade={grade.currentGrade}
            gradingScheme={grade.gradingScheme}
            lastUpdated={grade.lastUpdated}
            onShowGradebook={createGradebookHandler(grade.courseId)}
            gridIndex={gradeIndex}
            globalGradeVisibility={gradeVisibilities[grade.courseId] ?? true}
            onGradeVisibilityChange={visible =>
              handleGradeVisibilityChange(grade.courseId, visible)
            }
            courseColor={grade.courseColor}
            term={grade.term}
            image={grade.image}
          />
        ))}
      </div>
    </TemplateWidget>
  )
}

export default CourseGradesWidget
