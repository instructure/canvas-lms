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
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Course} from '../../../../api.d'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const ENV: GlobalEnv

const I18n = createI18nScope('CoursesTray')

const UNPUBLISHED = 'unpublished'

export const CourseListItemContent = ({course}: {course: Course}) => {
  const sectionNames = (course.sections || []).map(section => section.name)
  // @ts-expect-error
  const showSections = ENV.SETTINGS?.show_sections_in_course_tray
  const sectionDetails =
    showSections && sectionNames.length > 0 ? sectionNames.sort().join(', ') : null
  const courseDetails =
    ENV.FEATURES?.courses_popout_sisid && course.sis_course_id
      ? course.enrollment_term_id > 1
        ? I18n.t('SIS ID: %{courseSisId} | Term: %{termName}', {
            courseSisId: course.sis_course_id,
            termName: course.term.name,
          })
        : I18n.t('SIS ID: %{courseSisId}', {
            courseSisId: course.sis_course_id,
          })
      : course.enrollment_term_id > 1
        ? I18n.t('Term: %{termName}', {
            termName: course.term.name,
          })
        : null

  return (
    <>
      <Link isWithinText={false} href={`/courses/${course.id}`}>
        <Text as="div" size="medium">
          {course.name}
        </Text>
      </Link>
      {sectionDetails && (
        <Text as="div" size="x-small" weight="light">
          {sectionDetails}
        </Text>
      )}
      {courseDetails && (
        <Text as="div" size="x-small" weight="light">
          {courseDetails}
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
        <>
          <Heading level="h4" as="h3" key="published_courses">
            {k5User ? I18n.t('Published Subjects') : I18n.t('Published Courses')}
          </Heading>
          <List key="published" isUnstyled={true} margin="small small" itemSpacing="small">
            {publishedCourses.map(course => (
              <List.Item key={course.id}>
                <CourseListItemContent course={course} />
              </List.Item>
            ))}
          </List>
        </>
      )}
      {unpublishedCourses.length > 0 && (
        <>
          <Heading level="h4" as="h3" key="unpublished_courses">
            {k5User ? I18n.t('Unpublished Subjects') : I18n.t('Unpublished Courses')}
          </Heading>
          <List key="unpublished" isUnstyled={true} margin="small small" itemSpacing="small">
            {unpublishedCourses.map(course => (
              <List.Item key={course.id}>
                <CourseListItemContent course={course} />
              </List.Item>
            ))}
          </List>
        </>
      )}
    </>
  )
}
