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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Grid} from '@instructure/ui-grid'
import {Checkbox} from '@instructure/ui-checkbox'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseGradeCard from './CourseGradeCard'
import type {BaseWidgetProps} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {createGradebookHandler} from './utils'
import {COURSE_GRADES_WIDGET} from '../../../constants'
import {useResponsiveContext} from '../../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

const CourseGradesWidget: React.FC<BaseWidgetProps> = ({widget, isEditMode = false}) => {
  const [gradeVisibilities, setGradeVisibilities] = useState<{[key: string]: boolean}>({})
  const [globalGradeVisibility, setGlobalGradeVisibility] = useState(true)
  const {isMobile} = useResponsiveContext()

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
      <Flex direction="column" height="100%">
        <Flex.Item shouldGrow shouldShrink height="auto">
          <View as="div" padding="xx-small">
            <Grid
              rowSpacing={COURSE_GRADES_WIDGET.GRID_ROW_SPACING}
              colSpacing={COURSE_GRADES_WIDGET.GRID_COL_SPACING}
              startAt="medium"
              role="list"
            >
              {isMobile ? (
                <Grid.Row>
                  {displayedGrades.map((grade, gradeIndex) => (
                    <Grid.Col
                      key={grade.courseId}
                      width={{
                        small: 12,
                        medium: 4,
                        large: 4,
                      }}
                    >
                      <CourseGradeCard
                        courseId={grade.courseId}
                        courseCode={grade.courseCode}
                        courseName={grade.courseName}
                        currentGrade={grade.currentGrade}
                        gradingScheme={grade.gradingScheme}
                        lastUpdated={grade.lastUpdated}
                        onShowGradebook={createGradebookHandler(grade.courseId)}
                        gridIndex={gradeIndex}
                        globalGradeVisibility={gradeVisibilities[grade.courseId] ?? true}
                        onGradeVisibilityChange={visible =>
                          handleGradeVisibilityChange(grade.courseId, visible)
                        }
                      />
                    </Grid.Col>
                  ))}
                </Grid.Row>
              ) : (
                Array.from({length: 3}, (_, rowIndex) => (
                  <Grid.Row key={`row-${rowIndex}`}>
                    {Array.from({length: COURSE_GRADES_WIDGET.GRID_COLUMNS}, (_, colIndex) => {
                      const gradeIndex = rowIndex * COURSE_GRADES_WIDGET.GRID_COLUMNS + colIndex
                      const grade = displayedGrades[gradeIndex]

                      return (
                        <Grid.Col key={`col-${rowIndex}-${colIndex}`} width={6}>
                          {grade && (
                            <CourseGradeCard
                              key={grade.courseId}
                              courseId={grade.courseId}
                              courseCode={grade.courseCode}
                              courseName={grade.courseName}
                              currentGrade={grade.currentGrade}
                              gradingScheme={grade.gradingScheme}
                              lastUpdated={grade.lastUpdated}
                              onShowGradebook={createGradebookHandler(grade.courseId)}
                              gridIndex={gradeIndex}
                              globalGradeVisibility={gradeVisibilities[grade.courseId] ?? true}
                              onGradeVisibilityChange={visible =>
                                handleGradeVisibilityChange(grade.courseId, visible)
                              }
                            />
                          )}
                        </Grid.Col>
                      )
                    })}
                  </Grid.Row>
                ))
              )}
            </Grid>
          </View>
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default CourseGradesWidget
