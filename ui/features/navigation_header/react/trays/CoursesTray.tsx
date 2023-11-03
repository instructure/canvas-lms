/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {useQuery} from '@canvas/query'
import {SplitCoursesList, CourseListItemContent} from '../lists/SplitCoursesList'
import coursesQuery, {hideHomeroomCourseIfK5Student} from '../queries/coursesQuery'
import type {Course} from '../../../../api.d'

const I18n = useI18nScope('CoursesTray')

export default function CoursesTray() {
  const showSplitList = (window.ENV.current_user_roles || []).includes('teacher')
  const {data, isLoading, isSuccess} = useQuery<Course[], Error>({
    queryKey: ['courses'],
    queryFn: coursesQuery,
    fetchAtLeastOnce: true,
    refetchOnMount: false,
    select: courses => courses.filter(hideHomeroomCourseIfK5Student),
  })
  const k5User = window.ENV.K5_USER

  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {k5User ? I18n.t('Subjects') : I18n.t('Courses')}
      </Heading>
      <hr role="presentation" />
      <List isUnstyled={true} margin="small 0" itemSpacing="small">
        <List.Item key="all">
          <Link isWithinText={false} href="/courses">
            {k5User ? I18n.t('All Subjects') : I18n.t('All Courses')}
          </Link>
        </List.Item>
        <List.Item key="hr">
          <hr role="presentation" />
        </List.Item>
        {isLoading && (
          <List.Item>
            <Spinner delay={500} size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
        {isSuccess && showSplitList && (
          <List.Item>
            <SplitCoursesList courses={data} k5User={k5User} />
          </List.Item>
        )}
        {isSuccess && !showSplitList && (
          <List.Item>
            <List isUnstyled={true} margin="small 0" itemSpacing="small">
              {data.map(course => (
                <List.Item key={course.id}>
                  <CourseListItemContent course={course} />
                </List.Item>
              ))}
            </List>
          </List.Item>
        )}
      </List>
      <br />
      <Text as="div">
        {k5User
          ? I18n.t(
              'Welcome to your subjects! To customize the list of subjects, click on the "All Subjects" link and star the subjects to display.'
            )
          : I18n.t(
              'Welcome to your courses! To customize the list of courses, click on the "All Courses" link and star the courses to display.'
            )}
      </Text>
    </View>
  )
}
