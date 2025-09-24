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

import React, {useState, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Pagination} from '@instructure/ui-pagination'
import {IconButton} from '@instructure/ui-buttons'
import {IconMessageLine} from '@instructure/ui-icons'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import type {BaseWidgetProps, CourseOption} from '../../../types'
import {useSharedCourses} from '../../../hooks/useSharedCourses'
import {useCourseInstructors} from '../../../hooks/useCourseInstructors'
import {CourseCode} from '../../shared/CourseCode'

const I18n = createI18nScope('widget_dashboard')

const PeopleWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isLoading: externalIsLoading,
  error: externalError,
  onRetry,
}) => {
  const [selectedCourse, setSelectedCourse] = useState<string>('all')

  const {
    data: courseGrades = [],
    isLoading: coursesLoading,
    error: coursesError,
  } = useSharedCourses({
    limit: 1000,
  })
  const userCourses: CourseOption[] = courseGrades.map(courseGrade => ({
    id: courseGrade.courseId,
    name: courseGrade.courseName,
  }))

  const courseOptions: CourseOption[] = useMemo(
    () => [{id: 'all', name: I18n.t('All Courses')}, ...userCourses],
    [userCourses],
  )

  const instructorCourseIds = useMemo(() => {
    if (selectedCourse === 'all') {
      return []
    }
    return [selectedCourse]
  }, [selectedCourse])

  const {
    data: instructors = [],
    isLoading: instructorsLoading,
    error: instructorsError,
    hasNextPage,
    hasPreviousPage,
    currentPage,
    totalPages,
    goToPage,
  } = useCourseInstructors({
    courseIds: instructorCourseIds,
    limit: 5,
  })

  const error =
    externalError ||
    (coursesError ? I18n.t('Failed to load course data. Please try again.') : null) ||
    (instructorsError ? I18n.t('Failed to load instructor data. Please try again.') : null)
  const isLoading = !error && (externalIsLoading || coursesLoading || instructorsLoading)

  const handleCourseChange = (
    _event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => {
    if (data.value && typeof data.value === 'string') {
      setSelectedCourse(data.value)
    }
  }

  const handlePageChange = (pageNumber: number) => {
    goToPage(pageNumber)
  }

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error}
      onRetry={onRetry}
      loadingText={I18n.t('Loading people data...')}
    >
      <Flex direction="column" height="100%">
        <Flex.Item shouldGrow>
          <View as="div" padding="small 0">
            {instructors.length === 0 ? (
              <Text color="secondary">{I18n.t('No instructors found')}</Text>
            ) : (
              <View as="div">
                {instructors.map(instructor => (
                  <Flex key={instructor.id} gap="small" padding="xxx-small 0">
                    <Flex.Item>
                      <Avatar
                        name={instructor.name}
                        src={instructor.avatar_url}
                        size="medium"
                        data-testid={`instructor-avatar-${instructor.id}`}
                      />
                    </Flex.Item>
                    <Flex.Item shouldGrow shouldShrink>
                      <View as="div">
                        <Text size="medium" weight="bold" lineHeight="condensed">
                          {instructor.name}
                        </Text>
                        {instructor.course_code && (
                          <View as="div" margin="xxx-small 0 0 0">
                            <CourseCode
                              courseId={instructor.enrollments[0]?.course_id}
                              overrideCode={instructor.course_code}
                              size="x-small"
                            />
                          </View>
                        )}
                        <View as="div">
                          <Text size="x-small" color="secondary">
                            {instructor.enrollments
                              .map(enrollment => {
                                const role =
                                  enrollment.type === 'TeacherEnrollment'
                                    ? I18n.t('Teacher')
                                    : I18n.t('Teaching Assistant')
                                return role
                              })
                              .join(', ')}
                          </Text>
                        </View>
                        {instructor.email && (
                          <View as="div">
                            <Text size="x-small" color="secondary">
                              {instructor.email}
                            </Text>
                          </View>
                        )}
                      </View>
                    </Flex.Item>
                    <Flex.Item>
                      <View as="div" margin="0 small">
                        <IconButton
                          href={`/conversations?user_name=${encodeURIComponent(instructor.name)}&user_id=${instructor.id.split('-')[0]}`}
                          screenReaderLabel={I18n.t('Send a message to %{instructor}', {
                            instructor: instructor.name,
                          })}
                        >
                          <IconMessageLine />
                        </IconButton>
                      </View>
                    </Flex.Item>
                  </Flex>
                ))}
              </View>
            )}
          </View>
        </Flex.Item>
        {(hasNextPage || hasPreviousPage) && (
          <Flex.Item shouldShrink>
            <View as="div" textAlign="center" padding="x-small 0">
              <Pagination
                as="nav"
                margin="x-small"
                variant="compact"
                currentPage={currentPage}
                totalPageNumber={totalPages}
                onPageChange={handlePageChange}
                aria-label={I18n.t('Instructors pagination')}
              />
            </View>
          </Flex.Item>
        )}
      </Flex>
    </TemplateWidget>
  )
}

export default PeopleWidget
