/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Course} from '../../../../api.d'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('CoursesTray')

const UNPUBLISHED = 'unpublished'

export function CourseListItemContent({course}: {course: Course}) {
  return (
    <>
      <Link isWithinText={false} href={`/courses/${course.id}`}>
        {course.name}
      </Link>
      {course.enrollment_term_id > 1 && (
        <Text as="div" size="x-small" weight="light">
          {course.term.name}
        </Text>
      )}
    </>
  )
}

export function SplitCoursesList({courses, k5User}: {courses: Course[]; k5User: boolean}) {
  const publishedCourses = courses.filter(course => course.workflow_state !== UNPUBLISHED)
  const unpublishedCourses = courses.filter(course => course.workflow_state === UNPUBLISHED)
  return (
    <>
      {publishedCourses.length > 0 && (
        <Heading level="h4" as="h3" key="published_courses">
          {k5User ? I18n.t('Published Subjects') : I18n.t('Published Courses')}
        </Heading>
      )}
      <List key="published" isUnstyled={true} margin="small small" itemSpacing="small">
        {publishedCourses.map(course => (
          <List.Item key={course.id}>
            <CourseListItemContent course={course} />
          </List.Item>
        ))}
      </List>
      {unpublishedCourses.length > 0 && (
        <Heading level="h4" as="h3" key="unpublished_courses">
          {k5User ? I18n.t('Unpublished Subjects') : I18n.t('Unpublished Courses')}
        </Heading>
      )}
      <List key="unpublished" isUnstyled={true} margin="small small" itemSpacing="small">
        {unpublishedCourses.map(course => (
          <List.Item key={course.id}>
            <CourseListItemContent course={course} />
          </List.Item>
        ))}
      </List>
    </>
  )
}
