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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {TemplateWidget} from '@instructure/platform-widget-dashboard'
import CourseGradeCard from './CourseGradeCard'
import type {BaseWidgetProps} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {useWidgetConfig} from '../../../hooks/useWidgetConfig'
import {createGradebookHandler} from './utils'
import {COURSE_GRADES_WIDGET} from '../../../constants'

const I18n = createI18nScope('widget_dashboard')

const EMPTY_GRADE_VISIBILITIES: Record<string, boolean> = {}

const CourseGradesWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  dragHandleProps,
}) => {
  const [globalGradeVisibility, setGlobalGradeVisibility] = useWidgetConfig<boolean>(
    widget.id,
    'showGrades',
    true,
  )
  const [gradeVisibilities, setGradeVisibilities] = useWidgetConfig<Record<string, boolean>>(
    widget.id,
    'gradeVisibilities',
    EMPTY_GRADE_VISIBILITIES,
  )

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

  const handleGradeVisibilityChange = (courseId: string, visible: boolean) => {
    setGradeVisibilities({...gradeVisibilities, [courseId]: visible})
  }

  const handleToggleAllGrades = () => {
    setGlobalGradeVisibility(!globalGradeVisibility)
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
          checked={globalGradeVisibility}
          onChange={handleToggleAllGrades}
          data-testid={
            globalGradeVisibility ? 'hide-all-grades-checkbox' : 'show-all-grades-checkbox'
          }
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
            globalGradeVisibility={gradeVisibilities[grade.courseId] ?? globalGradeVisibility}
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
