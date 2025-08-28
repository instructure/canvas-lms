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
import {Link} from '@instructure/ui-link'
import {Checkbox} from '@instructure/ui-checkbox'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseGradeCard from './CourseGradeCard'
import type {BaseWidgetProps} from '../../../types'
import {useUserCoursesWithGrades} from '../../../hooks/useUserCourses'
import {createGradebookHandler, createShowAllGradesHandler, limitToGrid} from './utils'
import {COURSE_GRADES_WIDGET} from '../../../constants'

const I18n = createI18nScope('widget_dashboard')

const CourseGradesWidget: React.FC<BaseWidgetProps> = ({widget}) => {
  const {data: courseGrades = [], isLoading, error} = useUserCoursesWithGrades()
  const [gradeVisibilities, setGradeVisibilities] = useState<{[key: string]: boolean}>({})

  const handleShowAllGrades = createShowAllGradesHandler()
  const displayedGrades = limitToGrid(courseGrades)

  // Initialize visibilities for new courses (default to true)
  useEffect(() => {
    displayedGrades.forEach(grade => {
      if (!(grade.courseId in gradeVisibilities)) {
        setGradeVisibilities(prev => ({...prev, [grade.courseId]: true}))
      }
    })
  }, [displayedGrades, gradeVisibilities])

  // Calculate if any grades are visible (default to true if no visibilities set yet)
  const hasVisibleGrades =
    Object.keys(gradeVisibilities).length === 0
      ? true
      : Object.values(gradeVisibilities).some(visible => visible)

  const handleGradeVisibilityChange = (courseId: string, visible: boolean) => {
    setGradeVisibilities(prev => ({...prev, [courseId]: visible}))
  }

  const handleToggleAllGrades = () => {
    const newVisibility = !hasVisibleGrades
    const newVisibilities: {[key: string]: boolean} = {}
    displayedGrades.forEach(grade => {
      newVisibilities[grade.courseId] = newVisibility
    })
    setGradeVisibilities(newVisibilities)
  }

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load course grades. Please try again.') : null}
      loadingText={I18n.t('Loading course grades...')}
      headerActions={
        <Checkbox
          label={I18n.t('Show all grades')}
          variant="toggle"
          value="showGrades"
          checked={hasVisibleGrades}
          onChange={handleToggleAllGrades}
        />
      }
    >
      <Flex direction="column" height="100%">
        <Flex.Item shouldGrow shouldShrink height="30rem">
          <View as="div" overflowX="hidden" overflowY="hidden" height="100%">
            <Grid
              rowSpacing={COURSE_GRADES_WIDGET.GRID_ROW_SPACING}
              colSpacing={COURSE_GRADES_WIDGET.GRID_COL_SPACING}
            >
              {Array.from({length: 2}, (_, rowIndex) => (
                <Grid.Row key={`row-${rowIndex}`}>
                  {Array.from({length: COURSE_GRADES_WIDGET.GRID_COLUMNS}, (_, colIndex) => {
                    const gradeIndex = rowIndex * COURSE_GRADES_WIDGET.GRID_COLUMNS + colIndex
                    const grade = displayedGrades[gradeIndex]

                    return (
                      <Grid.Col key={`col-${rowIndex}-${colIndex}`} width={4}>
                        {grade && (
                          <CourseGradeCard
                            key={grade.courseId}
                            courseId={grade.courseId}
                            courseCode={grade.courseCode}
                            courseName={grade.courseName}
                            currentGrade={grade.currentGrade}
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
              ))}
            </Grid>
          </View>
        </Flex.Item>

        <Flex.Item shouldShrink>
          <View as="div" textAlign="center" padding="small 0">
            <Link
              href="#"
              isWithinText={false}
              onClick={e => {
                e.preventDefault()
                handleShowAllGrades()
              }}
            >
              {I18n.t('View all course grades')}
            </Link>
          </View>
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default CourseGradesWidget
